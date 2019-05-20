defmodule Services.TtsSplitterTest do
  use ExUnit.Case, async: true
  doctest Services.TtsSplitter

  alias DiscordBot.Broker
  alias Services.{Help, TtsSplitter}

  setup context do
    broker = start_supervised!({Broker, []}, id: Module.concat(context.test, :broker))

    help =
      start_supervised!({Help, [broker: broker, name: context.test]},
        id: Module.concat(context.test, :help),
        restart: :transient
      )

    splitter =
      start_supervised!({TtsSplitter, help: help, broker: broker},
        id: Module.concat(context.test, :splitter)
      )

    %{broker: broker, help: help, splitter: splitter}
  end

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

  test "registers help documentation", %{help: help} do
    assert {:ok, _} = Help.info?(help, "!tts_split")
  end

  test "subscribes to messages on start", %{broker: broker, splitter: splitter} do
    assert Enum.member?(Broker.subscribers?(broker, :message_create), splitter)
  end
end
