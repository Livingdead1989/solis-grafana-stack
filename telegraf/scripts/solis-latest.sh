
#!/usr/bin/env bash
set -euo pipefail

# Prefer env vars but fall back to Portainer/Docker secrets
read_secret() { [ -f "/run/secrets/$1" ] && cat "/run/secrets/$1" || printf "%s" "${!2:-}"; }

EMAIL="${SOLIS_EMAIL:-}"
PASSWORD="$(read_secret solis_password SOLIS_PASSWORD)"
CLIENT_ID="$(read_secret solarman_client_id SOLARMAN_CLIENT_ID)"
CLIENT_SECRET="$(read_secret solarman_client_secret SOLARMAN_CLIENT_SECRET)"
DEVICE_SN="${SOLIS_DEVICE_SN:-}"

AUTH_URL="${SOLIS_AUTH_URL:-https://api.solarmanpv.com/account/v1/auth/login}"
LATEST_URL="${SOLIS_LATEST_URL:-https://api.solarmanpv.com/device/v1/data/latest}"

# Build auth payload (some tenants require clientId/secret; others ignore them)
AUTH_PAYLOAD=$(jq -n --arg email "$EMAIL" --arg password "$PASSWORD" \
  --arg clientId "$CLIENT_ID" --arg clientSecret "$CLIENT_SECRET" \
  '{email: $email, password: $password, clientId: $clientId, clientSecret: $clientSecret}')

TOKEN=$(curl -sS -X POST "$AUTH_URL" \
  -H "Content-Type: application/json" \
  -d "$AUTH_PAYLOAD" | jq -r '.accessToken // .token')

if [ -z "$TOKEN" ] || [ "$TOKEN" = "null" ]; then
  echo '{"error":"auth_failed"}'
  exit 1
fi

DATA_PAYLOAD=$(jq -n --arg sn "$DEVICE_SN" '{deviceSn: $sn}')

curl -sS -X POST "$LATEST_URL" \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer '"$TOKEN"'" \
  -d "$DATA_PAYLOAD"
``
