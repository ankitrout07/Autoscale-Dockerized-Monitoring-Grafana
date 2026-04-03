#!/bin/bash

# Configuration (defaults provided if env vars not set)
PROM_URL="${PROM_URL:-http://prometheus:9090/api/v1/query}"
QUERY="${QUERY:-rate(nginx_http_requests_total[1m])}"
UP_THRESHOLD="${UP_THRESHOLD:-0.1}"
DOWN_THRESHOLD="${DOWN_THRESHOLD:-0.05}"
SLEEP_INTERVAL="${SLEEP_INTERVAL:-5}"
WEB_SERVICES="${WEB_SERVICES:-web_a web_b web_c}"
SCALE_UP_REPLICAS="${SCALE_UP_REPLICAS:-5}"
SCALE_DOWN_REPLICAS="${SCALE_DOWN_REPLICAS:-1}"

echo "Scaler started with parameters:"
echo "  Prometheus URL: $PROM_URL"
echo "  Query: $QUERY"
echo "  Up Threshold: $UP_THRESHOLD"
echo "  Down Threshold: $DOWN_THRESHOLD"
echo "  Web Services: $WEB_SERVICES"
echo "  Scale Up: $SCALE_UP_REPLICAS  | Scale Down: $SCALE_DOWN_REPLICAS"

while true; do
  # Fetch RPS from Prometheus
  RPS=$(curl -s -G "$PROM_URL" --data-urlencode "query=$QUERY" | jq -r '.data.result[0].value[1] // 0')
  
  # Handle empty/null results
  if [ "$RPS" == "null" ] || [ -z "$RPS" ]; then RPS=0; fi

  echo "$(date +%H:%M:%S) - Current RPS: $RPS"

  # Construct the scaling command
  SCALE_OPTS=""
  for svc in $WEB_SERVICES; do
    if (( $(echo "$RPS > $UP_THRESHOLD" | bc -l) )); then
      SCALE_OPTS="$SCALE_OPTS --scale $svc=$SCALE_UP_REPLICAS"
      ACTION="UP to $SCALE_UP_REPLICAS"
    elif (( $(echo "$RPS < $DOWN_THRESHOLD" | bc -l) )); then
      SCALE_OPTS="$SCALE_OPTS --scale $svc=$SCALE_DOWN_REPLICAS"
      ACTION="DOWN to $SCALE_DOWN_REPLICAS"
    fi
  done

  # Execute scaling if needed
  if [ -n "$SCALE_OPTS" ]; then
    echo "ALERT: Scaling Action Detected: $ACTION"
    # shellcheck disable=SC2086
    docker compose up -d $SCALE_OPTS
  fi

  sleep "$SLEEP_INTERVAL"
done