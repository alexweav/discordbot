defmodule Services.Fake.Spotify.Router do
  @moduledoc """
  Router for the mock Spotify server.
  """

  @fake_token "test"

  use Plug.Router

  plug(Plug.Parsers,
    parsers: [:json],
    pass: ["text/*"],
    json_decoder: Poison
  )

  plug(:match)
  plug(:dispatch)

  post "/api/token" do
    conn
    |> Plug.Conn.send_resp(200, Poison.encode!(%{access_token: @fake_token}))
  end
end
