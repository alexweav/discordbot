defmodule Services.Netstat.Server do
  @moduledoc """
  GenServer for the Netstat command.
  """

  use GenServer

  alias DiscordBot.Broker
  alias DiscordBot.Broker.Event
  alias DiscordBot.Entity.{Channel, ChannelManager}
  alias DiscordBot.Model.Message
  alias Services.Help
  alias Services.Netstat

  @doc """
  Starts the netstat handler.
  """
  def start_link(opts) do
    broker = Keyword.get(opts, :broker, Broker)
    help = Help.from_arg(opts)
    GenServer.start_link(__MODULE__, {broker, help}, opts)
  end

  ## Handlers

  def init({broker, help}) do
    Broker.subscribe(broker, :message_create)

    Help.register_info(help, %Help.Info{
      command_key: "!netstat",
      name: "Netstat",
      description: "Provides network connectivity information"
    })

    {:ok, broker}
  end

  def handle_info(%Event{message: message}, broker) do
    %Message{channel_id: channel_id, content: content} = message
    handle_content(content, channel_id)
    {:noreply, broker}
  end

  defp handle_content("!netstat", channel_id) do
    Task.Supervisor.start_child(
      Services.Netstat.TaskSupervisor,
      fn -> send_netstat_message(channel_id) end
    )
  end

  defp handle_content(_, _), do: nil

  defp send_netstat_message(channel_id) do
    {:ok, channel} = ChannelManager.lookup_by_id(DiscordBot.ChannelManager, channel_id)

    message = Netstat.stats_message()
    Channel.create_message(channel, message)
  end
end
