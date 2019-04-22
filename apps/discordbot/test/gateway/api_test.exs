defmodule DiscordBot.Gateway.ApiTest do
  use ExUnit.Case, async: true

  setup context do
    {:ok, {url, ref, core}} = DiscordBot.Fake.DiscordServer.start()

    on_exit(fn ->
      DiscordBot.Fake.DiscordServer.shutdown(ref)
    end)

    broker = start_supervised!({Broker, []}, id: Module.concat(context.test, :broker))

    %{url: url, ref: ref, core: core, broker: broker, test: context.test}
  end
end
