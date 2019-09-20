use Mix.Config

config :discordbot,
  token: "TOKEN",
  shards: 2,
  initial_activity_type: :playing

config :logger,
  level: :info,
  backends: [
    :console,
    {LoggerFileBackend, :info},
    {LoggerFileBackend, :error}
  ]

config :logger, :info,
  path: "logs/info.log",
  level: :info

config :logger, :error,
  path: "logs/error.log",
  level: :error

# The configuration in this file is set at compile time.
# Building this project from source via mix will use the
# configuration in this file. Building this project via distillery
# using `mix release` means that the configuration in rel/config
# will be applied on top of the configuration stored here, at runtime.
#
# If you are building and running this project from source, the bot token
# should be included in this directory. Otherwise, it should be
# set in the config files in rel/config instead.
import_config "*.secret.exs"
import_config "#{Mix.env()}.exs"
