Application.ensure_all_started(:mox)
Application.ensure_all_started(:cowboy)

Mox.defmock(DiscordBot.ApiMock, for: DiscordBot.Api)
Mox.defmock(DiscordBot.Entity.ChannelManagerMock, for: DiscordBot.Entity.ChannelManager)

ExUnit.start(capture_log: true)
