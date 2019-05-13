defmodule DiscordBot.UtilTest do
  use ExUnit.Case, async: true
  doctest DiscordBot.Util

  alias DiscordBot.Util

  setup context do
    %{test: context.test}
  end

  test ":error if supervisor has no children", %{test: test} do
    supervisor = start_supervised!({DynamicSupervisor, strategy: :one_for_one, id: test})
    assert Util.child_by_id(supervisor, :test) == :error
  end

  test "gets supervisor child by ID" do
    children = [
      Supervisor.child_spec({Agent, fn -> [] end}, id: :testid)
    ]

    {:ok, supervisor} = Supervisor.start_link(children, strategy: :one_for_one)

    assert {:ok, pid} = Util.child_by_id(supervisor, :testid)
    assert is_pid(pid)
  end

  test "gets option if present" do
    opts = [key: %{}]
    assert Util.require_opt!(opts, :key, "asdf") == %{}
  end

  test "throws if option not present" do
    opts = [key: %{}]

    assert_raise ArgumentError, fn ->
      Util.require_opt!(opts, :not_present, "asdf")
    end
  end
end
