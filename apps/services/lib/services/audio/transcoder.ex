defmodule Services.Audio.Transcoder do
  @moduledoc """
  Performs audio transcoding and sends the resulting
  frames through RabbitMQ.
  """

  alias DiscordBot.Voice.FFMPEG

  def transcode(file_name, _topic) do
    _ =
      :services
      |> :code.priv_dir()
      |> Path.join(file_name)
      |> FFMPEG.transcode()
  end
end
