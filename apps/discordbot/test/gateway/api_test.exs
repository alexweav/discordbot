defmodule DiscordBot.Gateway.ApiTest do
  use ExUnit.Case, async: true

  alias DiscordBot.Broker
  alias DiscordBot.Gateway.Api

  setup context do
    {:ok, {url, ref, core}} = DiscordBot.Fake.DiscordServer.start()

    on_exit(fn ->
      DiscordBot.Fake.DiscordServer.shutdown(ref)
    end)

    broker = start_supervised!({Broker, []}, id: Module.concat(context.test, :broker))

    gateway =
      start_supervised!(
        {DiscordBot.Gateway,
         url: url,
         shard_count: 1,
         broker_supervisor_name: Module.concat(context.test, :broker_supervisor)},
        id: Module.concat(context.test, :gateway)
      )

    %{url: url, ref: ref, core: core, broker: broker, gateway: gateway, test: context.test}
  end

  describe "update_status/2" do
    test "sends update event", %{core: core, gateway: gateway} do
      assert Api.update_status(gateway, :online) == :ok
      Process.sleep(100)
      json = DiscordBot.Fake.DiscordCore.latest_frame?(core)
      payload = DiscordBot.Model.Payload.from_json(json)
      assert payload.opcode == :status_update
      assert payload.data.status == :online
    end

    test "validates input", %{gateway: gateway} do
      assert Api.update_status(gateway, nil) == :error
      assert Api.update_status(gateway, :invalid) == :error
    end
  end

  describe "update_status/4" do
    test "sends update event", %{core: core, gateway: gateway} do
      assert Api.update_status(gateway, :online, :streaming, "CS:GO") == :ok
      Process.sleep(100)
      json = DiscordBot.Fake.DiscordCore.latest_frame?(core)
      payload = DiscordBot.Model.Payload.from_json(json)
      assert payload.opcode == :status_update
      assert payload.data.status == :online
      assert payload.data.game == %{"name" => "CS:GO", "type" => 1}
    end

    test "validates input", %{gateway: gateway} do
      assert Api.update_status(gateway, nil, :streaming, "CS:GO") == :error
      assert Api.update_status(gateway, :invalid, :streaming, "CS:GO") == :error
      assert Api.update_status(gateway, :online, nil, "CS:GO") == :error
      assert Api.update_status(gateway, :online, :invalid, "CS:GO") == :error
    end
  end
end
