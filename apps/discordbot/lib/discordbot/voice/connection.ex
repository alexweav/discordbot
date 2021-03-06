defmodule DiscordBot.Voice.Connection do
  @moduledoc """
  Represents a full voice connection in its entirety.
  """

  defstruct [
    :socket,
    :discord_ip,
    :discord_port,
    :my_ip,
    :my_port,
    :secret_key,
    :ssrc,
    :timestamp,
    :sequence
  ]

  @typedoc """
  UDP socket for voice data communication.
  """
  @type socket :: :gen_udp.socket()

  @typedoc """
  Discord's UDP IP.
  """
  @type discord_ip :: :inet.ip_address()

  @typedoc """
  Discord's UDP port.
  """
  @type discord_port :: integer

  @typedoc """
  Our external IP address.
  """
  @type my_ip :: :inet.ip_address()

  @typedoc """
  Our external UDP port.
  """
  @type my_port :: integer

  @typedoc """
  Secret key to use when encrypting voice data.
  """
  @type secret_key :: binary

  @typedoc """
  RTP synchronization source.
  """
  @type ssrc :: integer

  @typedoc """
  Packet timestamp, in relative units. The relative units are assumed to be monotonically and linearly increasing.
  """
  @type timestamp :: integer

  @typedoc """
  UDP packet index. Increments with each packet sent.
  """
  @type sequence :: integer

  @type t :: %__MODULE__{
          socket: socket,
          discord_ip: discord_ip,
          discord_port: discord_port,
          my_ip: my_ip,
          my_port: my_port,
          secret_key: secret_key,
          ssrc: ssrc,
          timestamp: timestamp,
          sequence: sequence
        }
end
