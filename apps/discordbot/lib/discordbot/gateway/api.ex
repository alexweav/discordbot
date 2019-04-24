defmodule DiscordBot.Gateway.Api do
  @moduledoc """
  Provides the portions of the Discord API which are consumed over
  websocket rather than HTTP requests.
  """

  alias DiscordBot.Gateway
  alias DiscordBot.Gateway.Connection

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
    unless validate_status(status) do
      :error
    else
      case get_connection(gateway) do
        {:ok, connection} -> Connection.update_status(connection, status)
        :error -> :error
      end
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
        case get_connection(gateway) do
          {:ok, connection} -> Connection.update_status(connection, status, type, name)
          :error -> :error
        end
    end
  end

  @spec validate_status(atom) :: boolean
  defp validate_status(status) do
    !is_nil(DiscordBot.Model.StatusUpdate.status_from_atom(status))
  end

  @spec validate_activity_type(atom) :: boolean
  defp validate_activity_type(type) do
    !is_nil(DiscordBot.Model.Activity.type_from_atom(type))
  end

  @spec get_connection(atom | pid) :: {:ok, pid} | :error
  defp get_connection(gateway) do
    with {:ok, sup} <- Gateway.get_gateway_instance(gateway, 0),
         {:ok, conn} <- Gateway.Supervisor.connection?(sup) do
      {:ok, conn}
    else
      :error -> :error
    end
  end
end
