SHELL := /bin/bash
VENV_PREFIX = .venv/bin/

# Prefer local .env, fall back to .env.example for CI
ENV_FILE := $(firstword $(wildcard .env .env.example))
DOCKER_ENV_FLAG := $(if $(ENV_FILE),--env-file $(ENV_FILE),)
COMPOSE_LOCAL := docker compose -f docker-compose.local.yml

.PHONY: lint format format-md lint-python lint-yaml lint-md lint-docker lint-caddy format-caddy test verify build-dev build-release prod-validate release-tag rollback

lint: lint-python lint-yaml lint-md lint-caddy ## Run all linters

format: format-caddy format-md ## Auto-format Python and Markdown
	$(VENV_PREFIX)black api

format-md: ## Auto-format Markdown files
	$(VENV_PREFIX)mdformat README.md docs || true

lint-python: ## Ruff + Black check
	$(VENV_PREFIX)ruff check api
	$(VENV_PREFIX)black --check api

lint-yaml: ## yamllint
	$(VENV_PREFIX)yamllint -s .

lint-md: ## mdformat --check
	$(VENV_PREFIX)mdformat --check README.md docs

lint-docker: ## Build lint image which runs checks at build-time
	docker build -f Dockerfile.lint .

lint-caddy: ## Validate Caddyfile syntax
	$(COMPOSE_LOCAL) exec caddy caddy validate --config /etc/caddy/Caddyfile

format-caddy: ## Format Caddyfile
	$(COMPOSE_LOCAL) exec caddy caddy fmt --overwrite /etc/caddy/Caddyfile

test: ## Run unit and integration tests
	$(COMPOSE_LOCAL) up -d
	$(VENV_PREFIX)pytest
	$(COMPOSE_LOCAL) down

verify: lint test ## Lint and run tests

help: ## Show this help
	@grep -E '^[a-zA-Z_-]+:.*?## ' Makefile | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-18s\033[0m %s\n", $1, $2}' | sort

build-dev: ## Build dev images (runs verify, builds all services)
	$(MAKE) verify
	$(COMPOSE_LOCAL) build --pull

build-release: ## Build release images (api + web only; no dev tooling)
	PROJECT_NAME=loancalc docker compose build --pull api web

prod-validate: ## Validate production hosts using curl (requires APEX_HOST, WWW_HOST)
	@bash scripts/validate_caddy_prod.sh

release-tag: ## Create an annotated release tag: make release-tag VERSION=vX.Y.Z [VERIFY=1] [PUSH=1]
	@bash scripts/release_tag.sh $(VERSION) $(if $(VERIFY),--verify,) $(if $(PUSH),--push,)

rollback: ## Roll back to a tag/commit: make rollback REF=<git-ref> [BUILD=1] [VERIFY=1] [YES=1]
	@bash scripts/rollback_to.sh $(REF) $(if $(BUILD),--build,) $(if $(VERIFY),--verify,) $(if $(YES),--yes,)