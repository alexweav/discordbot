defmodule DiscordBot.Model.Hello do
  @derive [Poison.Encoder]
  @moduledoc """
  The initial message sent over the websocket
  """

  use DiscordBot.Model.Serializable

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
    DiscordBot.Model.Serializable.struct_from_map(map, as: %__MODULE__{})
  end
end
