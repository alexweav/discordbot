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
    with :ok <- validate_token_request_body(conn.body_params) do
      conn
      |> put_resp_content_type("application/json")
      |> send_resp(200, Poison.encode!(%{access_token: @fake_token}))
    else
      error ->
        conn
        |> send_resp(400, "Request for token did not match: #{error}")
    end
  end

  match _ do
    conn
    |> send_resp(404, "Oops")
  end

  defp validate_token_request_body(%{"grant_type" => "client_credentials"}), do: :ok
  defp validate_token_request_body(body), do: {:error, "Invalid POST body: #{body}"}
end
