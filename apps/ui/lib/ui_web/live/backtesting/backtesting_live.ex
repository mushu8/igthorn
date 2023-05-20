defmodule UiWeb.BacktestingLive do
  @moduledoc false

  use UiWeb, :live_view

  @impl true
  def mount(_params, _session, socket) do
    symbols = Hefty.Pairs.fetch_symbols()

    socket =
      assign(
        socket,
        page_title: "Backtesting",
        section_subtitle: "Stream data through the system and check results",
        symbols: symbols
      )

    {:ok, socket}
  end

  @impl true
  def handle_event(
        "kick-off-backtesting",
        %{"symbol" => symbol, "date-range" => date_range},
        socket
      ) do
    [from_date, to_date] = convert_daterange_to_dates(date_range)
    stats = Hefty.Backtesting.kick_off_backtesting(symbol, from_date, to_date)
    # UiWeb.Endpoint.subscribe("stream-backtesting-#{symbol}")
    {:noreply, assign(socket, stats: stats)}
  end

  defp convert_daterange_to_dates(daterange) do
    [_from, _to] = String.split(daterange, " - ")
  end
end
