#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")"

# Ensure Docker is running
if ! docker info &>/dev/null; then
  echo "Starting Docker..."
  open -a Docker
  for i in $(seq 1 30); do
    docker info &>/dev/null && break
    sleep 2
  done
  if ! docker info &>/dev/null; then
    echo "Error: Docker failed to start" >&2
    exit 1
  fi
fi

docker compose up -d

echo ""
echo "Waiting for services to be healthy..."

# Wait for healthchecks with timeout
TIMEOUT=120
ELAPSED=0
while [ $ELAPSED -lt $TIMEOUT ]; do
  UNHEALTHY=$(docker compose ps --format json 2>/dev/null | python3 -c "
import sys, json
for line in sys.stdin:
    s = json.loads(line.strip())
    if s.get('Health') not in ('', 'healthy'):
        print(s.get('Service',''))
" 2>/dev/null || true)

  if [ -z "$UNHEALTHY" ]; then
    break
  fi
  sleep 2
  ELAPSED=$((ELAPSED + 2))
done

# Verify
OK=true
for port in 6667 6668 6669; do
  if nc -z -w 2 localhost $port 2>/dev/null; then
    : # port is open
  else
    echo "WARNING: IRC port $port not responding"
    OK=false
  fi
done

HTTP=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:9000/ 2>/dev/null || true)
if [ "$HTTP" != "200" ]; then
  echo "WARNING: The Lounge not responding on port 9000"
  OK=false
fi

if $OK; then
  echo "All services running!"
  echo "  IRC Hub:    localhost:6667"
  echo "  IRC Leaf1:  localhost:6668"
  echo "  IRC Leaf2:  localhost:6669"
  echo "  Web:        http://localhost:9000"
fi
