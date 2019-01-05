defmodule DiscordBot.Handlers.TtsSplitter do
  @moduledoc """
  Discord normally truncates messages sent with `/tts`
  to 200-300 characters. This can make it annoying to read
  long pieces of text over TTS.

  Adds the `!tts_split <text>` chat command, which breaks up
  a long paragraph of text into segments short enough to be
  read by Discord's TTS feature. It will then post the segments
  with TTS enabled, sequentially.
  """
end
