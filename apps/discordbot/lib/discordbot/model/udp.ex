defmodule DiscordBot.Model.UDP do
  @derive [Poison.Encoder]
  @moduledoc """
  Describes a voice UDP connection.
  """

  use DiscordBot.Model.Serializable

  alias DiscordBot.Model.Serializable

  defstruct [
    :address,
    :port,
    :mode
  ]

  @typedoc """
  The IP address of the connection.
  """
  @type address :: String.t()

  @typedoc """
  The port of the connection.
  """
  @type connection_port :: integer

  @typedoc """
  The connection mode, usually "xsalsa20_poly1305"
  """
  @type mode :: String.t()

  @type t :: %__MODULE__{
          address: address,
          port: connection_port,
          mode: mode
        }

  @doc """
  Converts a JSON map to a UDP connection struct.
  """
  @spec from_map(map) :: __MODULE__.t()
  def from_map(map) do
    map
    |> Serializable.struct_from_map(as: %__MODULE__{})
  end
end
