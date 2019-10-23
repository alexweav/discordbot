defmodule DiscordBot.Voice.Launcher do
  @moduledoc """
  Initiates and establishes voice connections.
  """

  alias DiscordBot.Voice.Session

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
         token: token},
        []
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

  defp apply_protocol("wss://" <> url), do: "wss://" <> url
  defp apply_protocol(url), do: "wss://" <> url

  defp apply_version(url), do: url <> "/?v=3"
end
