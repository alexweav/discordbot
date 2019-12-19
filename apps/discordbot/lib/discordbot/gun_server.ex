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
  @callback websocket_cast(message :: term, connection :: term, state :: term) ::
              {:noreply, new_state :: term}

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
      def websocket_cast(msg, _, _) do
        raise "No websocket_cast/3 defined for #{inspect(msg)}"
      end

      @doc false
      def websocket_info(msg, _) do
        raise "No websocket_info/2 defined for #{inspect(msg)}"
      end

      @doc false
      def init({url, state}) do
        {:ok, before_state} = before_connect(state)
        connection = DiscordBot.GunServer.connect(url, 10_000)
        {:ok, after_state} = after_connect(before_state)
        {:ok, {url, connection, after_state}}
      end

      @doc false
      def handle_info({:gun_ws, _, _, {:text, text}}, {url, conn, state}) do
        {:text, text}
        |> handle_frame(state)
        |> DiscordBot.GunServer.finalize(url, conn)
      end

      def handle_info({:gun_ws, _, _, {:binary, binary}}, {url, conn, state}) do
        {:binary, binary}
        |> handle_frame(state)
        |> DiscordBot.GunServer.finalize(url, conn)
      end

      def handle_info({:gun_ws, _, _, {:close, code, reason}}, {url, conn, state}) do
        code
        |> handle_close(reason, state)
        |> DiscordBot.GunServer.finalize(url, conn)
      end

      def handle_info({:gun_down, _, _, reason, _, _}, {url, conn, state}) do
        reason
        |> handle_interrupt(state)
        |> DiscordBot.GunServer.finalize(url, conn)
      end

      def handle_info({:gun_up, connection, _}, {url, conn, state}) do
        path = DiscordBot.GunServer.full_path(url)
        DiscordBot.GunServer.ws_upgrade(connection, path, 10_000)

        state
        |> handle_restore()
        |> DiscordBot.GunServer.finalize(url, conn)
      end

      def handle_info(msg, {url, conn, state}) do
        msg
        |> websocket_info(state)
        |> DiscordBot.GunServer.finalize(url, conn)
      end

      @doc false
      def handle_cast(msg, {url, conn, state}) do
        msg
        |> websocket_cast(conn, state)
        |> DiscordBot.GunServer.finalize(url, conn)
      end

      defoverridable before_connect: 1,
                     after_connect: 1,
                     handle_frame: 2,
                     handle_interrupt: 2,
                     handle_restore: 1,
                     handle_close: 3,
                     websocket_cast: 3,
                     websocket_info: 2
    end
  end

  @doc """
  Starts the GunServer.
  """
  def start_link(module, url, state, opts) do
    GenServer.start_link(module, {URI.parse(url), state}, opts)
  end

  @doc false
  def connect(url, connect_timeout) do
    connection_opts = %{protocols: [:http]}

    {:ok, connection} =
      url.host
      |> to_charlist()
      |> :gun.open(url.port || 443, connection_opts)

    {:ok, :http} = :gun.await_up(connection, connect_timeout)
    Logger.info("HTTP connection established.")
    ws_upgrade(connection, full_path(url), connect_timeout)

    Logger.info("WebSocket upgrade succeeded.")

    connection
  end

  @doc false
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

  @doc false
  def full_path(url) do
    base_path = if url.path, do: url.path, else: "/"
    if url.query, do: base_path <> "?" <> url.query, else: base_path
  end

  @doc false
  def finalize({:noreply, new_state}, url, conn) do
    {:noreply, {url, conn, new_state}}
  end

  def finalize({:stop, reason, new_state}, url, conn) do
    :gun.close(conn)
    {:stop, reason, {url, conn, new_state}}
  end
end
