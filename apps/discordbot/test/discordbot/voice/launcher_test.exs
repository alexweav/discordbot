defmodule DiscordBot.Voice.LauncherTest do
  use ExUnit.Case, async: true
  doctest DiscordBot.Voice.Launcher

  alias DiscordBot.Voice.Launcher

  describe "preprocess_url" do
    test "correct if protocol not provided" do
      assert Launcher.preprocess_url("asdf.gg") == "wss://asdf.gg/?v=3"
    end

    test "correct is protocol already provided" do
      assert Launcher.preprocess_url("wss://asdf.gg") == "wss://asdf.gg/?v=3"
    end

    test "removes port 80" do
      assert Launcher.preprocess_url("asdf.gg:80") == "wss://asdf.gg/?v=3"
    end

    test "doesn't remove other ports" do
      assert Launcher.preprocess_url("asdf.gg:100") == "wss://asdf.gg:100/?v=3"
    end
  end
end
