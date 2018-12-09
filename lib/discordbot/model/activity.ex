defmodule DiscordBot.Model.Activity do
  @moduledoc """
  Represents an activity that a user is currently performing
  """

  use DiscordBot.Model.Serializable

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

  defimpl Poison.Encoder, for: __MODULE__ do
    def encode(activity, options) do
      map = Map.from_struct(activity)

      Poison.Encoder.Map.encode(
        %{map | type: DiscordBot.Model.Activity.type_from_atom(map[:type])},
        options
      )
    end
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
      type: map |> Map.get("type") |> atom_from_type()
    }
  end

  @doc """
  Builds the activity object
  """
  @spec activity(atom, String.t()) :: __MODULE__.t()
  def activity(type, name) do
    %__MODULE__{
      type: type,
      name: name
    }
  end

  @doc """
  Converts an activity type ID into a corresponding atom
  """
  @spec atom_from_type(number) :: atom
  def atom_from_type(id) do
    %{
      0 => :playing,
      1 => :streaming,
      2 => :listening
    }[id]
  end

  @doc """
  Converts an activity type atom into its corresponding ID
  """
  @spec type_from_atom(atom) :: number
  def type_from_atom(atom) do
    %{
      playing: 0,
      streaming: 1,
      listening: 2
    }[atom]
  end
end
