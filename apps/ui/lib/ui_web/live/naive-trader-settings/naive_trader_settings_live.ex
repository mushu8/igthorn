defmodule UiWeb.NaiveTraderSettingsLive do
  @moduledoc false

  use UiWeb, :live_view

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     assign(socket,
       page_title: "Naive trader settings",
       section_subtitle: "Settings and enabling or disabling for naive trading",
       naive_trader_settings_data: naive_trader_settings_data(50, 1, ""),
       rows_numbers: [10, 20, 30, 40, 50, 100, 200],
       set_rows: 50,
       edit_row: nil,
       search: ""
     )}
  end

  @impl true
  def handle_event("search", %{"search" => search}, socket) do
    {:noreply,
     assign(socket,
       naive_trader_settings_data:
         naive_trader_settings_data(
           socket.assigns.naive_trader_settings_data.limit,
           1,
           search
         ),
       search: search
     )}
  end

  @impl true
  def handle_event("rows", %{"rows_per_page" => limit}, socket) do
    {:noreply,
     assign(socket,
       naive_trader_settings_data:
         naive_trader_settings_data(String.to_integer(limit), 1, socket.assigns.search),
       set_rows: String.to_integer(limit),
       search: socket.assigns.search
     )}
  end

  @impl true
  def handle_event("pagination-" <> page, _, socket) do
    {:noreply,
     assign(socket,
       naive_trader_settings_data:
         naive_trader_settings_data(
           socket.assigns.naive_trader_settings_data.limit,
           String.to_integer(page),
           socket.assigns.search
         ),
       search: socket.assigns.search
     )}
  end

  @impl true
  def handle_event("edit-row-" <> symbol, _, socket) do
    {:noreply, assign(socket, edit_row: symbol)}
  end

  @impl true
  def handle_event("save-row", data, socket) do
    Hefty.Traders.update_naive_trader_settings(data)

    {:noreply,
     assign(socket,
       naive_trader_settings_data:
         naive_trader_settings_data(
           socket.assigns.naive_trader_settings_data.limit,
           socket.assigns.naive_trader_settings_data.page,
           socket.assigns.search
         ),
       edit_row: nil
     )}
  end

  @impl true
  def handle_event("start-trade-symbol-" <> symbol, "", socket) do
    update_status(symbol, "ON", socket)
  end

  @impl true
  def handle_event("force-stop-trade-symbol-" <> symbol, "", socket) do
    update_status(symbol, "OFF", socket)
  end

  @impl true
  def handle_event("gracefully-stop-trade-symbol-" <> symbol, "", socket) do
    update_status(symbol, "SHUTDOWN", socket)
  end

  defp update_status(symbol, status, socket) do
    Hefty.Traders.update_status(symbol, status)

    {:noreply,
     assign(socket,
       naive_trader_settings_data:
         naive_trader_settings_data(
           socket.assigns.naive_trader_settings_data.limit,
           socket.assigns.naive_trader_settings_data.page,
           socket.assigns.search
         ),
       edit_row: nil
     )}
  end

  defp naive_trader_settings_data(limit, page, search) do
    pagination =
      Hefty.Traders.fetch_naive_trader_settings((page - 1) * limit, limit, search)
      |> Enum.into([], &{:"#{&1.symbol}", &1})

    all = Hefty.Traders.count_naive_trader_settings(search)

    pagination_links =
      Enum.filter(
        (page - 3)..(page + 3),
        &(&1 >= 1 and &1 <= round(Float.ceil(all / limit)))
      )

    %{
      :list => pagination,
      :total => all,
      :pages => pages_count(all, limit),
      :pagination_links => pagination_links,
      :page => page,
      :limit => limit,
      :show_pagination? => show_pagination?(limit, all)
    }
  end

  defp pages_count(all, limit), do: round(Float.ceil(all / limit))
  defp show_pagination?(limit, total), do: limit < total
end
