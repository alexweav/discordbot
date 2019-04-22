Application.ensure_all_started(:mox)
Application.ensure_all_started(:cowboy)

Mox.defmock(DiscordBot.ApiMock, for: DiscordBot.Api)

ExUnit.start(capture_log: true)
