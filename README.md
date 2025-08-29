# Vehicle Loan Calculator

Jump‑start your next ride with a fast, responsive vehicle loan payment calculator for autos, RVs, motorcycles, and jet skis — complete with lead‑gen and affiliate tracking. Fully containerized, tuned for growth, and ready to deploy. Calculate, compare, and cruise toward your dream vehicle today!

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
git clone https://github.com/bluegreenmirror/loan-calculator-trial
cd loan-calculator-trial

# Set environment for local dev
cp .env.example .env
# Edit DOMAIN and EMAIL in .env

# Run the stack
./deploy.sh --build

# Open https://$DOMAIN
```

Set `DOMAIN` to your hostname and `EMAIL` to the address used for Let's Encrypt certificates.

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

## Front‑end

- Modular static assets in `web/dist` (`index.html`, `style.css`, `app.js`)
- Footer links to legal pages (`privacy.html`, `terms.html`)
- The lead form (to be added) will auto-capture `affiliate`/UTM parameters from the page URL and submit them with the lead payload.
- Vehicle type dropdown (Auto, RV, Motorcycle, Jet Ski) updates APR and term presets.

## Environment variables

All settings live in `.env`:

| var             | dev                 | prod                  | note                         |
| --------------- | ------------------- | --------------------- | ---------------------------- |
| `DOMAIN`        | `example.com`       | your domain           | Used by deploy script        |
| `EMAIL`         | `admin@example.com` | admin@yourdomain      | Let's Encrypt contact        |
| `ADDR`          | `:80`               | `${DOMAIN}`           | Caddy site address           |
| `TLS_DIRECTIVE` | _(empty)_           | `tls ${EMAIL}`        | Enables HTTPS in prod        |
| `PERSIST_DIR`   | `/data`             | `/data` or custom dir | Persisted lead/track storage |

## CORS configuration

The API exposes configuration for cross‑origin requests via the `ALLOWED_ORIGINS` environment variable. Set this to a comma‑separated list of origins that are permitted to access the API (for example,

`ALLOWED_ORIGINS="https://example.com,http://localhost:8080"`).

If `ALLOWED_ORIGINS` is not provided, cross‑origin requests will be blocked by default to reduce the risk of malicious sites interacting with the service.

## Deploying

Any Docker‑friendly host (Render, Railway, Fly.io, ECS, etc.) will work.

Merges to `main` trigger a GitHub Actions workflow that writes a `.env` from repository secrets, runs `scripts/check-env.sh` to validate required keys, executes `./deploy.sh --build --pull`, and then calls `scripts/health-check.sh` to curl the root site and `/api/health`. Configure secrets `DOMAIN`, `EMAIL`, `APEX_HOST`, and `WWW_HOST` beforehand.

For a step‑by‑step server guide (Ubuntu/Debian), see `docs/SERVER_SETUP.md`.

Server setup (Ubuntu/Debian):

```bash
# One‑time: copy env and set values
cp .env.example .env
sed -i 's/example.com/your-domain.tld/' .env
sed -i 's/admin@example.com/you@your-domain.tld/' .env

# Optional: bootstrap server prerequisites (Docker, Compose, make, Python venv)
./deploy.sh --bootstrap

# Build and deploy (skips linters/tests by default on servers)
./deploy.sh --build --pull

# To include linters/tests on the server, add --verify
./deploy.sh --build --pull --verify
```

Notes:

- `--verify` runs `make verify` which uses a Python virtualenv and dev tools. The script will create `.venv` and install from `requirements-dev.txt` when `--verify` is provided.
- If Docker requires sudo on first run, the script falls back to `sudo docker`. After bootstrapping, log out and log back in (or run `newgrp docker`).

Manual health check after deploy:

```bash
curl -I http://$(grep ^DOMAIN .env | cut -d= -f2)
```

## Testing

Run linting and the test suite locally before building.

```bash
pip install -r requirements-dev.txt
make verify  # or `make test` to run tests only
```

`deploy.sh --build` automatically runs `make verify`.

### External checks

Some tests depend on external services (for example, an already running Caddy on your machine). These are disabled by default and can be enabled explicitly:

```bash
# Run everything, including external checks
pytest --run-external

# Optional: point the Caddy health check at a custom URL
CADDY_HEALTH_URL=http://localhost:8080 pytest --run-external

# Run only fast, hermetic tests (default behavior)
pytest -k 'not external'

## Releases & Rollback

- Tag a release:
  - `make release-tag VERSION=v0.1.0 VERIFY=1 PUSH=1`
    - Creates an annotated git tag (runs linters/tests if `VERIFY=1`) and pushes it if `PUSH=1`.

- Deploy a specific version (on server):
  - `git checkout v0.1.0 && ./deploy.sh -b --verify`

- Roll back to a previous version (scripted):
  - `make rollback REF=v0.1.0 BUILD=1 VERIFY=1 YES=1`
    - Checks out the ref and redeploys via `deploy.sh`.

Notes:
- Ensure `.env` is present on the server with your production values before deploying.
- If you prefer image-based releases, configure your container registry and extend the scripts to build/push images per tag.
```

## Linting & Formatting

- Tools: `ruff` (Python), `black` (Python), `mypy` with the `pydantic.mypy` plugin, `yamllint` (YAML), `mdformat` (Markdown).

- Local usage:

  ```bash
  # Install tools (one-time)
  pip install -r requirements-dev.txt || pip install ruff black mypy yamllint mdformat mdformat-gfm pre-commit

  # Install git hooks
  pre-commit install

  # Check everything
  make lint
  pre-commit run --all-files

  # Auto-format Python and Markdown
  make format
  ```

- Build-time check via Docker:

  ```bash
  # Runs all linters at image build; fails on issues
  docker compose build lint
  # or
  make lint-docker
  ```

- Caddyfile validation:

  - `make lint-caddy` validates the `Caddyfile` using the official `caddy:2.8` image. It loads environment variables from `.env` if present, otherwise falls back to `.env.example`. This allows CI to validate without requiring secrets. Ensure `ADDR` and `TLS_DIRECTIVE` are present in one of these files when running locally.

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
├─ deploy.sh           # build + deploy script
├─ .env.example        # sample configuration
└─ docs/
   ├─ PRD.md           # Product requirements
   ├─ agents.md        # Automation guidelines
   └─ CONTRIBUTING.md  # Contribution guide
```

## Roadmap

- Add lead form to front‑end and connect to `/api/leads`.
- Add JS to record affiliate clicks via `/api/track`.
- Support additional asset classes (boats, heavy equipment).
- Provide dealership analytics and export functionality.

## Contributing

See `CONTRIBUTING.md` for commit conventions and setup. See `AGENTS.md` if you’re using automation to generate PRs.
