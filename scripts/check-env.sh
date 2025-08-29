#!/usr/bin/env bash
set -euo pipefail

if [ ! -f .env ]; then
  echo "Missing .env" >&2
  exit 1
fi

required_vars=(APEX_HOST WWW_HOST EMAIL ALLOWED_ORIGINS)
missing=0

for var in "${required_vars[@]}"; do
  if ! grep -q "^${var}=" .env; then
    echo "Missing $var in .env" >&2
    missing=1
    continue
  fi
  value=$(grep "^${var}=" .env | head -n1 | cut -d= -f2-)
  if [[ -z "$value" || "$value" == *"\${"* ]]; then
    echo "$var is unset or templated ($value)" >&2
    missing=1
  fi

done

if [[ $missing -ne 0 ]]; then
  echo ".env sanity check failed" >&2
  exit 1
fi

echo ".env sanity check passed."
