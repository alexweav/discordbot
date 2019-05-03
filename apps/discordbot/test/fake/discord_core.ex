defmodule DiscordBot.Fake.DiscordCore do
  @moduledoc false

  use GenServer

  alias DiscordBot.Model.Hello

  def start_link(opts) do
    state = %{
      api_version: nil,
      encoding: nil,
      latest_text_frame: nil,
      all_frames: [],
      handler: nil
    }

    GenServer.start_link(__MODULE__, state, opts)
  end

  ## Handler API

  def register(core) do
    GenServer.call(core, :register)
  end

  def request_socket(core, req) do
    GenServer.call(core, {:request_socket, req})
  end

  def receive_text_frame(core, frame) do
    GenServer.call(core, {:receive_text_frame, frame})
  end

  ## Client API

  def api_version?(core) do
    GenServer.call(core, :get_api_version)
  end

  def encoding?(core) do
    GenServer.call(core, :encoding)
  end

  def latest_frame?(core) do
    GenServer.call(core, :latest_frame)
  end

  def all_frames?(core) do
    GenServer.call(core, :all_frames)
  end

  def hello(core, interval, trace) do
    GenServer.call(core, {:hello, interval, trace})
  end

  ## Handlers

  def init(state) do
    {:ok, state}
  end

  def handle_call(:register, {caller, _tag}, state) do
    {:reply, :ok, %{state | handler: caller}}
  end

  def handle_call(:get_api_version, _from, %{api_version: version} = state) do
    {:reply, version, state}
  end

  def handle_call(:encoding, _from, %{encoding: encoding} = state) do
    {:reply, encoding, state}
  end

  def handle_call(:latest_frame, _from, %{latest_text_frame: latest} = state) do
    {:reply, latest, state}
  end

  def handle_call(:all_frames, _from, %{all_frames: frames} = state) do
    {:reply, frames, state}
  end

  def handle_call({:request_socket, req}, _from, state) do
    params =
      req
      |> Map.get(:qs, "")
      |> URI.decode_query()

    {:reply, :ok,
     %{state | api_version: Map.get(params, "v"), encoding: Map.get(params, "encoding")}}
  end

  def handle_call({:receive_text_frame, text}, _from, state) do
    {:reply, :ok, %{state | latest_text_frame: text, all_frames: state[:all_frames] ++ [text]}}
  end

  def handle_call({:hello, interval, trace}, _from, state) do
    send(state[:handler], {:hello, Hello.hello(interval, trace)})
    {:reply, :ok, state}
  end
end
