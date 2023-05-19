defmodule UiWeb.StreamingSettingsLive.Table.Row do
  @moduledoc false

  use UiWeb, :live_component

  @impl true
  def render(assigns) do
    ~H"""
      <tr>
        <td><%= @setting.symbol %></td>
        <td>
          <a role="button" phx-click={"stream-symbol-#{@setting.symbol}"}>
            <span class={"label label-#{enabled_to_class(@setting.enabled)}"}>
              <%= enabled_to_text(@setting.enabled) %>
            </span>
          </a>
        </td>
      </tr>
    """
  end

  def enabled_to_class(true), do: "success"
  def enabled_to_class(_), do: "danger"

  def enabled_to_text(true), do: "Streaming"
  def enabled_to_text(_), do: "Stopped"
end
