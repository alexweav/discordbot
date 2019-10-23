defmodule DiscordBot.Voice.Supervisor do
  @moduledoc false

  use Supervisor

  def start_link(opts) do
    Supervisor.start_link(__MODULE__, :ok, opts)
  end

  def init(_) do
    children = [
      {DynamicSupervisor,
       name: DiscordBot.Voice.AcceptorSupervisor, strategy: :one_for_one, restart: :transient},
      {DynamicSupervisor,
       name: DiscordBot.Voice.ControlSupervisor, strategy: :one_for_one, restart: :transient}
    ]

    Supervisor.init(children, strategy: :one_for_all)
  end
end
