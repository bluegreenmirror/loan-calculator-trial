# Agents / Automation Guidelines

This project can be extended or maintained not only by humans but also by AI/automation “agents.” This file defines boundaries and conventions.

## Roles
- **Builder Agent**: Implements features in small, atomic commits.
- **Reviewer Agent**: Ensures PRs follow scope and quality.
- **Deployment Agent**: Handles Docker builds, pushes, and deploy commands.

## Rules
1. **Atomicity**: One PR = one logical change (e.g., add API endpoint, add Dockerfile, update docs).
2. **Branch Naming**: Use `feature/*`, `fix/*`, or `chore/*`.
3. **Commit Messages**: Conventional Commits style (`feat:`, `fix:`, `chore:`, `docs:`).
4. **Documentation**: Every feature PR must include docs or README notes.
5. **Safety**:
   - Never commit secrets to the repo.
   - Never overwrite `.env` in PRs.
   - Use `.env.example` for variable references.
6. **Testing**:
   - Manual curl commands for APIs.
   - Browser test for UI.
   - Linting (Python + YAML + Markdown) — see Lint & Formatting.

## Lint & Formatting
Agents must follow the repository's configured linters/formatters and keep formatting changes scoped.

- Python:
  - Formatter: Black (line-length 88, Python 3.12). Config: `pyproject.toml`.
  - Lint: Ruff (rules: E,F,W,I,UP,B; `E203`/`E501` ignored for Black). Config: `pyproject.toml`.
  - Commands:
    - Format: `make format` (formats Python under `api/`).
    - Lint: `make lint-python` or all linters via `make lint`.

- YAML:
  - Lint: `yamllint` with repo rules. Config: `.yamllint.yaml`.
  - Command: `make lint-yaml`.

- Markdown:
  - Formatter: `mdformat` with GitHub Flavored Markdown and wrap 88. Config: `pyproject.toml`.
  - Commands:
    - Format: `make format` (formats `README.md` and `docs/`).
    - Lint/check: `make lint-md`.

- Caddyfile:
  - Validate syntax using official image. Command: `make lint-caddy`.

- Docker build-time lint (optional local gate):
  - Build `Dockerfile.lint` to run all checks in a clean environment: `make lint-docker`.

- EditorConfig:
  - Respect `.editorconfig` (LF endings, UTF-8, trim trailing whitespace; 2-space indent by default, 4 for `.py`, tabs for `Makefile`). Ensure your editor applies it.

- Scope & PR hygiene:
  - Do not mix broad formatting rewrites with feature/fix changes. If a formatter touches unrelated files, either:
    - Limit formatting to files you edited, or
    - Open a separate `chore: format` PR containing only formatting changes.
  - All PRs must pass `make lint` before review.

## Communication
- Use Pull Requests for all changes.
- Each PR must include:
  - Summary of changes.
  - Testing instructions.
  - Any new env vars or config changes.
