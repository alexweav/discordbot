defmodule DiscordBot.Handlers.TtsSplitter.ServerTest do
  use ExUnit.Case, async: false
  doctest DiscordBot.Handlers.TtsSplitter.Server

  alias DiscordBot.Broker
  alias DiscordBot.Handlers.Help

  setup do
    broker = start_supervised!({Broker, []})
    help = start_supervised!({Help, [broker: broker, name: DiscordBot.Help]})
    _ = start_supervised!({DiscordBot.Handlers.TtsSplitter.Supervisor, broker: broker})
    %{broker: broker, help: help}
  end

  test "subscribes to provided broker", %{broker: broker} do
    pid = Process.whereis(DiscordBot.TtsSplitter.Server)
    assert Enum.member?(Broker.subscribers?(broker, :message_create), pid)
  end

  test "registers help documentation", %{help: help} do
    assert {:ok, _} = Help.info?(help, "!tts_split")
  end
end
