defmodule DiscordBot.Gateway.HeartbeatTest do
  use ExUnit.Case, async: true

  alias DiscordBot.Gateway.Heartbeat

  setup do
    broker = start_supervised!({DiscordBot.Gateway.Broker, []})
    heartbeat = start_supervised!({DiscordBot.Gateway.Heartbeat, [broker: broker]})
    %{heartbeat: heartbeat, broker: broker}
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

  test "running after schedule other", %{heartbeat: heartbeat} do
    :ok = Heartbeat.schedule(heartbeat, 10000, self())
    assert Heartbeat.target(heartbeat) == self()
  end

  test "running after broker hello event", %{heartbeat: heartbeat, broker: broker} do
    code = :hello

    message = %{
      connection: self(),
      json: %{}
    }

    DiscordBot.Gateway.Broker.publish(broker, code, message)
    assert Heartbeat.target(heartbeat) == self()
  end
end
