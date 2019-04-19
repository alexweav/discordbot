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
    connection_count = connection_count()

    heartbeats =
      for idx <- 0..(connection_count - 1) do
        case DiscordBot.Gateway.get_gateway_instance(DiscordBot.GatewaySupervisor, idx) do
          {:ok, gateway} ->
            case DiscordBot.Gateway.Supervisor.heartbeat?(gateway) do
              {:ok, pid} -> pid
              :error -> :error
            end

          :error ->
            :error
        end
      end

    stats_message_header(connection_count) <>
      Enum.join(
        for heartbeat <- heartbeats do
          stats_message_entry(heartbeat)
        end
      )
  end

  @doc """
  Gets the current number of active connections.
  """
  @spec connection_count() :: integer
  def connection_count do
    DiscordBot.Gateway.connection_count()
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
      "--- HB Interval: #{Heartbeat.interval?(heartbeat)}s\n"
  end

  defp format_time(time) do
    case time do
      nil -> "n/a"
      time -> DateTime.to_string(time) <> " UTC"
    end
  end
end
