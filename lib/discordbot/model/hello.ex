defmodule DiscordBot.Model.Hello do
  @derive [Poison.Encoder]
  @moduledoc """
  The initial message sent over the websocket
  """

  @behaviour DiscordBot.Model.Serializable

  defstruct [
    :heartbeat_interval,
    :_trace
  ]

  @typedoc """
  Interval in milliseconds that the bot should heartbeat with
  """
  @type heartbeat_interval :: number

  @typedoc """
  Array of servers connected to, for debugging
  """
  @type trace :: list(String.t())

  @type t :: %__MODULE__{
          heartbeat_interval: heartbeat_interval,
          _trace: trace
        }

  @doc """
  Serializes the provided `hello` object into JSON
  """
  @spec to_json(__MODULE__.t()) :: {:ok, iodata}
  def to_json(hello) do
    Poison.encode(hello)
  end

  @doc """
  Deserializes a JSON blob `json` into a hello object
  """
  @spec from_json(iodata) :: __MODULE__.t()
  def from_json(json) do
    {:ok, map} = Poison.decode(json)
    from_map(map)
  end

  @doc """
  Converts a plain map-represented JSON object `map` into a hello object
  """
  @spec from_map(map) :: __MODULE__.t()
  def from_map(map) do
    %__MODULE__{
      heartbeat_interval: Map.get(map, "heartbeat_interval"),
      _trace: Map.get(map, "_trace")
    }
  end
end
