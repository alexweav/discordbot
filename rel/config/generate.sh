#!/bin/sh

DIR="$( cd "$( dirname "$0" )" && pwd)"
FILE="$DIR/config.exs"

/bin/cat <<EOM >$FILE
use Mix.Config

config :discordbot,
  token: "${DISCORD_TOKEN}",
  youtube_data_api_key: "${YOUTUBE_DATA_API_KEY}"

EOM
