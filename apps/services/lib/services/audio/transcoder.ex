defmodule Services.Audio.Transcoder do
  @moduledoc """
  Performs audio transcoding and sends the resulting
  frames through RabbitMQ.
  """

  alias DiscordBot.Voice.FFMPEG
  alias Services.Audio.ConnectionManager

  def transcode(file_name, topic) do
    channel = ConnectionManager.get_channel!(Services.Audio.ConnectionManager)
    AMQP.Queue.declare(channel, topic)

    encoded_stream =
      :services
      |> :code.priv_dir()
      |> Path.join(file_name)
      |> FFMPEG.transcode()

    _ =
      Enum.reduce(encoded_stream, channel, fn packet, channel ->
        AMQP.Basic.publish(channel, "", topic, packet)
        channel
      end)
  end
end
