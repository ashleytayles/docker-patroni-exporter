#!/bin/sh
set -e

# Map environment variables to patroni_exporter CLI flags.
# Any flag can be overridden via its corresponding env var.
# Additional flags can be passed as CMD arguments.

ARGS=""

# Patroni connection settings
[ -n "$PATRONI_HOST" ]          && ARGS="$ARGS --patroni.host=$PATRONI_HOST"
[ -n "$PATRONI_PORT" ]          && ARGS="$ARGS --patroni.port=$PATRONI_PORT"

# Web / telemetry settings
[ -n "$WEB_LISTEN_ADDRESS" ]    && ARGS="$ARGS --web.listen-address=$WEB_LISTEN_ADDRESS"
[ -n "$WEB_TELEMETRY_PATH" ]    && ARGS="$ARGS --web.telemetry-path=$WEB_TELEMETRY_PATH"

# Logging settings (promlog)
[ -n "$LOG_LEVEL" ]             && ARGS="$ARGS --log.level=$LOG_LEVEL"
[ -n "$LOG_FORMAT" ]            && ARGS="$ARGS --log.format=$LOG_FORMAT"

# shellcheck disable=SC2086
exec patroni_exporter $ARGS "$@"
