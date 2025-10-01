#!/usr/bin/env bash
set -euo pipefail

if [ ! -f .env ]; then
  echo "Missing .env" >&2
  exit 1
fi

required_vars=(APEX_HOST WWW_HOST EMAIL DOMAIN)
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

project_line=$(grep "^PROJECT_NAME=" .env | head -n1 || true)
if [[ -z "$project_line" ]]; then
  if [ -t 0 ]; then
    read -rp "Enter a project name for docker-compose (PROJECT_NAME) [loancalc]: " project_input
    project_input=${project_input:-loancalc}
    if [[ -z "$project_input" ]]; then
      echo "PROJECT_NAME cannot be empty" >&2
      missing=1
    else
      echo "PROJECT_NAME=$project_input" >> .env
      echo "Added PROJECT_NAME=$project_input to .env"
    fi
  else
    echo "Missing PROJECT_NAME in .env (non-interactive session cannot prompt)" >&2
    missing=1
  fi
else
  project_value=$(echo "$project_line" | cut -d= -f2-)
  if [[ -z "$project_value" || "$project_value" == *"\${"* ]]; then
    echo "PROJECT_NAME is unset or templated ($project_value)" >&2
    missing=1
  fi
fi

if [[ $missing -ne 0 ]]; then
  echo ".env sanity check failed" >&2
  exit 1
fi

echo ".env sanity check passed."
