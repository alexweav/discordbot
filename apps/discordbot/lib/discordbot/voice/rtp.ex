defmodule DiscordBot.Voice.Rtp do
  @moduledoc """
  RTP protocol logic.
  """

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
