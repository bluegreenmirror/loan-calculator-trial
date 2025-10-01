# v2 Architecture — Consolidated

## Overview

The platform runs a small, containerized stack fronted by Caddy and exposes a
versioned REST API for calculators, partners, tracking, and leads. v2 focuses on
modular calculators, token‑gated amortization schedules, and a path from local
JSON persistence to Postgres and Cloud SQL in production.

## Services & Networking

- edge (Caddy): public entrypoint; listens on 80/443; blue/green switch.
- caddy: serves static web and reverse proxies `/api/*` → api.
- web: static assets (calculator UI/components).
- api: FastAPI application under `/api/v1/*`.

Networking

- External: `edge` exposes 80/443. Cloudflare proxy in front (Full strict).
- Internal: color stacks on an internal Docker network `edge-net`; edge routes
  to the active color (`<project>-caddy`).

## Environments & Blue/Green

- Dev: localhost over HTTP, no HSTS, `.env.example` values only.
- Staging: mirrors prod with HTTPS and validators.
- Prod: apex + www behind Cloudflare (Full strict). Deploy via blue/green: bring
  up the new color, validate health, then point edge to it. Roll back by
  switching edge back to previous color.

## Hosting & Deployment

- Current baseline: Docker Compose on a VM; Caddy handles TLS and static assets.
- Target option (v2+): Containers on Cloud Run for api/web; Caddy for static and
  edge concerns where applicable. Keep blue/green and health validation in CI/CD.

## Persistence

- Dev MVP: JSON files persisted at `/data` (leads.json, tracks.json).
- v2 database: Postgres via SQLAlchemy + Alembic migrations.
- Production: Google Cloud SQL Postgres (managed). Migrations applied in CI/CD.

## Module Layout (target)

```
api/
  calculators/
    vehicle.py
    mortgage.py
    heloc.py
    personal.py
  partners/
    endpoints.py
web/
  components/
    calculator-widget.js
    partner-cards.js
```

## APIs (summary)

- `GET /api/v1/health` — health probe
- `POST /api/v1/calculators/<type>` — payment + amortization schedule
- `POST /api/v1/leads` — capture lead; returns access token
- `POST /api/v1/track` — affiliate/UTM tracking
- `GET /api/v1/partners` — partner card data

See API_SPEC for request/response details and error codes.

## Lead Token Gating

- `/leads` issues a token; access to amortization schedules/exports requires a
  valid token. Future: optional email verification loop.

## Observability

- Access logs at proxy and API.
- Basic counters segmented by calculator type and affiliate.
- CI smoke tests: `/api/v1/health` and critical calculator/partners endpoints.

## Security & Configuration

- HTTPS in prod, Cloudflare Full (strict).
- No secrets in repo; `.env.example` placeholders only; CI injects secrets.
- CORS restricted to configured origins; input validation on all endpoints.
