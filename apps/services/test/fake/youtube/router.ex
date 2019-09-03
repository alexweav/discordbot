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
    with :ok <- validate_api_key_param(conn.query_params) do
      conn
      |> send_resp(200, "{}")
    else
      error ->
        conn
        |> send_resp(400, "Search request failed: #{error}")
    end
  end

  defp validate_api_key_param(%{"key" => "youtube-api-key"}), do: :ok
  defp validate_api_key_param(%{"key" => key}), do: {:error, "Invalid API key: #{key}"}
  defp validate_api_key_param(_), do: {:error, "Missing API key param"}
end
