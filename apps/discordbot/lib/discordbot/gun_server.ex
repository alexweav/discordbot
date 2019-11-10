defmodule DiscordBot.GunServer do
  @moduledoc """
  A supervisable GenServer-like wrapper for Gun.
  """

  @typedoc """
  A single WebSocket frame.
  """
  @type frame ::
          :ping
          | :pong
          | {:ping | :pong, nil | binary}
          | {:text | :binary, binary}

  @doc """
  Called before trying to connect.
  """
  @callback before_connect(state :: term) :: {:ok, new_state :: term}

  @doc """
  Called after a WebSocket connection is established.
  """
  @callback after_connect(state :: term) :: {:ok, new_state :: term}

  @doc """
  Called when a frame is received.
  """
  @callback handle_frame(frame :: frame, state :: term) :: {:noreply, new_state :: term}

  require Logger

  defmacro __using__(_opts) do
    quote location: :keep do
      @behaviour DiscordBot.GunServer

      use GenServer
      require Logger

      @doc false
      def before_connect(state), do: {:ok, state}

      @doc false
      def after_connect(state), do: {:ok, state}

      @doc false
      def handle_frame(frame, _state) do
        raise "No handle_frame/2 defined for #{inspect(frame)}"
      end

      @doc false
      def handle_info({:gun_ws, _, _, {:text, text}}, state) do
        handle_frame({:text, text}, state)
      end

      def handle_info({:gun_ws, _, _, {:binary, binary}}, state) do
        Logger.info("Binary frame received: #{binary}")
        {:noreply, state}
      end

      defoverridable before_connect: 1,
                     after_connect: 1,
                     handle_frame: 2
    end
  end

  def connect(url, connect_timeout) do
    url = URI.parse(url)
    connection_opts = %{protocols: [:http]}

    {:ok, connection} =
      url.host
      |> to_charlist()
      |> :gun.open(url.port, connection_opts)

    {:ok, :http} = :gun.await_up(connection, connect_timeout)
    Logger.info("HTTP connection established.")
    path = if url.path, do: url.path, else: "/"
    full_path = if url.query, do: path <> "?" <> url.query, else: path
    ws_upgrade(connection, full_path, connect_timeout)

    Logger.info("WebSocket upgrade succeeded.")

    connection
  end

  def ws_upgrade(connection, path, timeout) do
    :gun.ws_upgrade(connection, path)

    receive do
      {:gun_upgrade, _, _, ["websocket"], _} ->
        :ok

      {:gun_error, _, _, reason} ->
        Logger.error("WS upgrade failed: #{Kernel.inspect(reason)}")
        exit({:upgrade_failed, reason})
    after
      timeout ->
        Logger.error("WS upgrade timed out.")
        exit({:upgrade_failed, :timeout})
    end
  end
end
