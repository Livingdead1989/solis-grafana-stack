#!/usr/bin/env sh
set -eu

# Export INFLUX_TOKEN from secret (preferred). Falls back to env if already set.
if [ -f /run/secrets/influx_token ] && [ -z "${INFLUX_TOKEN:-}" ]; then
  export INFLUX_TOKEN="$(cat /run/secrets/influx_token)"
fi

exec telegraf --config /etc/telegraf/telegraf.conf
