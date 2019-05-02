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

  defp connect(guild_id, channel_id, self_mute, self_deaf) do
    DynamicSupervisor.start_child(DiscordBot.Voice.AcceptorSupervisor, DiscordBot.Voice.Acceptor)
    Api.update_voice_state(guild_id, channel_id, self_mute, self_deaf)
  end
end
