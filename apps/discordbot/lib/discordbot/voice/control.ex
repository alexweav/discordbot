defmodule DiscordBot.Voice.Control do
  @moduledoc """
  Represents a connection to Discord's voice control websocket API.
  """

  use WebSockex
  require Logger

  alias DiscordBot.Gateway.Heartbeat
  alias DiscordBot.Model.{VoiceHello, VoiceIdentify, VoicePayload}
  alias DiscordBot.Util
  alias DiscordBot.Voice.Session

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
    {:ok, state}
  end

  def handle_frame({:text, json}, state) do
    payload = VoicePayload.from_json(json)
    Logger.info("Received voice control frame: #{Kernel.inspect(payload)}")
    attempt_authenticate(payload)
    handle_acknowledge(payload, state)

    case setup_heartbeat(payload, state) do
      nil -> {:ok, state}
      new_state -> {:ok, new_state}
    end
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
    Logger.info("Sending voice control heartbeat.")

    {:ok, json} =
      nonce
      |> VoicePayload.heartbeat()
      |> VoicePayload.to_json()

    {:reply, {:text, json}, state}
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

  def handle_info(:heartbeat, state) do
    heartbeat(self(), :rand.uniform(999_999_999))
    {:ok, state}
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
         state
       ) do
    # According to discord docs, the correct heartbeat interval
    # is provided in the Hello event, and is an erroneous value.
    # Clients should take this heartbeat to be 75% of its
    # given value.
    # https://discordapp.com/developers/docs/topics/voice-connections

    # TODO: heartbeat will kill this process if things aren't ACKed,
    # TODO: set up ACKs here too.
    {:ok, heartbeat} = get_heartbeat(state)
    Heartbeat.schedule(heartbeat, trunc(interval * 0.75))
    %{state | heartbeat: heartbeat}
  end

  defp setup_heartbeat(_, _), do: nil

  defp get_heartbeat(state) do
    state
    |> Map.get(:parent)
    |> Session.heartbeat?()
  end

  defp handle_acknowledge(%VoicePayload{opcode: :heartbeat_ack}, state) do
    Heartbeat.acknowledge(state[:heartbeat])
  end

  defp handle_acknowledge(_, _), do: nil
end
