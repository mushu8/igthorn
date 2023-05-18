defmodule UiWeb.NaiveTraderSettingsLive do
  @moduledoc false

  use Phoenix.LiveView

  def render(assigns) do
    ~L"""
    <div class="row">
      <div class="col-xs-12">
        <div class="box">
          <div class="box-header">
            <h3 class="box-title">Naive trader settings</h3>
            <div class="box-tools">
              <form phx-change="search" phx-submit="search" id="search">
                <div class="input-group input-group-sm" style="width: 180px;">
                  <input type="text" name="search" class="form-control pull-right" placeholder="Search" value="<%= @search %>">
                  <div class="input-group-btn">
                    <button type="submit" class="btn btn-default"><i class="fa fa-search"></i></button>
                  </div>
                </div>
              </form>
            </div>
          </div>
          <!-- /.box-header -->
          <%= if length(@naive_trader_settings_data.list) > 0 do %>
            <div class="box-body table-responsive no-padding">
              <div class="box-body">
                <form phx-change="rows" phx-submit="rows">
                  <div class="input-group input-group-sm col-xs-1">
                    <select class="form-control" name="rows_per_page">
                      <%= for row <- @rows_numbers do %>
                        <option value="<%= row %>"
                        <%= if row == @set_rows do %>
                          selected
                        <% end %>
                        ><%= row %></option>
                      <% end %>
                    </select>
                    <span class="input-group-btn">
                      <button type="submit" class="btn btn-info btn-flat">Rows</button>
                    </span>
                  </div>
                </form>
              </div>
              <br>
              <form phx_change="save-row" phx-submit="save-row">
                <table class="table table-hover">
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
                  <tbody>
                    <%= for nts <- Keyword.values(@naive_trader_settings_data.list) do %>
                      <%= if @edit_row == nts.symbol do %>
                        <tr>
                          <td>
                            <input type="hidden" name="symbol" value="<%= nts.symbol %>">
                            <%= nts.symbol %>
                          </td>
                          <td>
                              <input class="form-control input-sm" type="text" name="budget" value="<%= nts.budget %>">
                          </td>
                          <td>
                            <input class="form-control input-sm" type="text" name="chunks" value="<%= nts.chunks %>">
                          </td>
                          <td>
                            <input class="form-control input-sm" type="text" name="profit_interval" value="<%= nts.profit_interval %>">
                          </td>
                          <td>
                            <input class="form-control input-sm" type="text" name="buy_down_interval" value="<%= nts.buy_down_interval %>">
                          </td>
                          <td>
                            <input class="form-control input-sm" type="text" name="retarget_interval" value="<%= nts.retarget_interval %>">
                          </td>
                          <td>
                            <input class="form-control input-sm" type="text" name="rebuy_interval" value="<%= nts.rebuy_interval %>">
                          </td>
                          <td>
                            <input class="form-control input-sm" type="text" name="stop_loss_interval" value="<%= nts.stop_loss_interval %>">
                          </td>
                          <td>
                            <%= nts.status %>
                          </td>
                          <td>
                            <button type="submit" class="btn btn-block btn-info btn-xs"><span class="fa fa-edit"></span>Save</button>
                          </td>
                        </tr>
                      <% else %>
                        <tr>
                          <td><%= nts.symbol %></td>
                          <td><%= nts.budget %></td>
                          <td><%= nts.chunks %></td>
                          <td><%= nts.profit_interval %></td>
                          <td><%= nts.buy_down_interval %></td>
                          <td><%= nts.retarget_interval %></td>
                          <td><%= nts.rebuy_interval %></td>
                          <td><%= nts.stop_loss_interval %></td>
                          <td>
                              <span class="label label-<%= status_decoration(nts.status) %>">
                                <%= status(nts.status) %>
                              </span>
                          </td>
                          <td>
                            <div class="btn-group">
                              <button type="button" phx-click="edit-row-<%= nts.symbol %>" class="btn btn-default">Edit</button>
                              <button type="button" class="btn btn-default dropdown-toggle" data-toggle="dropdown" aria-expanded="false">
                                <span class="caret"></span>
                                <span class="sr-only">More options</span>
                              </button>
                              <ul class="dropdown-menu" role="menu">
                                <li><a href="#" phx-click="start-trade-symbol-<%= nts.symbol %>">Start trading</a></li>
                                <li><a href="#" phx-click="force-stop-trade-symbol-<%= nts.symbol %>">Force stop trading</a></li>
                                <li><a href="#" phx-click="gracefully-stop-trade-symbol-<%= nts.symbol %>">Gracefully stop trading</a></li>
                              </ul>
                            </div>
                          </td>
                        </tr>
                      <%end %>
                    <% end %>
                  </tbody>
                </table>
              </form>
            </div>
            <div class="box-footer clearfix">
              <span><%= @naive_trader_settings_data.total %> rows</span>
              <%= if show_pagination?(@naive_trader_settings_data.limit, @naive_trader_settings_data.total) do %>
                <ul class="pagination pagination-sm no-margin pull-right">
                  <li><a phx-click="pagination-1" href="#">«</a></li>
                  <%= for link <- @naive_trader_settings_data.pagination_links do %>
                    <li <%= if link == @naive_trader_settings_data.page do %>
                        class="active"
                      <% end %>
                    >
                      <a phx-click="pagination-<%= link %>" href="#"><%= link %></a>
                    </li>
                  <% end %>
                  <li><a phx-click="pagination-<%= @naive_trader_settings_data.pages %>" href="#">»</a></li>
                </ul>
              <% end %>
            </div>
          <% end %>
          <!-- /.box-body -->
        </div>
        <!-- /.box -->
      </div>
    </div>
    """
  end

  def mount(%{}, _session, socket) do
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

  defp status("ON"), do: "Trading"
  defp status("OFF"), do: "Disabled"
  defp status("SHUTDOWN"), do: "Shutdown"
  defp status_decoration("ON"), do: "success"
  defp status_decoration("OFF"), do: "info"
  defp status_decoration("SHUTDOWN"), do: "warning"

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

  def handle_event("rows", %{"rows_per_page" => limit}, socket) do
    {:noreply,
     assign(socket,
       naive_trader_settings_data:
         naive_trader_settings_data(String.to_integer(limit), 1, socket.assigns.search),
       set_rows: String.to_integer(limit),
       search: socket.assigns.search
     )}
  end

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

  def handle_event("edit-row-" <> symbol, _, socket) do
    {:noreply, assign(socket, edit_row: symbol)}
  end

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

  def handle_event("start-trade-symbol-" <> symbol, "", socket) do
    update_status(symbol, "ON", socket)
  end

  def handle_event("force-stop-trade-symbol-" <> symbol, "", socket) do
    update_status(symbol, "OFF", socket)
  end

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
      :pages => round(Float.ceil(all / limit)),
      :pagination_links => pagination_links,
      :page => page,
      :limit => limit
    }
  end

  defp show_pagination?(limit, total), do: limit < total
end
