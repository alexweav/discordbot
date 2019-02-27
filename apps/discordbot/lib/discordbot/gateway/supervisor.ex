defmodule DiscordBot.Gateway.Supevisor do
  @moduledoc false

  use Supervisor

  def start_link(opts) do
    Supervisor.start_link(__MODULE__, :ok, opts)
  end

  def init(:ok) do
    children = []
    Supervisor.init(children, strategy: :rest_for_one)
  end
end
