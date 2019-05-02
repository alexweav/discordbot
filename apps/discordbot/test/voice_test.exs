defmodule DiscordBot.VoiceTest do
  use ExUnit.Case, async: true

  alias DiscordBot.Broker

  setup do
    broker = start_supervised!(Broker)

    _ =
      start_supervised!({DiscordBot.Entity.Supervisor, [broker: broker, api: DiscordBot.ApiMock]})

    %{broker: broker}
  end

  describe "connect" do
    test "errors if invalid channel ID" do
      assert DiscordBot.Voice.connect("asdf") == :error
    end
  end

  describe "preprocess_url" do
    test "correct if protocol not provided" do
      assert DiscordBot.Voice.preprocess_url("asdf.gg") == "wss://asdf.gg/?v=3"
    end

    test "correct is protocol already provided" do
      assert DiscordBot.Voice.preprocess_url("wss://asdf.gg") == "wss://asdf.gg/?v=3"
    end
  end
end
