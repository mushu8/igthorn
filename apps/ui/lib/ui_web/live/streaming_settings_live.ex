defmodule UiWeb.StreamingSettingsLive do
  @moduledoc false

  use Phoenix.LiveView
  require Logger

  def render(assigns) do
    ~L"""
        <div class="row">
        <div class="col-xs-12">
          <div class="box">
            <div class="box-header">
              <h3 class="box-title">Streaming settings</h3>

              <div class="box-tools">
                <form phx-change="search" phx-submit="search">
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
            <div class="box-body table-responsive no-padding">
              <table class="table table-hover">
                <tbody><tr>
                  <th>Symbol</th>
                  <th>Status</th>
                </tr>
                <%= for setting <- Keyword.values(@settings) do %>
                <tr>
                  <td><%= setting.symbol %></td>
                  <td><a role="button" phx-click="stream-symbol-<%= setting.symbol %>"><span class="label label-<%= enabled_to_class(setting.enabled) %>"><%= enabled_to_text(setting.enabled) %></span></a></td>
                </tr>
                <% end %>
              </tbody></table>
            </div>
            <!-- /.box-body -->
          </div>
          <!-- /.box -->
        </div>
      </div>
    """
  end

  def mount(_params, _session, socket) do
    settings =
      Hefty.Streams.fetch_settings()
      |> Enum.into([], &{:"#{&1.symbol}", &1})

    socket =
      assign(
        socket,
        %{
          page_title: "Streaming settings",
          section_subtitle: "Enabled or disable streaming on specific symbols",
          settings: settings,
          search: ""
        }
      )

    {:ok, socket}
  end

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

  def handle_event("search", %{"search" => search}, socket) do
    settings =
      Hefty.Streams.fetch_settings(search)
      |> Enum.into([], &{:"#{&1.symbol}", &1})

    {:noreply, assign(socket, settings: settings, search: search)}
  end

  def enabled_to_class(true), do: "success"
  def enabled_to_class(_), do: "danger"

  def enabled_to_text(true), do: "Streaming"
  def enabled_to_text(_), do: "Stopped"
end
