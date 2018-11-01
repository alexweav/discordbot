defmodule DiscordBot.ApiTest do
  use ExUnit.Case, async: true
  doctest DiscordBot.Api

  test "produces a fully qualified URL" do
    expected = "https://discordapp.com/api/v/test"
    assert DiscordBot.Api.process_request_url("v/test") == expected
    assert DiscordBot.Api.process_request_url("/v/test") == expected
  end
end
