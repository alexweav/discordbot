defmodule Services.SearchTest do
  use ExUnit.Case, async: true
  doctest Services.Search

  use Services.Fake.Spotify

  alias Services.Search

  setup do
    _ = start_supervised!({Services.Search.TokenManager, name: Services.Search.TokenManager})
    setup_spotify()
    Search.Spotify.start()
    Search.setup_handler()
    :ok
  end

  test "parses Spotify access token" do
    assert is_binary(Search.request_spotify_access_token())
  end

  @tag :skip
  test "parses albums from Spotify" do
    assert Search.search_spotify_albums("Portal of I") ==
             "https://open.spotify.com/album/2AX3vMS7gYbrS7tALE4U7Q"
  end

  @tag :skip
  test "parses tracks from Spotify" do
    assert Search.search_spotify_tracks("Disease, Injury, Madness") ==
             "https://open.spotify.com/track/78aw2e4YuglThxQs1THTDo"
  end
end
