defmodule DiscordBot.Voice.Supervisor do
  @moduledoc false

  use Supervisor

  def start_link(opts) do
    Supervisor.start_link(__MODULE__, :ok, opts)
  end

  def init(_) do
    children = [
      {Registry, keys: :unique, name: DiscordBot.Voice.SessionRegistry},
      {DynamicSupervisor, name: DiscordBot.Voice.ControlSupervisor, strategy: :one_for_one},
      {Task.Supervisor, name: DiscordBot.Voice.PlayerSupervisor}
    ]

    Supervisor.init(children, strategy: :one_for_all)
  end
end
