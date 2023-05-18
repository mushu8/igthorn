# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
import Config

# This configuration is loaded before any dependency and is restricted
# to this project. If another project depends on this project, this
# file won't be loaded nor affect the parent project. For this reason,
# if you want to provide default values for your application for
# third-party users, it should be done in your "mix.exs" file.

# You can configure your application as:
#
#     config :hefty, key: :value
#
# and access this configuration in your application as:
#
#     Application.get_env(:hefty, :key)
#
# You can also configure a third-party app:
#
#     config :logger, level: :info
#

# It is also possible to import configuration files, relative to this
# directory. For example, you can emulate configuration per environment
# by uncommenting the line below and defining dev.exs, test.exs and such.
# Configuration from the imported file will override the ones defined
# here (which is why it is important to import them last).

config :hefty,
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

# Configure your database
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

config :logger,
  backends: [:console],
  level: :debug

config :logger, :console,
  format: "\n$time $metadata[$level] $levelpad$message\n",
  metadata: :all

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
get_config_file_path = fn filename ->
  config_directory = __ENV__.file |> String.slice(0..-11)

  filename
  |> Path.expand(config_directory)
end

path = get_config_file_path.("#{Mix.env()}.exs")

if File.exists?(path) do
  import_config path
end

secrets_path = get_config_file_path.("secrets.exs")

if File.exists?(secrets_path) do
  import_config secrets_path
end
