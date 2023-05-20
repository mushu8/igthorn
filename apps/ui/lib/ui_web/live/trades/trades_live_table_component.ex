defmodule UiWeb.TradesLive.Table do
  @moduledoc false

  alias Timex, as: T

  use UiWeb, :live_component

  @impl true
  def render(assigns) do
    ~H"""
    <table class="table table-hover">
      <thead>
        <tr>
          <th>Id</th>
          <th>Symbol</th>
          <th>Buy price</th>
          <th>Sell price</th>
          <th>Quantity</th>
          <th>State</th>
          <th>Profit base currency</th>
          <th>Profit %</th>
          <th>Profit time</th>
        </tr>
      </thead>
      <tbody>
        <tr :for={trade <- @trades_data}>
          <td><%= trade.id %></td>
          <td><%= trade.symbol %></td>
          <td><%= trade.buy_price %></td>
          <td><%= trade.sell_price %></td>
          <td><%= trade.quantity %></td>
          <td><%= trade.state %></td>
          <td><%= trade.profit_base_currency %></td>
          <td><%= trade.profit_percentage %></td>
          <td><%= timestamp_to_datetime(trade.sell_time) %></td>
        </tr>
      </tbody>
    </table>
    """
  end

  defp timestamp_to_datetime(nil), do: nil

  defp timestamp_to_datetime(timestamp) do
    (timestamp / 1000)
    |> round()
    |> DateTime.from_unix!()
    |> T.format!("{YYYY}-{0M}-{0D} {h24}:{0m}:{0s}")
  end
end
