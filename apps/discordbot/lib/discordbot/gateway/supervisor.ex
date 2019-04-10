defmodule DiscordBot.Gateway.Supervisor do
  @moduledoc false
  @behaviour DiscordBot.Broker.Provider

  use Supervisor

  def start_link(opts) do
    token = Keyword.fetch!(opts, :token)
    url = Keyword.fetch!(opts, :url)
    Supervisor.start_link(__MODULE__, {token, url}, opts)
  end

  @impl true
  def init({token, url}) do
    children = [
      {DiscordBot.Broker, id: :broker},
      {DiscordBot.Gateway.Heartbeat, broker: Broker, id: :heartbeat},
      Supervisor.child_spec(
        {Task, fn -> DiscordBot.Gateway.Authenticator.authenticate(token, Broker) end},
        id: :authenticator,
        restart: :transient
      ),
      {DiscordBot.Gateway.Connection,
       url: url, token: token, broker: Broker, broker_provider: self()}
    ]

    Supervisor.init(children, strategy: :rest_for_one)
  end

  @impl DiscordBot.Broker.Provider
  @spec broker?(pid) :: pid | nil
  def broker?(supervisor) do
    child_pid?(supervisor, :broker)
  end

  @spec heartbeat?(pid) :: pid | nil
  def heartbeat?(supervisor) do
    child_pid?(supervisor, :heartbeat)
  end

  @spec authenticator?(pid) :: pid | nil
  def authenticator?(supervisor) do
    child_pid?(supervisor, :authenticator)
  end

  @spec child_pid?(pid, atom) :: pid | nil
  defp child_pid?(supervisor, id) do
    supervisor
    |> Supervisor.which_children()
    |> Enum.find_value(fn child ->
      case child do
        {^id, pid, _, _} -> pid
        _ -> nil
      end
    end)
  end
end
