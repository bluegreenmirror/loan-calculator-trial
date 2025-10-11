#!/usr/bin/env bash
set -euo pipefail

echo "==> Python linters and tests"
if command -v uv >/dev/null 2>&1; then
  PY_PREFIX="UV_PROJECT_ENVIRONMENT=.venv uv run --python 3.12 --with-requirements requirements-dev.txt"
else
  if [ -d .venv ]; then
    PY_PREFIX=". .venv/bin/activate &&"
  else
    PY_PREFIX=""
  fi
fi

run(){ echo "+ $*"; eval "$*"; }

run "${PY_PREFIX:+$PY_PREFIX }ruff check api"
run "${PY_PREFIX:+$PY_PREFIX }black --check api"
run "${PY_PREFIX:+$PY_PREFIX }yamllint -s ."
run "${PY_PREFIX:+$PY_PREFIX }mdformat --check README.md docs"
run "${PY_PREFIX:+$PY_PREFIX }pytest -q"

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

