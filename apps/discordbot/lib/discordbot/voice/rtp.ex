defmodule DiscordBot.Voice.RTP do
  @moduledoc """
  RTP protocol logic, packet building, and encryption.
  """

  alias DiscordBot.Voice.Connection

  @doc """
  Wraps a binary with an encrypted RTP packet.
  """
  @spec build_packet(binary, Connection.t()) :: binary
  def build_packet(body_bytes, connection) do
    header = header(connection)
    nonce = <<header::size(96), 0::size(96)>>
    body = Kcl.secretbox(body_bytes, body_bytes, nonce, connection.secret_key)
    header <> body
  end

  @doc """
  Builds an RTP header from a connection state.
  """
  @spec header(Connection.t()) :: binary
  def header(connection) do
    header(connection.sequence, connection.timestamp, connection.ssrc)
  end

  @doc """
  Builds an RTP header.
  """
  @spec header(integer, integer, integer) :: binary
  def header(sequence, timestamp, ssrc) do
    # Version 2
    version = 2
    # No additional padding
    padding = 0
    # No header extensions
    extension = 0
    # No CSRC identifiers
    csrc_count = 0
    # No markers defined
    marker = 0
    # Defined by Discord
    payload_type = 0x78

    <<version::size(2), padding::size(1), extension::size(1), csrc_count::size(4),
      marker::size(1), payload_type::size(7), sequence::size(16), timestamp::size(32),
      ssrc::size(32)>>
  end
end
