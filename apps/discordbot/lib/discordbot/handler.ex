defmodule DiscordBot.Handler do
  @moduledoc """
  A handler is a process which is used to perform actions
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
  Starts a Handler process linked to the current process.
  """
  @spec start_link(atom, any, list) :: GenServer.on_start()
  def start_link(module, init_arg, options \\ []) when is_atom(module) and is_list(options) do
    GenServer.start_link(module, init_arg, options)
  end

  @doc """
  Starts a Handler process without links (outside of a supervision tree).
  """
  @spec start(atom, any, list) :: GenServer.on_start()
  def start(module, init_arg, options \\ []) when is_atom(module) and is_list(options) do
    GenServer.start(module, init_arg, options)
  end
end
