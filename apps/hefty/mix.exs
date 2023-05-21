defmodule Hefty.MixProject do
  use Mix.Project

  def project do
    [
      app: :hefty,
      version: "0.1.0",
      build_path: "../../_build",
      config_path: "../../config/config.exs",
      deps_path: "../../deps",
      lockfile: "../../mix.lock",
      elixir: "~> 1.14",
      elixirc_paths: elixirc_paths(Mix.env()),
      start_permanent: Mix.env() == :prod,
      aliases: aliases(),
      deps: deps()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      mod: {Hefty.Application, []},
      extra_applications: [:logger, :binance, :timex, :runtime_tools]
    ]
  end

  # Specifies which paths to compile per environment.
  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:binance, "~> 1.0"},
      {:csv, "~> 3.0"},
      {:decimal, "~> 2.1"},
      {:ecto_sql, "~> 3.10"},
      {:ex_doc, "~> 0.29", only: :dev, runtime: false},
      {:flow, "~> 1.2"},
      {:json, "~> 1.4"},
      {:phoenix_pubsub, "~> 2.1"},
      {:postgrex, ">= 0.0.0"},
      {:timex, "~> 3.7"},
      {:websockex, "~> 0.4"},
      {:encrypt, "~> 0.1.0"}
    ]
  end

  # Aliases are shortcuts or tasks specific to the current project.
  # For example, to create, migrate and run the seeds file at once:
  #
  #     $ mix ecto.setup
  #
  # See the documentation for `Mix` for more info on aliases.
  defp aliases do
    [
      setup: ["deps.get", "ecto.setup"],
      "ecto.setup": ["ecto.create", "ecto.migrate", "run priv/repo/seeds.exs"],
      "ecto.reset": ["ecto.drop", "ecto.setup"],
      test: ["ecto.create --quiet", "ecto.migrate", "test"]
    ]
  end
end
