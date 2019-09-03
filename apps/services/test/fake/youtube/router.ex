defmodule Services.Fake.Youtube.Router do
  @moduledoc """
  Router for the fake Youtube server.
  """

  use Plug.Router

  plug(Plug.Parsers,
    parsers: [:json],
    pass: ["text/*"],
    json_decoder: Poison
  )

  plug(:match)
  plug(:dispatch)

  get "/v3/search" do
    conn
    |> send_resp(200, "{}")
  end
end
