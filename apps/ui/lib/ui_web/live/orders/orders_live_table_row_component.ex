defmodule UiWeb.Orders.OrdersLive.Table.Row do
  @moduledoc false

  alias Timex, as: T

  use UiWeb, :live_component

  @impl true
  def render(assigns) do
    ~H"""
    <tr>
      <td><%= @order.id %></td>
      <td><%= @order.trade_id %></td>
      <td><%= @order.symbol %></td>
      <td><%= @order.price %></td>
      <td><%= @order.original_quantity %></td>
      <td><%= @order.executed_quantity %></td>
      <td><%= @order.side %></td>
      <td><%= @order.status %></td>
      <td><%= @order.type %></td>
      <td><%= timestamp_to_datetime(@order.time) %></td>
    </tr>
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
