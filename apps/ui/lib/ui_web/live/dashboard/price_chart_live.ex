defmodule UiWeb.PriceChartLive do
  @moduledoc false

  use UiWeb, :live_view
  alias Timex, as: T

  @impl true
  def render(assigns) do
    ~H"""
      <%= if not is_nil(@data.symbol) do %>
        <div class="row">
          <div class="col-md-12">
            <!-- AREA CHART -->
            <div class="box box-primary">
              <div class="box-header with-border">
                <h3 class="box-title">
                  Price Chart
                </h3>
                 <div class="box-tools pull-right">
              <button type="button" class="btn btn-box-tool" data-widget="collapse"><i class="fa fa-minus"></i>
              </button>
              <button type="button" class="btn btn-box-tool" data-widget="remove"><i class="fa fa-times"></i></button>
            </div>
              </div>
              <div class="box-body">
                <div class="col-xs-2">
                  <form phx-change="change-symbol" id="price-chart-change-symbol">
                    <select name="selected_symbol" class="form-control">
                      <%= for row <- @symbols do %>
                      <option value={row} selected={row == @data.symbol}>
                        <%= row %>
                      </option>
                      <% end %>
                    </select>
                  </form>
                </div>
                <div class="chart">
                  <canvas id="lineChart" style="display: block; width: 1000px!important; height: 400px; margin: auto;" width="1000" height="400"></canvas>
                  <script id={"chart-#{Base.encode64(:erlang.md5(@data.prices))}"}>
                    renderChart(
                      [
                        <%= for l <- @data.labels do %>
                        "<%= l %>",
                        <% end %>
                      ], "<%= @data.symbol %>", <%= @data.prices %>)
                  </script>
                </div>
              </div>
              <!-- /.box-body -->
            </div>
            <!-- /.box -->
          </div>
        </div>
      <% end %>
    """
  end

  @impl true
  def mount(_params, _session, socket) do
    symbols =
      Hefty.Streams.fetch_streaming_symbols()
      |> Map.keys()

    symbol =
      symbols
      |> List.first()

    symbols
    |> Enum.map(&UiWeb.Endpoint.subscribe("stream-#{&1}"))

    {:ok, assign(socket, data: price_chart_data(symbol), symbols: symbols)}
  end

  @impl true
  def handle_info(%{event: "trade_event"}, socket) do
    {:noreply,
     assign(socket,
       data: price_chart_data(socket.assigns.data.symbol),
       symbols: socket.assigns.symbols
     )}
  end

  @impl true
  def handle_event("change-symbol", %{"selected_symbol" => selected_symbol}, socket) do
    {:noreply,
     assign(socket, data: price_chart_data(selected_symbol), symbols: socket.assigns.symbols)}
  end

  defp price_chart_data(symbol) when is_nil(symbol), do: %{:symbol => nil}

  defp price_chart_data(symbol) do
    data = Hefty.TradeEvents.fetch_latest_prices(symbol)

    prices =
      data
      |> Enum.map(&List.first/1)
      |> Enum.reverse()
      |> Enum.map(&String.to_float/1)
      |> Jason.encode!()

    labels =
      data
      |> Enum.map(&List.last/1)
      |> Enum.reverse()
      |> Enum.map(&T.format!(&1, "{h24}:{0m}:{0s}"))

    %{
      :labels => labels,
      :symbol => symbol,
      :prices => prices
    }
  end
end
