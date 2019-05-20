defmodule Services.PingTest do
  use ExUnit.Case, async: true
  doctest Services.Ping

  alias Services.Ping

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
end
