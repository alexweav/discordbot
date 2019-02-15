defmodule DiscordBot.Entity.Channel do
  @moduledoc """
  Represents a communication channel in Discord
  """

  use GenServer

  alias DiscordBot.Model.Channel, as: ChannelModel

  @doc """
  Starts the channel
  """
  def start_link(opts) do
    model = Keyword.fetch!(opts, :channel)

    api =
      case Keyword.fetch(opts, :api) do
        {:ok, name} -> name
        :error -> DiscordBot.Api
      end

    if model.id == nil do
      raise ArgumentError, "ID cannot be nil"
    end

    GenServer.start_link(__MODULE__, %{model: model, api: api}, opts)
  end

  @doc """
  Returns a channel info struct associated with
  the channel `channel`
  """
  @spec model?(pid) :: ChannelModel.t()
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
  Returns the name of the channel `channel`
  """
  @spec name?(pid) :: String.t()
  def name?(channel) do
    GenServer.call(channel, :name)
  end

  @doc """
  Returns the guild ID of the channel `channel`.
  """
  @spec name?(pid) :: String.t()
  def guild_id?(channel) do
    GenServer.call(channel, :guild_id)
  end

  @doc """
  Updates the channel `channel` with a new data model `model`
  """
  @spec update(pid, ChannelModel.t()) :: :ok
  def update(channel, model) do
    GenServer.call(channel, {:update, model})
  end

  @doc """
  Creates a message with content `content` on channel `channel`
  """
  @spec create_message(pid, String.t(), tts: boolean) :: any
  def create_message(channel, content, opts \\ []) do
    GenServer.call(channel, {:create_message, content, opts})
  end

  ## Handlers

  def init(state) do
    {:ok, state}
  end

  def handle_call(:model, _from, %{model: model} = state) do
    {:reply, model, state}
  end

  def handle_call(:id, _from, %{model: model} = state) do
    {:reply, model.id, state}
  end

  def handle_call(:name, _from, %{model: model} = state) do
    {:reply, model.name, state}
  end

  def handle_call(:guild_id, _from, %{model: model} = state) do
    {:reply, model.guild_id, state}
  end

  def handle_call({:update, update}, _from, %{model: old_model} = state) do
    if is_nil(update.id) or update.id == old_model.id do
      merged =
        Map.merge(
          Map.from_struct(old_model),
          update
          |> Map.from_struct()
          |> drop_nils()
        )

      new_model = struct(ChannelModel, merged)

      {:reply, :ok, %{state | model: new_model}}
    else
      {:reply, {:error, :incorrect_id}, state}
    end
  end

  def handle_call(
        {:create_message, content, [tts: true]},
        _from,
        %{model: model, api: api} = state
      ) do
    response = api.create_tts_message(model.id, content)
    {:reply, response, state}
  end

  def handle_call({:create_message, content, _opts}, _from, %{model: model, api: api} = state) do
    response = api.create_message(model.id, content)
    {:reply, response, state}
  end

  defp drop_nils(map) do
    map
    |> Enum.reject(fn {_, value} -> is_nil(value) end)
    |> Enum.into(%{})
  end
end
