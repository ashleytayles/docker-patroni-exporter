#!/bin/sh
# Integration test: verify patroni-exporter /metrics endpoint returns valid
# Prometheus metrics from a live Patroni cluster.
set -e

METRICS_URL="${METRICS_URL:-http://localhost:9933/metrics}"
MAX_RETRIES=30
RETRY_INTERVAL=2

echo "==> Waiting for /metrics endpoint at ${METRICS_URL} ..."
attempt=0
while [ "$attempt" -lt "$MAX_RETRIES" ]; do
  if wget -qO /dev/null "$METRICS_URL" 2>/dev/null || curl -sf "$METRICS_URL" >/dev/null 2>&1; then
    echo "    Endpoint is up (attempt $((attempt + 1)))"
    break
  fi
  attempt=$((attempt + 1))
  echo "    Attempt ${attempt}/${MAX_RETRIES} — retrying in ${RETRY_INTERVAL}s ..."
  sleep "$RETRY_INTERVAL"
done

if [ "$attempt" -ge "$MAX_RETRIES" ]; then
  echo "FAIL: /metrics endpoint did not become available"
  exit 1
fi

echo "==> Fetching metrics ..."
METRICS=$(curl -sf "$METRICS_URL" 2>/dev/null || wget -qO- "$METRICS_URL")

FAILURES=0

# Check for expected patroni_* metric families
for metric in patroni_node_up patroni_cluster_node_role patroni_cluster_node_state; do
  if echo "$METRICS" | grep -q "^${metric}"; then
    echo "  PASS: found ${metric}"
  else
    echo "  FAIL: missing ${metric}"
    FAILURES=$((FAILURES + 1))
  fi
done

# Check that we got HELP and TYPE lines (valid Prometheus exposition format)
if echo "$METRICS" | grep -q "^# HELP"; then
  echo "  PASS: found # HELP lines"
else
  echo "  FAIL: no # HELP lines found"
  FAILURES=$((FAILURES + 1))
fi

if echo "$METRICS" | grep -q "^# TYPE"; then
  echo "  PASS: found # TYPE lines"
else
  echo "  FAIL: no # TYPE lines found"
  FAILURES=$((FAILURES + 1))
fi

# Check we're getting more than just boilerplate (at least 10 metric lines)
METRIC_LINES=$(echo "$METRICS" | grep -cv "^#\|^$" || true)
if [ "$METRIC_LINES" -ge 10 ]; then
  echo "  PASS: ${METRIC_LINES} metric sample lines"
else
  echo "  FAIL: only ${METRIC_LINES} metric sample lines (expected >= 10)"
  FAILURES=$((FAILURES + 1))
fi

echo ""
if [ "$FAILURES" -gt 0 ]; then
  echo "RESULT: ${FAILURES} check(s) failed"
  echo ""
  echo "==> Full metrics dump for debugging:"
  echo "$METRICS"
  exit 1
fi

echo "RESULT: All checks passed"
