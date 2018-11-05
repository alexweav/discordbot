defmodule DiscordBot.Gateway.Connection do
  @moduledoc """
  Represents a single websocket connection to Discord.
  """

  use WebSockex
  require Logger

  def start_link([url, token]) do
    WebSockex.start_link(url <> "/?v=6&encoding=json", __MODULE__, {:launched, token})
  end

  def handle_connect(connection, {:launched, token}) do
    Logger.info("Connected!")
    IO.inspect(connection)
    {:ok, {:connecting, token}}
  end

  def handle_frame({:text, json}, {:connecting, _token}) do
    json
    |> Poison.decode!()
    |> IO.inspect()
  end

  def handle_frame(frame, _state) do
    Logger.info("Got message.")

    case frame do
      {:text, json} ->
        json
        |> Poison.decode!()
        |> IO.inspect()

      other ->
        IO.inspect(other)
    end
  end

  def handle_disconnect(_reason, _state) do
    Logger.info("Disconnected.")
  end

  def terminate(_reason, _state) do
    Logger.info("Terminated.")
    exit(:normal)
  end
end
