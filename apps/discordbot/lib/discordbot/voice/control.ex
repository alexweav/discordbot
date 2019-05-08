defmodule DiscordBot.Voice.Control do
  @moduledoc """
  Represents a connection to Discord's voice control websocket API.
  """

  use WebSockex
  require Logger

  alias DiscordBot.Model.{VoiceIdentify, VoicePayload}

  def start_link(opts) do
    url = get_opt!(opts, :url, "#{__MODULE__} is missing required parameter :url")

    server_id =
      get_opt!(opts, :server_id, "#{__MODULE__} is missing required parameter :server_id")

    user_id = get_opt!(opts, :user_id, "#{__MODULE__} is missing required parameter :user_id")

    session_id =
      get_opt!(opts, :session_id, "#{__MODULE__} is missing required parameter :session_id")

    token = get_opt!(opts, :token, "#{__MODULE__} is missing required parameter :token")

    state = %{
      server_id: server_id,
      user_id: user_id,
      session_id: session_id,
      token: token
    }

    WebSockex.start_link(url, __MODULE__, state, opts)
  end

  @doc """
  Sends a heartbeat message over the websocket.
  """
  @spec heartbeat(atom | pid) :: :ok
  def heartbeat(connection) do
    WebSockex.cast(connection, :heartbeat)
  end

  @doc """
  Sends an identify message over the websocket.
  """
  @spec identify(atom | pid) :: :ok
  def identify(connection) do
    WebSockex.cast(connection, :identify)
  end

  ## Handlers

  def handle_connect(_, state) do
    Logger.info("Connected to voice control!")
    {:ok, state}
  end

  def handle_frame({:text, json}, state) do
    payload = VoicePayload.from_json(json)
    Logger.info("Received voice control frame: #{Kernel.inspect(payload)}")
    attempt_authenticate(payload)
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

  def handle_cast(:heartbeat, state) do
    # TODO
    {:ok, state}
  end

  def handle_cast(:identify, state) do
    Logger.info(
      "Sending voice identification for control connection #{Kernel.inspect(self())}..."
    )

    message =
      VoiceIdentify.voice_identify(
        state[:server_id],
        state[:user_id],
        state[:session_id],
        state[:token]
      )

    {:ok, json} =
      message
      |> VoicePayload.to_json()

    {:reply, {:text, json}, state}
  end

  defp get_opt!(opts, key, msg) do
    case Keyword.fetch(opts, key) do
      {:ok, url} -> url
      :error -> raise ArgumentError, message: msg
    end
  end

  defp attempt_authenticate(%VoicePayload{opcode: :hello}) do
    identify(self())
  end

  defp attempt_authenticate(_), do: nil
end
