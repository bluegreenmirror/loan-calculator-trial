SHELL := /bin/bash
UV ?= uv
UV_ENV = UV_PROJECT_ENVIRONMENT=.venv
UV_RUN = $(UV_ENV) $(UV) run --python 3.12 --with-requirements requirements-dev.txt
UV_PIP = $(UV_ENV) $(UV) pip

# Default project name for docker-compose when not provided by environment.
# Ensures container_name templates like "${PROJECT_NAME}-caddy" are valid.
export PROJECT_NAME ?= loancalc

# Prefer local .env, fall back to .env.example for CI
ENV_FILE := $(firstword $(wildcard .env .env.example))
DOCKER_ENV_FLAG := $(if $(ENV_FILE),--env-file $(ENV_FILE),)
COMPOSE_DEV := docker compose --profile dev

.PHONY: lint format format-md lint-python lint-yaml lint-md lint-docker lint-caddy format-caddy test verify build-dev build-release prod-validate release-tag rollback validate-local validate-prod

setup-dev: ## Create venv and install dev deps using uv
	$(UV) venv --python 3.12 .venv
	$(UV_PIP) install --requirements requirements-dev.txt

lint: lint-python lint-yaml lint-md lint-caddy ## Run all linters

format: format-caddy format-md ## Auto-format Python and Markdown
	$(UV_RUN) black api

format-md: ## Auto-format Markdown files
	$(UV_RUN) mdformat README.md docs sprints || true

lint-python: ## Ruff + Black check
	$(UV_RUN) ruff check api
	$(UV_RUN) black --check api

lint-yaml: ## yamllint
	$(UV_RUN) yamllint -s .

lint-md: ## mdformat --check
	$(UV_RUN) mdformat --check README.md docs sprints

lint-docker: ## Build lint image which runs checks at build-time
	$(COMPOSE_DEV) build lint

lint-caddy: ## Validate Caddyfile syntax
        # Validate the main Caddyfile
	@if command -v docker >/dev/null 2>&1; then\
		docker run --rm $(DOCKER_ENV_FLAG) -v $(PWD)/Caddyfile:/etc/caddy/Caddyfile:ro caddy:2.8 caddy validate --config /etc/caddy/Caddyfile;\
	else\
		echo "Docker is not available; skipping Caddyfile validation.";\
	fi

format-caddy: ## Format Caddyfile
	docker run --rm -v $(PWD)/Caddyfile:/etc/caddy/Caddyfile caddy:2.8 caddy fmt --overwrite /etc/caddy/Caddyfile
	docker run --rm -v $(PWD)/Caddyfile.edge.template.caddyfile:/etc/caddy/Caddyfile.edge.template.caddyfile caddy:2.8 caddy fmt --overwrite /etc/caddy/Caddyfile.edge.template.caddyfile

test: ## Run unit and integration tests
	@if command -v docker >/dev/null 2>&1; then \
	trap '$(COMPOSE_DEV) down' EXIT; \
	$(COMPOSE_DEV) up -d; \
	$(UV_RUN) pytest; \
	else \
	echo "Docker is not available; running pytest without containers."; \
	$(UV_RUN) pytest; \
	fi

verify: lint test ## Lint and run tests

help: ## Show this help
	@grep -E '^[a-zA-Z_-]+:.*?## ' Makefile | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-18s\033[0m %s\n", $1, $2}' | sort

build-dev: ## Build dev images (runs verify, builds all services)
	$(MAKE) verify
	$(COMPOSE_DEV) build

build-release: ## Build release images (api + web only; no dev tooling)
	PROJECT_NAME=loancalc docker compose build --pull api web caddy edge

prod-validate: ## Validate production hosts using curl (requires APEX_HOST, WWW_HOST)
	@bash scripts/validate_caddy_prod.sh

release-tag: ## Create an annotated release tag: make release-tag VERSION=vX.Y.Z [VERIFY=1] [PUSH=1]
	@bash scripts/release_tag.sh $(VERSION) $(if $(VERIFY),--verify,) $(if $(PUSH),--push,)

rollback: ## Roll back to a tag/commit: make rollback REF=<git-ref> [BUILD=1] [VERIFY=1] [YES=1]
	@bash scripts/rollback_to.sh $(REF) $(if $(BUILD),--build,) $(if $(VERIFY),--verify,) $(if $(YES),--yes,)

validate-local: ## Run local end-to-end validation (edge + blue stack)
	bash scripts/validate_local.sh

validate-prod: ## Run production edge validation (apex/www, TLS, redirects)
	bash scripts/validate_prod.sh
