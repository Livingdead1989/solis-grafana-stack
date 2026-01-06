FROM telegraf:1.30-alpine

# Tools used by the exec script
RUN apk add --no-cache curl jq

# Provide an entrypoint that sources secrets then starts Telegraf
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]
