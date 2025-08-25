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
   - Linting (Python + YAML + Markdown).

## Communication
- Use Pull Requests for all changes.
- Each PR must include:
  - Summary of changes.
  - Testing instructions.
  - Any new env vars or config changes.