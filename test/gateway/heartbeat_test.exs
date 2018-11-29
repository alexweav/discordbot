defmodule DiscordBot.Gateway.HeartbeatTest do
  use ExUnit.Case, async: true

  alias DiscordBot.Gateway.Heartbeat

  setup do
    broker = start_supervised!({DiscordBot.Gateway.Broker, []})
    heartbeat = start_supervised!({DiscordBot.Gateway.Heartbeat, [broker: broker]})
    %{heartbeat: heartbeat, broker: broker}
  end

  test "waiting on launch", %{heartbeat: heartbeat} do
    assert Heartbeat.status?(heartbeat) == :waiting
    assert Heartbeat.interval?(heartbeat) == nil
  end

  test "untargeted on launch", %{heartbeat: heartbeat} do
    assert Heartbeat.target?(heartbeat) == nil
    assert Heartbeat.interval?(heartbeat) == nil
  end

  test "schedule :ok on launch", %{heartbeat: heartbeat} do
    assert Heartbeat.schedule(heartbeat, 10_000) == :ok
  end

  test "running after schedule", %{heartbeat: heartbeat} do
    :ok = Heartbeat.schedule(heartbeat, 10_000)
    assert Heartbeat.status?(heartbeat) == :running
  end

  test "self target after schedule", %{heartbeat: heartbeat} do
    :ok = Heartbeat.schedule(heartbeat, 10_000)
    assert Heartbeat.target?(heartbeat) == self()
    assert Heartbeat.interval?(heartbeat) == 10_000
  end

  test "running after schedule other", %{heartbeat: heartbeat} do
    {:ok, pid} =
      Task.start_link(fn ->
        receive do
          :dummy -> :wontmatch
        end
      end)

    :ok = Heartbeat.schedule(heartbeat, 10_000, pid)
    assert Heartbeat.target?(heartbeat) == pid
    assert Heartbeat.interval?(heartbeat) == 10_000
  end

  test "idle after scheduled process closes", %{heartbeat: heartbeat} do
    %{pid: pid} =
      task =
      Task.async(fn ->
        receive do
          {:dummy, msg} -> msg
        end
      end)

    :ok = Heartbeat.schedule(heartbeat, 10_000, pid)
    send(pid, {:dummy, :msg})
    Task.await(task)
    assert Heartbeat.status?(heartbeat) == :waiting
    assert Heartbeat.target?(heartbeat) == nil
    assert Heartbeat.interval?(heartbeat) == nil
  end

  test "running after broker hello event", %{heartbeat: heartbeat, broker: broker} do
    code = :hello

    message = %{
      connection: self(),
      json: %{
        "d" => %{
          "heartbeat_interval" => 10_000
        }
      }
    }

    DiscordBot.Gateway.Broker.publish(broker, code, message)
    assert Heartbeat.target?(heartbeat) == self()
    assert Heartbeat.interval?(heartbeat) == 10_000
  end
end
