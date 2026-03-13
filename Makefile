# =============================================================================
# ARKEA POC - Makefile
# =============================================================================
# Date : 2025-03-13
# Version : 1.0.0
# Author : David LECONTE (IBM WW|Tiger Team - Watsonx.Data GPS)
# Description : Centralized build, test, and operations management
# Usage : make [target]
# =============================================================================

.PHONY: help setup start stop status test test-unit test-integration test-e2e \
        clean docs check fmt lint security check-consistency \
        poc-bic poc-domirama2 poc-domiramaCatOps

# Default target
.DEFAULT_GOAL := help

# =============================================================================
# HELP
# =============================================================================

help: ## Show this help message
	@echo "ARKEA POC - Makefile Commands"
	@echo ""
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "  \033[36m%-20s\033[0m %s\n", $$1, $$2}'
	@echo ""

# =============================================================================
# ENVIRONMENT SETUP
# =============================================================================

setup: ## Initial project setup (run once)
	@echo "🔧 Setting up ARKEA POC environment..."
	@if [ ! -f .poc-profile ]; then cp .poc-profile.example .poc-profile 2>/dev/null || true; fi
	@if command -v pre-commit >/dev/null 2>&1; then pre-commit install; fi
	@echo "✅ Setup complete. Run 'source .poc-profile' to activate."

check-env: ## Validate environment configuration
	@echo "🔍 Checking environment..."
	@bash -c 'source .poc-config.sh && echo "ARKEA_HOME: $$ARKEA_HOME"'
	@bash -c 'source .poc-config.sh && echo "HCD: $${HCD_HOST:-localhost}:$${HCD_PORT:-9042}"'
	@bash -c 'source .poc-config.sh && echo "KAFKA: $${KAFKA_HOST:-localhost}:$${KAFKA_PORT:-9092}"'

# =============================================================================
# SERVICES
# =============================================================================

start: start-hcd start-kafka ## Start all services (HCD + Kafka)
	@echo "✅ All services started"

start-hcd: ## Start HCD (Cassandra)
	@echo "🚀 Starting HCD..."
	@./scripts/setup/03_start_hcd.sh 2>/dev/null || echo "⚠️  HCD start script not found or failed"
	@sleep 3
	@./scripts/utils/80_verify_all.sh 2>/dev/null || true

start-kafka: ## Start Kafka
	@echo "🚀 Starting Kafka..."
	@./scripts/setup/04_start_kafka.sh 2>/dev/null || echo "⚠️  Kafka start script not found or failed"

stop: ## Stop all services
	@echo "🛑 Stopping services..."
	@pkill -f "kafka.Kafka" 2>/dev/null || true
	@pkill -f "cassandra" 2>/dev/null || true
	@echo "✅ Services stopped"

status: ## Check service status
	@echo "📊 Service Status:"
	@echo "  HCD:    $$(nc -z localhost 9042 2>/dev/null && echo '✅ Running' || echo '❌ Stopped')"
	@echo "  Kafka:  $$(nc -z localhost 9092 2>/dev/null && echo '✅ Running' || echo '❌ Stopped')"
	@echo "  Spark:  $$(if [ -n \"$${SPARK_HOME:-}\" ]; then echo '✅ Configured'; else echo '❌ Not configured'; fi)"

# =============================================================================
# TESTS
# =============================================================================

test: test-unit test-integration ## Run all tests (unit + integration)
	@echo "✅ All tests completed"

test-unit: ## Run unit tests only
	@echo "🧪 Running unit tests..."
	@./tests/run_unit_tests.sh

test-integration: ## Run integration tests
	@echo "🧪 Running integration tests..."
	@./tests/run_integration_tests.sh

test-e2e: ## Run end-to-end tests
	@echo "🧪 Running E2E tests..."
	@./tests/run_e2e_tests.sh

test-portability: ## Run portability tests (macOS/Linux)
	@echo "🧪 Running portability tests..."
	@./tests/run_portability_tests.sh

test-consistency: ## Run consistency tests
	@echo "🧪 Running consistency tests..."
	@./tests/run_consistency_tests.sh

test-coverage: ## Run tests with coverage report
	@echo "📊 Running tests with coverage..."
	@./tests/utils/kcov_runner.sh all 2>/dev/null || ./tests/utils/coverage.sh 2>/dev/null || echo "⚠️  Coverage script not found"

test-coverage-shell: ## Run shell script coverage with kcov
	@echo "📊 Running shell coverage..."
	@./tests/utils/kcov_runner.sh shell 2>/dev/null || echo "⚠️  Install kcov: brew install kcov (macOS) or apt install kcov (Linux)"

test-coverage-python: ## Run Python coverage with pytest-cov
	@echo "📊 Running Python coverage..."
	@./tests/utils/kcov_runner.sh python

# =============================================================================
# POC-SPECIFIC TARGETS
# =============================================================================

poc-bic: ## Setup and test BIC POC
	@echo "🏦 Running BIC POC..."
	@cd poc-design/bic && ./scripts/setup/01_setup_bic_keyspace.sh 2>/dev/null || echo "Setup required"

poc-domirama2: ## Setup and test Domirama2 POC
	@echo "🏦 Running Domirama2 POC..."
	@cd poc-design/domirama2 && ./scripts/10_setup_domirama2_poc.sh 2>/dev/null || echo "Setup required"

poc-domiramaCatOps: ## Setup and test DomiramaCatOps POC
	@echo "🎯 Running DomiramaCatOps POC..."
	@cd poc-design/domiramaCatOps && ./scripts/01_setup_domiramaCatOps_keyspace.sh 2>/dev/null || echo "Setup required"

poc-all: poc-bic poc-domirama2 poc-domiramaCatOps ## Run all POCs
	@echo "✅ All POCs executed"

# =============================================================================
# CODE QUALITY
# =============================================================================

fmt: ## Format code (Python + Shell)
	@echo "✨ Formatting code..."
	@if command -v black >/dev/null 2>&1; then black . --line-length 100; fi
	@if command -v shfmt >/dev/null 2>&1; then shfmt -w -i 4 -ci scripts/ tests/ poc-design/*/scripts/ 2>/dev/null; fi

lint: ## Run linters (ShellCheck, pyflake)
	@echo "🔍 Running linters..."
	@if command -v shellcheck >/dev/null 2>&1; then \
		find . -name "*.sh" -not -path "./binaire/*" -not -path "./software/*" -exec shellcheck {} \; 2>/dev/null || true; \
	fi
	@if command -v flake8 >/dev/null 2>&1; then flake8 . --max-line-length 100; fi

security: ## Run security checks (secrets detection)
	@echo "🔒 Running security checks..."
	@if command -v detect-secrets >/dev/null 2>&1; then \
		detect-secrets scan --baseline .secrets.baseline 2>/dev/null || true; \
	fi
	@git diff --staged --name-only 2>/dev/null | xargs -I {} sh -c 'grep -l "password\|secret\|token\|api.key" "{}" 2>/dev/null && echo "⚠️  Potential secret in {}"' || true

check: lint security test-unit ## Run all checks (lint + security + unit tests)
	@echo "✅ All checks passed"

check-consistency: ## Check project consistency
	@echo "🔍 Checking project consistency..."
	@./scripts/utils/91_check_consistency.sh 2>/dev/null || echo "⚠️  Consistency script not found"

# =============================================================================
# DOCUMENTATION
# =============================================================================

docs: ## Generate documentation
	@echo "📚 Generating documentation..."
	@./scripts/utils/92_generate_docs.sh 2>/dev/null || echo "⚠️  Docs generator not found"

docs-index: ## Update documentation index
	@echo "📚 Updating docs index..."
	@./scripts/utils/92_generate_docs.sh --index 2>/dev/null || true

# =============================================================================
# CLEANUP
# =============================================================================

clean: ## Clean temporary files
	@echo "🧹 Cleaning temporary files..."
	@./scripts/utils/95_cleanup.sh 2>/dev/null || true
	@find . -name "*.pyc" -delete 2>/dev/null || true
	@find . -name "__pycache__" -type d -exec rm -rf {} + 2>/dev/null || true
	@find . -name ".DS_Store" -delete 2>/dev/null || true
	@rm -rf .pytest_cache/ .mypy_cache/ 2>/dev/null || true
	@echo "✅ Cleanup complete"

clean-logs: ## Clean log files
	@echo "🧹 Cleaning logs..."
	@rm -rf logs/*.log 2>/dev/null || true
	@echo "✅ Logs cleaned"

# =============================================================================
# UTILITY
# =============================================================================

verify: ## Verify all components
	@./scripts/utils/80_verify_all.sh

version: ## Show version info
	@echo "ARKEA POC"
	@echo "HCD:    $${HCD_VERSION:-1.2.3}"
	@echo "Spark:  $${SPARK_VERSION:-3.5.1}"
	@echo "Kafka:  4.1.1"

# =============================================================================
# PODMAN CONTAINER MANAGEMENT
# =============================================================================
# ⚠️ IMPERATIVE: See PODMAN_RULES.md for isolation requirements
# =============================================================================

podman-check: ## Pre-flight check for Podman ports and resources
	@echo "🔍 Running Podman pre-flight checks..."
	@./scripts/utils/96_check_podman_ports.sh

podman-up: ## Start ARKEA stack with Podman (full profile)
	@echo "🚀 Starting ARKEA stack with Podman..."
	@./scripts/utils/96_check_podman_ports.sh || exit 1
	podman-compose --profile full up -d
	@echo "✅ ARKEA stack started"
	@echo "  HCD CQL:    localhost:9102"
	@echo "  Spark UI:   localhost:9180"
	@echo "  Kafka:      localhost:9192"
	@echo "  Kafka UI:   localhost:9190"

podman-down: ## Stop ARKEA stack (preserves volumes)
	@echo "🛑 Stopping ARKEA stack..."
	podman-compose --profile full down
	@echo "✅ ARKEA stack stopped"

podman-logs: ## View ARKEA container logs
	@podman-compose logs -f

podman-status: ## Check ARKEA container status
	@echo "📊 ARKEA Container Status:"
	@podman ps --filter "label=project=arkea" --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}" 2>/dev/null || echo "No containers running"

podman-clean: ## Remove ARKEA containers and network (keeps volumes)
	@echo "🧹 Cleaning ARKEA containers..."
	podman-compose --profile full down --rmi local
	@podman network rm arkea-network 2>/dev/null || true
	@echo "✅ Cleanup complete (volumes preserved)"

podman-nuke: ## ⚠️ Remove ALL ARKEA resources including volumes
	@echo "⚠️  WARNING: This will delete all ARKEA data!"
	@read -p "Continue? [y/N] " confirm && [ "$$confirm" = "y" ] || exit 1
	podman-compose --profile full down -v
	@podman network rm arkea-network 2>/dev/null || true
	@podman volume rm arkea-hcd-data arkea-hcd-logs arkea-spark-data arkea-kafka-data 2>/dev/null || true
	@echo "✅ All ARKEA resources removed"

# =============================================================================
# DEVELOPMENT
# =============================================================================

dev-setup: setup ## Full development setup
	@echo "🚀 Full development setup..."
	@if command -v pre-commit >/dev/null 2>&1; then pre-commit install; fi
	@if command -v pre-commit >/dev/null 2>&1; then pre-commit run --all-files; fi
	@echo "✅ Development environment ready"

pre-commit: ## Run pre-commit hooks on all files
	@if command -v pre-commit >/dev/null 2>&1; then \
		pre-commit run --all-files; \
	else \
		echo "⚠️  pre-commit not installed. Run: pip install pre-commit"; \
	fi

# =============================================================================
# MONITORING (Phase 4)
# =============================================================================

monitoring-up: ## Start Prometheus and Grafana
	@echo "📊 Starting monitoring stack..."
	@podman-compose -f monitoring/docker-compose.monitoring.yml up -d 2>/dev/null || \
		echo "⚠️  Monitoring stack requires Podman. Run: make podman-up first"
	@echo "  Prometheus: http://localhost:9090"
	@echo "  Grafana:    http://localhost:3000 (admin/admin)"

monitoring-down: ## Stop monitoring stack
	@echo "🛑 Stopping monitoring..."
	@podman-compose -f monitoring/docker-compose.monitoring.yml down 2>/dev/null || true

monitoring-status: ## Check monitoring status
	@echo "📊 Monitoring Status:"
	@curl -s http://localhost:9090/-/healthy >/dev/null 2>&1 && echo "  Prometheus: ✅ Running" || echo "  Prometheus: ❌ Stopped"
	@curl -s http://localhost:3000/api/health >/dev/null 2>&1 && echo "  Grafana:    ✅ Running" || echo "  Grafana:    ❌ Stopped"

# =============================================================================
# DEVCONTAINER (Phase 5)
# =============================================================================

setup-devcontainer: ## Setup for DevContainer (called by .devcontainer/devcontainer.json)
	@echo "🔧 Setting up DevContainer environment..."
	@pip install --upgrade pip
	@if [ -f requirements.txt ]; then pip install -r requirements.txt; fi
	@if command -v pre-commit >/dev/null 2>&1; then pre-commit install; fi
	@echo "✅ DevContainer setup complete"

onboarding: ## Run full project onboarding
	@echo "🚀 Running project onboarding..."
	@./scripts/setup/00_onboarding.sh
