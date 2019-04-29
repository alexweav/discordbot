defmodule DiscordBot.Entity.GuildRecord do
  @moduledoc """
  Represents a cached guild, plus metadata.
  """

  defstruct [
    :shard_connection,
    :guild
  ]

  @typedoc """
  The PID of the `DiscordBot.Gateway.Connection` from which
  this guild originated.
  """
  @type shard_connection :: pid

  @typedoc """
  The core guild data.
  """
  @type guild :: DiscordBot.Model.Guild.t()

  @type t :: %__MODULE__{
          shard_connection: shard_connection,
          guild: guild
        }

  @doc """
  Creates a new guild record.
  """
  @spec new(pid, DiscordBot.Model.Guild.t()) :: __MODULE__.t()
  def new(connection, guild) do
    %__MODULE__{
      shard_connection: connection,
      guild: guild
    }
  end
end
