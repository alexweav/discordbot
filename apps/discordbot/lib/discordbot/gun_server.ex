defmodule DiscordBot.GunServer do
  @moduledoc """
  A supervisable GenServer-like wrapper for Gun.
  """

  require Logger

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

  @doc """
  Called when the connection is interrupted.
  """
  @callback handle_interrupt(reason :: term, state :: term) :: {:noreply, new_state :: term}

  @doc """
  Called when the connection is restored after an interruption.
  """
  @callback handle_restore(state :: term) :: {:noreply, new_state :: term}

  @doc """
  Called when this session is closed by the server.
  """
  @callback handle_close(code :: integer, reason :: term, state :: term) ::
              {:noreply, new_state :: term}

  @doc """
  Handles cast messages to this process.
  """
  @callback websocket_cast(message :: term, state :: term) :: {:noreply, new_state :: term}

  @doc """
  Called when the process receives a generic message.
  """
  @callback websocket_info(message :: term, state :: term) :: {:noreply, new_state :: term}

  defmacro __using__(_opts) do
    quote location: :keep do
      @behaviour DiscordBot.GunServer

      use GenServer

      @doc false
      def before_connect(state), do: {:ok, state}

      @doc false
      def after_connect(state), do: {:ok, state}

      @doc false
      def handle_frame(frame, _state) do
        raise "No handle_frame/2 defined for #{inspect(frame)}"
      end

      @doc false
      def handle_interrupt(_, state), do: {:noreply, state}

      @doc false
      def handle_restore(state), do: {:noreply, state}

      @doc false
      def handle_close(_, _, state) do
        exit(:closed)
        {:noreply, state}
      end

      @doc false
      def handle_info({:gun_ws, _, _, {:text, text}}, state) do
        handle_frame({:text, text}, state)
      end

      def handle_info({:gun_ws, _, _, {:binary, binary}}, state) do
        handle_frame({:binary, binary}, state)
      end

      def handle_info({:gun_ws, _, _, {:close, code, reason}}, state) do
        handle_close(code, reason, state)
      end

      def handle_info({:gun_down, _, _, reason, _, _}, state) do
        handle_interrupt(reason, state)
      end

      def handle_info({:gun_up, connection, _}, state) do
        path = DiscordBot.GunServer.full_path(state.url)
        DiscordBot.GunServer.ws_upgrade(connection, path, 10_000)
        handle_restore(state)
      end

      def handle_info(msg, state) do
        websocket_info(msg, state)
      end

      @doc false
      def handle_cast(msg, state) do
        websocket_cast(msg, state)
      end

      defoverridable before_connect: 1,
                     after_connect: 1,
                     handle_frame: 2,
                     handle_interrupt: 2,
                     handle_restore: 1,
                     handle_close: 3
    end
  end

  def start_link(module, url, state, opts) do
    GenServer.start_link(module, {URI.parse(url), state}, opts)
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
    ws_upgrade(connection, full_path(url), connect_timeout)

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

  def full_path(url) when is_binary(url) do
    url
    |> URI.parse()
    |> full_path()
  end

  def full_path(url) do
    base_path = if url.path, do: url.path, else: "/"
    if url.query, do: base_path <> "?" <> url.query, else: base_path
  end
end
