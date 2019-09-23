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
      alias DiscordBot.Entity.Messages
      alias DiscordBot.Model.Message

      @doc false
      @dialyzer {:no_match, init: 1}
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
      @dialyzer {:no_match, handle_info: 2}
      def handle_info(
            %Event{
              topic: :message_create,
              message: %Message{content: content} = message
            } = event,
            state
          ) do
        Task.Supervisor.start_child(state.worker_supervisor, fn ->
          case handle_message(content, message, state.client_state) do
            {:noreply} ->
              nil

            {:reply, {:text, response}} ->
              Messages.reply(message, response)
          end

          handle_event(event, state.client_state)
        end)

        {:noreply, state}
      end

      def handle_info(%Event{} = event, state) do
        Task.Supervisor.start_child(state.worker_supervisor, fn ->
          handle_event(event, state.client_state)
        end)

        {:noreply, state}
      end

      @doc false
      def handle_message(_, _, _), do: {:noreply}

      @doc false
      def handle_event(_, _), do: nil

      defoverridable handle_message: 3, handle_event: 2
    end
  end

  @doc """
  Invoked when the handler is started, in the main process.
  """
  @callback handler_init(any) ::
              {:ok, new_state :: term}
              | {:stop, reason :: any}

  @doc """
  Invoked to handle any subscribed event.
  """
  @callback handle_event(event :: Event.t(), state :: term) :: any

  @doc """
  Invoked to handle message_create events.
  """
  @callback handle_message(contents :: String.t(), message :: Message.t(), state :: term) ::
              {:reply, {:text, response :: String.t()}}
              | {:noreply}

  @optional_callbacks handle_message: 3

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
