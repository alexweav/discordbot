defmodule Services.Fake.Spotify.Router do
  @moduledoc """
  Router for the mock Spotify server.
  """

  @fake_token "test"

  use Plug.Router

  plug(Plug.Parsers,
    parsers: [:json, :urlencoded],
    pass: ["text/*"],
    json_decoder: Poison
  )

  plug(:match)
  plug(:dispatch)

  post "/api/token" do
    conn
    |> put_resp_content_type("application/json")
    |> send_resp(200, Poison.encode!(%{access_token: @fake_token}))
  end

  match _ do
    conn
    |> send_resp(404, "Oops")
  end
end
