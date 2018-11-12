defmodule DiscordBot.Gateway.Connection do
  @moduledoc """
  Represents a single websocket connection to Discord.
  """

  use WebSockex
  require Logger

  def start_link([url, token]) do
    state = %{
      url: url <> "/?v=6&encoding=json",
      token: token
    }

    WebSockex.start_link(state[:url], __MODULE__, state)
  end

  def handle_connect(connection, state) do
    Logger.info("Connected!")
    {:ok, Map.put(state, :connection, connection)}
  end

  def handle_frame({:text, json}, state) do
    Logger.info("Got message.")
    message = Poison.decode!(json)
    code = message
           |> Map.fetch("op")
           |> atom_from_opcode()
    DiscordBot.Gateway.Broker.publish(Broker, code, message)
    IO.inspect code
    {:ok, state}
  end

  def handle_frame(frame, state) do
    Logger.info("Got other frame.")
    IO.inspect(frame)
    {:ok, state}
  end

  def handle_disconnect(_reason, state) do
    Logger.info("Disconnected.")
    {:ok, state}
  end

  def terminate(_reason, _state) do
    Logger.info("Terminated.")
    exit(:normal)
  end

  defp atom_from_opcode({:ok, opcode}) do
    atom_from_opcode(opcode)
  end

  defp atom_from_opcode(opcode) do
    case opcode do
      0 -> :dispatch
      1 -> :heartbeat
      7 -> :reconnect
      9 -> :invalid_session
      10 -> :hello
      11 -> :heartbeat_ack
    end
  end end
