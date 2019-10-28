defmodule DiscordBot.Model.SelectProtocol do
  @derive [Poison.Encoder]
  @moduledoc """
  Defines the protocol for a UDP connection.
  """

  use DiscordBot.Model.Serializable

  alias DiscordBot.Model.{Serializable, UDP, VoicePayload}

  defstruct [
    :protocol,
    :data
  ]

  @typedoc """
  The protocol type of the connection.
  """
  @type protocol :: String.t()

  @typedoc """
  Describes the connection parameters.
  """
  @type data :: UDP.t()

  @type t :: %__MODULE__{
          protocol: protocol,
          data: data
        }

  @doc """
  Converts a JSON map to a UDP connection struct.
  """
  @spec from_map(map) :: __MODULE__.t()
  def from_map(map) do
    map
    |> Map.update("data", nil, &UDP.from_map(&1))
    |> Serializable.struct_from_map(as: %__MODULE__{})
  end

  @doc """
  Builds the Select Protocol struct.
  """
  @spec select_protocol(String.t(), String.t(), integer, String.t()) :: VoicePayload.t()
  def select_protocol(protocol, address, port, mode) do
    VoicePayload.payload(:select_protocol, %__MODULE__{
      protocol: protocol,
      data: %UDP{
        address: address,
        port: port,
        mode: mode
      }
    })
  end
end
