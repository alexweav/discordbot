defmodule DiscordBot.Voice.Player do
  @moduledoc """
  Joins a voice channel and plays an audio file.
  """

  alias DiscordBot.Voice
  alias DiscordBot.Voice.{Control, FFMPEG, RTP, Session}

  @connect_settle_delay_milliseconds 1000
  @rtp_packet_interval_milliseconds 20

  @doc """
  Plays an audio file in an audio channel, as a supervised task.
  Returns the task's PID.
  """
  def start_player(channel, audio_file) do
    Supervisor.start_child(
      DiscordBot.Voice.PlayerSupervisor,
      fn -> play(channel, audio_file) end
    )
  end

  @doc """
  Plays an audio file in a channel.
  """
  def play(channel, audio_file) do
    {:ok, session} = Voice.connect(channel.id)
    # The above call blocks until the connection is established.
    # Regardless, wait a bit to allow the dust to settle.
    Process.sleep(@connect_settle_delay_milliseconds)
    {:ok, control} = Session.control?(session)

    transcoded_stream =
      audio_file
      |> FFMPEG.transcode()

    voip_connection = Control.connection?(control)

    # Begin speaking.
    Control.speaking(control, true)

    _ =
      Enum.reduce(transcoded_stream, {nil, voip_connection}, fn packet, {last_time, conn} ->
        now = :os.system_time(:milli_seconds)
        last_time = last_time || now
        this_time = last_time + @rtp_packet_interval_milliseconds
        diff = max(this_time - now, 0)
        Process.sleep(diff)

        conn =
          conn
          |> RTP.send(packet)

        {this_time, conn}
      end)

    # Stop speaking.
    Control.speaking(control, false)

    # Send a few frames of silence in order to avoid unintended audio interpolation.
    send_silence_frames(voip_connection, 5)
    Voice.disconnect(channel.guild_id)
  end

  defp send_silence_frames(connection, num_frames, previous_frame_time \\ nil)
  defp send_silence_frames(_, 0, _), do: nil

  defp send_silence_frames(connection, num_frames, previous_frame_time) do
    # Slightly shorter than the default.
    # It's fine if silence gets frontloaded a bit, but sounds bad if it gets behind.
    delay = @rtp_packet_interval_milliseconds - 5
    now = :os.system_time(:milli_seconds)
    previous_frame_time = previous_frame_time || now
    this_time = previous_frame_time + delay
    diff = max(this_time - now, 0)
    Process.sleep(diff)

    connection
    |> RTP.send(RTP.silence_packet())

    send_silence_frames(connection, num_frames - 1, this_time)
  end
end
