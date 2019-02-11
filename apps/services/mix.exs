defmodule Services.MixProject do
  use Mix.Project

  def project do
    [
      app: :services,
      version: "0.1.0",
      build_path: "../../_build",
      config_path: "../../config/config.exs",
      deps_path: "../../deps",
      lockfile: "../../mix.lock",
      elixir: "~> 1.7",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      name: "Services",
      docs: [
        main: "Services"
      ],
      test_coverage: [tool: ExCoveralls],
      preferred_cli_env: [coveralls: :text, "coveralls.detail": :test]
    ]
  end

  def application do
    [
      extra_applications: [:logger],
      mod: {Services.Application, []}
    ]
  end

  defp deps do
    [
      {:credo, "~> 1.0.0", only: [:dev, :test], runtime: false},
      {:discordbot, in_umbrella: true},
      {:excoveralls, "~> 0.10", only: :test},
      {:ex_doc, "~> 0.19", only: :dev, runtime: false}
    ]
  end
end
