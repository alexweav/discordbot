defmodule Services.TtsSplitter.ServerTest do
  use ExUnit.Case, async: false
  doctest Services.TtsSplitter.Server

  alias DiscordBot.Broker
  alias Services.Help

  setup context do
    broker = start_supervised!({Broker, []})
    help = start_supervised!({Help, [broker: broker, name: context.test]})

    _ = start_supervised!({Services.TtsSplitter.Supervisor, broker: broker, help: help})

    %{broker: broker, help: help}
  end

  test "subscribes to provided broker", %{broker: broker} do
    pid = Process.whereis(Services.TtsSplitter.Server)
    assert Enum.member?(Broker.subscribers?(broker, :message_create), pid)
  end

  test "registers help documentation", %{help: help} do
    assert {:ok, _} = Help.info?(help, "!tts_split")
  end
end
