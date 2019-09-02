defmodule Services.MentionTest do
  use ExUnit.Case, async: true
  doctest Services.Mention

  alias DiscordBot.Broker
  alias DiscordBot.Model.Message
  alias DiscordBot.Model.User
  alias DiscordBot.Self
  alias Services.Mention

  setup_all do
    broker = start_supervised!({Broker, []})
    start_supervised!({Self, broker: broker, name: DiscordBot.Self})
    :ok
  end

  setup context do
    broker = start_supervised!({Broker, []}, id: Module.concat(context.test, :broker))

    mention =
      start_supervised!({Services.Mention, [broker: broker]},
        id: Module.concat(context.test, :mention)
      )

    %{broker: broker, mention: mention}
  end

  test "responds if mention matches self" do
    user = %User{
      id: "test"
    }

    Self.set_user(user)

    assert Mention.handle_message("<@test>", %Message{mentions: [user]}, :ok) ==
             {:reply, {:text, "can you dont"}}
  end

  test "no response if mentions someone else" do
    user = %User{
      id: "test"
    }

    actual = %User{
      id: "not-test"
    }

    Self.set_user(user)

    assert Mention.handle_message("<@not-test>", %Message{mentions: [actual]}, :ok) ==
             {:noreply}
  end

  test "no response if no mentions" do
    user = %User{
      id: "test"
    }

    Self.set_user(user)

    assert Mention.handle_message("asdf", %Message{mentions: []}, :ok) ==
             {:noreply}
  end
end
