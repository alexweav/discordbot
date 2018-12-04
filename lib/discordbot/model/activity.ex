defmodule DiscordBot.Model.Activity do
  @derive [Poison.Encoder]
  @moduledoc """
  Represents an activity that a user is currently performing
  """

  @behaviour DiscordBot.Model.Serializable

  defstruct [
    :name,
    :type
  ]

  @typedoc """
  The activity's name
  """
  @type name :: String.t()

  @typedoc """
  The activity's type. Possible values are:
  - `0`: Game - Displays as `Playing {name}`, e.g. "Playing Rocket League"
  - `1`: Streaming - Displays as `Streaming {name}`, e.g. "Streaming Rocket League"
  - `2`: Listening - Displays as `Listening to {name}`, e.g. "Listening to Spotify"
  """
  @type type :: number

  @type t :: %__MODULE__{
          name: name,
          type: type
        }

  @doc """
  Serializes the provided `activity` object into JSON
  """
  @spec to_json(__MODULE__.t()) :: {:ok, iodata}
  def to_json(activity) do
    Poison.encode(activity)
  end

  @doc """
  Deserializes a JSON blob `json` into an activity object
  """
  @spec from_json(iodata) :: __MODULE__.t()
  def from_json(json) do
    {:ok, map} = Poison.decode(json)
    from_map(map)
  end

  @doc """
  Converts a plain map-represented JSON object `map` into a payload
  """
  @spec from_map(map) :: __MODULE__.t()
  def from_map(map) do
    %__MODULE__{
      name: Map.get(map, "name"),
      type: Map.get(map, "type")
    }
  end

  @doc """
  Builds the activity object
  """
  @spec activity(String.t(), number) :: __MODULE__.t()
  def activity(name, type) do
    %__MODULE__{
      name: name,
      type: type
    }
  end
end
