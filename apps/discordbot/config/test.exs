use Mix.Config

config :discordbot,
  spotify_client_id: "spotify-test-id",
  spotify_client_secret: "spotify-client-secret"

config :services,
  channel_manager: DiscordBot.Entity.ChannelManagerMock,
  tts_response_interval: 10,
  spotify_token_base_url: "http://localhost:8081"
