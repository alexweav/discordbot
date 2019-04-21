defmodule DiscordBot.Gateway.Api do
  @moduledoc """
  Provides the portions of the Discord API which are consumed over
  websocket rather than HTTP requests.
  """

  @doc """
  Updates the bot account's global status.

  `status` may be one of the following:
  - `:online` - shows the bot as online. This is the default setting.
  - `:dnd` - sets the bot to Do Not Disturb mode.
  - `:idle` - shows the bot as `Away`.
  - `:invisible` - shows the bot as offline.
  """
  @spec update_status!(atom) :: :ok
  def update_status!(status) do
    options = [:online, :dnd, :idle, :invisible]

    unless Enum.member?(options, status) do
      raise ArgumentError, message: "#{status} is not a valid status."
    end

    # TODO
    :ok
  end
end
