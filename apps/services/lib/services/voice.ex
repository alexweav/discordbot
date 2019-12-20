defmodule Services.Voice do
  @moduledoc """
  Commands for joining voice channels.
  """

  use DiscordBot.Handler
  require Logger

  alias DiscordBot.Entity.Channels
  alias DiscordBot.Voice
  alias DiscordBot.Voice.{Control, FFMPEG, RTP, Session}

  @doc """
  Starts this handler inside a new process.
  """
  def start_link(opts) do
    DiscordBot.Handler.start_link(__MODULE__, :message_create, :ok, opts)
  end

  @doc false
  def handler_init(:ok) do
    {:ok, :ok}
  end

  def handle_message("!ff_rmqconnect", _, _) do
    channel = Services.Audio.ConnectionManager.get_channel!(Services.Audio.ConnectionManager)
    IO.inspect(channel)
    {:noreply}
  end

  @doc false
  def handle_message("!ff_voice", message, _) do
    channels = Channels.voice_channels?(message.guild_id)

    unless channels == [] do
      first_channel = Enum.min_by(channels, fn c -> c.position end)
      {:ok, session} = Voice.connect(first_channel.id)
      Process.sleep(3000)
      {:ok, control} = Session.control?(session)

      Task.Supervisor.start_child(Services.Audio.TaskSupervisor, fn ->
        Services.Audio.Transcoder.transcode("test.wav", "audio.data." <> message.guild_id)
      end)

      Control.speaking(control, true)
      connection = Control.connection?(control)

      encoded_stream =
        :services
        |> :code.priv_dir()
        |> Path.join("test.wav")
        |> FFMPEG.transcode()

      _ =
        Enum.reduce(encoded_stream, {nil, connection}, fn packet, {last_time, conn} ->
          delay = 20
          now = :os.system_time(:milli_seconds)
          last_time = last_time || now
          this_time = last_time + delay
          diff = max(this_time - now, 0)
          Process.sleep(diff)

          conn =
            conn
            |> RTP.send(packet)

          {this_time, conn}
        end)

      _ =
        Enum.reduce(1..5, connection, fn _, c ->
          Process.sleep(20)

          c
          |> RTP.send(RTP.silence_packet())
        end)

      Process.sleep(1000)
      Control.speaking(control, false)
      Voice.disconnect(message.guild_id)
    end

    {:noreply}
  end

  def handle_message("!ff_stop", message, _) do
    Voice.disconnect(message.guild_id)
    {:noreply}
  end

  def handle_message(_, _, _), do: {:noreply}
end
