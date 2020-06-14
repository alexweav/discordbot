defmodule Services.Voice do
  @moduledoc """
  Commands for joining voice channels.
  """

  use DiscordBot.Handler
  require Logger

  alias DiscordBot.Entity.Channels
  alias DiscordBot.Voice
  alias DiscordBot.Voice.{Control, FFMPEG, RTP, Session}
  alias Services.Audio.Downloader

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

  @doc false
  def handle_message("!play", _, _) do
    {:reply, {:text, "No file specified."}}
  end

  def handle_message("!play " <> audio_file_to_play, message, _) do
    channels = Channels.voice_channels?(message.guild_id)

    unless channels == [] do
      first_channel = Enum.min_by(channels, fn c -> c.position end)
      {:ok, session} = Voice.connect(first_channel.id)
      Process.sleep(1000)
      {:ok, control} = Session.control?(session)

      :ok = Downloader.available?()
      {:ok, file_metadata} = Downloader.get_file(audio_file_to_play)
      {:ok, audio_file} = Briefly.create()
      :ok = Downloader.download_file(file_metadata["path"], audio_file)

      Control.speaking(control, true)
      connection = Control.connection?(control)

      encoded_stream =
        audio_file
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

      send_silence_sigil(connection)
      Process.sleep(1000)
      Control.speaking(control, false)
      Voice.disconnect(message.guild_id)
    end

    {:noreply}
  end

  def handle_message("!stop", message, _) do
    Voice.disconnect(message.guild_id)
    {:noreply}
  end

  def handle_message(_, _, _), do: {:noreply}

  defp send_silence_sigil(connection) do
    _ =
      Enum.reduce(1..5, connection, fn _, c ->
        Process.sleep(20)

        c
        |> RTP.send(RTP.silence_packet())
      end)
  end
end
