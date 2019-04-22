defmodule DiscordBot.MixProject do
  use Mix.Project

  def project do
    [
      app: :discordbot,
      version: "0.1.0",
      elixir: "~> 1.8",
      build_path: "../../_build",
      config_path: "../../config/config.exs",
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
      {:cowboy, "~> 2.6", only: [:dev, :test], runtime: false},
      {:credo, "~> 1.0.0", only: [:dev, :test], runtime: false},
      {:dialyxir, "~> 1.0.0-rc.4", only: [:dev, :test], runtime: false},
      {:distillery, "~> 2.0"},
      {:excoveralls, "~> 0.10", only: :test},
      {:ex_doc, "~> 0.19", only: :dev, runtime: false},
      {:httpoison, "~> 1.4"},
      {:logger_file_backend, "~> 0.0.10"},
      {:mox, "~> 0.5", only: :test},
      {:plug_cowboy, "~> 2.0", only: [:dev, :test], runtime: false},
      {:poison, "~>3.1"},
      {:websockex, "~> 0.4.0"}
    ]
  end
end
