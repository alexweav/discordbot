defmodule DiscordBot.Voice.UDP do
  @moduledoc """
  UDP interactions for the voice API.
  """

  alias DiscordBot.Voice.Connection

  @doc """
  Opens and prepares a UDP socket and connection with Discord.
  """
  @spec open(String.t(), integer, integer) :: Connection.t()
  def open(discord_ip, discord_port, ssrc) do
    {:ok, discord_ip} =
      discord_ip
      |> to_charlist
      |> :inet.parse_address()

    {:ok, socket} = start_listening()

    {my_ip, my_port} = ip_discovery(socket, discord_ip, discord_port, ssrc)

    %Connection{
      socket: socket,
      discord_ip: discord_ip,
      discord_port: discord_port,
      my_ip: my_ip,
      my_port: my_port,
      ssrc: ssrc
    }
  end

  @doc """
  Closes a UDP socket.
  """
  @spec close(Connection.t()) :: :ok
  def close(connection) do
    if connection.socket do
      :gen_udp.close(connection.socket)
    end

    :ok
  end

  @spec start_listening :: {:ok, :gen_udp.socket()}
  defp start_listening do
    opts = [
      :binary,
      {:active, false},
      {:reuseaddr, true}
    ]

    # 0 auto-determines port
    :gen_udp.open(0, opts)
  end

  defp ip_discovery(socket, discord_ip, discord_port, ssrc) do
    # 70 bytes
    size = 70 * 8
    packet = <<ssrc::size(size)>>
    :gen_udp.send(socket, discord_ip, discord_port, packet)
    {:ok, {_src_ip, _src_port, response}} = :gen_udp.recv(socket, 70)
    <<_pad::32, ip::bitstring-size(120), _empty::392, port::16>> = response
    {String.replace(ip, "\0", ""), port}
  end
end
