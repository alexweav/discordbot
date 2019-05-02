defmodule DiscordBot.Voice do
  @moduledoc """
  Allows the client to communicate over the voice API.
  """

  alias DiscordBot.Entity.{Channel, ChannelManager}
  alias DiscordBot.Gateway.Api

  @doc """
  Connects to a voice channel.
  """
  @spec connect(String.t(), boolean, boolean) :: :ok | :error
  def connect(channel_id, self_mute \\ false, self_deaf \\ false) do
    case ChannelManager.lookup_by_id(DiscordBot.ChannelManager, channel_id) do
      {:ok, channel} -> connect(Channel.guild_id?(channel), channel_id, self_mute, self_deaf)
      :error -> :error
    end
  end

  @doc """
  Establishes a voice connection.
  """
  @spec establish(String.t(), String.t(), String.t(), String.t(), String.t()) :: :ok | :error
  def establish(_url, _server_id, _user_id, _session_id, _token) do
    :ok
  end

  @doc """
  Preprocesses a Discord Voice websocket URL.
  """
  @spec preprocess_url(String.t()) :: String.t()
  def preprocess_url(url), do: url |> apply_protocol() |> apply_version

  defp connect(guild_id, channel_id, self_mute, self_deaf) do
    DynamicSupervisor.start_child(DiscordBot.Voice.AcceptorSupervisor, DiscordBot.Voice.Acceptor)
    Api.update_voice_state(guild_id, channel_id, self_mute, self_deaf)
  end

  defp apply_protocol("wss://" <> url), do: "wss://" <> url
  defp apply_protocol(url), do: "wss://" <> url

  defp apply_version(url), do: url <> "/?v=3"
end
