defmodule DiscordBot.Model.Reaction do
  @derive [Poison.Encoder]
  @moduledoc """
  Represents a reaction to a message.
  """

  use DiscordBot.Model.Serializable

  alias DiscordBot.Model.{Emoji, Serializable}

  defstruct [
    :count,
    :me,
    :emoji
  ]

  @typedoc """
  The number of times that this emoji has been used to react.
  """
  @type count :: integer

  @typedoc """
  Whether the current user has reacted using this emoji.
  """
  @type me :: boolean

  @typedoc """
  The emoji associated with this reaction.
  """
  @type emoji :: Emoji.t()

  @type t :: %__MODULE__{
          count: count,
          me: me,
          emoji: emoji
        }

  @doc """
  Converts a JSON map into a reaction struct.
  """
  @spec from_map(map) :: __MODULE__.t()
  def from_map(map) do
    map
    |> Map.update("emoji", nil, &Emoji.from_map(&1))
    |> Serializable.struct_from_map(as: %__MODULE__{})
  end
end
