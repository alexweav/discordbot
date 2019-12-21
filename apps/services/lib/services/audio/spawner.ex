defmodule Services.Audio.Spawner do
  @moduledoc """
  Spawns transcoding jobs.
  """

  use Task

  require Logger

  alias Services.Audio.{ConnectionManager, Transcoder}

  def start_link(arg) do
    Task.start_link(__MODULE__, :run, [arg])
  end

  def run(_) do
    channel = ConnectionManager.get_channel!(Services.Audio.ConnectionManager)
    AMQP.Queue.declare(channel, "work.transcode")
    AMQP.Basic.consume(channel, "work.transcode", nil, no_ack: true)
    wait_for_messages()
  end

  def wait_for_messages do
    Logger.info("Waiting for messages.")

    receive do
      {:basic_deliver, payload, _} ->
        {file_name, guild_id} = parse(payload)
        Logger.info("Starting transcode job for file #{file_name}")

        Task.Supervisor.start_child(
          Services.Audio.TaskSupervisor,
          fn ->
            Transcoder.transcode(file_name, "audio.data." <> guild_id)
          end,
          restart: :temporary
        )
    end
  end

  defp parse(payload) do
    elements = String.split(payload, ",")
    {Enum.at(elements, 0), Enum.at(elements, 1)}
  end
end
