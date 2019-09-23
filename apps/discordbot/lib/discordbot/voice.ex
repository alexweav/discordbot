defmodule DiscordBot.Voice do
  @moduledoc """
  Allows the client to communicate over the voice API.
  """

  alias DiscordBot.Entity.Channels
  alias DiscordBot.Gateway.Api
  alias DiscordBot.Model.{VoiceServerUpdate, VoiceState}
  alias DiscordBot.Voice.Session

  @doc """
  Connects to a voice channel.
  """
  @spec connect(String.t(), boolean, boolean) :: :ok | :error
  def connect(channel_id, self_mute \\ false, self_deaf \\ false) do
    case Channels.from_id?(channel_id) do
      {:ok, channel} -> connect(channel.guild_id, channel_id, self_mute, self_deaf)
      :error -> :error
    end
  end

  @doc """
  Establishes a voice connection.
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
  @spec establish(String.t(), String.t(), String.t(), String.t(), String.t()) :: :ok | :error
  def establish(url, server_id, user_id, session_id, token) do
    DynamicSupervisor.start_child(
      DiscordBot.Voice.ControlSupervisor,
      Supervisor.child_spec(
        {Session,
         url: preprocess_url(url),
         server_id: server_id,
         user_id: user_id,
         session_id: session_id,
         token: token},
        []
      )
    )

    :ok
  end

  @doc """
  Preprocesses a Discord Voice websocket URL.
  """
  @spec preprocess_url(String.t()) :: String.t()
  def preprocess_url(url),
    do: url |> apply_protocol() |> apply_version |> String.replace(":80", "")

  defp connect(guild_id, channel_id, self_mute, self_deaf) do
    DynamicSupervisor.start_child(DiscordBot.Voice.AcceptorSupervisor, DiscordBot.Voice.Acceptor)
    Api.update_voice_state(guild_id, channel_id, self_mute, self_deaf)
  end

  defp apply_protocol("wss://" <> url), do: "wss://" <> url
  defp apply_protocol(url), do: "wss://" <> url

  defp apply_version(url), do: url <> "/?v=3"
end
