defmodule DiscordBot.Handlers.SearchTest do
  use ExUnit.Case, async: true
  doctest DiscordBot.Handlers.Search

  alias DiscordBot.Handlers.Search

  setup do
    Search.Spotify.start()
    :ok
  end

  test "parses Spotify access token" do
    assert %{"access_token" => _, "expires_in" => _} = Search.request_spotify_access_token()
  end
end
