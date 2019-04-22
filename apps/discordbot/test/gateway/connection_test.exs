defmodule DiscordBot.Gateway.ConnectionTest do
  use ExUnit.Case, async: true

  alias DiscordBot.Broker
  alias DiscordBot.Gateway.Connection

  setup context do
    {:ok, {url, ref}} = DiscordBot.Fake.DiscordServer.start()

    on_exit(fn ->
      DiscordBot.Fake.DiscordServer.shutdown(ref)
    end)

    broker = start_supervised!({Broker, []}, id: Module.concat(context.test, :broker))

    %{url: url, ref: ref, broker: broker, test: context.test}
  end

  test "establishes websocket connection using URL", %{url: url, broker: broker, test: test} do
    pid = start_supervised!({Connection, token: "asdf", url: url, broker: broker}, id: test)
    assert Connection.disconnect(pid, 4001) == :ok
  end
end
