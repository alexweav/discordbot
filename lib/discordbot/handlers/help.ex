defmodule DiscordBot.Handlers.Help do
  @moduledoc """
  Provides help-text on demand in a discord chat channel.
  """

  use GenServer

  @doc """
  Starts the help handler

  Available options:
  - `:name`: Sets the name of this process
  - `:broker`: Specifies the broker to listen to for events.
    If unspecified, the default broker is used.
  """
  def start_link(opts) do
    broker =
      case Keyword.fetch(opts, :broker) do
        {:ok, pid} -> pid
        :error -> Broker
      end

    GenServer.start_link(__MODULE__, broker, opts)
  end

  ## Handlers

  def init(broker) do
    {:ok, broker}
  end
end
