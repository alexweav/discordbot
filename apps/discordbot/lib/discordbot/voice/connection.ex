defmodule DiscordBot.Voice.Connection do
  @moduledoc """
  Represents a connection to Discord's voice control websocket API.
  """

  use WebSockex
  require Logger

  def start_link(opts) do
    url =
      case Keyword.fetch(opts, :url) do
        {:ok, url} -> url
        :error -> raise ArgumentError, message: "#{__MODULE__} is missing required parameter :url"
      end

    WebSockex.start_link(url, __MODULE__, %{}, opts)
  end

  ## Handlers

  def handle_connect(_, state) do
    Logger.info("Connected to voice control!")
    {:ok, state}
  end

  def handle_frame({:text, json}, state) do
    Logger.info("Received voice control frame: #{json}")
    {:ok, state}
  end

  def handle_frame(frame, state) do
    Logger.error("Got non-text frame: #{frame}")
    {:ok, state}
  end

  def handle_disconnect(reason, state) do
    Logger.error("Disconnected from voice control. Reason: #{reason}")
    {:ok, state}
  end

  def terminate({_, code, msg}, _) do
    Logger.error("Voice control connection closed with event #{code}: #{msg}")
    exit(:normal)
  end
end
