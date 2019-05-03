defmodule DiscordBot.Gateway.SupervisorTest do
  use ExUnit.Case, async: true

  alias DiscordBot.Broker
  alias DiscordBot.Gateway
  alias DiscordBot.Gateway.Heartbeat
  alias DiscordBot.Fake.{DiscordCore, DiscordServer}
  alias DiscordBot.Model.Payload

  setup context do
    {:ok, {url, ref, core}} = DiscordServer.start()

    on_exit(fn ->
      DiscordServer.shutdown(ref)
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

    assert DiscordCore.api_version?(core) == "6"
  end

  test "authenticator running before hello event", %{url: url, test: test} do
    pid =
      start_supervised!(
        {Gateway.Supervisor, token: "asdf", url: url, shard_index: 0, shard_count: 1},
        id: test
      )

    assert Gateway.Supervisor.authenticator?(pid) != nil
  end

  test "heartbeat untargeted before hello event", %{url: url, test: test} do
    pid =
      start_supervised!(
        {Gateway.Supervisor, token: "asdf", url: url, shard_index: 0, shard_count: 1},
        id: test
      )

    {:ok, heartbeat} = Gateway.Supervisor.heartbeat?(pid)
    assert Heartbeat.target?(heartbeat) == nil
  end

  test "authenticates after hello event", %{url: url, test: test, core: core} do
    start_supervised!(
      {Gateway.Supervisor, token: "asdf", url: url, shard_index: 0, shard_count: 1},
      id: test
    )

    DiscordCore.hello(core, 41_250, ["gateway-prd-main-bbqf"])
    Process.sleep(100)
    payload = Payload.from_json(DiscordCore.latest_frame?(core))

    assert payload.opcode == :identify
    assert payload.data.compress == false
    assert payload.data.large_threshold == 250
    assert payload.data.shard == [0, 1]
    assert payload.data.token == "asdf"
    assert payload.data.properties."$browser" == "DiscordBot"
    assert payload.data.properties."$device" == "DiscordBot"
    assert payload.data.properties."$os" == "linux"
  end
end
