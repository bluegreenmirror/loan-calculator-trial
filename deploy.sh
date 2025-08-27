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
  make verify
  docker compose build --pull
fi

# Start or update containers
DockerComposeUpOutput=$(docker compose up -d 2>&1) || {
  echo "$DockerComposeUpOutput";
  exit 1;
}

if [ $PRUNE -eq 1 ]; then
  docker image prune -f
fi

echo "Deployed. Checking health..."
sleep 2
domain=$(grep ^DOMAIN .env | cut -d= -f2)
status=$(curl -Is https://$domain | head -n 1 | sed 's/\r$//')
echo "$status"
