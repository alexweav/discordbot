defmodule DiscordBot.Model.MessageApplication do
  @derive [Poison.Encoder]
  @moduledoc """
  Represents message info which originated from an external application.
  """

  use DiscordBot.Model.Serializable

  alias DiscordBot.Model.Serializable

  defstruct [
    :id,
    :cover_image,
    :description,
    :icon,
    :name
  ]

  @typedoc """
  The ID of the application.
  """
  @type id :: String.t()

  @typedoc """
  The ID of the embed's image asset.
  """
  @type cover_image :: String.t() | nil

  @typedoc """
  The application's description.
  """
  @type description :: String.t()

  @typedoc """
  The ID of the application's icon.
  """
  @type icon :: String.t() | nil

  @typedoc """
  The name of the application.
  """
  @type name :: String.t()

  @type t :: %__MODULE__{
          id: id,
          cover_image: cover_image,
          description: description,
          icon: icon,
          name: name
        }

  @doc """
  Converts a JSON map into a message application struct.
  """
  @spec from_map(map) :: __MODULE__.t()
  def from_map(map) do
    map
    |> Serializable.struct_from_map(as: %__MODULE__{})
  end
end
