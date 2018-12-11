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

  ## Handlers

  def init(state) do
    DiscordBot.Gateway.Broker.subscribe(state.broker, :ready)
    {:ok, state}
  end

  def handle_info(%Event{topic: :ready, message: %{connection: _pid, json: message}}, state) do
    {:noreply, %{state | user: message.user, status: :initialized}}
  end
end
