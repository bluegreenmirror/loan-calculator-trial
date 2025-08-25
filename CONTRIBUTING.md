# Contributing Guide

We welcome contributions from developers, product thinkers, and automation agents. Please read this guide before making changes.

## Getting Started
1. Fork the repository.
2. Clone locally and create a branch from `main`:
   ```bash
   git checkout -b feature/your-feature
   ```
3.	Copy .env.example to .env and adjust for dev:
   ```bash
   cp .env.example .env
   ```
4. Run the stack
   ```bash
   ./deploy.sh --build
   ```
5. Open http://localhost to test.

## Commit Style

We follow Conventional Commits:
- feat: new features
- fix: bug fixes
- chore: config or non-feature tasks
- docs: documentation

## Example
>feat(api): add /api/leads endpoint

## Pull Requests
- Keep PRs atomic (small and focused).
- Include description and test plan.
- Reference related issues if any.

## Code Style
- Python: PEP8 + type hints.
- HTML/JS: Prettier defaults, semantic HTML.
- YAML: 2-space indentation 

## Environment
- Use .env.example for reference, never commit real secre- 
- Dev mode: ADDR=http://localhost, auto_https off.
- Prod mode: real domain with TLS.

## Testing
- Backend: test with curl requests.
- Frontend: load http://localhost and verify calculator + lead form.

## Issues
- Use GitHub Issues for bugs/feature requests.
- Good first issues will be labeled.
