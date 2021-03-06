defmodule DiscordBot.Gateway.ConnectionTest do
  use ExUnit.Case, async: true

  use DiscordBot.Fake.Discord

  alias DiscordBot.Broker
  alias DiscordBot.Fake.Discord
  alias DiscordBot.Gateway.Connection
  alias DiscordBot.Model.Payload

  setup context do
    {url, discord} = setup_discord()
    broker = start_supervised!({Broker, []}, id: Module.concat(context.test, :broker))
    %{url: url, discord: discord, broker: broker, test: context.test}
  end

  test "establishes websocket connection using URL", %{url: url, broker: broker, test: test} do
    pid = start_supervised!({Connection, token: "asdf", url: url, broker: broker}, id: test)
    assert Connection.disconnect(pid, 4001) == :ok
  end

  test "uses correct API version", %{url: url, test: test, discord: discord} do
    start_supervised!({Connection, token: "asdf", url: url}, id: test)
    assert Discord.api_version?(discord) == "6"
  end

  test "uses plain JSON encoding", %{url: url, test: test, discord: discord} do
    start_supervised!({Connection, token: "asdf", url: url}, id: test)
    assert Discord.encoding?(discord) == "json"
  end

  test "validates input" do
    assert_raise KeyError, fn ->
      Connection.start_link([])
    end

    assert_raise KeyError, fn ->
      Connection.start_link(token: "asdf")
    end

    assert_raise KeyError, fn ->
      Connection.start_link(url: "asdf")
    end
  end

  test "can update status", %{url: url, test: test, discord: discord} do
    pid = start_supervised!({Connection, token: "asdf", url: url}, id: test)
    Connection.update_status(pid, :dnd)
    # increase this if this test fails intermittently.
    # perhaps there is a better of waiting to ensure the test server received the frame?
    Process.sleep(100)
    json = Discord.latest_frame?(discord)
    payload = Payload.from_json(json)
    assert payload.opcode == :status_update
    assert payload.data.afk == false
    assert payload.data.status == :dnd
  end

  test "can update status and activity", %{url: url, test: test, discord: discord} do
    pid = start_supervised!({Connection, token: "asdf", url: url}, id: test)
    Connection.update_status(pid, :online, :playing, "CS:GO")
    Process.sleep(100)
    json = Discord.latest_frame?(discord)
    payload = Payload.from_json(json)
    assert payload.opcode == :status_update
    assert payload.data.afk == false
    assert payload.data.status == :online
    # TODO: once activity struct is fully updated
    assert payload.data.game == %{"name" => "CS:GO", "type" => 0}
  end

  test "can update voice state", %{url: url, test: test, discord: discord} do
    pid = start_supervised!({Connection, token: "asdf", url: url}, id: test)
    Connection.update_voice_state(pid, "a-guild", "a-channel", true, false)
    Process.sleep(100)
    json = Discord.latest_frame?(discord)
    map = Poison.decode!(json)
    # Discord overloads this opcode depending on if it is sent from client or server.
    # The existing deserializer for this opcode expects the message from the server,
    # so we must manually check the JSON's validity instead.
    assert map["op"] == 4
    assert map["d"]["guild_id"] == "a-guild"
    assert map["d"]["channel_id"] == "a-channel"
    assert map["d"]["self_mute"] == true
    assert map["d"]["self_deaf"] == false
  end
end
