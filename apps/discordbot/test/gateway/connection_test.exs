defmodule DiscordBot.Gateway.ConnectionTest do
  use ExUnit.Case, async: true

  setup do
    {:ok, {url, ref}} = DiscordBot.Fake.DiscordServer.start()

    on_exit(fn ->
      DiscordBot.Fake.DiscordServer.shutdown(ref)
    end)

    %{url: url, ref: ref}
  end

  test "establishes websocket connection using URL", %{url: url} do
    pid = start_supervised!({DiscordBot.Gateway.Connection, token: "asdf", url: url})
    assert DiscordBot.Gateway.Connection.disconnect(pid, 4001) == :ok
  end
end
