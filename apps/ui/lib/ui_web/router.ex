defmodule UiWeb.Router do
  @moduledoc false
  use UiWeb, :router

  pipeline :browser do
    plug(:accepts, ["html"])
    plug(:fetch_session)
    plug :fetch_live_flash
    plug(:put_root_layout, {UiWeb.Layouts, :root})
    plug(:protect_from_forgery)
    plug(:put_secure_browser_headers)
  end

  pipeline :api do
    plug(:accepts, ["json"])
  end

  scope "/", UiWeb do
    pipe_through(:browser)

    get("/", PageController, :index)
    get("/streaming-settings", StreamingSettingsController, :index)
    get("/orders", OrdersController, :index)
    get("/trades", TradesController, :index)
    get("/transactions", TransactionsController, :index)
    get("/backtesting", BacktestingController, :index)
    get("/naive-trader-settings", NaiveSettingsController, :index)
    get("/settings", SettingsController, :index)
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
      forward("/mailbox", Plug.Swoosh.MailboxPreview)
    end
  end
end
