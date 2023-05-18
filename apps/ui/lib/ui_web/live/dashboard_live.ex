defmodule UiWeb.DashboardLive do
  @moduledoc false

  use Phoenix.LiveView

  def render(assigns) do
    ~H"""
    <script src="/dist/js/chart.js"></script>
    <div class="row">
      <div class="col-xs-12">
        <%= live_render(@socket, UiWeb.PriceFeedLive, id: "price-feed-live") %>
      </div>
    </div>
    <div class="row">
      <div class="col-md-8">
        <%= live_render(@socket, UiWeb.PriceChartLive, id: "price-chart-live") %>
        <%= live_render(@socket, UiWeb.TradesChartLive, id: "trades-chart-live") %>
      </div>
      <div class="col-md-4">
        <%= live_render(@socket, UiWeb.ProfitIndicatorLive, id: "profit-indicatorfeed-live") %>
        <%= live_render(@socket, UiWeb.GainingLosingTradesLive, id: "gl-trades-live") %>
      </div>
    </div>
    """
  end

  def mount(_params, _session, socket) do
    socket = assign(
      socket,
      page_title: "Dashboard",
      section_subtitle: "Overview of the system"
    )
    {:ok, socket}
  end
end
