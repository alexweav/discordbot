defmodule DiscordBot.Voice.Udp do
  @moduledoc """
  UDP interactions for the voice API.
  """

  defmodule Connection do
    @moduledoc false

    defstruct [
      :listener,
      :discord_ip,
      :discord_port,
      :my_ip,
      :my_port
    ]

    @type listener :: :gen_udp.socket()
    @type discord_ip :: :inet.ip_address()
    @type discord_port :: integer
    @type my_ip :: :inet.ip_address()
    @type my_port :: integer
    @type t :: %__MODULE__{
            listener: listener,
            discord_ip: discord_ip,
            discord_port: discord_port,
            my_ip: my_ip,
            my_port: my_port
          }
  end

  def open(discord_ip, discord_port) do
    {:ok, discord_ip} =
      discord_ip
      |> to_charlist
      |> :inet.parse_address()

    {:ok, listener} = start_listening()

    # TODO: get our external IP and port
    {my_ip, my_port} = {nil, nil}

    %Connection{
      listener: listener,
      discord_ip: discord_ip,
      discord_port: discord_port,
      my_ip: my_ip,
      my_port: my_port
    }
  end

  def start_listening do
    opts = [
      :binary,
      {:active, false},
      {:reuseaddr, true}
    ]

    # 0 auto-determines port
    :gen_udp.open(0, opts)
  end
end
