#!/usr/bin/env bash
set -euo pipefail

# Ensure external Docker resources exist for the first run
bash "$(dirname "$0")/ensure_external_volumes.sh"

# Developer build: run local verification then build all services
make build-dev

