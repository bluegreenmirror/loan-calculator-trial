# Vehicle Loan Calculator

Jump‑start your next ride with a fast, responsive vehicle loan payment calculator for autos, RVs, motorcycles, and jet skis — complete with lead‑gen and affiliate tracking. Fully containerized, tuned for growth, and ready to deploy. Calculate, compare, and cruise toward your dream vehicle today!

## Features

- ⚡️ **Instant calculator**: monthly payment, amount financed, total cost, total interest.
- 📊 **Cost breakdown chart**: smooth 3D pie chart with a CSS bounce effect highlighting principal vs interest, with the legend displayed outside the chart.
- 🚘 **Presets**: Auto, RV, Motorcycle, Jet Ski.
- 👨‍⚖️ **Lead capture**: name/email/phone (+ affiliate/UTM captured automatically).
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
    -d '{"name":"Jane Doe","email":"jane@example.com","phone":"415-555-1212","vehicle_type":"rv","price":75000,"affiliate":"partnerX"}'
  ```
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

| var | dev | prod | note |
| --- | --- | ---- | ---- |
| `DOMAIN` | `localhost` | your domain | Caddy site address |
| `EMAIL` | `admin@example.com` | admin@yourdomain | Let's Encrypt contact |

## CORS configuration

The API exposes configuration for cross‑origin requests via the `ALLOWED_ORIGINS` environment variable. Set this to a comma‑separated list of origins that are permitted to access the API (for example,

`ALLOWED_ORIGINS="https://example.com,http://localhost:8080"`).

If `ALLOWED_ORIGINS` is not provided, cross‑origin requests will be blocked by default to reduce the risk of malicious sites interacting with the service.

## Deploying

Any Docker‑friendly host (Render, Railway, Fly.io, ECS, etc.) will work.

1. Point DNS to your server.
1. Set `DOMAIN` and `EMAIL` in `.env`.
1. Run `./deploy.sh --build`.

## Linting & Formatting

- Tools: `ruff` (Python), `black` (Python), `yamllint` (YAML), `mdformat` (Markdown).
- Local usage:
  ```bash
  # Install tools (one-time)
  pip install -r requirements-dev.txt || pip install ruff black yamllint mdformat mdformat-gfm

  # Check everything
  make lint

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

## Repository layout

```
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
