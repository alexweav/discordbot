defmodule DiscordBot.Handlers.Help do
  @moduledoc """
  Provides help-text on demand in a discord chat channel.
  """

  use GenServer

  alias DiscordBot.Broker
  alias DiscordBot.Broker.Event

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

    GenServer.start_link(__MODULE__, broker, opts)
  end

  @doc """
  Registers a new entry of help info, `info`, to be formatted
  and displayed when help is requested over Discord.
  """
  @spec register_info(pid, Info.t()) :: :ok
  def register_info(help, info) do
    GenServer.call(help, {:register, info})
  end

  @doc """
  Returns the info struct registered for a given command key,
  `key`. Returns `:error` if nothing is registered for the key.
  """
  @spec info?(pid, String.t()) :: {:ok, Info.t()} | :error
  def info?(help, key) do
    GenServer.call(help, {:lookup, key})
  end

  @doc """
  Returns the formatted help response
  """
  @spec help_message(pid) :: String.t()
  def help_message(help) do
    GenServer.call(help, :help)
  end

  ## Handlers

  def init(broker) do
    Broker.subscribe(broker, :message_create)

    registry = %{
      "!help" => %Info{
        command_key: "!help",
        name: "Help",
        description: "Replies with this help message"
      }
    }

    {:ok, {broker, registry}}
  end

  def handle_call({:register, %Info{} = info}, _from, {broker, registry}) do
    {:reply, :ok, {broker, Map.put(registry, info.command_key, info)}}
  end

  def handle_call({:lookup, key}, _from, {_, registry} = state) do
    {:reply, Map.fetch(registry, key), state}
  end

  def handle_call(:help, _from, {broker, registry}) do
    {:reply, build_message(Map.values(registry)), {broker, registry}}
  end

  def handle_info(%Event{message: message}, {broker, registry}) do
    %DiscordBot.Model.Message{channel_id: channel_id, content: content} = message

    if content == "!help" do
      {:ok, channel} =
        DiscordBot.Channel.Controller.lookup_by_id(DiscordBot.ChannelController, channel_id)

      DiscordBot.Channel.Channel.create_message(channel, build_message(Map.values(registry)))
    end

    {:noreply, {broker, registry}}
  end

  defp build_message(info_list) do
    help_message_header() <>
      Enum.reduce(info_list, "", fn info, str ->
        str <> "`#{info.command_key}`: #{info.description}\n"
      end)
  end

  defp help_message_header do
    "**Available Commands**\n"
  end
end
