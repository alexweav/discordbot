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
    with :ok <- Downloader.available?(),
         {:ok, file_response} <- Downloader.query_files(audio_file_to_play),
         # Downloader.get_file(audio_file_to_play),
         {:ok, file_metadata} <- get_file_by_term(file_response),
         {:ok, audio_file} <- Briefly.create(),
         :ok <- Downloader.download_file(file_metadata["path"], audio_file) do
      transcode_and_send(audio_file, message)
      {:noreply}
    else
      error -> log_error_and_reply(error)
    end
  end

  def handle_message("!stop", message, _) do
    Voice.disconnect(message.guild_id)
    {:noreply}
  end

  def handle_message(_, _, _), do: {:noreply}

  defp transcode_and_send(audio_file, message) do
    channels = Channels.voice_channels?(message.guild_id)

    unless channels == [] do
      first_channel = Enum.min_by(channels, fn c -> c.position end)
      {:ok, session} = Voice.connect(first_channel.id)
      Process.sleep(1000)
      {:ok, control} = Session.control?(session)

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

      Control.speaking(control, false)
      send_silence_sigil(connection)
      Voice.disconnect(message.guild_id)
    end
  end

  defp get_file_by_term(%{"files" => []}) do
    {:error, :notfound}
  end

  defp get_file_by_term(resp) do
    {:ok, Enum.at(resp["files"], 0)}
  end

  defp send_silence_sigil(connection) do
    _ =
      Enum.reduce(1..5, {nil, connection}, fn _, {last_time, conn} ->
        delay = 15
        now = :os.system_time(:milli_seconds)
        last_time = last_time || now
        this_time = last_time + delay
        diff = max(this_time - now, 0)
        Process.sleep(diff)

        conn
        |> RTP.send(RTP.silence_packet())

        {this_time, conn}
      end)
  end

  defp log_error_and_reply({:error, :notfound}) do
    {:reply, {:text, "That file doesn't exist."}}
  end

  defp log_error_and_reply(error) do
    Logger.error("Error acquiring an audio file: #{inspect(error)}")
    {:reply, {:text, "Error obtaining that audio file. :("}}
  end
end
