# TEST_PLAN.md

## Scope

- API unit tests (FastAPI routes, validators).
- Calculator math correctness tests.
- Integration: Caddy proxy routing `/api/*` and static assets.
- E2E: Headless browser checks form submission and lead persistence.
- Performance: Locust or k6 smoke at 50 RPS for `/api/quote`.

## CI Jobs

- `make verify` runs ruff/black/mypy/pytest.
- Dockerized lint: `docker compose --profile dev build lint`.

## Manual Checks

- Blue/green switch test in staging.
- SSL validity and HSTS header check.
