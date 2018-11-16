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
      ]
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
      {:ex_doc, "~> 0.19", only: :dev, runtime: false},
      {:httpoison, "~> 1.4"},
      {:poison, "~>3.1"},
      {:websockex, "~> 0.4.0"}
    ]
  end
end
