defmodule DiscordBot.Voice.Control do
  @moduledoc """
  Represents a connection to Discord's voice control websocket API.
  """

  use WebSockex
  require Logger

  def start_link(opts) do
    IO.inspect("asdf")
    url = get_opt!(opts, :url, "#{__MODULE__} is missing required parameter :url")
    IO.inspect(url)

    server_id =
      get_opt!(opts, :server_id, "#{__MODULE__} is missing required parameter :server_id")

    IO.inspect(server_id)
    user_id = get_opt!(opts, :user_id, "#{__MODULE__} is missing required parameter :user_id")
    IO.inspect(user_id)

    session_id =
      get_opt!(opts, :session_id, "#{__MODULE__} is missing required parameter :session_id")

    IO.inspect(session_id)
    token = get_opt!(opts, :token, "#{__MODULE__} is missing required parameter :token")
    IO.inspect(token)

    state = %{
      server_id: server_id,
      user_id: user_id,
      session_id: session_id,
      token: token
    }

    WebSockex.start_link(url, __MODULE__, state, opts)
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

  defp get_opt!(opts, key, msg) do
    case Keyword.fetch(opts, key) do
      {:ok, url} -> url
      :error -> raise ArgumentError, message: msg
    end
  end
end
