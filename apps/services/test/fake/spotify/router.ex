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
    with :ok <- validate_token_request_body(conn.body_params),
         :ok <- validate_headers(conn.req_headers) do
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

  defp validate_headers(headers) do
    auth_header =
      headers
      |> Enum.find(fn {key, _} -> String.downcase(key) == "authorization" end)

    case auth_header do
      {_key, value} -> validate_auth_token(value)
      nil -> {:error, "No auth key header"}
    end
  end

  defp validate_auth_token("Basic " <> token) do
    client_id = Application.get_env(:discordbot, :spotify_client_id)
    client_secret = Application.get_env(:discordbot, :spotify_client_secret)
    expected_token = client_id <> ":" <> client_secret

    case Base.url_decode64(token) do
      {:ok, expected_token} -> :ok
      {:ok, _} -> {:error, "Incorrect auth token. Got #{token}, expected #{expected_token}"}
      :error -> {:error, "Bad auth token encoding: #{token}"}
    end
  end

  defp validate_auth_token(token), do: {:error, "Invalid auth token #{token}"}
end
