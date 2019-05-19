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
end
