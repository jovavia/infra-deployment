#!/bin/sh
set -eu

# ------------------------------------------------------------------
# Validate required environment variables
# ------------------------------------------------------------------
: "${REDIS_PASSWORD:?REDIS_PASSWORD must be set}"
: "${REDIS_NODE_ID:?REDIS_NODE_ID must be set}"
: "${REDIS_BASE_PORT:?REDIS_BASE_PORT must be set}"

REDIS_PORT=$((REDIS_BASE_PORT + REDIS_NODE_ID))
REDIS_BUS_PORT=$((REDIS_PORT + 10000))

export REDIS_PORT
export REDIS_BUS_PORT
export REDIS_PASSWORD

# ------------------------------------------------------------------
# Generate Redis configuration
# ------------------------------------------------------------------
sed \
  -e "s|\${REDIS_PASSWORD}|${REDIS_PASSWORD}|g" \
  -e "s|\${REDIS_PORT}|${REDIS_PORT}|g" \
  -e "s|\${REDIS_BUS_PORT}|${REDIS_BUS_PORT}|g" \
  /config/redis.conf.template > /tmp/redis.conf

exec redis-server /tmp/redis.conf