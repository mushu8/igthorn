defmodule Hefty.Streaming.Binance.Streamer do
  use WebSockex, restart: :temporary

  require Logger

  defmodule State do
    defstruct symbol: nil
  end

  def start_link(symbol) do
    symbol = String.downcase(symbol)
    Logger.debug("Starting streaming on #{symbol}")
    Logger.debug("wss://stream.binance.com:9443/ws/#{symbol}@trade")

    WebSockex.start_link(
      "wss://stream.binance.com:9443/ws/#{symbol}@trade",
      __MODULE__,
      %State{
        :symbol => symbol
      },
      name: :"#{__MODULE__}-#{symbol}"
      # debug: [:trace]
    )
  end

  @doc """
  This function will be used to handle incoming trade events.

  Two things needs  to happen:
  - store trade event
  - inform interested parties about event
  """
  def handle_frame({:text, msg}, state) do
    Logger.debug("Frame received")

    case JSON.decode(msg) do
      {:ok, event} -> handle_event(event, state)
      _ -> throw("Unable to parse: " <> msg)
    end
  end

  defp handle_event(%{"e" => "trade"} = event, state) do
    Logger.debug("Getting event - #{event["e"]}")

    # {:ok, trade_event} =
      %Hefty.Repo.Binance.TradeEvent{
        :event_type => event["e"],
        :event_time => event["E"],
        :symbol => event["s"],
        :trade_id => event["t"],
        :price => event["p"],
        :quantity => event["q"],
        :buyer_order_id => event["b"],
        :seller_order_id => event["a"],
        :trade_time => event["T"],
        :buyer_market_maker => event["m"]
      }
      |> Hefty.Repo.insert()

    # UiWeb.Endpoint.broadcast_from(
    #   self(),
    #   "stream-#{trade_event.symbol}",
    #   "trade_event",
    #   trade_event
    # )

    {:ok, state}
  end
end
