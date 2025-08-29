#!/usr/bin/env bash
set -euo pipefail

REQUIRED_VARS=(APEX_HOST WWW_HOST EMAIL)

if [[ ! -f .env ]]; then
  echo "Missing .env" >&2
  exit 1
fi

missing=()
templated=()

for var in "${REQUIRED_VARS[@]}"; do
  if ! grep -q "^${var}=" .env; then
    missing+=("$var")
    continue
  fi
  value=$(grep "^${var}=" .env | cut -d= -f2-)
  if [[ -z "$value" ]]; then
    missing+=("$var")
  elif [[ "$value" == *"\${"* ]]; then
    templated+=("$var")
  fi
done

if [[ ${#missing[@]} -gt 0 ]]; then
  echo "Missing required variables: ${missing[*]}" >&2
fi
if [[ ${#templated[@]} -gt 0 ]]; then
  echo "Templated values found for: ${templated[*]}" >&2
fi
if [[ ${#missing[@]} -gt 0 || ${#templated[@]} -gt 0 ]]; then
  exit 1
fi
