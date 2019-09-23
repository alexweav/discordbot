ExUnit.start(exclude: [:skip])

Application.put_env(:services, :messages, DiscordBot.MessagesMock)
