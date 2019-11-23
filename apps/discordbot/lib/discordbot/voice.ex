defmodule DiscordBot.Voice do
  @moduledoc """
  Allows the client to communicate over the voice API.
  """

  alias DiscordBot.Entity.Channels
  alias DiscordBot.Gateway.Api
  alias DiscordBot.Voice.{Launcher, Session}

  @doc """
  Connects to a voice channel.
  """
  @spec connect(String.t(), boolean, boolean) :: {:ok, pid} | :error
  def connect(channel_id, self_mute \\ false, self_deaf \\ false) do
    case Channels.from_id?(channel_id) do
      {:ok, channel} ->
        # Run this in another process because it affects subscriptions
        task =
          Task.async(fn ->
            Launcher.initiate(channel.guild_id, channel_id, self_mute, self_deaf)
          end)

        Task.await(task, :infinity)

      :error ->
        :error
    end
  end

  @doc """
  Disconnects from a voice channel.
  """
  @spec disconnect(String.t()) :: :ok | :error
  def disconnect(guild_id) do
    sessions = Registry.lookup(DiscordBot.Voice.SessionRegistry, guild_id)

    Api.update_voice_state(guild_id, nil, false, false)

    unless sessions == [] do
      [{session, _}] = sessions
      Session.disconnect(session)
    end
  end
end
