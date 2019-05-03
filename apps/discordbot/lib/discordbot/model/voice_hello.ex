defmodule DiscordBot.Model.VoiceHello do
  @derive [Poison.Encoder]
  @moduledoc """
  Contains initial connection information for the voice control websocket.
  """

  use DiscordBot.Model.Serializable

  alias DiscordBot.Model.Serializable

  defstruct [
    :v,
    :heartbeat_interval
  ]

  @typedoc """
  The version of the websocket protocol.
  """
  @type v :: number

  @typedoc """
  The interval at which to send heartbeat messages.
  """
  @type heartbeat_interval :: number

  @type t :: %__MODULE__{
          v: v,
          heartbeat_interval: heartbeat_interval
        }

  @doc """
  Converts a JSON map to a voice hello struct.
  """
  @spec from_map(map) :: __MODULE__.t()
  def from_map(map) do
    map
    |> Serializable.struct_from_map(as: %__MODULE__{})
  end
end
