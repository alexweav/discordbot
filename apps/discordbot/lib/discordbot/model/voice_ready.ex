defmodule DiscordBot.Model.VoiceReady do
  @moduledoc """
  An object indicating that the voice control websocket has begun operating.
  """

  use DiscordBot.Model.Serializable

  alias DiscordBot.Model.Serializable

  defstruct [
    :ssrc,
    :ip,
    :port,
    :modes,
    :heartbeat_interval
  ]

  @typedoc """
  Synchronization source value for the voice connection.
  """
  @type ssrc :: integer

  @typedoc """
  The IP address to use for the voice UDP connection.
  """
  @type ip :: String.t()

  @typedoc """
  The port to use for the voice UDP connection.
  """
  @type udp_port :: integer

  @typedoc """
  The server's supported encryption modes.
  """
  @type modes :: list(String.t())

  @typedoc """
  A duplicate of the heartbeat interval value.

  In the current API version, this value is always erroneous
  and should be ignored. The correct heartbeat_interval is provided
  in the hello message.
  """
  @type heartbeat_interval :: integer

  @type t :: %__MODULE__{
          ssrc: ssrc,
          ip: ip,
          port: udp_port,
          modes: modes,
          heartbeat_interval: heartbeat_interval
        }

  @doc """
  Converts a JSON map to a voice ready struct.
  """
  @spec from_map(map) :: __MODULE__.t()
  def from_map(map) do
    map
    |> Serializable.struct_from_map(as: %__MODULE__{})
  end
end
