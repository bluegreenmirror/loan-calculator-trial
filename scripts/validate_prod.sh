#!/usr/bin/env bash
set -euo pipefail

if [ ! -f .env ]; then
  echo "Missing .env" >&2
  exit 1
fi

set -a
source .env
set +a

APEX_HOST=${APEX_HOST:-${DOMAIN:-}}
WWW_HOST=${WWW_HOST:-}

if [[ -z "$APEX_HOST" || -z "$WWW_HOST" ]]; then
  echo "APEX_HOST and WWW_HOST are required (via .env)" >&2
  exit 1
fi

echo "[validate-prod] Apex/WWW/TLS checks for $APEX_HOST / $WWW_HOST"
bash scripts/validate_caddy_prod.sh

echo "[validate-prod] API health over HTTPS"
resp=$(curl -fsS "https://$APEX_HOST/api/health" || true)
echo "$resp" | grep -Eq '"ok"\s*:\s*true' || { echo "Unexpected API health response: $resp" >&2; exit 1; }
echo "[validate-prod] OK: production site reachable and API healthy"
