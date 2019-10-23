defmodule DiscordBot.Voice.Launcher do
  @moduledoc """
  Initiates and establishes voice connections.
  """

  @doc """
  Builds a Discord Voice websocket URL.
  """
  @spec preprocess_url(String.t()) :: String.t()
  def preprocess_url(url) do
    url
    |> apply_protocol()
    |> apply_version
    |> String.replace(":80", "")
  end

  defp apply_protocol("wss://" <> url), do: "wss://" <> url
  defp apply_protocol(url), do: "wss://" <> url

  defp apply_version(url), do: url <> "/?v=3"
end
