#!/usr/bin/env bash
set -euo pipefail

# Ensure external Docker resources exist for the first run
bash "$(dirname "$0")/ensure_external_volumes.sh"

# Release build: build only runtime images (api, web)
make build-release

