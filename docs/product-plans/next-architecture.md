# ARCHITECTURE.md

## Overview

Three services via Docker Compose:

- `caddy`: reverse proxy and TLS, serves `web` and proxies `/api/*` to `api`.
- `web`: static files (calculator UI).
- `api`: FastAPI application.

## Networking

- Internal Docker network `edge-net` for blue/green stacks.
- Public ports: 80/443 on `edge` Caddy.

## Blue/Green

- Live color behind `edge` Caddy, standby color pre-warmed.
- Deploy `blue`, validate, then switch to `green` (or vice versa).

## Persistence

- Dev: JSON files in `/data` volume for `leads.json` and `tracks.json`.
- Prod: Postgres (Neon/Supabase/ElephantSQL). See `DATA_MODEL.md`.

## Observability

- Access logs at proxy and API.
- Minimal metrics counters with labels by vehicle_type and affiliate.
