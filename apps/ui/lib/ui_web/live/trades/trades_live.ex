defmodule UiWeb.TradesLive do
  @moduledoc false

  use UiWeb, :live_view

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     assign(socket,
       page_title: "Trades",
       section_subtitle: "Trades",
       trades_data: trades_data(50, 1, ""),
       rows_numbers: [10, 20, 30, 40, 50, 100, 200],
       set_rows: 50,
       search: ""
     )}
  end

  @impl true
  def handle_event("search", %{"search" => search}, socket) do
    {:noreply,
     assign(socket,
       trades_data: trades_data(50, 1, search),
       rows_numbers: [10, 20, 30, 40, 50, 100, 200],
       set_rows: socket.assigns.set_rows,
       search: search
     )}
  end

  @impl true
  def handle_event("rows", %{"rows_per_page" => limit}, socket) do
    {:noreply,
     assign(socket,
       trades_data: trades_data(String.to_integer(limit), 1, socket.assigns.search),
       rows_numbers: [10, 20, 30, 40, 50, 100, 200],
       set_rows: String.to_integer(limit),
       search: socket.assigns.search
     )}
  end

  @impl true
  def handle_event("pagination-" <> page, _, socket) do
    {:noreply,
     assign(socket,
       trades_data:
         trades_data(
           socket.assigns.trades_data.limit,
           String.to_integer(page),
           socket.assigns.search
         ),
       rows_numbers: [10, 20, 30, 40, 50, 100, 200],
       set_rows: socket.assigns.set_rows,
       search: socket.assigns.search
     )}
  end

  defp trades_data(limit, page, search) do
    trades = Hefty.Trades.fetch((page - 1) * limit, limit, search)

    all = Hefty.Trades.count(search)

    pagination_links =
      Enum.filter(
        (page - 3)..(page + 3),
        &(&1 >= 1 and &1 <= round(Float.ceil(all / limit)))
      )

    %{
      :list => trades,
      :total => all,
      :page => page,
      :limit => limit,
      :pagination_links => pagination_links,
      :pages => pages_number(all, limit),
      :show_pagination? => show_pagination?(limit, all)
    }
  end

  defp pages_number(all, limit), do: round(Float.ceil(all / limit))
  defp show_pagination?(limit, total), do: limit < total
end
