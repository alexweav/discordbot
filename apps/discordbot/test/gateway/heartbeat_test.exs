defmodule DiscordBot.Gateway.HeartbeatTest do
  use ExUnit.Case, async: true

  alias DiscordBot.Gateway.Heartbeat
  alias DiscordBot.Broker

  setup do
    broker = start_supervised!({Broker, []})
    heartbeat = start_supervised!({Heartbeat, [broker: broker]})
    %{heartbeat: heartbeat, broker: broker}
  end

  test "waiting on launch", %{heartbeat: heartbeat} do
    assert Heartbeat.status?(heartbeat) == :waiting
    assert Heartbeat.interval?(heartbeat) == nil
  end

  test "untargeted on launch", %{heartbeat: heartbeat} do
    assert Heartbeat.target?(heartbeat) == nil
    assert Heartbeat.acknowledged?(heartbeat) == false
    assert Heartbeat.last_ack_time?(heartbeat) == nil
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

    message = %DiscordBot.Model.Hello{
      heartbeat_interval: 10_000
    }

    Broker.publish(broker, code, message)
    assert Heartbeat.target?(heartbeat) == self()
    assert Heartbeat.interval?(heartbeat) == 10_000
  end

  test "sends after interval on broker hello event", %{broker: broker} do
    message = %DiscordBot.Model.Hello{
      heartbeat_interval: 10
    }

    Broker.publish(broker, :hello, message)
    assert_receive({:"$websockex_cast", {:heartbeat}}, 1_000)
  end

  test "replies to out-of-band heartbeat requests", %{broker: broker} do
    message = %DiscordBot.Model.Hello{
      heartbeat_interval: 100_000
    }

    Broker.publish(broker, :hello, message)
    Broker.publish(broker, :heartbeat, {})
    assert_receive({:"$websockex_cast", {:heartbeat}}, 1_000)
  end

  test "waiting if OOB request is sent with no target", %{heartbeat: heartbeat, broker: broker} do
    Broker.publish(broker, :heartbeat, {})
    assert Heartbeat.target?(heartbeat) == nil
    assert Heartbeat.interval?(heartbeat) == nil
    assert Heartbeat.status?(heartbeat) == :waiting
  end

  test "acknowledged before first heartbeat sent", %{heartbeat: heartbeat} do
    Heartbeat.schedule(heartbeat, 10_000)
    assert Heartbeat.acknowledged?(heartbeat) == true
    assert Heartbeat.last_ack_time?(heartbeat) == nil
  end

  test "not acknowledged after heartbeat sent", %{heartbeat: heartbeat} do
    Heartbeat.schedule(heartbeat, 10)
    block_until_message(1_000)
    assert Heartbeat.acknowledged?(heartbeat) == false
  end

  test "acknowledged after acknowledgement event", %{heartbeat: heartbeat, broker: broker} do
    Heartbeat.schedule(heartbeat, 10)
    block_until_message(1_000)
    Broker.publish(broker, :heartbeat_ack, {})
    assert Heartbeat.acknowledged?(heartbeat) == true
  end

  test "disconnects after two beats without ack", %{heartbeat: heartbeat} do
    Heartbeat.schedule(heartbeat, 10)
    block_until_message(1_000)
    assert_receive({:"$websockex_cast", {:disconnect, 4_000}}, 1_000)
  end

  @spec block_until_message(integer) :: nil
  defp block_until_message(timeout) do
    receive do
      _ -> nil
    after
      timeout -> nil
    end
  end
end
