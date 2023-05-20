defmodule UiWeb.NaiveTraderSettingsLive.Table.Row do
  @moduledoc false

  use UiWeb, :live_component

  @impl true
  def render(assigns) do
    ~H"""
    <tr>
      <td><%= @nts.symbol %></td>
      <td><%= @nts.budget %></td>
      <td><%= @nts.chunks %></td>
      <td><%= @nts.profit_interval %></td>
      <td><%= @nts.buy_down_interval %></td>
      <td><%= @nts.retarget_interval %></td>
      <td><%= @nts.rebuy_interval %></td>
      <td><%= @nts.stop_loss_interval %></td>
      <td>
          <span class={"label label-#{status_decoration(@nts.status)}"}>
            <%= status(@nts.status) %>
          </span>
      </td>
      <td>
        <div class="btn-group">
          <button type="button" phx-click={"edit-row-#{@nts.symbol}"} class="btn btn-default">Edit</button>
          <button type="button" class="btn btn-default dropdown-toggle" data-toggle="dropdown" aria-expanded="false">
            <span class="caret"></span>
            <span class="sr-only">More options</span>
          </button>
          <ul class="dropdown-menu" role="menu">
            <li>
              <a href="#" phx-click={"start-trade-symbol-#{@nts.symbol}"}>Start trading</a>
            </li>
            <li>
              <a href="#" phx-click={"force-stop-trade-symbol-#{@nts.symbol}"}>Force stop trading</a>
            </li>
            <li>
              <a href="#" phx-click={"gracefully-stop-trade-symbol-#{@nts.symbol}"}>Gracefully stop trading</a>
            </li>
          </ul>
        </div>
      </td>
    </tr>
    """
  end

  defp status_decoration("ON"), do: "success"
  defp status_decoration("OFF"), do: "info"
  defp status_decoration("SHUTDOWN"), do: "warning"

  defp status("ON"), do: "Trading"
  defp status("OFF"), do: "Disabled"
  defp status("SHUTDOWN"), do: "Shutdown"
end
