defmodule Services.Netstat do
  @moduledoc """
  Provides network statistics and connectivity information.
  """

  alias DiscordBot.Gateway.Heartbeat

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
