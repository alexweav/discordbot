#!/bin/sh

DIR="$( cd "$( dirname "$0" )" && pwd)"
FILE="$DIR/config.exs"

/bin/cat <<EOM >$FILE
use Mix.Config

config :discordbot,
  token: "${DISCORD_TOKEN}"

EOM
