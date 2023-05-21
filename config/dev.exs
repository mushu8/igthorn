import Config

# UI

# For development, we disable any cache and enable
# debugging and code reloading.
config :ui, UiWeb.Endpoint,
  http: [ip: {127, 0, 0, 1}, port: 4000],
  debug_errors: true,
  code_reloader: true,
  check_origin: false,
  secret_key_base: "D+ZMJ4arEIn3SGE9TdS60bGsd1APK2GAAgD8vlWH6qDPNY2UIfnQrJ/WcxY2hh/D",
  watchers: [
    # node: [
    #   "node_modules/webpack/bin/webpack.js",
    #   "--mode",
    #   "development",
    #   "--watch-stdin",
    #   cd: Path.expand("../assets", __DIR__)
    # ],
    esbuild: {Esbuild, :install_and_run, [:default, ~w(--sourcemap=inline --watch)]},
  ]

# Watch static and templates for browser reloading.
config :ui, UiWeb.Endpoint,
  live_reload: [
    patterns: [
      ~r"priv/static/.*(js|css|png|jpeg|jpg|gif|svg)$",
      ~r"priv/gettext/.*(po)$",
      ~r"lib/ui_web/(controllers|live|components)/.*(ex|heex)$"
    ]
  ]

# Set a higher stacktrace during development. Avoid configuring such
# in production as building large stacktraces may be expensive.
config :phoenix, :stacktrace_depth, 20

# Enable dev routes for dashboard and mailbox
config :ui, dev_routes: true

# Initialize plugs at runtime for faster development compilation
config :phoenix, :plug_init_mode, :runtime
