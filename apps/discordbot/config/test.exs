use Mix.Config

config :services,
  channel_manager: DiscordBot.Entity.ChannelManagerMock,
  tts_response_interval: 10,
  spotify_token_base_url: "http://localhost:8081"
