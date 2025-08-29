# Server Setup

This guide covers preparing a fresh Ubuntu/Debian server and deploying the
stack using the provided `deploy.sh` script. It offers two deployment options:

- Option 1: Build with verification (runs linters/tests on server)
- Option 2: Build without verification (faster, minimal server footprint)

Both options result in the same running containers. CI should already enforce
style and tests on pull requests, so most teams prefer Option 2 for servers and
keep verification in CI and local dev.

## Prerequisites

- A domain pointing to your server (`A`/`AAAA` DNS records).
- A copy of the repo on the server and a configured `.env`:

  ```bash
  cp .env.example .env
  # Edit DOMAIN and EMAIL to match your setup
  ```

## Bootstrap the server (one time)

Installs Docker, Compose plugin, `make`, and Python venv tools; adds your user
to the `docker` group.

```bash
./deploy.sh --bootstrap
# Important: re-login or run the following so the docker group applies
newgrp docker
```

## Option 2: Deploy without verification (recommended for servers)

This option keeps production hosts lean and deploys faster by skipping dev-only
tooling (linters, test runners) on the server. CI already runs these checks on
pull requests. You can still run full verification locally and in CI.

Steps:

```bash
# Build images and pull latest base layers
./deploy.sh --build --pull

# Check health
curl -I http://$(grep ^DOMAIN .env | cut -d= -f2)
```

Why choose this option:

- Minimizes packages on production hosts (smaller attack surface).
- Faster deploys and fewer moving parts on the server.
- CI already enforces code quality; duplication on servers is unnecessary.

## Option 1: Deploy with verification on server

Runs `make verify` (ruff, black, yamllint, mdformat, pytest). Requires a Python
virtual environment and dev dependencies.

Steps:

```bash
./deploy.sh --build --pull --verify
```

Notes:

- The script automatically creates `.venv` and installs `requirements-dev.txt`.
- If `docker` needs elevated permissions, the script falls back to `sudo docker`.

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
- `make: command not found` during `--verify`:
  - Install via `./deploy.sh --bootstrap` or `sudo apt-get install -y make`.
- Health check shows non-200:
  - Confirm DNS points to the server and ports 80/443 are open in your firewall.

## Security notes

- Do not commit secrets. Use `.env` locally and provider secrets in CI.
- Keep servers minimal: prefer Option 2 for deploys; rely on CI for code checks.
- Regularly update Docker base images and rotate credentials.

