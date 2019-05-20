defmodule Services.PingTest do
  use ExUnit.Case, async: true
  doctest Services.Ping

  alias DiscordBot.Broker
  alias Services.{Help, Ping}

  setup context do
    broker = start_supervised!({Broker, []}, id: Module.concat(context.test, :broker))

    help =
      start_supervised!({Help, [broker: broker, name: context.test]},
        id: Module.concat(context.test, :help),
        restart: :transient
      )

    ping =
      start_supervised!({Ping, help: help, broker: broker}, id: Module.concat(context.test, :ping))

    %{broker: broker, help: help, ping: ping}
  end

  test "responds to ping query" do
    assert Ping.handle_message("!ping", :ok) == {:reply, {:text, "Pong!"}}
  end

  test "responds to source query" do
    assert Ping.handle_message("!source", :ok) ==
             {:reply, {:text, "https://github.com/alexweav/discordbot"}}
  end

  test "ignores other queries" do
    assert Ping.handle_message("!Ping", :ok) == {:noreply}
    assert Ping.handle_message("asdfasdf", :ok) == {:noreply}
    assert Ping.handle_message("", :ok) == {:noreply}
  end

  test "registers help info on start", %{help: help} do
    assert {:ok, _ping_info} = Help.info?(help, "!ping")
    assert {:ok, _src_info} = Help.info?(help, "!source")
  end

  test "subscribes to messages on start", %{broker: broker, ping: ping} do
    assert Enum.member?(Broker.subscribers?(broker, :message_create), ping)
  end
end
