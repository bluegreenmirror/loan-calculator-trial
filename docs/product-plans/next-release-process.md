# RELEASE_PROCESS.md

## Environments

- Local: Docker Compose with `.env.example`
- Prod: Single VM with edge Caddy and blue/green stacks.

## Blue/Green Procedure

1. Build and push images with git SHA tags.
1. Deploy to inactive color: `./deploy.sh blue` or `green`.
1. Run smoke tests: `make validate-prod`.
1. Flip edge Caddy upstream to the new color.
1. Monitor logs and metrics for 30 minutes.
1. Rollback: flip back to previous color if errors exceed SLO.

## Validation Gates

- `/api/health` returns ok.
- Home page returns 200 and contains title.
- `/api/quote` round-trip within 100 ms locally.

## CI/CD

- On PR: run lint, unit tests, build images.
- On main: build images, deploy with manual approval gate.
