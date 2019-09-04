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
    with :ok <- validate_action(conn.query_params),
         :ok <- validate_namespace(conn.query_params) do
      conn
      |> send_resp(200, "{}")
    else
      error ->
        conn
        |> send_resp(400, "Search request failed: #{error}")
    end
  end

  defp validate_action(%{"action" => "opensearch"}), do: :ok
  defp validate_action(%{"action" => action}), do: {:error, "Invalid action: #{action}"}
  defp validate_action(_), do: {:error, "Missing action param"}

  defp validate_namespace(%{"namespace" => "0"}), do: :ok
  defp validate_namespace(%{"namespace" => namespace}), do: {:error, "Invalid namespace: #{namespace}"}
  defp validate_namespace(_), do: {:error, "Missing namespace param"}
end
