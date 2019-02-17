defmodule DiscordbotUmbrella.MixProject do
  use Mix.Project

  def project do
    [
      app: :discordbot_umbrella,
      apps_path: "apps",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      name: "DiscordBot Umbrella",
      source_url: "https://github.com/alexweav/discordbot",
      test_paths: test_paths(),
      test_coverage: [tool: ExCoveralls],
      preferred_cli_env: [
        coveralls: :test,
        "coveralls.detail": :test,
        "coveralls.post": :test,
        "coveralls.html": :test,
        "coveralls.json": :test
      ]
    ]
  end

  # Dependencies listed here are available only for this
  # project and cannot be accessed from applications inside
  # the apps folder.
  #
  # Run "mix help deps" for examples and options.
  defp deps do
    [
      {:distillery, "~> 2.0"},
      {:excoveralls, "~> 0.10", only: :test}
    ]
  end

  defp test_paths do
    "apps/*/test" |> Path.wildcard() |> Enum.sort()
  end
end
