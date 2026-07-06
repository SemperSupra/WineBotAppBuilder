.PHONY: help act-ci act-lint test unit-test

help: ## Show this help
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | \
		awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-20s\033[0m %s\n", $$1, $$2}'

# ── Local CI (nektos/act) ──────────────────────────────────────────────────

act-ci: ## Run full CI workflow locally with act
	act -j lint -j shell-unit -j contract -j policy -j python-unit -j e2e-smoke

act-lint: ## Run only the lint job locally
	act -j lint

act-test: ## Run all test jobs locally
	act -j shell-unit -j contract -j policy -j python-unit -j e2e-smoke

# ── Python Tests ──────────────────────────────────────────────────────────

unit-test: ## Run Python unit tests
	python3 -m unittest discover -s tests/unit -p "*.py" -v

# ── Lint ───────────────────────────────────────────────────────────────────

lint: ## Run containerized lint
	./scripts/lint.sh
