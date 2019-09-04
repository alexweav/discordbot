use Mix.Config

config :discordbot,
  spotify_client_id: "spotify-test-id",
  spotify_client_secret: "spotify-client-secret",
  youtube_data_api_key: "youtube-api-key"

config :services,
  channel_manager: DiscordBot.Entity.ChannelManagerMock,
  tts_response_interval: 10,
  spotify_token_base_url: "http://localhost:8081",
  spotify_api_base_url: "http://localhost:8081",
  youtube_api_base_url: "http://localhost:8082",
  wikipedia_api_base_url: "http://localhost:8083"
