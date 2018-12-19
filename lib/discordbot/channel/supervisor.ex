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
      {DiscordBot.Channel.Registry, name: DiscordBot.ChannelRegistry}
    ]

    Supervisor.init(children, strategy: :one_for_all)
  end
end
