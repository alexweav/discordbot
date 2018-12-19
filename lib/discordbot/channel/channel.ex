defmodule DiscordBot.Channel.Channel do
  @moduledoc """
  Represents a text communication channel in Discord
  """

  use GenServer

  @doc """
  Starts the channel
  """
  def start_link(opts) do
    model = Keyword.fetch!(opts, :channel)
    GenServer.start_link(__MODULE__, {model}, opts)
  end

  @doc """
  Returns a `DiscordBot.Model.Channel.t()` struct associated with
  the channel `channel`
  """
  @spec model?(pid) :: DiscordBot.Model.Channel.t()
  def model?(channel) do
    GenServer.call(channel, :model)
  end

  ## Handlers

  def init(state) do
    {:ok, state}
  end

  def handle_call(:model, _from, {model} = state) do
    {:reply, model, state}
  end
end
