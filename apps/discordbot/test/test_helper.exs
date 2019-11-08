Application.ensure_all_started(:mox)
Application.ensure_all_started(:cowboy)
Application.ensure_all_started(:gun)

Mox.defmock(DiscordBot.ApiMock, for: DiscordBot.Api)
Mox.defmock(DiscordBot.MessagesMock, for: DiscordBot.Entity.Messages)

Application.put_env(:discordbot, :http_api, DiscordBot.ApiMock)

ExUnit.start(capture_log: true)
