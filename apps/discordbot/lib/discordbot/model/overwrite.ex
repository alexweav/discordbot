defmodule DiscordBot.Model.Overwrite do
  @derive [Poison.Encoder]
  @moduledoc """
  Represents an explicit permission overwrite
  """

  use DiscordBot.Model.Serializable

  defstruct [
    :id,
    :type,
    :allow,
    :deny
  ]

  @typedoc """
  Role or user ID
  """
  @type id :: String.t()

  @typedoc """
  Either "role" or "member"
  """
  @type type :: String.t()

  @typedoc """
  Permission bit set
  """
  @type allow :: number

  @typedoc """
  Permission bit set
  """
  @type deny :: number

  @type t :: %__MODULE__{
          id: id,
          type: type,
          allow: allow,
          deny: deny
        }

  @doc """
  Converts a plain map-represented JSON object `map` into an overwrite
  """
  @spec from_map(map) :: __MODULE__.t()
  def from_map(map) do
    DiscordBot.Model.Serializable.struct_from_map(map, as: %__MODULE__{})
  end
end
