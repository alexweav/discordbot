defmodule DiscordBot.Self do
  @moduledoc """
  Represents the bot user itself
  """

  use GenServer

  alias DiscordBot.Broker.Event
  alias DiscordBot.Model.User

  defmodule State do
    @moduledoc false

    defstruct [
      :status,
      :broker,
      :user
    ]

    @type status :: atom
    @type broker :: pid
    @type user :: User.t()
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
  Returns the initialization status of the bot. Possible values are:
  - `:uninitialized` - the bot is not yet connected
  - `:initialized` - the bot is connected and ready for commands
  """
  @spec status?() :: atom
  def status? do
    GenServer.call(DiscordBot.Self, :status)
  end

  @doc """
  Returns the `DiscordBot.Model.User` struct describing the bot user
  """
  @spec user?() :: User.t()
  def user? do
    GenServer.call(DiscordBot.Self, :user)
  end

  @doc """
  Returns the username of the bot user, or `nil` if the bot is not yet connected
  """
  @spec username?() :: String.t() | nil
  def username? do
    GenServer.call(DiscordBot.Self, :username)
  end

  @doc """
  Returns the four-digit discriminator of the bot user as a string, or `nil` if the bot is not yet connected
  """
  @spec discriminator?() :: String.t() | nil
  def discriminator? do
    GenServer.call(DiscordBot.Self, :discriminator)
  end

  @doc """
  Returns the unique user ID of the bot account, or `nil` if the bot is not yet connected
  """
  @spec id?() :: String.t() | nil
  def id? do
    GenServer.call(DiscordBot.Self, :id)
  end

  @doc false
  @spec set_user(User.t()) :: :ok
  def set_user(user) do
    # Only to be used for testing.
    GenServer.call(DiscordBot.Self, {:set_user, user})
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

  def handle_call({:set_user, user}, _from, state) when user != nil do
    {:reply, :ok, %{state | user: user}}
  end

  def handle_info(%Event{topic: :ready, message: message}, state) do
    {:noreply, %{state | user: message.user, status: :initialized}}
  end
end
