defmodule DiscordBot.MixProject do
  use Mix.Project

  def project do
    [
      app: :discordbot,
      version: "0.1.0",
      elixir: "~> 1.9",
      build_path: "../../_build",
      config_paths: ~w(../../config/config.exs ../../config/#{Mix.env()}.exs),
      deps_path: "../../deps",
      lockfile: "../../mix.lock",
      start_permanent: Mix.env() == :prod,
      elixirc_paths: elixirc_paths(Mix.env()),
      deps: deps(),
      name: "DiscordBot",
      docs: [
        main: "DiscordBot"
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
      mod: {DiscordBot.Application, []}
    ]
  end

  defp deps do
    [
      # Prod deps
      {:cowlib, "~> 2.7", override: true},
      {:distillery, "~> 2.0"},
      {:gun, "~> 1.3"},
      {:httpoison, "~> 1.4"},
      {:kcl, "~> 1.2"},
      {:logger_file_backend, "~> 0.0.10"},
      {:poison, "~> 4.0"},
      {:porcelain, "~> 2.0"},

      # Dev/Test deps
      {:cowboy, "~> 2.6", only: [:dev, :test], runtime: false},
      {:credo, "~> 1.2.3", only: [:dev, :test], runtime: false},
      {:credo_naming, "~> 0.4", only: [:dev, :test], runtime: false},
      {:dialyxir, "~> 1.0.0-rc.4", only: [:dev, :test], runtime: false},
      {:excoveralls, "~> 0.10", only: :test},
      {:mox, "~> 0.5", only: :test},
      {:plug_cowboy, "~> 2.0", only: [:dev, :test], runtime: false}
    ]
  end
end
