defmodule DiscordBot.Channel.Supervisor do
  @moduledoc """
  Supervisor for the Channel-related processes
  """

  use Supervisor

  def start_link(opts) do
    broker =
      case Keyword.fetch(opts, :broker) do
        {:ok, pid} -> pid
        :error -> Broker
      end

    Supervisor.start_link(__MODULE__, broker, opts)
  end

  def init(broker) do
    children = [
      {DynamicSupervisor, name: DiscordBot.ChannelSupervisor, strategy: :one_for_one},
      {Registry, keys: :unique, name: DiscordBot.ChannelRegistry},
      {DiscordBot.Channel.Controller, name: DiscordBot.ChannelController, broker: broker}
    ]

    Supervisor.init(children, strategy: :one_for_all)
  end
end
