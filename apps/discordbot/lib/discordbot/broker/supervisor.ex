defmodule DiscordBot.Broker.Supervisor do
  @moduledoc false

  use Supervisor

  def start_link(opts) do
    topics = Keyword.get(opts, :logged_topics, [])
    broker_name = Keyword.get(opts, :broker_name, nil)
    Supervisor.start_link(__MODULE__, {topics, broker_name}, opts)
  end

  def init({topics, broker_name}) do
    broker_opts =
      case broker_name do
        nil -> []
        name -> [name: name]
      end

    children = [
      {DiscordBot.Broker, broker_opts},
      {DiscordBot.Broker.EventLogger, [name: EventLogger, broker: broker_name, topics: topics]}
    ]

    Supervisor.init(children, strategy: :rest_for_one)
  end
end
