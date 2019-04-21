defmodule DiscordBot.Gateway.ConnectionTest do
  use ExUnit.Case, async: true

  setup do
    url = DiscordBot.Fake.DiscordServer.start(self())
  end

  test "sample" do
    assert 1 == 2
  end
end
