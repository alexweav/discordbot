defmodule DiscordBot.Handlers.Search.TokenManagerTest do
  use ExUnit.Case, async: true
  doctest DiscordBot.Handlers.Search.TokenManager

  alias DiscordBot.Handlers.Search.TokenManager

  setup do
    manager = start_supervised!(TokenManager)
    %{manager: manager}
  end
end
