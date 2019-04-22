defmodule DiscordBot.Fake.DiscordCore do
  @moduledoc false

  use GenServer

  def start_link(opts) do
    state = %{api_version: nil, encoding: nil}
    GenServer.start_link(__MODULE__, state, opts)
  end

  def request_socket(core, req) do
    GenServer.call(core, {:request_socket, req})
  end

  def api_version?(core) do
    GenServer.call(core, :get_api_version)
  end

  def encoding?(core) do
    GenServer.call(core, :encoding)
  end

  ## Handlers

  def init(state) do
    {:ok, state}
  end

  def handle_call(:get_api_version, _from, %{api_version: version} = state) do
    {:reply, version, state}
  end

  def handle_call(:encoding, _from, %{encoding: encoding} = state) do
    {:reply, encoding, state}
  end

  def handle_call({:request_socket, req}, _from, state) do
    params =
      req
      |> Map.get(:qs, "")
      |> URI.decode_query()

    {:reply, :ok,
     %{state | api_version: Map.get(params, "v"), encoding: Map.get(params, "encoding")}}
  end
end
