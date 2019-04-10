defmodule DiscordBot.Broker.Provider do
  @moduledoc """
  Represents an entity which provides access to a `DiscordBot.Broker` instance.
  """

  @callback broker?(pid) :: pid | nil
end
