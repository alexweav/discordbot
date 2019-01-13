defmodule DiscordBot.Handlers.Search.TokenManager do
  @moduledoc """
  Manages and refreshes access tokens which have a defined expiry period.
  """

  use GenServer

  def start_link(opts) do
    GenServer.start_link(__MODULE__, :ok, opts)
  end

  ## Handlers

  def init(:ok) do
    {:ok, nil}
  end
end
