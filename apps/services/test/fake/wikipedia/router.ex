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
         :ok <- Util.validate_query_parameter(conn.query_params, "namespace", "0"),
         :ok <- Util.validate_query_parameter(conn.query_params, "format", "json"),
         :ok <- Util.validate_query_parameter(conn.query_params, "limit", "1"),
         {:ok, resp} <- execute_query(conn.query_params) do
      conn
      |> send_resp(200, Poison.encode!(resp))
    else
      error ->
        conn
        |> send_resp(400, "Search request failed: #{error}")
    end
  end

  defp execute_query(%{"search" => "yeet"}) do
    {:ok,
     [
       "yeet",
       ["Yeeting"],
       [""],
       ["https://en.wikipedia.org/wiki/Yeeting"]
     ]}
  end

  defp execute_query(params), do: {:error, "Invalid query params: #{params}"}
end
