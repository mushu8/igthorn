defmodule UiWeb.StreamingSettingsLive do
  @moduledoc false

  use UiWeb, :live_view
  require Logger

  # %Hefty.Repo.StreamingSetting
  @impl true
  def mount(_params, _session, socket) do
    settings =
      Hefty.Streams.fetch_settings()
      |> Enum.into([], &{:"#{&1.symbol}", &1})

    socket = assign(
      socket,
      page_title: "Streaming settings",
      section_subtitle: "Enabled or disable streaming on specific symbols",
      settings: settings,
      search: ""
    )

    {:ok, socket}
  end

  @impl true
  def handle_event("stream-symbol-" <> symbol, _, socket) do
    Logger.info("Flipping streaming of " <> symbol, entity: "SettingLive")
    Hefty.Streams.flip_streamer(symbol)

    settings =
      Keyword.update!(
        socket.assigns.settings,
        :"#{symbol}",
        &%{&1 | :enabled => !&1.enabled}
      )

    {:noreply, assign(socket, settings: settings)}
  end

  @impl true
  def handle_event("search", %{"search" => search}, socket) do
    settings =
      Hefty.Streams.fetch_settings(search)
      |> Enum.into([], &{:"#{&1.symbol}", &1})

    {:noreply, assign(socket, settings: settings, search: search)}
  end
end
