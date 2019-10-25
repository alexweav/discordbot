defmodule DiscordBot.VoiceTest do
  use ExUnit.Case, async: true
  doctest DiscordBot.Voice

  alias DiscordBot.Broker

  setup do
    broker = start_supervised!(Broker)

    _ =
      start_supervised!({DiscordBot.Entity.Supervisor, [broker: broker, api: DiscordBot.ApiMock]})

    _ = start_supervised!({DiscordBot.Voice.Supervisor, []})

    %{broker: broker}
  end

  describe "connect" do
    test "errors if invalid channel ID" do
      assert DiscordBot.Voice.connect("asdf") == :error
    end
  end
end
