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
end

environment :prod do
  set include_erts: true
  set include_src: false
  # We don't use erlang distribution protocol, so this doesn't matter
  # Ideally, this would be provided through a config provider
  set cookie: :crypto.strong_rand_bytes(32) |> Base.encode16
  set vm_args: "rel/vm.args"
end

release :discordbot do
  set version: current_version(:discordbot)
  set applications: [
    :runtime_tools
  ]
end

