defmodule DiscordBot.Fake.DiscordServer do
  @moduledoc false
  use Plug.Router

  plug(:match)
  plug(:dispatch)

  def start() do
    ref = make_ref()
    url = "ws://localhost:#{8473}/gateway"
    {:ok, core} = DiscordBot.Fake.DiscordCore.start_link([])
    opts = [port: 8473, ref: ref, dispatch: dispatch(core)]
    Plug.Adapters.Cowboy.http(__MODULE__, [], opts)
    {:ok, {url, ref, core}}
  end

  def shutdown(ref) do
    Plug.Adapters.Cowboy.shutdown(ref)
  end

  match _ do
    send_resp(conn, 200, "Hello world!")
  end

  def dispatch(args) do
    [
      {:_,
       [
         {"/gateway", DiscordBot.Fake.DiscordWebsocketHandler, [args]},
         {:_, Plug.Cowboy.Handler, {DiscordBot.Fake.DiscordServer, []}}
       ]}
    ]
  end
end
