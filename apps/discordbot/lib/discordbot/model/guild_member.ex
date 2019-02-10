defmodule DiscordBot.Model.GuildMember do
  @derive [Poison.Encoder]
  @moduledoc """
  Represents a Discord guild member
  """

  use DiscordBot.Model.Serializable

  defstruct [
    :user,
    :nick,
    :roles,
    :joined_at,
    :deaf,
    :mute
  ]

  @typedoc """
  The user this guild member represents
  """
  @type user :: DiscordBot.Model.User.t()

  @typedoc """
  This user's guild nickname, if one is set
  """
  @type nick :: String.t()

  @typedoc """
  Array of role object IDs
  """
  @type roles :: list(String.t())

  @typedoc """
  ISO8601 timestamp of when the user joined the guild
  """
  @type joined_at :: String.t()

  @typedoc """
  Whether the user is deafened
  """
  @type deaf :: boolean

  @typedoc """
  Whether the user is muted
  """
  @type mute :: boolean

  @type t :: %__MODULE__{
          user: user,
          nick: nick,
          roles: roles,
          joined_at: joined_at,
          deaf: deaf,
          mute: mute
        }

  @doc """
  Converts a plain map-represented JSON object `map` into a guild member
  """
  @spec from_map(map) :: __MODULE__.t()
  def from_map(map) do
    map
    |> Map.update("user", nil, &DiscordBot.Model.User.from_map(&1))
    |> DiscordBot.Model.Serializable.struct_from_map(as: %__MODULE__{})
  end
end
