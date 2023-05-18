defmodule UiWeb.PriceFeedLive do
  @moduledoc false

  use Phoenix.LiveView
  alias Decimal, as: D

  def render(assigns) do
    ~L"""
      Current prices of streamed symbol
      <div class="box">
        <div class="box-header">
          <h3 class="box-title">Current prices</h3>
          <div class="box-tools pull-right">
            <form phx_change="validate" phx-submit="validate">
              <div class="input-group input-group-sm" style="width: 180px;">
                <input type="text" name="search" class="form-control pull-right" placeholder="Search">
                <div class="input-group-btn">
                  <button type="submit" class="btn btn-default"><i class="fa fa-search"></i></button>
                </div>
              </div>
            </form>
          </div>
        </div>
        <!-- /.box-header -->
        <%= if length(@ticks) > 0 do %>
          <div class="box-body table-responsive no-padding">
            <table class="table table-hover">
              <tbody><tr>
                <th>Symbol</th>
                <th>Price</th>
              </tr>
              <%= for tick <- Keyword.values(@ticks) do %>
              <tr>
                <td><%= tick.symbol %></td>
                <td>
                  <span class="<%= elem(get_direction_indicators(tick.direction), 0) %>">
                    <i class="fa <%= elem(get_direction_indicators(tick.direction), 1) %>"></i>
                    <%= tick.price %>
                  </span>
                </td>
              </tr>
              <% end %>
            </tbody></table>
          </div>
        <% else %>
          <div class="box-body">
            You are not streaming any symbols at the moment. Go to "Streaming settings" to enable
            streaming on symbols that will show up here
          </div>
        <% end %>
        <!-- /.box-body -->
      </div>
      <!-- /.box -->
    """
  end

  def mount(_params, _session, socket) do
    ticks =
      Hefty.Streams.fetch_streaming_symbols()
      |> symbols_to_keywords

    ticks
    |> Keyword.keys()
    |> Enum.map(&UiWeb.Endpoint.subscribe("stream-#{&1}"))

    ticks =
      ticks
      |> Enum.map(fn {key, data} -> {key, Map.put_new(data, :direction, :eq)} end)

    {:ok, assign(socket, ticks: ticks)}
  end

  def handle_event("validate", %{"search" => search}, socket) do
    ticks =
      Hefty.Streams.fetch_streaming_symbols(search)
      |> symbols_to_keywords

    # todo: possibly unsubrice all non-showing symbols here

    {:noreply, assign(socket, ticks: ticks)}
  end

  def handle_info(%{event: "trade_event", payload: event}, socket) do
    old_tick =
      Keyword.get(
        socket.assigns.ticks,
        :"#{event.symbol}"
      )

    ticks =
      Keyword.update!(
        socket.assigns.ticks,
        :"#{event.symbol}",
        &%{&1 | :price => event.price, :direction => get_direction(event.price, old_tick.price)}
      )

    {:noreply, assign(socket, ticks: ticks)}
  end

  defp symbols_to_keywords(symbols) do
    symbols
    |> Enum.map(&elem(&1, 0))
    |> Enum.map(&fetch_tick(&1))
    |> Enum.into([], &{:"#{&1.symbol}", &1})
  end

  defp fetch_tick(symbol) do
    case Hefty.TradeEvents.fetch_price(symbol) do
      nil -> %{:symbol => symbol, :price => "Not available"}
      price -> %{:symbol => symbol, :price => price}
    end
  end

  defp get_direction(new_price, old_price), do: D.compare(new_price, old_price)

  defp get_direction_indicators(:gt), do: {"text-green", "fa-angle-up"}
  defp get_direction_indicators(:lt), do: {"text-red", "fa-angle-down"}
  defp get_direction_indicators(:eq), do: {"text-black", "fa-angle-left"}
end
