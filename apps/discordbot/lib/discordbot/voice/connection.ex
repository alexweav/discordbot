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
    :ssrc
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
  @type secret_key :: list(integer)

  @typedoc """
  RTP synchronization source.
  """
  @type ssrc :: integer

  @type t :: %__MODULE__{
          socket: socket,
          discord_ip: discord_ip,
          discord_port: discord_port,
          my_ip: my_ip,
          my_port: my_port,
          secret_key: secret_key,
          ssrc: ssrc
        }
end
