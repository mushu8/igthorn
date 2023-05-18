# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.

# General application configuration
import Config

# Configures the endpoint
config :ui, UiWeb.Endpoint,
  url: [host: "localhost"],
  secret_key_base: "R23gwF7fVqXLhFsqsIyDPxPwZiZPKzZxjtJHw+p1U4vHPJdk3dh1zB6PK1tyYtYV",
  render_errors: [view: UiWeb.ErrorView, accepts: ~w(html json)],
  pubsub: [name: Ui.PubSub, adapter: Phoenix.PubSub.PG2]

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:application, :request_id, :module]

# Use Jason for JSON parsing in Phoenix
config :phoenix, :json_library, Jason

config :ui, UiWeb.Endpoint,
  live_view: [
    signing_salt: "SECRET_SALT"
  ]

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
get_config_file_path = fn filename ->
  config_directory = __ENV__.file |> String.slice(0..-11)

  filename
  |> Path.expand(config_directory)
end

path = get_config_file_path.("#{config_env()}.exs")

if File.exists?(path) do
  import_config path
end
