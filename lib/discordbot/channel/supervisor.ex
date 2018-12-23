defmodule DiscordBot.Channel.Supervisor do
  @moduledoc """
  Supervisor for the Channel-related processes
  """

  use Supervisor

  def start_link(opts) do
    Supervisor.start_link(__MODULE__, :ok, opts)
  end

  def init(:ok) do
    children = [
      {DynamicSupervisor, name: DiscordBot.ChannelSupervisor, strategy: :one_for_one},
      {Registry, keys: :unique, name: DiscordBot.ChannelRegistry},
      {DiscordBot.Channel.Registry, name: DiscordBot.ChannelController}
    ]

    Supervisor.init(children, strategy: :one_for_all)
  end
end
