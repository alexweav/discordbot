defmodule Services.TtsSplitter do
  @moduledoc """
  Discord normally truncates messages sent with `/tts`
  to 200-300 characters. This can make it annoying to read
  long pieces of text over TTS.

  Adds the `!tts_split <text>` chat command, which breaks up
  a long paragraph of text into segments short enough to be
  read by Discord's TTS feature. It will then post the segments
  with TTS enabled, sequentially.

  The module `DiscordBot.Handlers.TtsSplitter.Supervisor` is a
  supervisable process for this functionality, which will automatically
  host a handler for the logic in this module.
  """

  use DiscordBot.Handler

  alias DiscordBot.Entity.ChannelManager
  alias DiscordBot.Model.Message
  alias Services.Help

  @default_character_threshold 175
  @reply_interval Application.get_env(
                    :services,
                    :tts_response_interval,
                    3_000
                  )

  def start_link(opts) do
    help = Keyword.get(opts, :help, Services.Help)
    DiscordBot.Handler.start_link(__MODULE__, :message_create, help, opts)
  end

  @doc """
  Returns the given text as a list of TTS-compatible chunks
  """
  @spec tts_split(String.t(), integer) :: list(String.t())
  def tts_split(text, character_threshold \\ @default_character_threshold) do
    text
    |> words()
    |> group_words(character_threshold)
  end

  @doc """
  Groups and concatenates a list of words into space-separated
  strings which are each shorter than `character_threshold`
  """
  @spec group_words(list(String.t()), integer) :: list(String.t())
  def group_words([], _character_threshold), do: []

  def group_words(words, character_threshold) do
    chunk = get_words_under_aggregate_length(words, character_threshold)
    remaining = take_tail(words, Enum.count(words) - Enum.count(chunk))
    [rejoin(chunk)] ++ group_words(remaining, character_threshold)
  end

  @doc """
  Splits text into a list of individual words
  """
  @spec words(String.t()) :: list(String.t())
  def words(text) do
    text
    |> String.trim()
    |> String.split(" ")
  end

  @doc """
  Gets the first n words from a list of words, such that their summed aggregate length
  is less than `total_length`. The length of each word is adjusted to account for spaces.
  """
  @spec get_words_under_aggregate_length(list(String.t()), number) :: list(String.t())
  def get_words_under_aggregate_length(words, total_length) do
    {words, _, _} =
      Enum.reduce(words, {[], 0, false}, fn word, {parsed, accumulated_length, done} ->
        adjusted_length = String.length(word) + 1

        cond do
          done ->
            {parsed, accumulated_length, done}

          parsed == [] and adjusted_length >= total_length ->
            {[word], adjusted_length, true}

          accumulated_length + adjusted_length >= total_length ->
            {parsed, accumulated_length, true}

          true ->
            {parsed ++ [word], accumulated_length + adjusted_length, false}
        end
      end)

    words
  end

  @doc """
  Joins a list of words into a string with space separators
  """
  @spec rejoin(list(String.t())) :: String.t()
  def rejoin(words) do
    Enum.join(words, " ")
  end

  @doc """
  Takes the last `amount` items from the given enumerable
  """
  @spec take_tail(Enum.t(), integer) :: list
  def take_tail(enumerable, amount) do
    enumerable
    |> Enum.reverse()
    |> Enum.take(amount)
    |> Enum.reverse()
  end

  ## Handlers

  @doc false
  def handler_init(help) do
    Help.register_info(help, %Help.Info{
      command_key: "!tts_split",
      name: "TTS Split",
      description: "Splits long text into segments and repeats them using /tts"
    })

    {:ok, :ok}
  end

  @doc false
  def handle_message("!tts_split " <> text, message, _) do
    chunks = tts_split(text)
    send_tts_chunks(chunks, message)
    {:noreply}
  end

  def handle_message(_, _, _), do: {:noreply}

  defp send_tts_chunks(chunks, message) do
    for chunk <- chunks do
      channel_manager().reply(message, chunk, tts: true)
      Process.sleep(@reply_interval)
    end
  end

  defp channel_manager do
    Application.get_env(
      :services,
      :channel_manager,
      ChannelManager
    )
  end
end
