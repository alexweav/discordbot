defmodule DiscordBot.Broker.Supervisor do
  @moduledoc false

  use Supervisor

  def start_link([logged_topics: topics] = opts) when is_list(topics) do
    Supervisor.start_link(__MODULE__, topics, opts)
  end

  def start_link(opts) do
    Supervisor.start_link(__MODULE__, [], opts)
  end

  def init(topics) do
    children = [
      {DiscordBot.Broker, [name: Broker]},
      {DiscordBot.Broker.EventLogger, [name: EventLogger, broker: Broker, topics: topics]}
    ]

    Supervisor.init(children, strategy: :rest_for_one)
  end
end
