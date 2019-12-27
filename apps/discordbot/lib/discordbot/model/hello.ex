defmodule DiscordBot.Model.Hello do
  @derive [Poison.Encoder]
  @moduledoc """
  The initial message sent over the websocket
  """

  use DiscordBot.Model.Serializable

  alias DiscordBot.Model.{Payload, Serializable}

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
  Converts a plain map-represented JSON object `map` into a hello object
  """
  @spec from_map(map) :: __MODULE__.t()
  def from_map(map) do
    Serializable.struct_from_map(map, as: %__MODULE__{})
  end

  @doc """
  Creates a hello struct.
  """
  @spec new(integer, list(String.t())) :: __MODULE__.t()
  def new(interval, trace) do
    %__MODULE__{
      heartbeat_interval: interval,
      _trace: trace
    }
  end

  @doc """
  Creates a hello struct wrapped in a payload.
  """
  @spec hello(integer, list(String.t())) :: Payload.t()
  def hello(interval, trace) do
    Payload.payload(:hello, new(interval, trace))
  end
end
