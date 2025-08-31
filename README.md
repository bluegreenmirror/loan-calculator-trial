# Vehicle Loan Calculator

Jump-start your next ride with a fast, responsive vehicle loan payment calculator for autos, RVs, motorcycles, and jet skis — complete with lead-gen and affiliate tracking. Fully containerized, tuned for growth, and ready to deploy. Calculate, compare, and cruise toward your dream vehicle today!

> **Note:** This project is for demo purposes only as of Aug 25, 2025 and may not result in offers or responses.

## Features

- ⚡️ **Instant calculator**: monthly payment, amount financed, total cost, total interest.
- 📊 **Cost breakdown chart**: flat pie chart sized between 200–260px with generous side and canvas padding, highlighting principal vs interest; tooltips float outside each slice and the caret points back at the chart without getting cut off, with the legend beside it.
- 🎰 **Rolling digits**: payment amounts animate with fast, smooth scrolling numbers.
- 🚘 **Presets**: Auto, RV, Motorcycle, Jet Ski.
- 👨‍⚖️ **Lead capture**: name/email/phone validated and persisted (+ affiliate/UTM captured automatically).
- 🤝 **Affiliate tracking**: records click metadata; passthrough to form.
- 💐 **API for dealerships**: compute quotes, accept leads.
- 👨‍⚖️ **Dockerized**: Caddy (TLS), FastAPI, static web.
- 🤓 **Dev/Prod toggles**: via `.env` + Caddyfile placeholders.

## Quick Start

```bash
# Clone the repo
git clone https://github.com/bluegreenmirror/loan-calculator-internal
cd loan-calculator-internal

# Local dev (HTTP on localhost)
cp .env.example .env   # no secrets; keep TLS vars empty for dev

# One-time Python toolchain (venv) for lint/tests
python3 -m venv .venv
source .venv/bin/activate
pip install -r requirements-dev.txt

# Bring up local stack and validate via edge proxy
make validate-local     # uses Docker; serves http://localhost

# Alternative: lint + tests only (no running stack)
make verify
```

## API

Base URL in dev: `http://localhost`

- Health:

  ```bash
  curl -s http://localhost/api/health
  ```

- Quote (POST JSON):

  ```bash
  curl -s http://localhost/api/quote -X POST -H 'content-type: application/json' \
    -d '{"vehicle_price":35000,"down_payment":3000,"apr":6.9,"term_months":60,"tax_rate":0.095,"fees":495,"trade_in_value":0}'
  ```

- Leads (POST JSON):

  ```bash
  curl -s http://localhost/api/leads -X POST -H 'content-type: application/json' \
    -d '{"name":"Jane Doe","email":"jane@example.com","phone":"+14155551212","vehicle_type":"rv","price":75000,"affiliate":"partnerX"}'
  ```

Leads are stored in `leads.json` and tracking events in `tracks.json`, both inside `PERSIST_DIR` (default `/data`). Lead names must be non-empty and phone numbers (if provided) must include 10–15 digits with an optional leading `+`. Affiliate identifiers must not be empty. Invalid submissions are rejected and not written to disk.

- Affiliate tracking (POST JSON):

  ```bash
  curl -s http://localhost/api/track -X POST -H 'content-type: application/json' \
    -d '{"affiliate":"partnerX"}'
  ```

- Affiliate tracking with UTMs (POST JSON):

  ```bash
  curl -s http://localhost/api/track -X POST -H 'content-type: application/json' \
    -d '{
      "affiliate": "partnerX",
      "utm_source": "newsletter",
      "utm_medium": "email",
      "utm_campaign": "summer-2025",
      "utm_term": "low-apr",
      "utm_content": "cta-button"
    }'
  ```

## Local Development

- Prerequisites: Docker Desktop (or Docker Engine + compose plugin) running.
- `make validate-local` will:
  - Create shared Docker network/volume if missing.
  - Build and start a color stack (`loancalc-blue` by default).
  - Point the `edge` Caddy to that stack without modifying repo files.
  - Verify the site root and `/api/health` through `http://localhost`.

If you prefer manual compose:

```bash
docker network create edge-net || true
docker volume create edge_caddy_data || true
PROJECT_NAME=loancalc-blue docker compose -p loancalc-blue up -d --build caddy api web
docker compose -p edge up -d edge
curl -s http://localhost/api/health
```

## Deployment

This project supports blue‑green deployment to minimize downtime. See [Release Process](RELEASE_PROCESS.md) for full details. Quick reference:

- Production prerequisites:

  - `.env` has: `DOMAIN`, `APEX_HOST`, `WWW_HOST`, `EMAIL`, and `TLS_DIRECTIVE=tls ${EMAIL}`.
  - One‑time infra: `docker network create edge-net` and `docker volume create edge_caddy_data`.
  - Cloudflare (if used): SSL/TLS mode “Full” or “Full (strict)”, apex/www DNS → server IP.
  - Never commit a real `.env`. Keep only `.env.example` in git and generate `.env` in CI/CD or locally.

- Deploy and validate:

  - Deploy blue: `./deploy.sh blue`
  - Validate prod: `make validate-prod`
  - Switch to green: `./deploy.sh green`
  - Shut down inactive color:
    - If live is green: `docker compose -p loancalc-blue down --remove-orphans`
    - If live is blue: `docker compose -p loancalc-green down --remove-orphans`

Notes:

- `deploy.sh` reads `.env` for `APEX_HOST`/`WWW_HOST`/`DOMAIN`. For live verification it prefers `APEX_HOST`, then `DOMAIN`, and falls back to `localhost` in dev.

- Local validation:

  - `make validate-local` brings up a color stack, points edge to it, and verifies:
    - `http://localhost` returns HTML
    - `http://localhost/api/health` returns `{ "ok": true }`

## Testing

Run linting and the test suite locally before building. For fast, hermetic tests (no Docker), run pytest without external checks.

```bash
pip install -r requirements-dev.txt
make verify  # or `make test` to run tests only
```

### External checks

Some tests depend on external services (for example, an already running Caddy on your machine). These are disabled by default and can be enabled explicitly:

```bash
# Run everything, including external checks
pytest --run-external

# Optional: point the Caddy health check at a custom URL
CADDY_HEALTH_URL=http://localhost:8080 pytest --run-external

# Run only fast, hermetic tests (default behavior)
pytest -k 'not external'
```

## Linting & Formatting

- Tools: `ruff` (Python), `black` (Python), `mypy` with the `pydantic.mypy` plugin, `yamllint` (YAML), `mdformat` (Markdown).

- Local usage (requires venv):

  ```bash
  # One-time setup (in repo root)
  python3 -m venv .venv
  source .venv/bin/activate
  pip install -r requirements-dev.txt

  # Install git hooks
  pre-commit install

  # Check everything
  make lint
  pre-commit run --all-files

  # Auto-format Python and Markdown
  make format
  ```

- Notes:

  - The Makefile runs tools from `.venv/bin/...`. Ensure you installed into `.venv` as above. If you open a new shell, re-activate with `source .venv/bin/activate`.

- Build-time check via Docker:

  ```bash
  # Runs all linters at image build; fails on issues
  docker compose --profile dev build lint
  # or
  make lint-docker
  ```

- Caddyfile validation:

  - `make lint-caddy` validates the `Caddyfile` using the official `caddy:2.8` image. It loads environment variables from `.env` if present, otherwise falls back to `.env.example`. This allows CI to validate without requiring secrets. Ensure `ADDR`, `TLS_DIRECTIVE`, and `API_UPSTREAM` are present in one of these files when running locally.

## Continuous Integration

Pull requests trigger GitHub Actions to run linters and build all Docker images.

## Repository layout

```md
.
├─ api/
│  ├─ app.py           # FastAPI app (health, quote, leads)
│  └─ Dockerfile
├─ web/
│  ├─ dist/index.html  # responsive calculator (lead form to be added)
│  └─ Dockerfile
├─ Caddyfile           # reverse proxy, TLS (auto in prod)
├─ docker-compose.yml  # orchestrates caddy/web/api
├─ deploy.sh           # blue/green deploy script
├─ .env.example        # sample configuration
├─ AGENTS.md           # Automation guidelines (operating contract)
└─ docs/
   ├─ PRD.md           # Product requirements
   ├─ SERVER_SETUP.md  # Server prep + deploy flow
   └─ CONTRIBUTING.md  # Contribution guide
```

## Roadmap

- Support additional asset classes (boats, heavy equipment).
- Provide dealership analytics and export functionality.
- Persist UTM parameters server‑side (currently stored client‑side only).
- Add CI smoke test that boots the API and curls `/api/health`.

## Contributing

See `CONTRIBUTING.md` for commit conventions and setup. See `AGENTS.md` if you’re using automation to generate PRs.

Before you push (humans and agents):

- Always run `make lint` and fix issues.
- Run `make format` to apply formatters (Python/Markdown/Caddyfile) to touched files.
- Keep PRs atomic; include tests and curl examples for API changes.
