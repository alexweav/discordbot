defmodule DiscordBot.Gateway.ApiTest do
  use ExUnit.Case, async: true

  use DiscordBot.Fake.Discord

  alias DiscordBot.Broker
  alias DiscordBot.Entity.Guilds
  alias DiscordBot.Fake.Discord
  alias DiscordBot.Gateway
  alias DiscordBot.Gateway.Api
  alias DiscordBot.Model.Payload

  setup context do
    {url, discord} = setup_discord()
    broker = start_supervised!({Broker, []}, id: Module.concat(context.test, :broker))
    start_supervised!({Guilds, [broker: broker, api: DiscordBot.ApiMock]})

    gateway =
      start_supervised!(
        {Gateway,
         url: url,
         shard_count: 1,
         broker: broker,
         broker_supervisor_name: Module.concat(context.test, :broker_supervisor)},
        id: Module.concat(context.test, :gateway)
      )

    %{
      url: url,
      discord: discord,
      broker: broker,
      gateway: gateway,
      test: context.test
    }
  end

  describe "update_status/2" do
    test "sends update event", %{discord: discord, gateway: gateway} do
      assert Api.update_status(gateway, :online) == :ok
      Process.sleep(100)
      json = Discord.latest_frame?(discord)
      payload = Payload.from_json(json)
      assert payload.opcode == :status_update
      assert payload.data.status == :online
    end

    test "validates input", %{gateway: gateway} do
      assert Api.update_status(gateway, nil) == :error
      assert Api.update_status(gateway, :invalid) == :error
    end
  end

  describe "update_status/4" do
    test "sends update event", %{discord: discord, gateway: gateway} do
      assert Api.update_status(gateway, :online, :streaming, "CS:GO") == :ok
      Process.sleep(100)
      json = Discord.latest_frame?(discord)
      payload = Payload.from_json(json)
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

  describe "update_voice_state/4" do
    test "errors if guild does not exist" do
      assert Api.update_voice_state("not-real", "not-a-channel") == :error
    end

    test "sends if guild exists", %{discord: discord} do
      model = %DiscordBot.Model.Guild{
        id: "update-voice-test-id"
      }

      Discord.guild_create(discord, model)
      Process.sleep(100)
      assert Api.update_voice_state("update-voice-test-id", "test-channel") == :ok
      Process.sleep(100)
      json = Discord.latest_frame?(discord)
      map = Poison.decode!(json)
      # Discord overloads this opcode depending on if it is sent from client or server.
      # The existing deserializer for this opcode expects the message from the server,
      # so we must manually check the JSON's validity instead.
      assert map["op"] == 4
      assert map["d"]["guild_id"] == "update-voice-test-id"
      assert map["d"]["channel_id"] == "test-channel"
      assert map["d"]["self_mute"] == false
      assert map["d"]["self_deaf"] == false
    end
  end
end
