defmodule DiscordBot.ApiTest do
  use ExUnit.Case, async: true
  doctest DiscordBot.Api

  test "produces a fully qualified URL" do
    expected = "https://discordapp.com/api/v0/test"
    assert DiscordBot.Api.process_request_url("v0/test") == expected
    assert DiscordBot.Api.process_request_url("/v0/test") == expected
  end
end
