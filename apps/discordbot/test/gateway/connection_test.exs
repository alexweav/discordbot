defmodule DiscordBot.Gateway.ConnectionTest do
  use ExUnit.Case, async: true

  setup do
    {:ok, {url, ref}} = DiscordBot.Fake.DiscordServer.start()

    on_exit(fn ->
      DiscordBot.Fake.DiscordServer.shutdown(ref)
    end)

    %{url: url, ref: ref}
  end

  test "sample", %{url: url} do
    start_supervised!({DiscordBot.Gateway.Connection, token: "asdf", url: url})
    assert 1 == 2
  end
end
