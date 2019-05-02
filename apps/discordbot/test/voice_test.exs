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
end
