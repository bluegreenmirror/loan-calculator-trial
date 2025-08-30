# Contributing Guide

We welcome contributions from developers, product thinkers, and automation agents. Please read this guide before making changes.

## Getting Started

1. Fork the repository.
1. Clone locally and create a branch from `main`:
   ```bash
   git checkout -b feature/your-feature
   ```
1. Copy `.env.example` to `.env` and adjust for dev:
   ```bash
   cp .env.example .env
   ```
1. Set up Python venv and development tools (one-time):
   ```bash
   python3 -m venv .venv
   source .venv/bin/activate
   pip install -r requirements-dev.txt
   pre-commit install
   ```
1. Run the stack:
   ```bash
   ./deploy.sh --build
   ```
1. Open http://localhost to test.

## Commit Style

We follow Conventional Commits:

- feat: new features
- fix: bug fixes
- chore: config or non-feature tasks
- docs: documentation

## Example

> feat(api): add /api/leads endpoint

## Pull Requests

- Keep PRs atomic (small and focused).
- Include description and test plan.
- Reference related issues if any.

## Code Style

- Python: PEP8 + type hints.
- HTML/JS: Prettier defaults, semantic HTML.
- YAML: 2-space indentation
- Always run `make lint` before committing and fix any issues.
- Run `make format` to apply formatters to touched files.
- You can also use `pre-commit run --all-files` locally.

## Required checks (humans and agents)

- `make lint` must pass (Python, YAML, Markdown, Caddyfile).
- For API changes: add/adjust tests and include curl examples in the PR.

## Environment

- Use `.env.example` for reference, never commit real secrets.
- Dev mode: set `DOMAIN=localhost` and `EMAIL=admin@example.com`.
- Prod mode: real domain with TLS.

## Testing

- Backend: test with curl requests.
- Frontend: load http://localhost and verify calculator + lead form.

## Issues

- Use GitHub Issues for bugs/feature requests.
- Good first issues will be labeled.
