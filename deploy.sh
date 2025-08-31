#!/bin/bash
set -euo pipefail

usage() {
  cat <<EOF
Usage: $0 <blue|green>

Deploys the application to the specified environment using a blue-green strategy.
EOF
}

if [ $# -ne 1 ]; then
  usage
  exit 1
fi

ENV=$1
if [ "$ENV" != "blue" ] && [ "$ENV" != "green" ]; then
  usage
  exit 1
fi

# Load environment from .env if present (for DOMAIN/APEX_HOST/WWW_HOST, etc.)
if [ -f .env ]; then
  set -a
  # shellcheck disable=SC1091
  . ./.env
  set +a
fi

# Create external network and volumes if they don't exist
docker network create edge-net || true
docker volume create edge_caddy_data || true
docker volume create app_data || true

# Set environment variables based on the chosen environment
if [ "$ENV" == "blue" ]; then
  export PROJECT_NAME="loancalc-blue"
  OLD_PROJECT_NAME="loancalc-green"
else
  export PROJECT_NAME="loancalc-green"
  OLD_PROJECT_NAME="loancalc-blue"
fi

echo "Deploying to $ENV environment..."
docker compose -p $PROJECT_NAME up -d --build caddy api web

echo "Waiting for $ENV environment to be healthy..."
sleep 15

# Health check on the internal service
if ! docker run --rm --network=${PROJECT_NAME}_default curlimages/curl:latest -sSf http://api:8000/api/health > /dev/null; then
  echo "Health check failed for $ENV environment."
  exit 1
fi

echo "$ENV environment is healthy."

# Switch traffic by creating a new Caddyfile for the edge
echo "Switching traffic to $ENV environment."
sed "s|##LIVE_UPSTREAM##|${PROJECT_NAME}-caddy:80|g" Caddyfile.edge.template.caddyfile > Caddyfile.edge

# Reload the main Caddy instance
echo "Reloading edge Caddy instance..."
if docker ps -a --format '{{.Names}}' | grep -qx "loancalc-edge"; then
  docker start loancalc-edge >/dev/null 2>&1 || true
else
  docker compose up -d edge
fi
EDGE_CONTAINER_ID=$(docker ps -qf "name=loancalc-edge")
docker kill -s SIGHUP "$EDGE_CONTAINER_ID"
sleep 5

rollback_edge() {
  echo "Rolling back edge to $OLD_PROJECT_NAME..."
  sed "s|##LIVE_UPSTREAM##|${OLD_PROJECT_NAME}-caddy:80|g" Caddyfile.edge.template.caddyfile > Caddyfile.edge
  local EDGE_ID
  EDGE_ID=$(docker ps -qf "name=loancalc-edge")
  docker kill -s SIGHUP "$EDGE_ID"
  sleep 5
}

# Internal upstream health from edge container (network reachability)
echo "Verifying upstream from edge network..."
if ! docker run --rm --network=edge-net curlimages/curl:latest -sSf "http://${PROJECT_NAME}-caddy:80/api/health" > /dev/null; then
  echo "Upstream not reachable from edge."
  rollback_edge
  exit 1
fi

# External live domain health (with retries)
echo "Verifying live domain..."
# Prefer explicit APEX_HOST from .env, else fallback to DOMAIN, else localhost (dev)
LIVE_HOST="${APEX_HOST:-${DOMAIN:-localhost}}"
# Use HTTPS for real hosts; HTTP for localhost/dev
SCHEME="http"
if [ "$LIVE_HOST" != "localhost" ]; then
  SCHEME="https"
fi
LIVE_URL="${SCHEME}://${LIVE_HOST}/api/health"
ok=false
for i in {1..10}; do
  if curl -ksSf "$LIVE_URL" > /dev/null; then
    ok=true; break
  fi
  sleep 2
done
if [ "$ok" != true ]; then
  echo "Live domain health check failed for $LIVE_URL"
  rollback_edge
  exit 1
fi

echo "Live domain is healthy."

# Stop the old environment to save resources
echo "Stopping old environment ($OLD_PROJECT_NAME)..."
docker compose -p $OLD_PROJECT_NAME down --remove-orphans || true

echo "Deployment to $ENV environment successful."
echo "Live environment is now: $ENV"
