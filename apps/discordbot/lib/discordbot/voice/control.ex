defmodule DiscordBot.Voice.Control do
  @moduledoc """
  Represents a connection to Discord's voice control websocket API.
  """

  use WebSockex
  require Logger

  alias DiscordBot.Gateway.Heartbeat
  alias DiscordBot.Model.{VoiceHello, VoiceIdentify, VoicePayload}
  alias DiscordBot.Util

  def start_link(opts) do
    url = Util.require_opt!(opts, :url)
    server_id = Util.require_opt!(opts, :server_id)
    user_id = Util.require_opt!(opts, :user_id)
    session_id = Util.require_opt!(opts, :session_id)
    token = Util.require_opt!(opts, :token)

    state = %{
      server_id: server_id,
      user_id: user_id,
      session_id: session_id,
      token: token,
      parent: self(),
      heartbeat: nil
    }

    WebSockex.start_link(url, __MODULE__, state, opts)
  end

  @doc """
  Sends a heartbeat message over the websocket.
  """
  @spec heartbeat(atom | pid, integer) :: :ok
  def heartbeat(connection, nonce) do
    WebSockex.cast(connection, {:heartbeat, nonce})
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
    send(self(), :after_connect)
    {:ok, state}
  end

  def handle_frame({:text, json}, state) do
    payload = VoicePayload.from_json(json)
    Logger.info("Received voice control frame: #{Kernel.inspect(payload)}")
    attempt_authenticate(payload)
    setup_heartbeat(payload, state[:heartbeat])
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

  def handle_cast({:heartbeat, nonce}, state) do
    {:ok, json} =
      nonce
      |> VoicePayload.heartbeat()
      |> IO.inspect()
      |> VoicePayload.to_json()

    {:ok, {:text, json}, state}
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

  def handle_info(:after_connect, state) do
    {:ok, heartbeat} =
      state
      |> Map.get(:parent)
      |> DiscordBot.Voice.Session.heartbeat?()

    {:ok, %{state | heartbeat: IO.inspect(heartbeat)}}
  end

  defp attempt_authenticate(%VoicePayload{opcode: :hello}) do
    identify(self())
  end

  defp attempt_authenticate(_), do: nil

  defp setup_heartbeat(
         %VoicePayload{
           opcode: :hello,
           data: %VoiceHello{heartbeat_interval: interval}
         },
         heartbeat
       ) do
    IO.inspect("asdf")
    # According to discord docs, the correct heartbeat interval
    # is provided in the Hello event, and is an erroneous value.
    # Clients should take this heartbeat to be 75% of its
    # given value.
    # https://discordapp.com/developers/docs/topics/voice-connections

    # TODO: send_after crashes if it's given a float.
    # TODO: heartbeat should convert it.
    # TODO: heartbeat will kill this process if things aren't ACKed,
    # TODO: set up ACKs here too.
    Heartbeat.schedule(heartbeat, interval * 0.75)
  end

  defp setup_heartbeat(_, _), do: nil
end
