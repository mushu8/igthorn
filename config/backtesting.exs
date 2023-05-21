import Config

import_config "dev.exs"

# Hefty

config :hefty,
  env: config_env(),
  exchanges: %{
    binance: Hefty.Exchanges.BinanceMock
  }

# Configure your database
config :hefty, Hefty.Repo,
  database: "hefty_backtesting"

config :logger, level: :info

# UI

config :ui, UiWeb.Endpoint, code_reloader: false
