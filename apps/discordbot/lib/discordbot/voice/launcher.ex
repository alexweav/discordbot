defmodule DiscordBot.Voice.Launcher do
  @moduledoc """
  Initiates and establishes voice connections.
  """

  require Logger

  alias DiscordBot.Broker
  alias DiscordBot.Broker.Event
  alias DiscordBot.Gateway.Api
  alias DiscordBot.Voice.Session

  @default_timeout_milliseconds 10_000

  @doc """
  Initiates a connection.
  """
  @spec initiate(String.t(), String.t(), boolean, boolean) :: DynamicSupervisor.on_start_child()
  def initiate(guild_id, channel_id, self_mute, self_deaf) do
    broker = Elixir.Broker
    Broker.subscribe(broker, :voice_state_update)
    Broker.subscribe(broker, :voice_server_update)
    Api.update_voice_state(guild_id, channel_id, self_mute, self_deaf)

    recv_loop(nil, nil)
  end

  @doc """
  Establishes a voice connection given a state and server update message.
  """
  @spec establish(VoiceState.t(), VoiceServerUpdate.t()) :: :ok | :error
  def establish(voice_state_update, voice_server_update) do
    establish(
      voice_server_update.endpoint,
      voice_server_update.guild_id,
      voice_state_update.member.user.id,
      voice_state_update.session_id,
      voice_server_update.token
    )
  end

  @doc """
  Establishes a voice connection.
  """
  @spec establish(String.t(), String.t(), String.t(), String.t(), String.t()) ::
          DynamicSupervisor.on_start_child()
  def establish(url, server_id, user_id, session_id, token) do
    DynamicSupervisor.start_child(
      DiscordBot.Voice.ControlSupervisor,
      Supervisor.child_spec(
        {Session,
         url: preprocess_url(url),
         server_id: server_id,
         user_id: user_id,
         session_id: session_id,
         token: token,
         name: {:via, Registry, {DiscordBot.Voice.SessionRegistry, server_id}}},
        restart: :transient
      )
    )
  end

  @doc """
  Builds a Discord Voice websocket URL.
  """
  @spec preprocess_url(String.t()) :: String.t()
  def preprocess_url(url) do
    url
    |> apply_protocol
    |> apply_version
    |> String.replace(":80", "")
  end

  defp recv_loop(state, server) when state != nil and server != nil do
    Logger.info("Preparing new voice connection.")
    establish(state, server)
  end

  defp recv_loop(state, server) do
    receive do
      %Event{topic: :voice_state_update, message: message} ->
        recv_loop(message, server)

      %Event{topic: :voice_server_update, message: message} ->
        recv_loop(state, message)
    after
      @default_timeout_milliseconds -> :error
    end
  end

  defp apply_protocol("wss://" <> url), do: "wss://" <> url
  defp apply_protocol(url), do: "wss://" <> url

  defp apply_version(url), do: url <> "/?v=3"
end
