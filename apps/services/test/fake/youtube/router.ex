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
    with :ok <- validate_api_key_param(conn.query_params),
         :ok <- validate_part(conn.query_params),
         :ok <- validate_type(conn.query_params),
         :ok <- validate_take(conn.query_params) do
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

  defp validate_part(%{"part" => "snippet"}), do: :ok
  defp validate_part(%{"part" => part}), do: {:error, "Invalid part: #{part}"}
  defp validate_part(_), do: {:error, "Missing part param"}

  defp validate_type(%{"type" => "video"}), do: :ok
  defp validate_type(%{"type" => type}), do: {:error, "Invalid type: #{type}"}
  defp validate_type(_), do: {:error, "Missing type param"}

  defp validate_take(%{"maxResults" => "1"}), do: :ok
  defp validate_take(%{"maxResults" => take}), do: {:error, "Invalid take: #{take}"}
  defp validate_take(_), do: {:error, "Missing take param"}
end
