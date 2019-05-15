defmodule DiscordBot.Fake.VoiceCore do
  @moduledoc false

  use GenServer

  def start_link(opts) do
    state = %{
      handler: nil
    }

    GenServer.start_link(__MODULE__, state, opts)
  end

  ## Handler API

  def register(core) do
    GenServer.call(core, :register)
  end

  ## Handlers

  def init(state) do
    {:ok, state}
  end

  def handle_call(:register, {caller, _tag}, state) do
    {:reply, :ok, %{state | handler: caller}}
  end
end
