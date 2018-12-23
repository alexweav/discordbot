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

  @doc """
  Creates a new channel for model `model`
  """
  @spec create(pid, DiscordBot.Model.Channel.t()) :: {:ok, pid} | :error
  def create(registry, model) do
    GenServer.call(registry, {:create, model})
  end

  @doc """
  Gets a channel by its ID
  """
  @spec lookup_by_id(pid, String.t()) :: {:ok, pid} | :error
  def lookup_by_id(registry, id) do
    GenServer.call(registry, {:lookup_by_id, id})
  end

  ## Handlers

  def init(state) do
    {:ok, state}
  end

  def handle_call({:create, model}, _from, state) do
    case Map.fetch(state, model.id) do
      {:ok, pid} ->
        DiscordBot.Channel.Channel.update(pid, model)
        {:reply, {:ok, pid}, state}

      :error ->
        {:ok, pid} =
          DynamicSupervisor.start_child(
            DiscordBot.ChannelSupervisor,
            {DiscordBot.Channel.Channel, [channel: model, name: via_tuple(model)]}
          )

        {:reply, {:ok, pid}, Map.put(state, model.id, pid)}
    end
  end

  def handle_call({:lookup_by_id, id}, _from, state) do
    pids = IO.inspect(Registry.lookup(DiscordBot.ChannelRegistry, id))
    {:reply, parse_lookup(pids), state}
  end

  defp parse_lookup([]) do
    :error
  end

  defp parse_lookup([{pid, _}]) when is_pid(pid) do
    {:ok, pid}
  end

  defp via_tuple(%DiscordBot.Model.Channel{} = model) do
    {:via, Registry, {DiscordBot.ChannelRegistry, model.id}}
  end

  defp via_tuple(id) when is_binary(id) do
    {:via, Registry, {DiscordBot.ChannelRegistry, id}}
  end
end
