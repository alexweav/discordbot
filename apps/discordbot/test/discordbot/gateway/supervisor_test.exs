defmodule DiscordBot.Gateway.SupervisorTest do
  use ExUnit.Case, async: true

  use DiscordBot.Fake.Discord

  alias DiscordBot.Broker
  alias DiscordBot.Fake.Discord
  alias DiscordBot.Gateway
  alias DiscordBot.Gateway.Heartbeat
  alias DiscordBot.Model.Payload

  setup context do
    {url, discord} = setup_discord()
    broker = start_supervised!({Broker, []}, id: Module.concat(context.test, :broker))

    start_supervised!(
      {DynamicSupervisor, name: DiscordBot.Gateway.BrokerSupervisor, strategy: :one_for_one}
    )

    %{url: url, discord: discord, broker: broker, test: context.test}
  end

  test "establishes connection on launch", %{url: url, discord: discord, test: test} do
    start_supervised!(
      {Gateway.Supervisor, token: "asdf", url: url, shard_index: 0, shard_count: 1},
      id: test
    )

    assert Discord.api_version?(discord) == "6"
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

  test "authenticates after hello event", %{url: url, test: test, discord: discord} do
    start_supervised!(
      {Gateway.Supervisor, token: "asdf", url: url, shard_index: 0, shard_count: 1},
      id: test
    )

    Discord.hello(discord, 41_250, ["gateway-prd-main-bbqf"])
    Process.sleep(100)
    payload = Payload.from_json(Discord.latest_frame?(discord))

    assert payload.opcode == :identify
    assert payload.data.compress == false
    assert payload.data.large_threshold == 250
    assert payload.data.shard == [0, 1]
    assert payload.data.token == "asdf"
    assert payload.data.properties."$browser" == "DiscordBot"
    assert payload.data.properties."$device" == "DiscordBot"
    assert payload.data.properties."$os" == "linux"
  end

  test "heartbeat sets interval from hello event", %{url: url, test: test, discord: discord} do
    pid =
      start_supervised!(
        {Gateway.Supervisor, token: "asdf", url: url, shard_index: 0, shard_count: 1},
        id: test
      )

    Discord.hello(discord, 123, ["gateway-prd-main-bbqf"])
    Process.sleep(100)
    {:ok, heartbeat} = Gateway.Supervisor.heartbeat?(pid)
    assert Heartbeat.interval?(heartbeat) == 123
  end

  test "send heartbeat after hello with short interval", %{url: url, test: test, discord: discord} do
    start_supervised!(
      {Gateway.Supervisor, token: "asdf", url: url, shard_index: 0, shard_count: 1},
      id: test
    )

    Discord.hello(discord, 200, ["gateway-prd-main-bbqf"])
    Process.sleep(300)
    payload = Payload.from_json(Discord.latest_frame?(discord))
    assert payload.opcode == :heartbeat
  end
end
