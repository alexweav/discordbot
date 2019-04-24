defmodule DiscordBot.Gateway.SupervisorTest do
  use ExUnit.Case, async: true

  alias DiscordBot.Broker
  alias DiscordBot.Gateway

  setup context do
    {:ok, {url, ref, core}} = DiscordBot.Fake.DiscordServer.start()

    on_exit(fn ->
      DiscordBot.Fake.DiscordServer.shutdown(ref)
    end)

    broker = start_supervised!({Broker, []}, id: Module.concat(context.test, :broker))

    # TODO: possible race condition here?
    start_supervised!(
      {DynamicSupervisor, name: DiscordBot.Gateway.BrokerSupervisor, strategy: :one_for_one}
    )

    %{url: url, ref: ref, core: core, broker: broker, test: context.test}
  end

  test "establishes connection on launch", %{url: url, core: core, test: test} do
    start_supervised!(
      {Gateway.Supervisor, token: "asdf", url: url, shard_index: 0, shard_count: 1},
      id: test
    )

    assert DiscordBot.Fake.DiscordCore.api_version?(core) == "6"
  end

  test "authenticator running before ready event", %{url: url, test: test} do
    pid =
      start_supervised!(
        {Gateway.Supervisor, token: "asdf", url: url, shard_index: 0, shard_count: 1},
        id: test
      )

    assert DiscordBot.Gateway.Supervisor.authenticator?(pid) != nil
  end

  test "heartbeat untargeted before ready event", %{url: url, test: test} do
    pid =
      start_supervised!(
        {Gateway.Supervisor, token: "asdf", url: url, shard_index: 0, shard_count: 1},
        id: test
      )

    {:ok, heartbeat} = DiscordBot.Gateway.Supervisor.heartbeat?(pid)
    assert DiscordBot.Gateway.Heartbeat.target?(heartbeat) == nil
  end
end
