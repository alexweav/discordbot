defmodule DiscordBot.Fake.DiscordServer do
  @moduledoc false
  use Plug.Router

  alias DiscordBot.Fake.DiscordCore
  alias DiscordBot.Fake.DiscordServer
  alias DiscordBot.Fake.DiscordWebsocketHandler
  alias Plug.Adapters.Cowboy
  alias Plug.Cowboy.Handler

  plug(:match)
  plug(:dispatch)

  def start do
    ref = make_ref()
    port = generate_port()
    url = "ws://localhost:#{port}/gateway"
    {:ok, core} = DiscordCore.start_link([])
    opts = [port: port, ref: ref, dispatch: dispatch(core)]
    Cowboy.http(__MODULE__, [], opts)
    {:ok, {url, ref, core}}
  end

  def shutdown(ref) do
    Cowboy.shutdown(ref)
  end

  match _ do
    send_resp(conn, 200, "Hello world!")
  end

  def dispatch(args) do
    [
      {:_,
       [
         {"/gateway", DiscordWebsocketHandler, [args]},
         {:_, Handler, {DiscordServer, []}}
       ]}
    ]
  end

  defp generate_port do
    Enum.random(50_000..60_000)
  end
end
