use Mix.Config

# SAMPLE configuration file

config :discordbot,
  # Configures the application to use the Discord token provided below
  # To configure the bot yourself, provide a valid token below
  # Then, rename this file to "config.exs".
  #
  # If you wish to override configuration here in a specific mix environment,
  # create an additional file in this directory named "<env>.config.exs"
  # (e.g. prod.config.exs). The configuration supplied in that file will be merged
  # on top of the config provided in the base config.exs file.
  token: "MY_BOT_TOKEN",

  # The default number of websockets that the bot will use for communication.
  shards: 2
