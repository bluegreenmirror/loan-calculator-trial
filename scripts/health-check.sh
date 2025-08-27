#!/usr/bin/env bash
set -euo pipefail

if [ ! -f .env ]; then
  echo "Missing .env" >&2
  exit 1
fi

set -a
source .env
set +a

check_url() {
  url="$1"
  code=$(curl -s -o /dev/null -w "%{http_code}" "$url")
  echo "$url -> $code"
  if [[ $code -ge 500 ]]; then
    echo "Health check failed for $url" >&2
    exit 1
  fi
}

check_url "https://${APEX_HOST}/api/health"
check_url "http://${APEX_HOST}/api/health"
check_url "https://${WWW_HOST}/"
check_url "http://${WWW_HOST}/"
