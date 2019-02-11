defmodule DiscordbotUmbrella.MixProject do
  use Mix.Project

  def project do
    [
      app: :discordbot_umbrella,
      apps_path: "apps",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      name: "DiscordBot Umbrella",
      source_url: "https://github.com/alexweav/discordbot"
    ]
  end

  # Dependencies listed here are available only for this
  # project and cannot be accessed from applications inside
  # the apps folder.
  #
  # Run "mix help deps" for examples and options.
  defp deps do
    [
      {:distillery, "~> 2.0"}
    ]
  end
end
