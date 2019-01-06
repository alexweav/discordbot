defmodule DiscordBot.Handlers.TtsSplitterTest do
  use ExUnit.Case, async: true
  doctest DiscordBot.Handlers.TtsSplitter

  alias DiscordBot.Handlers.TtsSplitter

  test "splits text into words" do
    text1 = "test string wew"
    text2 = "      test string wew   "
    expected = ["test", "string", "wew"]
    assert TtsSplitter.words(text1) == expected
    assert TtsSplitter.words(text2) == expected
  end

  test "can take last n items" do
    list = [1, 2, 3, 4]
    assert TtsSplitter.take_tail(list, 1) == [4]
    assert TtsSplitter.take_tail(list, 3) == [2, 3, 4]
  end

  test "doesn't split short strings" do
    text = "a string"
    assert TtsSplitter.tts_split(text) == [text]
  end

  test "words longer than threshold end up in their own chunk" do
    text = "a b test asdfasdfasdf done"
    chunks = TtsSplitter.tts_split(text, 5)
    assert chunks == ["a b", "test", "asdfasdfasdf", "done"]
  end
end
