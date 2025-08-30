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

# Create external network and volume if they don't exist
docker network create edge-net || true
docker volume create edge_caddy_data || true

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
docker compose up -d edge
EDGE_CONTAINER_ID=$(docker ps -qf "name=loancalc-edge")
docker kill -s SIGHUP $EDGE_CONTAINER_ID
sleep 5

# Health check on the live domain
echo "Verifying live domain..."
LIVE_URL="https://$DOMAIN"
if ! curl -ksSf "$LIVE_URL" > /dev/null; then
  echo "Health check failed for live domain."
  echo "Rolling back to $OLD_PROJECT_NAME..."
  sed "s|##LIVE_UPSTREAM##|${OLD_PROJECT_NAME}-caddy:80|g" Caddyfile.edge.template.caddyfile > Caddyfile.edge
  EDGE_CONTAINER_ID=$(docker ps -qf "name=loancalc-edge")
docker kill -s SIGHUP $EDGE_CONTAINER_ID
sleep 5
  exit 1
fi

echo "Live domain is healthy."

# Stop the old environment to save resources
echo "Stopping old environment ($OLD_PROJECT_NAME)..."
docker compose -p $OLD_PROJECT_NAME down --remove-orphans || true

echo "Deployment to $ENV environment successful."
echo "Live environment is now: $ENV"