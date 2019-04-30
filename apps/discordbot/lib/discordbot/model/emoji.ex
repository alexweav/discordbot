defmodule DiscordBot.Model.Emoji do
  @derive [Poison.Encoder]
  @moduledoc """
  Represents an emoji
  """

  use DiscordBot.Model.Serializable

  alias DiscordBot.Model.{Serializable, User}

  defstruct [
    :id,
    :name,
    :roles,
    :user,
    :require_colons,
    :managed,
    :animated
  ]

  @typedoc """
  The emoji's ID
  """
  @type id :: String.t()

  @typedoc """
  The emoji's name
  """
  @type name :: String.t()

  @typedoc """
  IDs of roles that this emoji is whitelisted to
  """
  @type roles :: list(String.t())

  @typedoc """
  User that created this emoji
  """
  @type user :: User.t()

  @typedoc """
  Whether this emoji must be wrapped in colons
  """
  @type require_colons :: boolean

  @typedoc """
  Whether this emoji is managed
  """
  @type managed :: boolean

  @typedoc """
  Whether this emoji is animated
  """
  @type animated :: boolean

  @type t :: %__MODULE__{
          id: id,
          name: name,
          roles: roles,
          user: user,
          require_colons: require_colons,
          managed: managed,
          animated: animated
        }

  @doc """
  Converts a plain map-represented JSON object `map` into an emoji
  """
  @spec from_map(map) :: __MODULE__.t()
  def from_map(map) do
    Serializable.struct_from_map(map, as: %__MODULE__{})
  end
end
