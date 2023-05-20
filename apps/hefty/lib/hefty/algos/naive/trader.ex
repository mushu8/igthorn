defmodule Hefty.Algos.Naive.Trader do
  use GenServer, restart: :temporary
  require Logger
  import Ecto.Query, only: [from: 2]
  alias Decimal, as: D

  @binance_client Application.compile_env(:hefty, :exchanges).binance

  @moduledoc """
  Hefty.Algos.Naive.Trader module is responsible for making a trade(buy + sell)
  on a single symbol.

  Naive trader is simple strategy which hopes that it will get on more raising
  waves than drops.

  Idea is based on "My Adventures in Automated Crypto Trading" presentation
  by Timothy Clayton @ https://youtu.be/b-8ciz6w9Xo?t=2297

  It requires few informations to work:
  - symbol
  - budget (amount of coins in "quote" currency)
  - profit interval (expected net profit in % - this will be used to set
  `sell orders` at level of `buy price`+`buy_fee`+`sell_fee`+`expected profit`)
  - buy down interval (expected buy price in % under current value)
  - chunks (split of budget to transactions - for example 5 represents
  up 5 transactions at the time - none of them will be more than 20%
  of budget*)
  - stop loss interval (defines % of value that stop loss order will be at)

  NaiveTrader implements retargeting when buying - as price will go up it
  will "follow up" with buy order price to keep `buy down interval` distance
  (as price it will go down it won't retarget as it would never buy anything)

  On buying NaiveTrader puts 2 orders:
  - `sell order` at price of
     ((`buy price` * (1 + `buy order fee`)) * (1 + `profit interval`)) * (1 + `sell price fee`)
  - stop loss order at
      `buy price` * (1 - `stop loss interval`)
  """
  defmodule State do
    defstruct id: nil,
              symbol: nil,
              strategy: :blank,
              budget: nil,
              buy_order: nil,
              sell_order: nil,
              buy_down_interval: nil,
              profit_interval: nil,
              stop_loss_interval: nil,
              stop_loss_triggered: false,
              rebuy_interval: nil,
              rebuy_notified: false,
              retarget_interval: nil,
              pair: nil,
              trade: nil
  end

  def start_link({symbol, strategy, data}) do
    GenServer.start_link(__MODULE__, {symbol, strategy, data})
  end

  def init({symbol, strategy, data}) do
    Logger.debug("Trader starting(symbol: #{symbol}, strategy: #{strategy})")
    GenServer.cast(self(), {:init_strategy, strategy, data})

    Logger.debug("Trader subscribing to #{"stream-#{symbol}"}")
    # :ok = UiWeb.Endpoint.subscribe("stream-#{symbol}")

    {:ok,
     %State{
       :symbol => symbol,
       :strategy => strategy
     }}
  end

  @doc """
  Blank strategy called on init when there's no state
  to be passed to trader.
  """
  def handle_cast({:init_strategy, :blank, _state}, state) do
    Logger.debug("Trader initialized successfully")
    settings = fetch_settings(state.symbol)

    fresh_state = prepare_state(state.symbol, settings)

    Logger.info(
      "Starting trader(#{fresh_state.id}) on symbol #{settings.symbol} with budget" <>
        " of #{D.to_float(fresh_state.budget)}"
    )

    {:noreply, fresh_state}
  end

  # Continue strategy called on init when trading was stopped
  # and there's no detailed state in leader so only buy and sell
  # order can be passed from leader (fetched from db)
  def handle_cast(
        {
          :init_strategy,
          :continue,
          %{
            :trade => trade,
            :buy_order => buy_order,
            :sell_order => sell_order
          }
        },
        state
      ) do
    Logger.debug("Trader initialized successfully")

    fresh_state = prepare_state(state.symbol, fetch_settings(state.symbol))

    Logger.info(
      "Starting trader(#{fresh_state.id}) on symbol #{state.symbol} with budget" <>
        " of #{D.to_float(fresh_state.budget)}"
    )

    {:noreply,
     Map.merge(fresh_state, %{
       :buy_order => buy_order,
       :sell_order => sell_order,
       :trade => trade
     })}
  end

  # Restart strategy called on init when leader is aware of exact
  # state what trader was in before stopping. Current state of trader
  # is ignored.
  def handle_cast(
        {
          :init_strategy,
          :restart,
          %State{:symbol => symbol, :budget => budget} = new_state
        },
        _state
      ) do
    Logger.info("Starting trader on symbol #{symbol} with budget of #{budget}")
    {:noreply, new_state}
  end

  # Updates settings cache.
  def handle_cast({:update_settings, settings}, state) do
    Logger.debug("Updating trader(#{state.id}) settings")

    {:noreply,
     Map.merge(prepare_state(state.symbol, settings), %{
       :buy_order => state.buy_order,
       :sell_order => state.sell_order,
       :trade => state.trade
     })}
  end

  # Re-enable rebuy notification
  def handle_cast(:reenable_rebuy, state) do
    {:noreply, %{state | rebuy_notified: false}}
  end

  # -----------
  # HANDLE CALL
  # -----------

  def handle_call(
        :stop_trading,
        _from,
        %State{
          :id => id,
          :symbol => symbol,
          :buy_order => buy_order
        } = state
      ) do
    stop_trading(id, symbol, buy_order)
    {:reply, :ok, %{state | :buy_order => nil}}
  end

  @doc """
  Situation:

  Clean slate - no buy trade placed

  It will try to make limit buy order based on current price (from event) taking under
  consideration substracting `buy_down_interval`
  """
  def handle_info(
        %{
          event: "trade_event",
          payload: %Hefty.Repo.Binance.TradeEvent{price: price} = event
        },
        %State{
          buy_order: nil,
          symbol: symbol
        } = state
      ) do
    Logger.debug("Placing buy order - event received - #{inspect(event)}")

    new_state =
      case place_buy_order(price, state) do
        {:ok, order} ->
          new_state = %State{state | :buy_order => order}
          Hefty.Algos.Naive.Leader.notify(symbol, :state, new_state)
          new_state

        {:error, :price_level_taken, price} ->
          handle_price_level_taken(price, state)
          state
      end

    {:noreply, new_state}
  end

  # Situation:
  # Buy order was placed but it didn't get filled yet. Incoming event
  # points to that buy order
  # Updates buy order as incoming transaction is filling our buy order
  # If buy order is now fully filled it will submit sell order.
  def handle_info(
        %{
          event: "trade_event",
          payload:
            %Hefty.Repo.Binance.TradeEvent{
              buyer_order_id: order_id
            } = event
        },
        %State{
          buy_order:
            %Hefty.Repo.Binance.Order{
              order_id: order_id,
              symbol: symbol,
              time: time,
              price: price
            } = buy_order,
          profit_interval: profit_interval,
          pair: %Hefty.Repo.Binance.Pair{price_tick_size: tick_size},
          symbol: symbol,
          id: id
        } = state
      ) do
    Logger.debug("Buy order filling - event received - #{inspect(event)}")

    Logger.info(
      "Trader(#{id}) received an transaction of #{event.quantity} for BUY order #{order_id} @ #{price}"
    )

    # Race condition here - when a lot of transactions are happening - before we will
    # make this query there's second transaction happened in Binance and this
    # order will be fully filled but another event will show up here later which will
    # have problem of this buy order being closed.
    {:ok, current_buy_order} = @binance_client.get_order(symbol, time, order_id)

    {:ok, new_state} =
      case current_buy_order.executed_qty == current_buy_order.orig_qty do
        true ->
          Logger.debug("Current buy order has been filled. Submitting sell order")

          Hefty.Repo.transaction(fn ->
            trade = Hefty.Trades.create_trade(buy_order)

            sell_order = create_sell_order(buy_order, profit_interval, tick_size)

            new_buy_order =
              update_order(buy_order, %{
                :executed_quantity => current_buy_order.executed_qty,
                :status => current_buy_order.status
              })

            %{state | :buy_order => new_buy_order, :sell_order => sell_order, :trade => trade}
          end)

        false ->
          new_buy_order =
            update_order(buy_order, %{
              :executed_quantity => current_buy_order.executed_qty,
              :status => current_buy_order.status
            })

          {:ok, %{state | :buy_order => new_buy_order}}
      end

    Hefty.Algos.Naive.Leader.notify(symbol, :state, new_state)
    {:noreply, new_state}
  end

  # Situation:
  # Buy order and sell order are already placed. Incoming event points to
  # our sell order.
  # Updates sell order as incoming transaction is filling our sell order
  # If sell order is now fully filled it should stop trading.
  def handle_info(
        %{
          event: "trade_event",
          payload:
            %Hefty.Repo.Binance.TradeEvent{
              seller_order_id: order_id
            } = event
        },
        %State{
          buy_order: buy_order,
          sell_order:
            %Hefty.Repo.Binance.Order{
              order_id: order_id,
              symbol: symbol,
              time: time,
              price: price
            } = sell_order,
          trade: trade,
          symbol: symbol,
          id: id
        } = state
      ) do
    Logger.debug("Sell order filling - event received - #{inspect(event)}")

    Logger.info(
      "Trader(#{id}) received an transaction of #{event.quantity} for SELL order #{order_id} @ #{price}"
    )

    {:ok, current_sell_order} = @binance_client.get_order(symbol, time, order_id)

    new_sell_order =
      update_order(sell_order, %{
        # To cover market orders
        :price => current_sell_order.price,
        :executed_quantity => current_sell_order.executed_qty,
        :status => current_sell_order.status
      })

    new_state = %{state | :sell_order => new_sell_order}

    case current_sell_order.executed_qty == current_sell_order.orig_qty do
      true ->
        Logger.debug("Current sell order has been filled. Process can terminate")

        trade = Hefty.Trades.update_trade(trade, buy_order, new_sell_order)

        new_state = %{new_state | :trade => trade}

        GenServer.cast(
          :"#{Hefty.Algos.Naive.Leader}-#{symbol}",
          {:trade_finished, self(), new_state}
        )

      _ ->
        nil
    end

    Hefty.Algos.Naive.Leader.notify(symbol, :state, new_state)
    {:noreply, new_state}
  end

  # Situation:
  # Buy order is placed and not filled, price is increasing so we need check did
  # it grow more than `retarget_interval`, then we need to cancel order and
  # place another one based on current value
  def handle_info(
        %{
          event: "trade_event",
          payload: %Hefty.Repo.Binance.TradeEvent{price: price} = event
        },
        %State{
          buy_order:
            %Hefty.Repo.Binance.Order{
              order_id: order_id,
              trade_id: trade_id,
              price: order_price,
              executed_quantity: "0.00000000",
              time: timestamp
            } = buy_order,
          retarget_interval: retarget_interval,
          symbol: symbol,
          id: id
        } = state
      ) do
    Logger.debug("RETARGET - event received - #{inspect(event)}")

    d_current_price = D.new(price)
    d_order_price = D.new(order_price)

    retarget_price = D.add(d_order_price, D.mult(d_order_price, D.new(retarget_interval)))

    new_state =
      case D.compare(retarget_price, d_current_price) do
        :lt ->
          Logger.info(
            "Trader(#{id}) - Retargeting triggered for trade #{trade_id}" <>
              " with buy order @ #{order_price}" <>
              " as price raised above #{D.to_float(retarget_price)}"
          )

          Logger.info("Cancelling BUY order #{order_id}")

          case @binance_client.cancel_order(symbol, timestamp, order_id) do
            {:ok, %Binance.Order{} = canceled_order} ->
              Logger.debug("Successfully canceled BUY order #{order_id}")

              update_order(buy_order, %{
                status: canceled_order.status,
                time: canceled_order.time
              })

            {:error, %{"code" => -2011, "msg" => "Unknown order sent."}} ->
              update_order(buy_order, %{
                status: "CANCELED"
              })
          end

          %{state | :buy_order => nil}

        _ ->
          state
      end

    Hefty.Algos.Naive.Leader.notify(symbol, :state, new_state)
    {:noreply, new_state}
  end

  # Situation
  # STOP LOSS OR REBUY:
  # Buy and sell orders were placed, only buy got filled.
  # Price is dropping - stop loss should be triggered
  def handle_info(
        %{
          event: "trade_event",
          payload: %Hefty.Repo.Binance.TradeEvent{price: current_price} = event
        },
        %State{
          buy_order:
            %Hefty.Repo.Binance.Order{
              price: buy_price,
              executed_quantity: matching_quantity,
              original_quantity: matching_quantity
            } = buy_order,
          sell_order: %Hefty.Repo.Binance.Order{} = sell_order,
          stop_loss_interval: stop_loss_interval,
          stop_loss_triggered: stop_loss_triggered,
          rebuy_interval: rebuy_interval,
          rebuy_notified: rebuy_notified,
          symbol: symbol
        } = state
      ) do
    Logger.debug("STOP LOSS / REBUY - event received - #{inspect(event)}")

    new_state =
      if !stop_loss_triggered do
        case is_stop_loss(buy_price, current_price, stop_loss_interval) do
          false -> state
          stop_loss_price -> handle_stop_loss(buy_order, sell_order, stop_loss_price, state)
        end
      else
        state
      end

    new_state =
      if !rebuy_notified do
        case is_rebuy(buy_price, current_price, rebuy_interval) do
          false -> new_state
          rebuy_price -> handle_rebuy(rebuy_price, new_state)
        end
      else
        new_state
      end

    Hefty.Algos.Naive.Leader.notify(symbol, :state, new_state)
    {:noreply, new_state}
  end

  # Situation:
  # Rebuy scenario after placing buy order
  def handle_info(
        %{
          event: "trade_event",
          payload: %Hefty.Repo.Binance.TradeEvent{price: current_price}
        },
        %State{
          buy_order: %Hefty.Repo.Binance.Order{
            price: buy_price
          },
          rebuy_interval: rebuy_interval,
          rebuy_notified: rebuy_notified,
          symbol: symbol
        } = state
      ) do
    new_state =
      if !rebuy_notified do
        case is_rebuy(buy_price, current_price, rebuy_interval) do
          false -> state
          rebuy_price -> handle_rebuy(rebuy_price, state)
        end
      else
        state
      end

    Hefty.Algos.Naive.Leader.notify(symbol, :state, new_state)
    {:noreply, new_state}
  end

  defp is_stop_loss(buy_price, current_price, stop_loss_interval) do
    d_current_price = D.new(current_price)
    d_buy_price = D.new(buy_price)

    stop_loss_price = D.sub(d_buy_price, D.mult(d_buy_price, D.new(stop_loss_interval)))

    case D.compare(d_current_price, stop_loss_price) do
      :lt -> stop_loss_price
      _ -> false
    end
  end

  defp is_rebuy(buy_price, current_price, rebuy_interval) do
    d_current_price = D.new(current_price)
    d_buy_price = D.new(buy_price)

    rebuy_price = D.sub(d_buy_price, D.mult(d_buy_price, D.new(rebuy_interval)))

    case D.compare(d_current_price, rebuy_price) do
      :lt -> rebuy_price
      _ -> false
    end
  end

  defp handle_rebuy(
         rebuy_price,
         %State{
           buy_order: %Hefty.Repo.Binance.Order{
             trade_id: trade_id,
             price: buy_price
           },
           symbol: symbol,
           id: id
         } = state
       ) do
    Logger.info(
      "Trader(#{id}) - Rebuy triggered for trade #{trade_id} bought @ #{buy_price}" <>
        " as price fallen below #{D.to_float(rebuy_price)}"
    )

    Hefty.Algos.Naive.Leader.notify(symbol, :rebuy)

    %{state | :rebuy_notified => true}
  end

  defp handle_stop_loss(
         %Hefty.Repo.Binance.Order{
           price: buy_price
         },
         %Hefty.Repo.Binance.Order{
           order_id: order_id,
           time: timestamp,
           original_quantity: original_quantity,
           trade_id: trade_id
         } = sell_order,
         stop_loss_price,
         %State{
           symbol: symbol,
           id: id
         } = state
       ) do
    Logger.info(
      "Trader(#{id}) - Stop loss triggered for trade #{trade_id} bought @ #{buy_price}" <>
        " as price fallen below #{D.to_float(stop_loss_price)}"
    )

    Logger.debug("Cancelling SELL order #{order_id}")

    {:ok, %Binance.Order{} = canceled_order} =
      @binance_client.cancel_order(symbol, timestamp, order_id)

    Logger.debug("Successfully canceled BUY order #{order_id}")

    update_order(sell_order, %{
      executed_quantity: canceled_order.executed_qty,
      status: canceled_order.status,
      time: canceled_order.time
    })

    # just in case of partially filled order
    remaining_quantity =
      D.to_float(D.sub(D.new(original_quantity), D.new(canceled_order.executed_qty)))

    Logger.info(
      "Trader(#{id}) - Placing stop loss MARKET SELL order for #{symbol} " <>
        "@ MARKET PRICE, quantity: #{remaining_quantity}"
    )

    {:ok, market_sell_order} = @binance_client.order_market_sell(symbol, remaining_quantity)

    Logger.debug(
      "Successfully placed an stop loss market SELL order #{market_sell_order.order_id}"
    )

    stop_loss_order = store_order(market_sell_order, trade_id)

    %{state | :stop_loss_triggered => true, :sell_order => stop_loss_order}
  end

  defp place_buy_order(price, %State{
         buy_order: nil,
         id: id,
         symbol: symbol,
         buy_down_interval: buy_down_interval,
         budget: budget,
         pair: %Hefty.Repo.Binance.Pair{
           price_tick_size: tick_size,
           quantity_step_size: quantity_step_size
         }
       }) do
    target_price = calculate_target_price(price, buy_down_interval, tick_size)
    quantity = calculate_quantity(budget, target_price, quantity_step_size)

    case Hefty.Algos.Naive.Leader.is_price_level_available(symbol, target_price) do
      true ->
        Logger.info(
          "Trader(#{id}) - Placing BUY order for #{symbol} @ #{target_price}, quantity: #{quantity}"
        )

        {:ok, res} =
          @binance_client.order_limit_buy(
            symbol,
            quantity,
            target_price,
            "GTC"
          )

        Logger.debug("Trader #{id} successfully placed an BUY order #{res.order_id}")

        {:ok, store_order(res)}

      false ->
        Logger.info(
          "Trader #{id}: Price level(#{target_price}) not available for trader(#{id}) on symbol #{symbol}"
        )

        {:error, :price_level_taken, target_price}
    end
  end

  defp prepare_state(symbol, settings) do
    pair = fetch_pair(symbol)
    budget = D.div(D.new(settings.budget), settings.chunks)
    id = rem(:os.system_time(:second), 100_000)

    %State{
      id: id,
      symbol: settings.symbol,
      budget: budget,
      buy_down_interval: settings.buy_down_interval,
      profit_interval: settings.profit_interval,
      stop_loss_interval: settings.stop_loss_interval,
      retarget_interval: settings.retarget_interval,
      rebuy_interval: settings.rebuy_interval,
      pair: pair
    }
  end

  defp fetch_settings(symbol) do
    from(nts in Hefty.Repo.NaiveTraderSetting,
      where: nts.platform == "Binance" and nts.symbol == ^symbol
    )
    |> Hefty.Repo.one()
  end

  defp fetch_pair(symbol) do
    query =
      from(p in Hefty.Repo.Binance.Pair,
        where: p.symbol == ^symbol
      )

    Hefty.Repo.one(query)
  end

  defp calculate_target_price(price, buy_down_interval, tick_size) do
    current_price = D.new(price)
    interval = D.new(buy_down_interval)
    tick = D.new(tick_size)

    # not necessarily legal price
    exact_target_price = D.sub(current_price, D.mult(current_price, interval))

    D.to_float(D.mult(D.div_int(exact_target_price, tick), tick))
  end

  defp calculate_quantity(budget, price, quantity_step_size) do
    step = D.new(quantity_step_size)
    price = D.from_float(price)

    # not necessarily legal quantity
    exact_target_quantity = D.div(budget, price)

    D.to_float(D.mult(D.div_int(exact_target_quantity, step), step))
  end

  defp store_order(%Binance.OrderResponse{} = response, trade_id \\ nil) do
    Logger.debug("Storing order #{response.order_id} to db")

    %Hefty.Repo.Binance.Order{
      :order_id => response.order_id,
      :symbol => response.symbol,
      :client_order_id => response.client_order_id,
      :price => response.price,
      :original_quantity => response.orig_qty,
      :executed_quantity => response.executed_qty,
      # :cummulative_quote_quantity => response.X, # missing??
      :status => response.status,
      :time_in_force => response.time_in_force,
      :type => response.type,
      :side => response.side,
      # :stop_price => response.X, # missing ??
      # :iceberg_quantity => response.X, # missing ??
      :time => response.transact_time,
      # :update_time => response.X, # missing ??
      # :is_working => response.X, # gave up on this
      :strategy => "#{__MODULE__}",
      :trade_id => trade_id || response.order_id
    }
    |> Hefty.Repo.insert()
    |> elem(1)
  end

  defp create_sell_order(
         %Hefty.Repo.Binance.Order{
           symbol: symbol,
           price: buy_price,
           original_quantity: quantity,
           trade_id: trade_id
         },
         profit_interval,
         tick_size
       ) do
    # close enough
    sell_price = calculate_sell_price(buy_price, profit_interval, tick_size)
    quantity = D.to_float(D.new(quantity))

    Logger.info("Placing SELL order for #{symbol} @ #{sell_price}, quantity: #{quantity}")

    {:ok, res} =
      @binance_client.order_limit_sell(
        symbol,
        quantity,
        sell_price,
        "GTC"
      )

    Logger.debug("Successfully placed an SELL order #{res.order_id}")

    store_order(res, trade_id)
  end

  defp calculate_sell_price(buy_price, profit_interval, tick_size) do
    fee = D.add(D.new("1.0"), D.new(Application.get_env(:hefty, :trading).defaults.fee))
    buy_price = D.new(buy_price)
    real_buy_price = D.mult(buy_price, fee)
    tick = D.new(tick_size)

    net_target_price = D.mult(real_buy_price, D.add(1, D.new(profit_interval)))
    gross_target_price = D.mult(net_target_price, fee)
    D.to_float(D.mult(D.div_int(gross_target_price, tick), tick))
  end

  defp update_order(%Hefty.Repo.Binance.Order{} = order, %{} = changes) do
    changeset = Ecto.Changeset.change(order, changes)

    case Hefty.Repo.update(changeset) do
      {:ok, struct} -> struct
      {:error, _changeset} -> throw("Unable to update buy order")
    end
  end

  defp stop_trading(trader_id, symbol, buy_order) do
    Logger.info("Shuting down trader(#{trader_id}) on #{symbol}")

    # :ok = UiWeb.Endpoint.unsubscribe("stream-#{symbol}")

    case buy_order do
      nil ->
        Logger.info("Trader #{trader_id} didn't have any buy orders open so nothing to do")

      %Hefty.Repo.Binance.Order{
        :time => timestamp,
        :order_id => order_id
      } ->
        Logger.info("Trader #{trader_id} had a buy order open - canceling and updating db")

        {:ok, %Binance.Order{} = canceled_order} =
          @binance_client.cancel_order(symbol, timestamp, order_id)

        Logger.debug("Successfully canceled BUY order #{order_id}")

        update_order(buy_order, %{
          status: canceled_order.status,
          time: canceled_order.time
        })
    end
  end

  defp handle_price_level_taken(
         price,
         %State{
           :id => trader_id,
           :symbol => symbol,
           :buy_order => buy_order
         }
       ) do
    stop_trading(trader_id, symbol, buy_order)

    GenServer.cast(
      :"#{Hefty.Algos.Naive.Leader}-#{symbol}",
      {:reenable_rebuy, price}
    )

    GenServer.cast(
      :"#{Hefty.Algos.Naive.Leader}-#{symbol}",
      {:kill, self()}
    )
  end
end
