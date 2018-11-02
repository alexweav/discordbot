defmodule DiscordBot.ApiTest do
  use ExUnit.Case, async: true
  doctest DiscordBot.Api

  test "produces a fully qualified URL" do
    expected = "https://discordapp.com/api/v/test"
    assert DiscordBot.Api.process_request_url("v/test") == expected
    assert DiscordBot.Api.process_request_url("/v/test") == expected
  end

  test "appends the authorization header" do
    headers = [{"test", "header"}]

    assert Enum.member?(
             DiscordBot.Api.process_request_headers(headers),
             {"Authorization", "Bot " <> DiscordBot.Token.token()}
           )
  end

  test "appends the Content-Type application/json header" do
    headers = [{"test", "header"}]

    assert Enum.member?(
             DiscordBot.Api.process_request_headers(headers),
             {"Content-Type", "application/json"}
           )
  end

  test "json encodes elixir objects" do
    body = %{
      "bool" => true,
      "number" => 3.1,
      "string" => "yeet",
      "list" => [
        "asdf",
        3.1,
        true,
        []
      ],
      "object" => %{
        "key" => "value",
        "number" => 3.2
      }
    }

    assert DiscordBot.Api.process_response_body(Poison.encode!(body)) == body
  end

  test "deserializes json responses" do
  end
end
