SHELL := /bin/bash
VENV_PREFIX = .venv/bin/

.PHONY: lint format lint-python lint-yaml lint-md lint-docker

lint: lint-python lint-yaml lint-md ## Run all linters

format: ## Auto-format Python and Markdown
	$(VENV_PREFIX)black api
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

help: ## Show this help
	@grep -E '^[a-zA-Z_-]+:.*?## ' Makefile | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-18s\033[0m %s\n", $$1, $$2}' | sort