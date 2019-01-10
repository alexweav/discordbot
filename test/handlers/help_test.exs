defmodule DiscordBot.Handlers.HelpTest do
  use ExUnit.Case, async: true
  doctest DiscordBot.Handlers.Help

  alias DiscordBot.Broker
  alias DiscordBot.Handlers.Help

  setup do
    broker = start_supervised!({Broker, []})
    help = start_supervised!({Help, [broker: broker, name: DiscordBot.Help]}, restart: :transient)
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
end
