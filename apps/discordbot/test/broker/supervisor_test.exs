defmodule DiscordBot.Broker.SupervisorTests do
  use ExUnit.Case, async: true

  alias DiscordBot.Broker
  alias DiscordBot.Broker.EventLogger

  setup context do
    %{test: context.test}
  end

  test "passes topics to event logger", %{test: test} do
    sup =
      start_supervised!(
        {Broker.Supervisor,
         logged_topics: [:test, :topic], broker_name: Module.concat(Broker, test)},
        id: test
      )

    children =
      sup
      |> Supervisor.which_children()
      |> Enum.filter(fn {name, _, _, _} -> name == DiscordBot.Broker.EventLogger end)

    [{_, logger, _, _}] = children
    assert EventLogger.topics?(logger) == [:test, :topic]
  end
end
