defmodule Igthorn.Umbrella.MixProject do
  use Mix.Project

  def project do
    [
      apps_path: "apps",
      version: "1.1.1",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      # Docs
      name: "Igthorn",
      source_url: "https://github.com/mushu8/igthorn",
      docs: [
        # The main page in the docs
        main: "Hefty",
        logo: "docs/logo.png",
        extras: ["README.md"]
      ],
      aliases: aliases()
    ]
  end

  # Dependencies listed here are available only for this
  # project and cannot be accessed from applications inside
  # the apps folder.
  #
  # Run "mix help deps" for examples and options.
  defp deps do
    [
      {:dialyxir, "~> 0.5", runtime: false}
    ]
  end

  defp aliases do
    [
      # run `mix setup` in all child apps
      setup: ["cmd mix setup"]
    ]
  end
end
