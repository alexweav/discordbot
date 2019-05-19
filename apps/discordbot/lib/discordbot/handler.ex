defmodule DiscordBot.Handler do
  @moduledoc """
  A handler is a set of processes which is used to perform actions
  based on events occurring in the bot.
  """

  alias DiscordBot.Broker.Event

  defmodule State do
    @moduledoc """
    The internal state of a generic event handler.
    """
    @enforce_keys [:worker_supervisor]

    defstruct [
      :client_state,
      :worker_supervisor
    ]

    @typedoc """
    The consumer's application-specific state.
    """
    @type client_state :: any

    @typedoc """
    The pid of the supervisor for this handler's
    worker processes.
    """
    @type worker_supervisor :: pid

    @type t :: %__MODULE__{
            client_state: client_state,
            worker_supervisor: worker_supervisor
          }
  end

  defmacro __using__(_opts) do
    quote([]) do
      @behaviour DiscordBot.Handler

      use GenServer

      alias DiscordBot.Broker
      alias DiscordBot.Broker.Event

      @doc false
      def init({event_types, broker, init_arg}) do
        for type <- event_types, do: Broker.subscribe(broker, type)
        {:ok, pid} = Task.Supervisor.start_link(strategy: :one_for_one)

        case handler_init(init_arg) do
          {:stop, reason} ->
            {:stop, reason}

          {:ok, client_state} ->
            {:ok,
             %State{
               client_state: client_state,
               worker_supervisor: pid
             }}
        end
      end

      @doc false
      def handle_info(%Event{} = event, %State{client_state: state, worker_supervisor: supervisor}) do
        Task.Supervisor.start_child(supervisor, fn -> handle_event(event, state) end)
        {:noreply, %State{client_state: state, worker_supervisor: supervisor}}
      end
    end
  end

  @doc """
  Invoked when the handler is started, in the main process.
  """
  @callback handler_init(any) ::
              {:ok, new_state}
              | {:stop, reason :: any}
            when new_state: term

  @doc """
  Invoked to handle generic events.
  """
  @callback handle_event(event :: Event.t(), state :: term) :: any

  @doc """
  Starts a Handler process linked to the current process.
  """
  @spec start_link(atom, atom | list(atom), any, list) :: GenServer.on_start()
  def start_link(module, event_types, init_arg, options \\ [])

  def start_link(module, event_type, init_arg, options)
      when is_atom(module) and is_list(options) and is_atom(event_type) do
    start_link(module, [event_type], init_arg, options)
  end

  def start_link(module, event_types, init_arg, options)
      when is_atom(module) and is_list(options) and is_list(event_types) do
    broker = Keyword.get(options, :broker, Broker)
    GenServer.start_link(module, {event_types, broker, init_arg}, options)
  end

  @doc """
  Starts a Handler process without links (outside of a supervision tree).
  """
  @spec start(atom, atom | list(atom), any, list) :: GenServer.on_start()
  def start(module, event_types, init_arg, options \\ [])

  def start(module, event_type, init_arg, options)
      when is_atom(module) and is_list(options) and is_atom(event_type) do
    start_link(module, [event_type], init_arg, options)
  end

  def start(module, event_types, init_arg, options)
      when is_atom(module) and is_list(options) and is_list(event_types) do
    broker = Keyword.get(options, :broker, Broker)
    GenServer.start(module, {event_types, broker, init_arg}, options)
  end
end
