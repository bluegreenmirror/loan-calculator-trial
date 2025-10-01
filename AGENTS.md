# Agents / Automation Guidelines

This project can be extended or maintained not only by humans but also by AI/automation “agents.”  
This document is the **operating contract** for collaboration. Follow it exactly.

---

## Roles

- **Builder Agent**: Implements features/fixes in _small, atomic_ commits; adds/updates tests.
  - **Scope guard**: If a request mixes multiple concerns, the Builder must stop, document the conflict,
    and ask for the work to be split into separate PRs before coding.
- **Reviewer Agent**: Ensures PRs follow scope, quality, and documentation requirements.
  - **Atomicity enforcement**: Reject reviews that expand scope or bundle unrelated changes. Require new PRs
    when feedback introduces additional features or chores outside the original goal.
- **Deployment Agent**: Builds & deploys (blue/green), creates `.env` from CI secrets, validates health.
- **Infra Agent**: Proposes & updates Docker/Caddy/Cloudflare/DB/CI; keeps changes backward compatible.

---

## Rules

### 1) Atomicity

- One PR = one logical change. No exceptions.
  _Examples_: add API endpoint **or** update Caddy config **or** docs refresh.
  _Non-examples_: app feature + infra + formatting in one PR.
- **Enforcement workflow**:
  1. Author documents the single change scope in the PR description before coding.
  2. If, during review or follow-up requests, new scope appears, the author must open a **new branch/PR**
     and sequence it after the current one.
  3. Reviewers reject PRs that attempt to incorporate additional scope instead of spawning a new PR.
  4. Agents must never accept “just add this quick extra” in the same PR; log the request in an issue or
     TODO for the follow-up PR.

### 2) Branch naming

- `feature/*`, `fix/*`, `chore/*`, `infra/*`, `docs/*`.

### 3) Commit messages

- Use **Conventional Commits**: `feat:`, `fix:`, `chore:`, `infra:`, `docs:`.

### 4) Documentation

- If behavior, endpoints, env vars, or deployment steps change, update `README.md` or `docs/`.  
- If truly no docs impact, write: **“No docs impact.”**

### 5) Secrets & safety

- Never commit secrets (API keys, DB URLs, Cloudflare tokens).  
- Never commit a real `.env`; only update `.env.example`.  
- Use **placeholders** in configs (`{$APEX_HOST}`, `{$WWW_HOST}`, `{$EMAIL}`, `{$HSTS_LINE}`); concrete values live only in `.env` and GitHub Secrets.

### 6) Environment separation (mandatory)

- **Dev**: `localhost`, HTTP only, no HSTS.  
- **Staging**: staging domain, HTTPS, mirrors prod.  
- **Prod**: apex + www, Cloudflare **Full (strict)**.  
- Agents must not collapse these environments or reuse prod secrets in dev.

### 7) Determinism

- Pin dependencies in requirements files.  
- Upgrades are separate PRs with migration notes (e.g., Pydantic v2: `regex → pattern`).  
- If a tool fails on prod (e.g., Ruff not installed), move that check to CI or make it optional behind a flag.

### 8) Testing & health checks (required)

- **Every PR** must:
  - Add/adjust **pytest** unit tests for new/changed models & business logic.
  - Include **curl** examples for any changed endpoint.  
  - Pass **smoke tests** in CI: `/api/health`, critical endpoints.
  - Pass `make lint` (Python/YAML/Markdown/Caddyfile).

---

## Lint & formatting

Keep formatting scoped to touched files unless doing a dedicated fmt PR.

- **Python**
  - Formatter: Black (line-length 88).
  - Lint: Ruff (rules: E,F,W,I,UP,B; Black-compatible ignores).
  - Commands:
    - Format: `make format` (Python under `api/`).
    - Lint: `make lint-python` or `make lint`.

- **YAML**: `make lint-yaml`

- **Markdown**: `make lint-md`

### Markdown authoring standards (mdlint compliant)

When creating or updating Markdown files, follow these conventions so `make lint-md`
passes consistently:

- Start each file with a single `#` level-one heading that summarizes the page.
- Increment heading levels by one level at a time (no skipping from `##` to `####`).
- Insert a blank line before and after headings, lists, blockquotes, and code fences.
- Use `-` for unordered list markers and keep list text aligned; indent nested list
  content by two spaces.
- Use `1.` for every ordered list item so Markdown auto-numbers lists consistently.
- Wrap paragraphs at 120 characters or fewer to improve diffs while satisfying
  markdownlint line-length rules.
- Provide a language hint for fenced code blocks (for example, ```` ```bash ````)
  whenever the snippet represents a specific language or shell.
- Avoid trailing whitespace and ensure files end with a single newline.
- Reference links using inline Markdown syntax unless a shared reference list is
  required; keep link reference identifiers in lowercase.

- **Caddyfile**: `make lint-caddy` (uses official image)

- **EditorConfig**: enforce LF, UTF-8, trimming, 2-space indent default (4 for `.py`, tabs for Makefile)

- **Scope & PR hygiene**
  - Don’t mix formatting with features.
  - If formatting touches >2 unrelated files → isolate to `chore: format` PR.
  - Before opening a PR, always run `make lint` and `make format` locally.

---

## Deployment rules

- **Blue/Green only** in prod. Use `deploy.sh blue|green`.  
  Direct `docker compose up` on the server is **not** allowed.

- **.env in CI/CD**:
  - Deployment Agent must **generate `.env` from GitHub Secrets** before running `deploy.sh`.  
  - Never assume `.env` already exists on the target VM.

- **Validation after cutover**:
  - Run `make validate-prod` (or scripts/validate_*.sh).  
  - If validation fails, revert edge to the previous color automatically and exit non-zero.

- **Cloudflare/TLS**:
  - Obtain certs with Caddy (DNS only during issuance).  
  - Switch to Cloudflare proxy after certs exist; SSL mode **Full (strict)**.

---

## Communication & PR template

Each PR must include:

1. **Summary** of changes (what/why).  
2. **Testing instructions** (pytest + curl examples).  
3. **New env vars** (and update to `.env.example`).  
4. **Docs impact** (what was updated or “No docs impact”).  
5. **Validation** (how it will be verified after deploy).

---

## Planning & workstreams (deterministic delivery)

Break work into explicit milestones with acceptance criteria:

1) **Core app**  
   - `/api/health` returns 200.  
   - Front-end served by Caddy (dev: HTTP).

2) **Local dev baseline**  
   - `docker-compose.override.dev.yml` (localhost, no TLS).  
   - `curl http://localhost/api/health` returns 200.

3) **Production baseline**  
   - Caddyfile uses **placeholders**; CI verifies config loads (`caddy adapt`).  
   - Smoke test `curl -I -H "Host:$APEX_HOST" http://127.0.0.1`.

4) **Persistence**  
   - Phase 1: JSON file with Docker volume `/data` (MVP).  
   - Phase 2: migrate to **Postgres** (schema, migrations, integration tests).

5) **Infra**  
   - Decide early: Caddy ACME vs Cloudflare origin certs.  
   - Acceptance: apex + www both serve valid TLS; redirect strategy documented.

6) **CI/CD**  
   - Stage 1: lint + pytest.  
   - Stage 2: docker build + compose up in runner.  
   - Stage 3: deploy to **staging**; run smoke tests.  
   - Stage 4: promote to **prod** (blue/green).

---

## Quick-reference checklists

### Feature PR

- [ ] Branch name `feature/*`  
- [ ] Tests added (pytest)  
- [ ] curl examples in PR description  
- [ ] Lint passes (`make lint`)  
- [ ] Docs updated or “No docs impact”  
- [ ] `.env.example` updated if needed

### Infra PR

- [ ] Caddy/Docker changes isolated (no app code mixed)  
- [ ] `caddy adapt` passes (CI)  
- [ ] Blue/green plan included, with rollback steps  
- [ ] Validation script updated if needed

### Deploy

- [ ] `.env` generated from secrets in CI  
- [ ] Staging deployed and validated  
- [ ] Prod blue/green cutover completed  
- [ ] Post-cutover validation passed; rollback if not

---

## Collaboration Contract

This file is the collaboration contract. If a change would violate these rules, open a discussion first and adjust the plan rather than “forcing it to work.”
