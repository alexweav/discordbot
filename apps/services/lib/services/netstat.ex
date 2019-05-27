defmodule Services.Netstat do
  @moduledoc """
  Provides network statistics and connectivity information.
  """

  use DiscordBot.Handler

  alias DiscordBot.Gateway.Heartbeat
  alias Services.Help

  def start_link(opts) do
    help = Keyword.get(opts, :help, Services.Help)
    DiscordBot.Handler.start_link(__MODULE__, :message_create, help, opts)
  end

  @doc false
  def handler_init(help) do
    Help.register_info(help, %Help.Info{
      command_key: "!netstat",
      name: "Netstat",
      description: "Provides network connectivity information"
    })

    {:ok, :ok}
  end

  @doc false
  def handle_message("!netstat", _, _) do
    {:reply, {:text, stats_message()}}
  end

  def handle_message(_, _, _), do: {:noreply}

  @doc """
  Builds a message describing the current network statistics.
  """
  @spec stats_message() :: String.t()
  def stats_message do
    heartbeats =
      for gateway <- DiscordBot.Gateway.active_gateways(DiscordBot.GatewaySupervisor) do
        case DiscordBot.Gateway.Supervisor.heartbeat?(gateway) do
          {:ok, pid} -> pid
          :error -> :error
        end
      end

    stats_message_header(Enum.count(heartbeats)) <>
      Enum.join(
        for heartbeat <- heartbeats do
          stats_message_entry(heartbeat)
        end
      )
  end

  @spec stats_message_header(integer) :: String.t()
  defp stats_message_header(conn_count) do
    "**#{conn_count} known connections to Discord.**\n"
  end

  defp stats_message_entry(:error) do
    "- Undiscoverable connection. There may be connectivity issues.\n"
  end

  defp stats_message_entry(heartbeat) do
    last_hb_time =
      heartbeat
      |> Heartbeat.last_heartbeat_time?()
      |> format_time()

    last_ack_time =
      heartbeat
      |> Heartbeat.last_ack_time?()
      |> format_time()

    "- Connection #{Kernel.inspect(heartbeat)}:\n" <>
      "--- Ping: #{Heartbeat.ping?(heartbeat) || "Currently unknown"}\n" <>
      "--- Last HB Timestamp: #{last_hb_time}\n" <>
      "--- Last ACK Timestamp: #{last_ack_time}\n" <>
      "--- HB Interval: #{Heartbeat.interval?(heartbeat)}ms\n"
  end

  defp format_time(time) do
    case time do
      nil -> "n/a"
      time -> DateTime.to_string(time) <> " UTC"
    end
  end
end
