~w(rel plugins *.exs)
|> Path.join()
|> Path.wildcard()
|> Enum.map(&Code.eval_file(&1))

use Mix.Releases.Config,
    default_release: :default,
    default_environment: Mix.env()

environment :dev do
  set dev_mode: true
  set include_erts: false
  # We don't use erlang distribution protocol, so this doesn't matter
  # Ideally, this would be provided through a config provider
  set cookie: :crypto.strong_rand_bytes(32) |> Base.encode16
  set config_providers: [
    {DiscordBot.ConfigProvider, ["${RELEASE_ROOT_DIR}/etc/config.exs"]},
    {DiscordBot.ConfigProvider, ["${RELEASE_ROOT_DIR}/etc/dev.config.exs"]}
  ]
  set overlays: [
    {:copy, "rel/config", "etc"}
  ]
end

environment :prod do
  set include_erts: true
  set include_src: false
  # We don't use erlang distribution protocol, so this doesn't matter
  # Ideally, this would be provided through a config provider
  set cookie: :crypto.strong_rand_bytes(32) |> Base.encode16
  set config_providers: [
    {DiscordBot.ConfigProvider, ["${RELEASE_ROOT_DIR}/etc/config.exs"]},
    {DiscordBot.ConfigProvider, ["${RELEASE_ROOT_DIR}/etc/prod.config.exs"]}
  ]
  set overlays: [
    {:copy, "rel/config", "etc"}
  ]
  set vm_args: "rel/vm.args"
end

release :discordbot_umbrella do
  set version: "0.1.0"
  set applications: [
    :runtime_tools,
    discordbot: :permanent,
    services: :permanent
  ]
end

