defmodule DiscordBot.MixProject do
  use Mix.Project

  def project do
    [
      app: :discordbot,
      version: "0.1.0",
      elixir: "~> 1.7",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      name: "DiscordBot",
      source_url: "https://github.com/alexweav/discordbot",
      docs: [
        main: "DiscordBot"
      ],
      test_coverage: [tool: ExCoveralls],
      preferred_cli_env: [coveralls: :text, "coveralls.detail": :test]
    ]
  end

  def application do
    [
      extra_applications: [:logger],
      mod: {DiscordBot.Application, []}
    ]
  end

  defp deps do
    [
      {:credo, "~> 1.0.0", only: [:dev, :test], runtime: false},
      {:dialyxir, "~> 1.0.0-rc.4", only: [:dev, :test], runtime: false},
      {:distillery, "~> 2.0"},
      {:excoveralls, "~> 0.10", only: :test},
      {:ex_doc, "~> 0.19", only: :dev, runtime: false},
      {:httpoison, "~> 1.4"},
      {:logger_file_backend, "~> 0.0.10"},
      {:poison, "~>3.1"},
      {:websockex, "~> 0.4.0"}
    ]
  end
end
