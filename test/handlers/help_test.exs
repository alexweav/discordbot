defmodule DiscordBot.Handlers.HelpTest do
  use ExUnit.Case, async: true
  doctest DiscordBot.Handlers.Help

  alias DiscordBot.Broker
  alias DiscordBot.Handlers.Help

  setup do
    broker = start_supervised!({Broker, []})
    help = start_supervised!({Help, [broker: broker]})
    %{broker: broker, help: help}
  end

  test "registers new info entries", %{help: help} do
    assert Help.info?(help, "!command") == :error

    info = %Help.Info{
      command_key: "!command",
      name: "Command",
      description: "A command"
    }

    assert Help.register_info(help, info) == :ok
    assert Help.info?(help, "!command") == {:ok, info}
  end

  test "always registers help command", %{help: help} do
    assert Help.info?(help, "!help") != :error
  end

  test "keeps things registered if process restarts", %{help: help, broker: broker} do
    info = %Help.Info{
      command_key: "!command",
      name: "Command",
      description: "A command"
    }

    Help.register_info(help, info)

    ref = Process.monitor(help)
    GenServer.stop(help, :normal)
    new_info = start_supervised!({Help, [broker: broker]}, id: :test)

    assert Help.info?(new_info, "!command") == {:ok, info}
  end
end
