defmodule UiWeb.StreamingSettingsController do
  @moduledoc false

  use UiWeb, :controller

  # def index(conn, _params) do
  #   settings =
  #     Hefty.Streams.fetch_settings()
  #     |> Enum.into([], &{:"#{&1.symbol}", &1})

  #   conn
  #   |> assign(:page_title, "Streaming settings")
  #   |> assign(:section_subtitle, "Enabled or disable streaming on specific symbols")
  #   |> live_render(UiWeb.StreamingSettingsLive, session: %{settings: settings})
  # end
end
