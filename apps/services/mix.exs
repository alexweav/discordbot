defmodule Services.MixProject do
  use Mix.Project

  def project do
    [
      app: :services,
      version: "0.1.0",
      build_path: "../../_build",
      config_paths: ~w(../../config/config.exs ../../config/#{Mix.env()}.exs),
      deps_path: "../../deps",
      lockfile: "../../mix.lock",
      elixir: "~> 1.9",
      start_permanent: Mix.env() == :prod,
      elixirc_paths: elixirc_paths(Mix.env()),
      deps: deps(),
      name: "Services",
      docs: [
        main: "Services"
      ],
      test_coverage: [tool: ExCoveralls],
      preferred_cli_env: [coveralls: :text, "coveralls.detail": :test]
    ]
  end

  defp elixirc_paths(:dev), do: elixirc_paths(:prod) ++ ['test/fake']
  defp elixirc_paths(:test), do: elixirc_paths(:prod) ++ ['test/fake']
  defp elixirc_paths(_), do: ['lib']

  def application do
    [
      extra_applications: [:logger],
      mod: {Services.Application, []}
    ]
  end

  defp deps do
    [
      {:cowboy, "~> 2.6", only: [:dev, :test], runtime: false},
      {:cowlib, "~> 2.7", override: true},
      {:credo, "~> 1.0.0", only: [:dev, :test], runtime: false},
      {:discordbot, in_umbrella: true},
      {:excoveralls, "~> 0.10", only: :test},
      {:ex_doc, "~> 0.19", only: :dev, runtime: false},
      {:plug_cowboy, "~> 2.0", only: [:dev, :test], runtime: false}
    ]
  end
end
