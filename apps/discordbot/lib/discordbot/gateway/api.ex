defmodule DiscordBot.Gateway.Api do
  @moduledoc """
  Provides the portions of the Discord API which are consumed over
  websocket rather than HTTP requests.
  """

  alias DiscordBot.Gateway
  alias DiscordBot.Gateway.Connection
  alias DiscordBot.Model.{Activity, StatusUpdate}

  @doc """
  Updates the bot account's global status.

  `gateway` must be a `DiscordBot.Gateway` instance.

  `status` may be one of the following:
  - `:online` - shows the bot as online. This is the default setting.
  - `:dnd` - sets the bot to Do Not Disturb mode.
  - `:idle` - shows the bot as `Away`.
  - `:invisible` - shows the bot as offline.
  """
  @spec update_status(atom | pid, atom) :: :ok | :error
  def update_status(gateway, status) do
    if validate_status(status) do
      for gateway <- Gateway.active_gateways(gateway) do
        {:ok, pid} =
          gateway
          |> Gateway.Supervisor.connection?()

        Connection.update_status(pid, status)
      end

      :ok
    else
      :error
    end
  end

  @doc """
  Updates the bot account's global status and activity.

  `gateway` must be a `DiscordBot.Gateway` instance.

  `status` may be one of the following:
  - `:online` - shows the bot as online. This is the default setting.
  - `:dnd` - sets the bot to Do Not Disturb mode.
  - `:idle` - shows the bot as `Away`.
  - `:invisible` - shows the bot as offline.

  `name` indicates the bot's activity verb, and `name` is its subject.
  For instance, a type of `:playing` and a name of "Skyrim" will
  cause the bot to be shown as "Playing Skyrim."

  `type` may be one of the following:
  - `:playing` - Displays as "Playing `name`".
  - `:streaming` - Displays as "Streaming `name`".
  - `:listening` - Displays as "Listening to `name`".
  """
  @spec update_status(atom | pid, atom, atom, String.t()) :: :ok | :error
  def update_status(gateway, status, type, name) do
    cond do
      !validate_status(status) ->
        :error

      !validate_activity_type(type) ->
        :error

      true ->
        for gateway <- Gateway.active_gateways(gateway) do
          {:ok, pid} =
            gateway
            |> Gateway.Supervisor.connection?()

          Connection.update_status(pid, status, type, name)
        end

        :ok
    end
  end

  @doc """
  Updates the bot's voice state to a channel.

  A voice state is guild-specific. `guild_id` indicates the ID of the guild
  for which the update will be applied. `channel_id` is the ID of the voice
  channel to which the bot's state will be updated. `self_mute` and `self_deaf`
  represent the initial mute/deaf state of the bot on update.
  """
  @spec update_voice_state(String.t(), String.t(), boolean, boolean) :: :ok | :error
  def update_voice_state(guild_id, channel_id, self_mute \\ false, self_deaf \\ false) do
    with {:ok, record} <- DiscordBot.Entity.Guild.lookup_by_id(guild_id),
         connection <- record.shard_connection do
      Connection.update_voice_state(connection, guild_id, channel_id, self_mute, self_deaf)
      :ok
    else
      :error -> :error
    end
  end

  @spec validate_status(atom) :: boolean
  defp validate_status(status) do
    !is_nil(StatusUpdate.status_from_atom(status))
  end

  @spec validate_activity_type(atom) :: boolean
  defp validate_activity_type(type) do
    !is_nil(Activity.type_from_atom(type))
  end
end
