defmodule DiscordBot.Voice do
  @moduledoc """
  Allows the client to communicate over the voice API.
  """

  alias DiscordBot.Entity.Channels
  alias DiscordBot.Gateway.Api
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
  Disconnects from a voice channel.
  """
  @spec disconnect(String.t()) :: :ok | :error
  def disconnect(guild_id) do
    sessions = Registry.lookup(DiscordBot.Voice.SessionRegistry, guild_id)

    unless sessions == [] do
      [{session, _}] = sessions
      Session.disconnect(session)
    end
  end

  defp connect(guild_id, channel_id, self_mute, self_deaf) do
    DynamicSupervisor.start_child(DiscordBot.Voice.AcceptorSupervisor, DiscordBot.Voice.Acceptor)
    Api.update_voice_state(guild_id, channel_id, self_mute, self_deaf)
  end
end
