defmodule DiscordBot.Model.Role do
  @derive [Poison.Encoder]
  @moduledoc """
  Represents a role within a guild
  """

  use DiscordBot.Model.Serializable

  alias DiscordBot.Model.Serializable

  defstruct [
    :id,
    :name,
    :color,
    :hoist,
    :position,
    :permissions,
    :managed,
    :mentionable
  ]

  @typedoc """
  The role's ID
  """
  @type id :: String.t()

  @typedoc """
  The role's name
  """
  @type name :: String.t()

  @typedoc """
  Integer representation of hex color code
  """
  @type color :: number

  @typedoc """
  If the role is pinned in the user listing
  """
  @type hoist :: boolean

  @typedoc """
  Position of this role
  """
  @type position :: integer

  @typedoc """
  Permission bit set
  """
  @type permissions :: integer

  @typedoc """
  Whether this role is managed by an integration
  """
  @type managed :: boolean

  @typedoc """
  Whether this role is mentionable
  """
  @type mentionable :: boolean

  @type t :: %__MODULE__{
          id: id,
          name: name,
          color: color,
          hoist: hoist,
          position: position,
          permissions: permissions,
          managed: managed,
          mentionable: mentionable
        }

  @doc """
  Converts a plain map-represented JSON object `map` into a role
  """
  @spec from_map(map) :: __MODULE__.t()
  def from_map(map) do
    Serializable.struct_from_map(map, as: %__MODULE__{})
  end
end
