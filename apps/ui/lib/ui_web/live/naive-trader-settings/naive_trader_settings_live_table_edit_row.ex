defmodule UiWeb.NaiveTraderSettingsLive.Table.EditRow do
  @moduledoc false

  use UiWeb, :live_component

  @impl true
  def render(assigns) do
    ~H"""
    <tr>
      <td>
        <input type="hidden" name="symbol" value={@nts.symbol}>
        <%= @nts.symbol %>
      </td>
      <td>
          <input class="form-control input-sm" type="text" name="budget" value={@nts.budget}>
      </td>
      <td>
        <input class="form-control input-sm" type="text" name="chunks" value={@nts.chunks}>
      </td>
      <td>
        <input class="form-control input-sm" type="text" name="profit_interval" value={@nts.profit_interval}>
      </td>
      <td>
        <input class="form-control input-sm" type="text" name="buy_down_interval" value={@nts.buy_down_interval}>
      </td>
      <td>
        <input class="form-control input-sm" type="text" name="retarget_interval" value={@nts.retarget_interval}>
      </td>
      <td>
        <input class="form-control input-sm" type="text" name="rebuy_interval" value={@nts.rebuy_interval}>
      </td>
      <td>
        <input class="form-control input-sm" type="text" name="stop_loss_interval" value={@nts.stop_loss_interval}>
      </td>
      <td>
        <%= @nts.status %>
      </td>
      <td>
        <button type="submit" class="btn btn-block btn-info btn-xs"><span class="fa fa-edit"></span>Save</button>
      </td>
    </tr>
    """
  end
end
