defmodule DiscordBot.Voice.Acceptor do
  @moduledoc """
  Launches a voice connection.
  """

  use GenServer, restart: :transient
  require Logger

  alias DiscordBot.Broker
  alias DiscordBot.Broker.Event
  alias DiscordBot.Voice.Launcher

  @default_timeout_milliseconds 10_000

  def start_link(opts) do
    broker = Keyword.get(opts, :broker, Elixir.Broker)
    timeout = Keyword.get(opts, :timeout, @default_timeout_milliseconds)

    state = %{
      broker: broker,
      timeout: timeout,
      timer: nil,
      voice_state_update: nil,
      voice_server_update: nil
    }

    GenServer.start_link(__MODULE__, state, opts)
  end

  ## Handlers

  def init(state) do
    Broker.subscribe(state[:broker], :voice_state_update)
    Broker.subscribe(state[:broker], :voice_server_update)
    timer = Process.send_after(self(), :timeout, state[:timeout])
    {:ok, %{state | timer: timer}}
  end

  def handle_info(%Event{topic: :voice_state_update, message: message}, state) do
    complete_event(%{state | voice_state_update: message})
  end

  def handle_info(%Event{topic: :voice_server_update, message: message}, state) do
    complete_event(%{state | voice_server_update: message})
  end

  def handle_info(:timeout, state) do
    Logger.error("Did not receive the expected response to a voice state update request.")
    {:stop, :normal, state}
  end

  defp complete_event(%{voice_state_update: nil} = state), do: {:noreply, state}
  defp complete_event(%{voice_server_update: nil} = state), do: {:noreply, state}

  defp complete_event(state) do
    Logger.info("Preparing new voice connection.")
    Launcher.establish(state[:voice_state_update], state[:voice_server_update])
    {:stop, :normal, state}
  end
end
