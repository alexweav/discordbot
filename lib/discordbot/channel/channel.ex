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

  @doc """
  Returns the ID of the channel `channel`
  """
  @spec id?(pid) :: String.t()
  def id?(channel) do
    GenServer.call(channel, :id)
  end

  @doc """
  Return the name of the channel `channel`
  """
  @spec name?(pid) :: String.t()
  def name?(channel) do
    GenServer.call(channel, :name)
  end

  @doc """
  Updates the channel `channel` with a new data `model`
  """
  @spec update(pid, DiscordBot.Model.Channel.t()) :: :ok
  def update(channel, model) do
    GenServer.call(channel, {:update, model})
  end

  ## Handlers

  def init(state) do
    {:ok, state}
  end

  def handle_call(:model, _from, {model} = state) do
    {:reply, model, state}
  end

  def handle_call(:id, _from, {model} = state) do
    {:reply, model.id, state}
  end

  def handle_call(:name, _from, {model} = state) do
    {:reply, model.name, state}
  end

  def handle_call({:update, model}, _from, {state}) do
    if model.id == state.id do
      {:reply, :ok, {model}}
    else
      {:reply, {:error, :incorrect_id}, {model}}
    end
  end
end
