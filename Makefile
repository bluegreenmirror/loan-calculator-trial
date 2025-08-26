SHELL := /bin/bash

.PHONY: lint format lint-python lint-yaml lint-md lint-docker

lint: lint-python lint-yaml lint-md ## Run all linters

format: ## Auto-format Python and Markdown
	black api
	mdformat README.md docs || true

lint-python: ## Ruff + Black check
	ruff check api
	black --check api

lint-yaml: ## yamllint
	yamllint -s .

lint-md: ## mdformat --check
	mdformat --check README.md docs

lint-docker: ## Build lint image which runs checks at build-time
	docker build -f Dockerfile.lint .

help: ## Show this help
	@grep -E '^[a-zA-Z_-]+:.*?## ' Makefile | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-18s\033[0m %s\n", $$1, $$2}' | sort

