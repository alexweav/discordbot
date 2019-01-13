#!/bin/sh

DIR="$( cd "$( dirname "$0" )" && pwd)"
FILE="$DIR/config.exs"

/bin/cat <<EOM >$FILE
use Mix.Config

config :discordbot,
  token: "${DISCORD_TOKEN}",
  youtube_data_api_key: "${YOUTUBE_DATA_API_KEY}",
  spotify_client_id: "${SPOTIFY_CLIENT_ID}",
  spotify_client_secret: "${SPOTIFY_CLIENT_SECRET}"

EOM
