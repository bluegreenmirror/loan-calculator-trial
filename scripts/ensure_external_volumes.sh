#!/usr/bin/env bash
set -euo pipefail

# Ensure required external Docker volumes (and network) exist.
# This script is idempotent and safe to run multiple times.

ensure_volume() {
  local volume=$1
  if docker volume inspect "$volume" >/dev/null 2>&1; then
    echo "Volume '$volume' already exists."
  else
    echo "Creating volume '$volume'."
    docker volume create "$volume" >/dev/null
  fi
}

ensure_network() {
  local network=$1
  if docker network inspect "$network" >/dev/null 2>&1; then
    echo "Network '$network' already exists."
  else
    echo "Creating network '$network'."
    docker network create "$network" >/dev/null
  fi
}

ensure_network edge-net
ensure_volume edge_caddy_data
ensure_volume app_data

echo "External Docker resources are ready."
