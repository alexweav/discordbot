defmodule Services.Fake.Wikipedia.Router do
  @moduledoc """
  Router for the fake Wikipedia server.
  """

  use Plug.Router

  plug(Plug.Parsers,
    parsers: [:json],
    pass: ["text/*"],
    json_decoder: Poison
  )

  plug(:match)
  plug(:dispatch)

  get "/w/api.php" do
    conn
    |> send_resp(200, "{}")
  end
end
