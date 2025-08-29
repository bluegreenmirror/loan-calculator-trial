#!/usr/bin/env bash
set -euo pipefail

# Release build: build only runtime images (api, web)
make build-release

