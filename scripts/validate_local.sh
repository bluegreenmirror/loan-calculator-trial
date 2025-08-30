#!/usr/bin/env bash
set -euo pipefail

echo "[validate-local] Ensuring docker is available..."
command -v docker >/dev/null 2>&1 || { echo "Docker is required" >&2; exit 1; }

DOMAIN=${DOMAIN:-localhost}

echo "[validate-local] Creating shared network/volume if missing..."
docker network create edge-net >/dev/null 2>&1 || true
docker volume create edge_caddy_data >/dev/null 2>&1 || true

COLOR=${1:-blue}
if [[ "$COLOR" != "blue" && "$COLOR" != "green" ]]; then
  echo "Usage: $0 [blue|green]" >&2
  exit 1
fi

export PROJECT_NAME="loancalc-$COLOR"

echo "[validate-local] Bringing up color stack: $PROJECT_NAME"
docker compose -p "$PROJECT_NAME" up -d --build caddy api web

echo "[validate-local] Waiting for color API health..."
sleep 3
# Use a curl container on the project network to check the API by service name
docker run --rm --network=${PROJECT_NAME}_default curlimages/curl:latest -sSf http://api:8000/api/health >/dev/null

echo "[validate-local] Pointing edge to ${PROJECT_NAME}-caddy:80"
# For local validation, use a localhost-only edge config to avoid missing domain env vars
cat > Caddyfile.edge <<EOF
http://localhost {
    reverse_proxy ${PROJECT_NAME}-caddy:80
}
EOF

echo "[validate-local] Starting/reloading edge..."
# Try to start existing named container; if missing, create via compose
docker start loancalc-edge >/dev/null 2>&1 || docker compose -p edge up -d edge
# Wait for edge to be running
for i in {1..30}; do
  state=$(docker inspect -f '{{.State.Running}}' loancalc-edge 2>/dev/null || echo false)
  if [ "$state" = "true" ]; then break; fi
  sleep 1
done
# Reload config
docker exec loancalc-edge caddy reload --config /etc/caddy/Caddyfile

# Give edge a moment to accept connections after reload
sleep 1

echo "[validate-local] Checking site (HTTP) at http://$DOMAIN ..."
root_code=$(curl -s -o /dev/null -w '%{http_code}' "http://$DOMAIN/")
[[ "$root_code" == "200" || "$root_code" == "301" || "$root_code" == "308" ]] || {
  echo "Root returned unexpected code: $root_code" >&2; exit 1; }

ctype=$(curl -sI "http://$DOMAIN/" | awk -v IGNORECASE=1 '/^Content-Type:/ {print tolower($2)}' | tr -d '\r')
echo "$ctype" | grep -qi 'text/html' || echo "(warn) Content-Type not HTML on HTTP root: $ctype"

echo "[validate-local] Checking API health via edge..."
curl -fsS "http://$DOMAIN/api/health" | grep -q '"ok": true'

echo "[validate-local] OK: site reachable and API healthy"
