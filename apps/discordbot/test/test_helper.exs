Application.ensure_all_started(:mox)

Mox.defmock(DiscordBot.ApiMock, for: DiscordBot.Api)

ExUnit.start()
