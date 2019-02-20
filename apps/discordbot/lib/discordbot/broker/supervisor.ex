defmodule DiscordBot.Broker.Supervisor do
  @moduledoc false

  use Supervisor

  def start_link(opts) do
    topics = Keyword.get(opts, :logged_topics, [])
    Supervisor.start_link(__MODULE__, topics, opts)
  end

  def init(topics) do
    children = [
      {DiscordBot.Broker, [name: Broker]},
      {DiscordBot.Broker.EventLogger, [name: EventLogger, broker: Broker, topics: topics]}
    ]

    Supervisor.init(children, strategy: :rest_for_one)
  end
end
