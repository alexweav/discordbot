defmodule Services.Fake.Util do
  @moduledoc """
  Utilities for fake test servers.
  """

  @doc """
  Validates a query parameter.
  """
  @spec validate_query_parameter(map, String.t(), String.t()) :: :ok | {:error, String.t()}
  def validate_query_parameter(params, key, value) do
    params
    |> Map.fetch(key)
    |> case do
        {:ok, ^value} -> :ok
        :error -> {:error, "Missing param: #{key}"}
        actual -> {:error, "Invalid #{key} value: #{actual}"}
    end
  end
end
