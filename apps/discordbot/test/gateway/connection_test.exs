defmodule DiscordBot.Gateway.ConnectionTest do
  use ExUnit.Case, async: true

  setup do
    {:ok, {url, ref}} = DiscordBot.Fake.DiscordServer.start(self())
    %{url: url, ref: ref}
  end

  test "sample" do
    assert 1 == 2
  end
end
