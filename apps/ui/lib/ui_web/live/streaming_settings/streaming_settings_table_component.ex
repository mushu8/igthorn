defmodule UiWeb.StreamingSettingsLive.Table do
  @moduledoc false

  use UiWeb, :live_component

  @impl true
  def render(assigns) do
    ~H"""
    <table class="table table-hover">
      <tbody>
        <tr>
          <th>Symbol</th>
          <th>Status</th>
        </tr>
        <.live_component
          module={__MODULE__.Row}
          :for={setting <- @settings}
          id={"setting-row-#{setting.symbol}"}
          setting={setting} />
      </tbody>
    </table>
    """
  end
end
