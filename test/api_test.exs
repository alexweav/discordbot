defmodule DiscordBot.ApiTest do
  use ExUnit.Case, async: true
  doctest DiscordBot.Api

  test "produces a fully qualified URL" do
    DiscordBot.Api.base_url("v0/test")
    expected = "https://discordapp.com/api/v0/test"
    assert DiscordBot.Api.base_url("v0/test") == expected
    assert DiscordBot.Api.base_url("/v0/test") == expected
  end
end
