Application.ensure_all_started(:mox)
Application.ensure_all_started(:cowboy)

Mox.defmock(DiscordBot.ApiMock, for: DiscordBot.Api)
Mox.defmock(DiscordBot.MessagesMock, for: DiscordBot.Entity.Messages)
Mox.defmock(DiscordBot.Entity.ChannelManagerMock, for: DiscordBot.Entity.ChannelManager)

Application.put_env(:discordbot, :http_api, DiscordBot.ApiMock)

ExUnit.start(capture_log: true)
