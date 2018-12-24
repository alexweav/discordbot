defmodule DiscordBot.Self do
  @moduledoc """
  Represents the bot user itself
  """

  use GenServer

  alias DiscordBot.Broker.Event

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
  - `:online` - online
  - `:dnd` - do not disturb
  - `:idle` - AFK
  - `:invisible` - invisible, shown as offline
  - `:offline` - offline
  """
  @spec update_status(atom) :: :ok
  def update_status(status) do
    GenServer.cast(Self, {:update_status, status})
  end

  @doc """
  Updates the bot's status to `status`, also setting the
  activity type `type` and activity name `name`.
  See `DiscordBot.Self.update_status/1` for the eligible `status` values.
  Possible type values are:
  - `:playing` - Shown as "Playing `name`"
  - `:streaming` - Shown as "Streaming `name`"
  - `:listening` - Shown as "Listening to `name`"
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

  @doc """
  Returns the username of the bot user, or `nil` if the bot is not yet connected
  """
  @spec username?() :: String.t() | nil
  def username? do
    GenServer.call(Self, :username)
  end

  @doc """
  Returns the four-digit discriminator of the bot user as a string, or `nil` if the bot is not yet connected
  """
  @spec discriminator?() :: String.t() | nil
  def discriminator? do
    GenServer.call(Self, :discriminator)
  end

  @doc """
  Returns the unique user ID of the bot account, or `nil` if the bot is not yet connected
  """
  @spec id?() :: String.t() | nil
  def id? do
    GenServer.call(Self, :id)
  end

  ## Handlers

  def init(state) do
    DiscordBot.Broker.subscribe(state.broker, :ready)
    {:ok, state}
  end

  def handle_call(:status, _from, state) do
    {:reply, state.status, state}
  end

  def handle_call(:user, _from, state) do
    {:reply, state.user, state}
  end

  def handle_call(:username, _from, state) do
    {:reply, state.user.username, state}
  end

  def handle_call(:discriminator, _from, state) do
    {:reply, state.user.discriminator, state}
  end

  def handle_call(:id, _from, state) do
    {:reply, state.user.id, state}
  end

  def handle_cast({:update_status, status}, state) do
    DiscordBot.Gateway.Connection.update_status(Connection, status)
    {:noreply, state}
  end

  def handle_cast({:update_status, status, type, name}, state) do
    DiscordBot.Gateway.Connection.update_status(Connection, status, type, name)
    {:noreply, state}
  end

  def handle_info(%Event{topic: :ready, message: message}, state) do
    {:noreply, %{state | user: message.user, status: :initialized}}
  end
end
