# Server Setup

This guide covers preparing a fresh Ubuntu/Debian server and deploying the
stack using the provided `deploy.sh` script with blue/green.

## Prerequisites

- A domain pointing to your server (`A`/`AAAA` DNS records).

- A copy of the repo on the server and a configured `.env`:

  ```bash
  cp .env.example .env
  # Edit DOMAIN and EMAIL to match your setup
  ```

## Bootstrap the server (one time)

Install Docker Engine, the Compose plugin, and add your user to the `docker`
group. Refer to the official Docker docs for your distro.

## Deploy (blue/green)

`deploy.sh` supports two colors: `blue` and `green`. It builds and brings up
the specified color, health-checks it internally, then points the `edge` Caddy
at the new color. If the edge check fails, it reverts to the previous color.

Steps:

```bash
# One-time infra
docker network create edge-net || true
docker volume create edge_caddy_data || true

# Deploy blue
./deploy.sh blue

# Deploy green on next release
./deploy.sh green
```

## Verification

After a cutover, run production validation:

```bash
make validate-prod
```

This validates apex/www redirects, TLS, and `/api/health` over HTTPS. See
`scripts/validate_prod.sh` and `scripts/validate_caddy_prod.sh` for details.

## Environment variables

Key variables in `.env`:

- `DOMAIN`: your domain (used by Caddy and health checks)
- `EMAIL`: Let’s Encrypt contact (for TLS in production)
- `ADDR`: `:80` for local HTTP, `${DOMAIN}` for production
- `TLS_DIRECTIVE`: empty for local; `tls ${EMAIL}` in production

Example production values:

```env
ADDR=${DOMAIN}
TLS_DIRECTIVE=tls ${EMAIL}
```

## Troubleshooting

- Permission denied running docker:
  - Ensure you ran `./deploy.sh --bootstrap` and then re-login or `newgrp docker`.
- Caddyfile validation fails in CI due to missing `.env`:
  - The Makefile uses `.env` or `.env.example`; ensure `.env.example` contains
    the placeholders used by `Caddyfile`.
- `make: command not found` on server:
  - Install via your package manager, e.g. `sudo apt-get install -y make`.
- Health check shows non-200:
  - Confirm DNS points to the server and ports 80/443 are open in your firewall.

## Security notes

- Do not commit secrets. Use `.env` locally and provider secrets in CI.
- Keep servers minimal: prefer Option 2 for deploys; rely on CI for code checks.
- Regularly update Docker base images and rotate credentials.
