defmodule Services.Fake.Wikipedia.Router do
  @moduledoc """
  Router for the fake Wikipedia server.
  """

  use Plug.Router

  alias Services.Fake.Util

  plug(Plug.Parsers,
    parsers: [:json],
    pass: ["text/*"],
    json_decoder: Poison
  )

  plug(:match)
  plug(:dispatch)

  get "/w/api.php" do
    with :ok <- Util.validate_query_parameter(conn.query_params, "action", "opensearch"),
         :ok <- Util.validate_query_parameter(conn.query_params, "namespace", "0") do
      conn
      |> send_resp(200, "{}")
    else
      error ->
        conn
        |> send_resp(400, "Search request failed: #{error}")
    end
  end
end
