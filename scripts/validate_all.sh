#!/usr/bin/env bash
set -euo pipefail

echo "==> Python linters and tests"
if [ -d .venv ]; then
  VENV_ACTIVATE=". .venv/bin/activate"
else
  VENV_ACTIVATE=":"
fi

run(){ echo "+ $*"; eval "$*"; }

run "$VENV_ACTIVATE; ruff check api"
run "$VENV_ACTIVATE; black --check api"
run "$VENV_ACTIVATE; yamllint -s ."
run "$VENV_ACTIVATE; mdformat --check README.md docs"
run "$VENV_ACTIVATE; pytest -q"

echo "==> Caddyfile validation (best-effort)"
if command -v docker >/dev/null 2>&1; then
  # Validate edge Caddyfile.main (imports live.caddy); pass envs from .env if present
  if [ -f .env ]; then ENV_FLAG="--env-file .env"; else ENV_FLAG=""; fi
  run "docker run --rm $ENV_FLAG -e API_UPSTREAM=api:8000 -v $(pwd):/etc/caddy:ro caddy:2.8 caddy validate --config /etc/caddy/Caddyfile.main"
  # Validate app Caddyfile used by color stacks
  run "docker run --rm -e API_UPSTREAM=api:8000 -v $(pwd)/Caddyfile:/etc/caddy/Caddyfile:ro caddy:2.8 caddy validate --config /etc/caddy/Caddyfile"
else
  echo "(skip) Docker not available; skipping Caddyfile validation"
fi

echo "All validations completed."

