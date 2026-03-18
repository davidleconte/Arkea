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
	@bash -c 'source .poc-config.sh && echo "ARKEA_LEG: $$ARKEA_LEG"'
	@bash -c 'source .poc-config.sh && echo "HCD: $$HCD_HOST:$$HCD_PORT"'
	@bash -c 'source .poc-config.sh && echo "KAFKA: $$KAFKA_HOST:$$KAFKA_PORT"'

# =============================================================================
# SERVICES
# =============================================================================

select-leg: ## Ask which runtime leg to use (1=podman/cassandra5, 2=binary/hcd-tarball)
	@bash -c ' \
		set -e; \
		if [ -t 0 ]; then \
			echo "🎯 Select runtime leg for this deployment:"; \
			echo "  1) Cassandra 5.0 (Podman)"; \
			echo "  2) HCD tarball (Binary)"; \
			read -r -p "Choice [1/2]: " choice; \
			case "$$choice" in \
				1) leg="podman" ;; \
				2) leg="binary" ;; \
				*) echo "❌ Invalid choice: $$choice"; exit 1 ;; \
			esac; \
		else \
			leg="$${ARKEA_LEG:-podman}"; \
			echo "ℹ️  Non-interactive mode: using ARKEA_LEG=$$leg"; \
		fi; \
		if [ "$$leg" = "binary" ]; then \
			if [ "$${ARKEA_ENABLE_BINARY_LEG:-0}" != "1" ]; then \
				echo "❌ Binary leg disabled by policy (latest HCD tarball unavailable)."; \
				echo "   Use OSS 5.0 leg for now: ARKEA_LEG=podman make start"; \
				echo "   To force-enable binary leg later: ARKEA_ENABLE_BINARY_LEG=1 ARKEA_LEG=binary make start"; \
				exit 1; \
			fi; \
			hcd_installed=0; \
			hcd_tarball=0; \
			[ -d binaire/hcd-1.2.3 ] && hcd_installed=1 || true; \
			compgen -G "software/*hcd*.tar.gz" > /dev/null && hcd_tarball=1 || true; \
			compgen -G "software/*hcd*.tgz" > /dev/null && hcd_tarball=1 || true; \
			if [ "$$hcd_installed" -ne 1 ] && [ "$$hcd_tarball" -ne 1 ]; then \
				echo "❌ Binary leg unavailable: no HCD tarball and no local HCD install found."; \
				echo "   Use OSS 5.0 leg for now: ARKEA_LEG=podman make start"; \
				exit 1; \
			fi; \
		fi; \
		echo "$$leg" > .arkea-leg; \
		echo "✅ Selected leg: $$leg" \
	'

enforce-single-leg: ## Ensure only one leg is active to avoid conflicts
	@bash -c ' \
		set -e; \
		LEG="$${ARKEA_LEG:?ARKEA_LEG required}"; \
		if [ "$$LEG" = "podman" ]; then \
			pkill -f "kafka.Kafka" 2>/dev/null || true; \
			pkill -f "cassandra" 2>/dev/null || true; \
			echo "🧹 Binary leg processes stopped (if any)."; \
		else \
			podman-compose -f podman-compose.yml down 2>/dev/null || true; \
			echo "🧹 Podman leg stopped (if running)."; \
		fi \
	'

start: ## Start selected leg (asks each time) with conflict prevention
	@echo "🚀 Starting services..."
	@$(MAKE) select-leg
	@LEG=$$(cat .arkea-leg 2>/dev/null || echo "$${ARKEA_LEG:-podman}"); $(MAKE) enforce-single-leg ARKEA_LEG=$$LEG
	@LEG=$$(cat .arkea-leg 2>/dev/null || echo "$${ARKEA_LEG:-podman}"); $(MAKE) start-hcd ARKEA_LEG=$$LEG
	@LEG=$$(cat .arkea-leg 2>/dev/null || echo "$${ARKEA_LEG:-podman}"); $(MAKE) start-kafka ARKEA_LEG=$$LEG
	@LEG=$$(cat .arkea-leg 2>/dev/null || echo "$${ARKEA_LEG:-podman}"); $(MAKE) status ARKEA_LEG=$$LEG
	@rm -f .arkea-leg
	@echo "✅ Selected leg started successfully"

start-hcd: ## Start HCD/Cassandra according to selected leg
	@bash -c ' \
		set -e; \
		source .poc-config.sh; \
		echo "🚀 Starting HCD ($$ARKEA_LEG leg)..."; \
		if [ "$$ARKEA_LEG" = "podman" ]; then \
			podman-compose -f podman-compose.yml --profile full up -d hcd; \
		else \
			./scripts/setup/03_start_hcd.sh background; \
		fi; \
		echo "⏳ Waiting for HCD on $$HCD_HOST:$$HCD_PORT..."; \
		for i in $$(seq 1 30); do \
			if nc -z "$$HCD_HOST" "$$HCD_PORT" 2>/dev/null; then \
				echo "✅ HCD ready on port $$HCD_PORT"; \
				exit 0; \
			fi; \
			sleep 2; \
		done; \
		echo "⚠️  HCD failed to start within 60s"; \
		exit 1 \
	'

start-kafka: ## Start Kafka according to selected leg
	@bash -c ' \
		set -e; \
		source .poc-config.sh; \
		echo "🚀 Starting Kafka ($$ARKEA_LEG leg)..."; \
		if [ "$$ARKEA_LEG" = "podman" ]; then \
			podman-compose -f podman-compose.yml --profile full up -d kafka; \
		else \
			./scripts/setup/04_start_kafka.sh background; \
		fi; \
		echo "⏳ Waiting for Kafka on $$KAFKA_HOST:$$KAFKA_PORT..."; \
		for i in $$(seq 1 30); do \
			if nc -z "$$KAFKA_HOST" "$$KAFKA_PORT" 2>/dev/null; then \
				echo "✅ Kafka ready on port $$KAFKA_PORT"; \
				exit 0; \
			fi; \
			sleep 2; \
		done; \
		echo "⚠️  Kafka failed to start within 60s"; \
		exit 1 \
	'

stop: ## Stop all services gracefully (both legs)
	@echo "🛑 Stopping services..."
	@podman-compose -f podman-compose.yml down 2>/dev/null || true
	@pkill -f "kafka.Kafka" 2>/dev/null || true
	@pkill -f "cassandra" 2>/dev/null || true
	@echo "✅ Services stopped"

restart: stop start ## Restart all services

status: ## Check service status for selected leg
	@bash -c ' \
		set -e; \
		source .poc-config.sh; \
		echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"; \
		echo "📊 ARKEA Service Status ($$ARKEA_LEG)"; \
		echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"; \
		echo ""; \
		echo "  HCD/Cassandra:"; \
		if nc -z "$$HCD_HOST" "$$HCD_PORT" 2>/dev/null; then \
			echo "    Status: ✅ Running on $$HCD_HOST:$$HCD_PORT"; \
			if [ "$$ARKEA_LEG" = "podman" ]; then \
				podman exec arkea-hcd cqlsh localhost 9042 -e "DESCRIBE KEYSPACES;" 2>/dev/null | head -5 || true; \
			fi; \
		else \
			echo "    Status: ❌ Stopped"; \
		fi; \
		echo ""; \
		echo "  Kafka:"; \
		if nc -z "$$KAFKA_HOST" "$$KAFKA_PORT" 2>/dev/null; then \
			echo "    Status: ✅ Running on $$KAFKA_HOST:$$KAFKA_PORT"; \
		else \
			echo "    Status: ❌ Stopped"; \
		fi; \
		echo ""; \
		if [ "$$ARKEA_LEG" = "podman" ]; then \
			echo "  Spark:"; \
			if nc -z localhost 9280 2>/dev/null; then \
				echo "    Status: ✅ Running (Master: 9280, Worker: 9281)"; \
			else \
				echo "    Status: ❌ Stopped"; \
			fi; \
			echo ""; \
		fi; \
		echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" \
	'

# =============================================================================
# DEMO TARGETS (Quick Start for Presentations)
# =============================================================================

demo: ## Quick demo: Start services + run verification
	@echo "🎯 Starting ARKEA Demo..."
	@$(MAKE) start
	@echo ""
	@echo "⏳ Running verification..."
	@./scripts/utils/80_verify_all.sh
	@echo ""
	@echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
	@echo "✅ Demo environment ready!"
	@echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
	@echo ""
	@echo "Quick commands:"
	@echo "  make status      - Check service status"
	@echo "  make demo-poc    - Run a POC demo"
	@echo "  make demo-stop   - Stop demo environment"

demo-quick: ## Fast demo: Skip waits, start services in background
	@echo "🚀 Quick demo start (no waits)..."
	@./scripts/setup/03_start_hcd.sh background 2>/dev/null || true
	@./scripts/setup/04_start_kafka.sh background 2>/dev/null || true
	@sleep 5
	@$(MAKE) status

demo-stop: ## Stop demo environment
	@echo "🛑 Stopping demo environment..."
	@$(MAKE) stop
	@echo "✅ Demo stopped"

demo-poc: ## Run POC demo (BIC by default)
	@echo "🏦 Running BIC POC demo..."
	@$(MAKE) poc-bic

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
	@if command -v flake8 >/dev/null 2>&1; then \
		flake8 . --max-line-length 100 --exclude="binaire/*,software/*,inputs-*,poc-design/*,.venv/*,.git/*"; \
	fi

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
