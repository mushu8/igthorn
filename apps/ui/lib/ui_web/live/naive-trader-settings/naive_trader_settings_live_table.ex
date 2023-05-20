defmodule UiWeb.NaiveTraderSettingsLive.Table do
  @moduledoc false

  use UiWeb, :live_component

  @impl true
  def render(assigns) do
    ~H"""
    <form phx_change="save-row" phx-submit="save-row">
      <table class="table table-hover">
        <.table_header/>
        <tbody>
          <%= for nts <- @naive_trader_settings_data do %>
            <%= if @edit_row == nts.symbol do %>
              <.live_component
                module={__MODULE__.EditRow}
                id={"naive-trader-settings-table-edit-row-#{nts.symbol}"}
                nts={nts}/>
            <% else %>
              <.live_component
                module={__MODULE__.Row}
                id={"naive-trader-settings-table-row-#{nts.symbol}"}
                nts={nts}/>
            <%end %>
          <% end %>
        </tbody>
      </table>
    </form>
    """
  end

  defp table_header(assigns) do
    ~H"""
    <tbody>
      <th>Symbol</th>
      <th>Budget</th>
      <th>Chunks</th>
      <th>Profit Interval</th>
      <th>Buy Down Interval</th>
      <th>Retarget Interval</th>
      <th>Rebuy Interval</th>
      <th>Stop Loss Interval</th>
      <th>Trading</th>
      <th></th>
    </tbody>
    """
  end
end
