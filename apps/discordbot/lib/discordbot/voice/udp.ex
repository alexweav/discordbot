defmodule DiscordBot.Voice.Udp do
  @moduledoc """
  UDP interactions for the voice API.
  """

  defmodule Connection do
    @moduledoc false

    defstruct [
      :socket,
      :discord_ip,
      :discord_port,
      :my_ip,
      :my_port
    ]

    @type socket :: :gen_udp.socket()
    @type discord_ip :: :inet.ip_address()
    @type discord_port :: integer
    @type my_ip :: :inet.ip_address()
    @type my_port :: integer
    @type t :: %__MODULE__{
            socket: socket,
            discord_ip: discord_ip,
            discord_port: discord_port,
            my_ip: my_ip,
            my_port: my_port
          }
  end

  @spec open(String.t(), integer, integer) :: Connection.t()
  def open(discord_ip, discord_port, ssrc) do
    {:ok, discord_ip} =
      discord_ip
      |> to_charlist
      |> :inet.parse_address()

    {:ok, socket} = start_listening()

    # TODO: get our external IP and port
    {my_ip, my_port} = ip_discovery(socket, discord_ip, discord_port, ssrc)

    %Connection{
      socket: socket,
      discord_ip: discord_ip,
      discord_port: discord_port,
      my_ip: my_ip,
      my_port: my_port
    }
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

  defp ip_discovery(_socket, _discord_ip, _discord_port, ssrc) do
    # 70 bytes
    size = 70 * 8
    _packet = <<ssrc::size(size)>>
    {nil, nil}
  end
end
