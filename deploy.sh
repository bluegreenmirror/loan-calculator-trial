#!/usr/bin/env bash
set -euo pipefail

BUILD=0; PULL=0; PRUNE=0
for arg in "$@"; do
  case "$arg" in
    -b|--build) BUILD=1 ;;
    --pull)     PULL=1 ;;
    --prune)    PRUNE=1 ;;
  esac
done

if [ ! -f ".env" ]; then
  echo "Missing .env. Create it with DOMAIN and EMAIL."; exit 1
fi

if [ $PULL -eq 1 ]; then
  docker compose pull
fi

if [ $BUILD -eq 1 ]; then
  docker compose build --pull
fi

# Start or update containers first so Caddy is up for tests
DockerComposeUpOutput=$(docker compose up -d 2>&1) || {
  echo "$DockerComposeUpOutput";
  exit 1;
}

domain=$(grep ^DOMAIN .env | cut -d= -f2)
echo "Waiting for Caddy at http://$domain ..."
for i in {1..20}; do
  if curl -sSf -o /dev/null http://$domain; then
    echo "Caddy is up."
    break
  fi
  sleep 1
done

# Run lint and tests after services are up so Caddy health test passes
make verify

if [ $PRUNE -eq 1 ]; then
  docker image prune -f
fi

echo "Health:"
status=$(curl -Is http://$domain | head -n 1 | sed 's/\r$//')
echo "$status"

