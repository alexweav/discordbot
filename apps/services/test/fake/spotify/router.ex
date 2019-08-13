defmodule Services.Fake.Spotify.Router do
  @moduledoc """
  Router for the mock Spotify server.
  """

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
    |> Plug.Conn.send_resp(200, nil)
  end
end
