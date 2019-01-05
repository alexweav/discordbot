defmodule DiscordBot.Handlers.TtsSplitter.Server do
  @moduledoc """
  GenServer for the TTS splitter command
  """

  use GenServer

  @doc """
  Starts the TTS-splitter handler
  """
  def start_link(opts) do
    GenServer.start_link(__MODULE__, :ok, opts)
  end

  ## Handlers

  def init(:ok) do
    {:ok, nil}
  end
end
