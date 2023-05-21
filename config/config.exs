# This file is responsible for configuring your umbrella
# and **all applications** and their dependencies with the
# help of the Config module.
#
# Note that all applications in your umbrella share the
# same configuration and dependencies, which is why they
# all use the same configuration file. If you want different
# configurations or dependencies per app, it is best to
# move said applications out of the umbrella.
import Config

# Hefty

config :hefty,
  env: config_env(),
  ecto_repos: [Hefty.Repo],
  exchanges: %{
    binance: Binance
  },
  trading: %{
    :defaults => %{
      :chunks => 50,
      :budget => "1000.0",
      # 0.25%
      :profit_interval => "0.0025",
      # buy down should never be below 0.15% as stop losses
      # would generate even more losses
      # 0.1%
      :buy_down_interval => "0.001",
      # 5%
      :stop_loss_interval => "0.05",
      # 0.2% - buy down so 0.1% really
      # needs to be always bigger than buy_down_interval!!
      :retarget_interval => "0.002",
      # 0.1%
      :rebuy_interval => "0.001",
      # WARNING: Change this to 0.001 if you won't pay fees in BNB
      :fee => "0.00075"
      # :fee => "0.001"
    }
  }

config :hefty, Hefty.Repo,
  username: "postgres",
  password: "postgres",
  database: "hefty_dev",
  hostname: "localhost",
  port: 5432,
  pool_size: 10,
  log: :debug,
  timeout: 60_000,
  stacktrace: true,
  show_sensitive_data_on_connection_error: true

config :binance,
  api_key: "",
  secret_key: ""

# UI

# Configures the endpoint
config :ui, UiWeb.Endpoint,
  url: [host: "localhost"],
  secret_key_base: "R23gwF7fVqXLhFsqsIyDPxPwZiZPKzZxjtJHw+p1U4vHPJdk3dh1zB6PK1tyYtYV",
  render_errors: [
    formats: [html: Ui.ErrorHTML],
    layout: false
  ],
  pubsub_server: Hefty.PubSub,
  live_view: [signing_salt: "SECRET_SALT"]

# Configure esbuild (the version is required)
config :esbuild,
  version: "0.17.19",
  default: [
    args:
      ~w(js/app.js --bundle --target=es2017 --outdir=../priv/static/assets --external:/fonts/* --external:/images/*),
    cd: Path.expand("../apps/ui_web/assets", __DIR__),
    env: %{"NODE_PATH" => Path.expand("../deps", __DIR__)}
  ]

# Common to all apps

config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:application, :request_id, :module]

# Import environment specific config.
# This must remain at the bottom of this file so
# it overrides the configuration defined above.
import_config "#{config_env()}.exs"
