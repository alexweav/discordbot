defmodule DiscordBot.Gateway.Supervisor do
  @moduledoc false

  use Supervisor

  def start_link(opts) do
    Supervisor.start_link(__MODULE__, :ok, opts)
  end

  @spec init(:ok) :: {:ok, {%{intensity: any(), period: any(), strategy: any()}, [any()]}}
  def init(:ok) do
    children = []
    Supervisor.init(children, strategy: :rest_for_one)
  end
end
