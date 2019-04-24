defmodule DiscordBot.Gateway.ConnectionTest do
  use ExUnit.Case, async: true

  alias DiscordBot.Broker
  alias DiscordBot.Gateway.Connection

  setup context do
    {:ok, {url, ref, core}} = DiscordBot.Fake.DiscordServer.start()

    on_exit(fn ->
      DiscordBot.Fake.DiscordServer.shutdown(ref)
    end)

    broker = start_supervised!({Broker, []}, id: Module.concat(context.test, :broker))

    %{url: url, ref: ref, core: core, broker: broker, test: context.test}
  end

  test "establishes websocket connection using URL", %{url: url, broker: broker, test: test} do
    pid = start_supervised!({Connection, token: "asdf", url: url, broker: broker}, id: test)
    assert Connection.disconnect(pid, 4001) == :ok
  end

  test "uses correct API version", %{url: url, test: test, core: core} do
    start_supervised!({Connection, token: "asdf", url: url}, id: test)
    assert DiscordBot.Fake.DiscordCore.api_version?(core) == "6"
  end

  test "uses plain JSON encoding", %{url: url, test: test, core: core} do
    start_supervised!({Connection, token: "asdf", url: url}, id: test)
    assert DiscordBot.Fake.DiscordCore.encoding?(core) == "json"
  end

  test "validates input" do
    assert_raise ArgumentError, fn ->
      Connection.start_link([])
    end

    assert_raise ArgumentError, fn ->
      Connection.start_link(token: "asdf")
    end

    assert_raise ArgumentError, fn ->
      Connection.start_link(url: "asdf")
    end
  end

  test "can update status", %{url: url, test: test, core: core} do
    pid = start_supervised!({Connection, token: "asdf", url: url}, id: test)
    DiscordBot.Gateway.Connection.update_status(pid, :dnd)
    # increase this if this test fails intermittently.
    # perhaps there is a better of waiting to ensure the test server received the frame?
    Process.sleep(100)
    json = DiscordBot.Fake.DiscordCore.latest_frame?(core)
    payload = DiscordBot.Model.Payload.from_json(json)
    assert payload.opcode == :status_update
    assert payload.data.afk == false
    assert payload.data.status == :dnd
  end

  test "can update status and activity", %{url: url, test: test, core: core} do
    pid = start_supervised!({Connection, token: "asdf", url: url}, id: test)
    DiscordBot.Gateway.Connection.update_status(pid, :online, :playing, "CS:GO")
    Process.sleep(100)
    json = DiscordBot.Fake.DiscordCore.latest_frame?(core)
    payload = DiscordBot.Model.Payload.from_json(json)
    assert payload.opcode == :status_update
    assert payload.data.afk == false
    assert payload.data.status == :online
    # TODO: once activity struct is fully updated
    assert payload.data.game == %{"name" => "CS:GO", "type" => 0}
  end
end
