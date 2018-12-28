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

    if model.id == nil do
      raise ArgumentError, "ID cannot be nil"
    end

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

  @doc """
  Creates a message with content `content` on channel `channel`
  """
  @spec create_message(pid, String.t()) :: any
  def create_message(channel, content) do
    GenServer.call(channel, {:create_message, content})
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

  def handle_call({:update, update}, _from, {state}) do
    if is_nil(update.id) or update.id == state.id do
      merged =
        Map.merge(
          Map.from_struct(state),
          update
          |> Map.from_struct()
          |> drop_nils()
        )

      new_model = struct(DiscordBot.Model.Channel, merged)

      {:reply, :ok, {new_model}}
    else
      {:reply, {:error, :incorrect_id}, {state}}
    end
  end

  def handle_call({:create_message, content}, _from, {state}) do
    response = DiscordBot.Api.create_message(state.id, content)
    {:reply, response, {state}}
  end

  defp drop_nils(map) do
    map
    |> Enum.reject(fn {_, value} -> is_nil(value) end)
    |> Enum.into(%{})
  end
end
