use Mix.Config

config :services,
  channel_manager: DiscordBot.Entity.ChannelManagerMock,
  tts_response_interval: 10
