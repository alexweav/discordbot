defmodule DiscordBot.Gateway.HeartbeatTest do
  use ExUnit.Case, async: true

  alias DiscordBot.Gateway.Heartbeat

  setup do
    heartbeat = start_supervised!({DiscordBot.Gateway.Heartbeat, []})
    %{heartbeat: heartbeat}
  end

  test "waiting on launch", %{heartbeat: heartbeat} do
    assert Heartbeat.status(heartbeat) == :waiting
  end

  test "nil target on launch", %{heartbeat: heartbeat} do
    assert Heartbeat.target(heartbeat) == Nil
  end

  test "schedule :ok on launch", %{heartbeat: heartbeat} do
    assert Heartbeat.schedule(heartbeat, 10000) == :ok
  end

  test "running after schedule", %{heartbeat: heartbeat} do
    :ok = Heartbeat.schedule(heartbeat, 10000)
    assert Heartbeat.status(heartbeat) == :running
  end

  test "self target after schedule", %{heartbeat: heartbeat} do
    :ok = Heartbeat.schedule(heartbeat, 10000)
    assert Heartbeat.target(heartbeat) == self()
  end
end
