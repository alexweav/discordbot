defmodule DiscordBot.Handler do
  @moduledoc """
  A handler is a set of processes which is used to perform actions
  based on events occurring in the bot.
  """

  alias DiscordBot.Broker.Event

  defmacro __using__(_opts) do
    quote([]) do
      @behaviour DiscordBot.Handler

      use GenServer

      alias DiscordBot.Broker.Event
    end
  end

  @doc """
  Invoked to handle events.
  """
  @callback handle_event(event :: Event.t(), state :: term) ::
              {:ok, new_state}
            when new_state: term

  @doc """
  Invoked when the handler is started, in the main process.
  """
  @callback handler_init(any) ::
              {:ok, new_state}
              | {:stop, reason :: any}
            when new_state: term

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
    GenServer.start_link(module, {event_types, init_arg}, options)
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
    GenServer.start(module, {event_types, init_arg}, options)
  end
end
