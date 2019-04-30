defmodule Services.Help do
  @moduledoc """
  Provides help-text on demand in a discord chat channel.
  """

  use GenServer

  alias DiscordBot.Broker
  alias DiscordBot.Broker.Event
  alias DiscordBot.Entity.{Channel, ChannelManager}
  alias DiscordBot.Model.Message

  defmodule Info do
    @moduledoc """
    A struct which represents an entry of help text
    """
    @enforce_keys [:command_key]

    defstruct [
      :name,
      :command_key,
      :description
    ]

    @typedoc """
    The full name of the entry, e.g. `Ping`
    """
    @type name :: String.t()

    @typedoc """
    The short prefix of the entry, e.g. `!ping`. This should
    be unique among all helptext entries.
    """
    @type command_key :: String.t()

    @typedoc """
    A text description of the entry, e.g. "Responds with `Pong`"
    """
    @type description :: String.t()

    @type t :: %__MODULE__{
            name: name,
            command_key: command_key,
            description: description
          }
  end

  @doc """
  Starts the help handler

  Available options:
  - `:name`: Sets the name of this process
  - `:broker`: Specifies the broker to listen to for events.
    If unspecified, the default broker is used.
  """
  def start_link(opts) do
    broker =
      case Keyword.fetch(opts, :broker) do
        {:ok, pid} -> pid
        :error -> Broker
      end

    name = Keyword.fetch!(opts, :name)

    GenServer.start_link(__MODULE__, {broker, name}, opts)
  end

  @doc """
  Parses a help handler PID from a keyword list, under the key `:help`
  Returns the default name of a help handler process if
  the key is not found
  """
  @spec from_arg(help: pid) :: pid | Services.Help
  def from_arg(keyword_list) do
    case Keyword.fetch(keyword_list, :help) do
      {:ok, pid} -> pid
      :error -> Services.Help
    end
  end

  @doc """
  Registers a new entry of help info, `info`, to be formatted
  and displayed when help is requested over Discord.
  """
  @spec register_info(atom | pid, Info.t()) :: :ok
  def register_info(help, info) do
    GenServer.call(help, {:register, info})
  end

  @doc """
  Returns the info struct registered for a given command key,
  `key`. Returns `:error` if nothing is registered for the key.
  """
  @spec info?(atom | pid, String.t()) :: {:ok, Info.t()} | :error
  def info?(help, key) do
    GenServer.call(help, {:lookup, key})
  end

  @doc """
  Returns the formatted help response
  """
  @spec help_message(atom | pid) :: String.t()
  def help_message(help) do
    GenServer.call(help, :help)
  end

  ## Handlers

  def init({broker, name}) do
    Broker.subscribe(broker, :message_create)

    registry = setup_ets_table(name)

    :ets.insert(
      registry,
      {"!help",
       %Info{
         command_key: "!help",
         name: "Help",
         description: "Replies with this help message"
       }}
    )

    {:ok, {broker, registry}}
  end

  def handle_call({:register, %Info{} = info}, _from, {broker, registry}) do
    :ets.insert(registry, {info.command_key, info})
    {:reply, :ok, {broker, registry}}
  end

  def handle_call({:lookup, key}, _from, {_, registry} = state) do
    result =
      case :ets.lookup(registry, key) do
        [{^key, info}] -> {:ok, info}
        [] -> :error
      end

    {:reply, result, state}
  end

  def handle_call(:help, _from, {broker, registry}) do
    {:reply, build_message(value_stream(registry)), {broker, registry}}
  end

  def handle_info(%Event{message: message}, {broker, registry}) do
    %Message{channel_id: channel_id, content: content} = message

    if content == "!help" do
      {:ok, channel} = ChannelManager.lookup_by_id(DiscordBot.ChannelManager, channel_id)

      Channel.create_message(channel, build_message(value_stream(registry)))
    end

    {:noreply, {broker, registry}}
  end

  defp build_message(info_stream) do
    help_message_header() <>
      Enum.reduce(info_stream, "", fn info, str ->
        str <> "`#{info.command_key}`: #{info.description}\n"
      end)
  end

  defp help_message_header do
    "**Available Commands**\n"
  end

  defp setup_ets_table(name) do
    case :ets.whereis(name) do
      :undefined ->
        :ets.new(name, [:named_table, read_concurrency: true])
        name

      _ ->
        name
    end
  end

  defp key_stream(table) do
    Stream.resource(
      fn -> :ets.first(table) end,
      fn
        :"$end_of_table" -> {:halt, nil}
        previous_key -> {[previous_key], :ets.next(table, previous_key)}
      end,
      fn _ -> :ok end
    )
  end

  defp value_stream(table) do
    table
    |> key_stream()
    |> Stream.map(fn key ->
      case :ets.lookup(table, key) do
        [{^key, info}] -> info
        [] -> nil
      end
    end)
  end
end
