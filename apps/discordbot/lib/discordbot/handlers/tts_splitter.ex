defmodule DiscordBot.Handlers.TtsSplitter do
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

  @default_character_threshold 175

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
end
