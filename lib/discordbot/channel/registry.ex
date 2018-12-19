defmodule DiscordBot.Channel.Registry do
  @moduledoc """
  Manages creation, deletion, and lookup of Channels
  """

  use GenServer

  @doc """
  Starts the registry
  """
  def start_link(opts) do
    GenServer.start_link(__MODULE__, %{}, opts)
  end

  ## Handlers

  def init(state) do
    {:ok, state}
  end
end
