defmodule Services.SearchTest do
  use ExUnit.Case, async: true
  doctest Services.Search

  use Services.Fake.Spotify
  use Services.Fake.Wikipedia
  use Services.Fake.Youtube

  alias Services.Search

  setup_all do
    setup_spotify()
    setup_wikipedia()
    setup_youtube()
    :ok
  end

  setup do
    _ = start_supervised!({Services.Search.TokenManager, name: Services.Search.TokenManager})
    Search.Spotify.start()
    Search.setup_handler()
    :ok
  end

  test "parses Spotify access token" do
    assert Search.request_spotify_access_token() == "test"
  end

  test "gets album links from Spotify" do
    assert Search.search_spotify_albums("Portal of I") ==
             "https://open.spotify.com/album/2AX3vMS7gYbrS7tALE4U7Q"
  end

  test "gets track links from Spotify" do
    assert Search.search_spotify_tracks("Disease, Injury, Madness") ==
             "https://open.spotify.com/track/78aw2e4YuglThxQs1THTDo"
  end

  test "gets video links from youtube" do
    assert Search.search_youtube("test video") ==
             "https://www.youtube.com/watch?v=test-id"
  end
end
