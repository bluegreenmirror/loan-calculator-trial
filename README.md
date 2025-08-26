# Loan Calculator

Fast, responsive loan payment calculator for autos, RVs, motorcycles, and jet skis — with lead‑gen and affiliate tracking. Fully containerized and ready to deploy.

## Features
- ⚡️ **Instant calculator**: monthly payment, amount financed, total cost, total interest.
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
# Dev (no TLS):
# ADDR=http://localhost
# AUTO_HTTPS=auto_https off
# TLS_DIRECTIVE=
# HSTS_LINE=

# Run the stack
./deploy.sh --build

# Open http://localhost
```

For production, set `ADDR=${DOMAIN}`, `TLS_DIRECTIVE=tls ${EMAIL}`, and remove `AUTO_HTTPS` and `HSTS_LINE` from `.env`.

## API
Base URL in dev: `http://localhost`

- **Health**
  ```bash
  curl -s http://localhost/api/health
  ```
- **Quote**
  ```bash
  curl -s http://localhost/api/quote -X POST -H 'content-type: application/json' \
    -d '{"vehicle_price":35000,"down_payment":3000,"apr":6.9,"term_months":60,"tax_rate":0.095,"fees":495,"trade_in_value":0}'
  ```
- **Leads**
  ```bash
  curl -s http://localhost/api/leads -X POST -H 'content-type: application/json' \
    -d '{"name":"Jane Doe","email":"jane@example.com","phone":"415-555-1212","vehicle_type":"rv","price":75000,"affiliate":"partnerX"}'
  ```
- **Affiliate tracking** (future)
  ```bash
  curl -s "http://localhost/api/track?affiliate=partnerX"
  ```

## Front‑end
- Modular static assets in `web/dist` (`index.html`, `style.css`, `app.js`)
- Footer links to legal pages (`privacy.html`, `terms.html`)
- The lead form (to be added) will auto-capture `affiliate`/UTM parameters from the page URL and submit them with the lead payload.
- Calculator presets update APR and term per vehicle type.

## Environment variables
All settings live in `.env`:

| var              | dev                  | prod                    | note                                |
|------------------|----------------------|-------------------------|--------------------------------------|
| `ADDR`           | `http://localhost`   | `${DOMAIN}`             | Caddy site address                  |
| `AUTO_HTTPS`     | `auto_https off`     | *(unset)*               | disable TLS in dev                  |
| `TLS_DIRECTIVE`  | *(unset)*            | `tls ${EMAIL}`          | prod TLS via Let’s Encrypt          |
| `HSTS_LINE`      | *(unset)*            | `Strict-Transport-Security "max-age=31536000; includeSubDomains; preload"` | HSTS only in prod  |
| `DOMAIN`         | *(optional)*         | your domain             | used by Caddy TLS                   |
| `EMAIL`          | *(optional)*         | admin@yourdomain        | used by Caddy TLS                   |

## CORS configuration

The API exposes configuration for cross‑origin requests via the `ALLOWED_ORIGINS` environment variable. Set this to a comma‑separated list of origins that are permitted to access the API (for example,

`ALLOWED_ORIGINS="https://example.com,http://localhost:8080"`).

If `ALLOWED_ORIGINS` is not provided, cross‑origin requests will be blocked by default to reduce the risk of malicious sites interacting with the service.

## Deploying
Any Docker‑friendly host (Render, Railway, Fly.io, ECS, etc.) will work.

1. Point DNS to your server.
2. In `.env`, set:
   ```
   ADDR=${DOMAIN}
   TLS_DIRECTIVE=tls ${EMAIL}
   ```
   and remove `AUTO_HTTPS` and `HSTS_LINE`.
3. Run `./deploy.sh --build`.

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
- Add `/api/track` endpoint and JS to record affiliate clicks.
- Support additional asset classes (boats, heavy equipment).
- Provide dealership analytics and export functionality.
=======
## API endpoints

- `GET /api/health` – service health check.
- `POST /api/quote` – compute financing details.
- `POST /api/leads` – store submitted leads.
- `POST /api/track` – log affiliate clicks with a timestamp.

## Affiliate tracking

The frontend captures `aff` and common UTM query parameters. When an affiliate ID
is present it is sent to the backend `/api/track` endpoint and stored in
`localStorage` for later use.

## Contributing
See `CONTRIBUTING.md` for commit conventions and setup. See `docs/agents.md` if you’re using automation to generate PRs.
