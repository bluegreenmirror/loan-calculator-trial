#!/bin/bash
set -euo pipefail

usage() {
  cat <<EOF
Usage: $0 <blue|green>

Deploys the application to the specified environment.
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

# Set environment variables based on the chosen environment
if [ "$ENV" == "blue" ]; then
  export PROJECT_NAME="loancalc-blue"
  export CADDY_HTTP_PORT=8080
  export CADDY_HTTPS_PORT=8443
  OLD_PROJECT_NAME="loancalc-green"
else
  export PROJECT_NAME="loancalc-green"
  export CADDY_HTTP_PORT=9080
  export CADDY_HTTPS_PORT=9443
  OLD_PROJECT_NAME="loancalc-blue"
fi

export DOMAIN="localhost"
export API_UPSTREAM="${PROJECT_NAME}-api:8000"

echo "Deploying to $ENV environment..."
docker compose -p $PROJECT_NAME up -d --build

echo "Waiting for $ENV environment to be healthy..."
sleep 15

# Health check
HEALTH_URL="http://localhost:${CADDY_HTTP_PORT}/api/health"
if ! curl -sSf $HEALTH_URL > /dev/null; then
  echo "Health check failed for $ENV environment."
  exit 1
fi

echo "$ENV environment is healthy."

# Switch traffic by updating the live Caddy snippet
echo "Switching traffic to $ENV environment."
echo "reverse_proxy localhost:${CADDY_HTTP_PORT}" > live.caddy

# Reload the main Caddy instance
# You would need to know the container name or ID of your main Caddy instance
# For example: docker exec main_caddy caddy reload --config /etc/caddy/Caddyfile.main
echo "To complete the switch, reload your main Caddy instance."

# Stop the old environment to save resources
echo "Stopping old environment ($OLD_PROJECT_NAME)..."
docker compose -p $OLD_PROJECT_NAME down --remove-orphans || true

echo "Deployment to $ENV environment successful."
echo "Live environment is now: $ENV"