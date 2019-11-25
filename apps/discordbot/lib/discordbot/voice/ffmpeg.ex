defmodule DiscordBot.Voice.FFMPEG do
  @moduledoc """
  Interacts with FFMPEG.
  """

  def transcode(filepath) do
    "ffmpeg"
    |> Porcelain.spawn(
      [
        "-i",
        filepath,
        "-acodec",
        "libopus",
        "-ac",
        "2",
        "-ar",
        "48k",
        "-f",
        "s16le",
        "-loglevel",
        "quiet",
        "pipe:1"
      ],
      out: :stream
    )
    |> Map.get(:out)
  end
end
