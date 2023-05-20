defmodule UiWeb.Router do
  @moduledoc false
  use UiWeb, :router

  pipeline :browser do
    plug(:accepts, ["html"])
    plug(:fetch_session)
    plug(:fetch_live_flash)
    plug(:put_root_layout, {UiWeb.Layouts, :root})
    plug(:protect_from_forgery)
    plug(:put_secure_browser_headers)
  end

  scope "/", UiWeb do
    pipe_through(:browser)

    live("/", DashboardLive)
    live("/streaming-settings", StreamingSettingsLive)
    live("/trades", TradesLive)
    live("/orders", OrdersLive)
    live("/backtesting", BacktestingLive)
    live("/naive-trader-settings", NaiveTraderSettingsLive)
    live("/settings", SettingsLive)
  end

  if Application.compile_env(:ui, :dev_routes) do
    # If you want to use the LiveDashboard in production, you should put
    # it behind authentication and allow only admins to access it.
    # If your application does not have an admins-only section yet,
    # you can use Plug.BasicAuth to set up some basic authentication
    # as long as you are also using SSL (which you should anyway).
    import Phoenix.LiveDashboard.Router

    scope "/dev" do
      pipe_through(:browser)

      live_dashboard("/dashboard", metrics: UiWeb.Telemetry)
    end
  end
end
