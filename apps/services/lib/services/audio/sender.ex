defmodule Services.Audio.Sender do
  alias Services.Audio.ConnectionManager

  def initiate_transcode(file_name, guild_id) do
    channel = ConnectionManager.get_channel!(Services.Audio.ConnectionManager)
    AMQP.Queue.declare(channel, "work.transcode")
    AMQP.Basic.publish(channel, "", "work.transcode", "#{file_name},#{guild_id}")
  end
end
