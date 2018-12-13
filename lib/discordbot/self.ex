defmodule DiscordBot.Self do
  @moduledoc """
  Represents the bot user itself
  """

  use GenServer

  alias DiscordBot.Gateway.Broker.Event

  defmodule State do
    defstruct [
      :status,
      :broker,
      :user
    ]

    @type status :: atom
    @type broker :: pid
    @type user :: DiscordBot.Model.User.t()
    @type t :: %__MODULE__{
            status: status,
            broker: broker,
            user: user
          }
  end

  @doc """
  Launches the self GenServer
  """
  def start_link(opts) do
    broker =
      case Keyword.fetch(opts, :broker) do
        {:ok, pid} -> pid
        :error -> Broker
      end

    state = %State{
      status: :uninitialized,
      broker: broker,
      user: nil
    }

    GenServer.start_link(__MODULE__, state, opts)
  end

  @doc """
  Update's the bot's status to `status`.
  Possible options are:
  - `:online`,
  - `:dnd`
  - TODO
  """
  @spec update_status(atom) :: :ok
  def update_status(status) do
    GenServer.cast(Self, {:update_status, status})
  end

  @doc """
  Updates the bot's status to `status`, also setting the
  activity type `type` and activity name `name`.
  """
  @spec update_status(atom, atom, String.t()) :: :ok
  def update_status(status, type, name) do
    GenServer.cast(Self, {:update_status, status, type, name})
  end

  @doc """
  Returns the initialization status of the bot. Possible values are:
  - `:uninitialized` - the bot is not yet connected
  - `:initialized` - the bot is connected and ready for commands
  """
  @spec status?() :: atom
  def status? do
    GenServer.call(Self, :status)
  end

  @doc """
  Returns the `DiscordBot.Model.User` struct describing the bot user
  """
  @spec user?() :: DiscordBot.Model.User.t()
  def user? do
    GenServer.call(Self, :user)
  end

  ## Handlers

  def init(state) do
    DiscordBot.Gateway.Broker.subscribe(state.broker, :ready)
    {:ok, state}
  end

  def handle_call(:status, _from, state) do
    {:reply, state.status, state}
  end

  def handle_call(:user, _from, state) do
    {:reply, state.user, state}
  end

  def handle_cast({:update_status, status}, state) do
    DiscordBot.Gateway.Connection.update_status(Connection, status)
    {:noreply, state}
  end

  def handle_cast({:update_status, status, type, name}, state) do
    DiscordBot.Gateway.Connection.update_status(Connection, status, type, name)
    {:noreply, state}
  end

  def handle_info(%Event{topic: :ready, message: %{connection: _pid, json: message}}, state) do
    {:noreply, %{state | user: message.user, status: :initialized}}
  end
end
