#!/bin/bash
# =============================================================================
# Script : kcov Runner for Bash Coverage
# =============================================================================
# Date : 2026-03-13
# Version : 1.0.0
# Author : David LECONTE (IBM WW|Tiger Team - Watsonx.Data GPS)
# Description : Run bash scripts with kcov for code coverage
# Usage : ./tests/utils/kcov_runner.sh <script_to_test>
# =============================================================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"
COVERAGE_DIR="${PROJECT_ROOT}/tests/coverage"

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

# =============================================================================
# Check kcov Installation
# =============================================================================
check_kcov() {
    if ! command -v kcov &>/dev/null; then
        echo -e "${YELLOW}⚠️  kcov not found. Installing...${NC}"
        echo ""

        if [[ "$(uname)" == "Darwin" ]]; then
            echo "On macOS, install with:"
            echo "  brew install kcov"
        elif [[ "$(uname)" == "Linux" ]]; then
            echo "On Linux, install with:"
            echo "  sudo apt-get install kcov  # Debian/Ubuntu"
            echo "  sudo dnf install kcov      # Fedora"
        fi

        echo ""
        echo "Continuing with pytest-cov for Python coverage only..."
        return 1
    fi

    return 0
}

# =============================================================================
# Run Coverage for Shell Scripts
# =============================================================================
run_shell_coverage() {
    local script="$1"
    local script_name
    script_name=$(basename "$script" .sh)

    echo -e "${GREEN}📊 Running kcov for: $script_name${NC}"

    mkdir -p "${COVERAGE_DIR}/bash"

    # Run kcov
    kcov \
        --include-path="${PROJECT_ROOT}/lib,${PROJECT_ROOT}/scripts" \
        --exclude-path="${PROJECT_ROOT}/tests,${PROJECT_ROOT}/binaire,${PROJECT_ROOT}/software" \
        "${COVERAGE_DIR}/bash/${script_name}" \
        "$script" || true

    echo ""
    echo "Coverage report: ${COVERAGE_DIR}/bash/${script_name}/index.html"
}

# =============================================================================
# Run Coverage for All Shell Scripts
# =============================================================================
run_all_shell_coverage() {
    echo -e "${GREEN}📊 Running kcov for all shell scripts${NC}"
    echo ""

    local scripts=()
    local failed=0

    # Find testable scripts
    while IFS= read -r script; do
        scripts+=("$script")
    done < <(find "${PROJECT_ROOT}/lib" -name "*.sh" -type f 2>/dev/null)

    if [[ ${#scripts[@]} -eq 0 ]]; then
        echo -e "${YELLOW}No shell scripts found to test${NC}"
        return 0
    fi

    for script in "${scripts[@]}"; do
        if run_shell_coverage "$script"; then
            ((failed++)) || true
        fi
    done

    echo ""
    echo -e "${GREEN}✅ Coverage reports generated in: ${COVERAGE_DIR}/bash/${NC}"
}

# =============================================================================
# Run Coverage for Python
# =============================================================================
run_python_coverage() {
    echo -e "${GREEN}📊 Running pytest-cov for Python${NC}"
    echo ""

    mkdir -p "${COVERAGE_DIR}/python"

    # Run pytest with coverage
    pytest "${PROJECT_ROOT}/tests/unit/" \
        --cov="${PROJECT_ROOT}" \
        --cov-report=html:"${COVERAGE_DIR}/python/html" \
        --cov-report=xml:"${COVERAGE_DIR}/python/coverage.xml" \
        --cov-report=term \
        --cov-exclude="binaire/*,software/*,inputs-*,tests/*" \
        -v || true

    echo ""
    echo -e "${GREEN}✅ Python coverage report: ${COVERAGE_DIR}/python/html/index.html${NC}"
}

# =============================================================================
# Generate Combined Report
# =============================================================================
generate_combined_report() {
    echo ""
    echo -e "${GREEN}📋 Generating Combined Coverage Report${NC}"
    echo ""

    local report_file="${COVERAGE_DIR}/COVERAGE_SUMMARY.md"

    {
        echo "# Coverage Report Summary"
        echo ""
        echo "**Date**: $(date '+%Y-%m-%d %H:%M:%S')"
        echo ""
        echo "---"
        echo ""
        echo "## Shell Script Coverage (kcov)"
        echo ""

        # Summarize bash coverage if available
        if [[ -d "${COVERAGE_DIR}/bash" ]]; then
            for dir in "${COVERAGE_DIR}/bash"/*/; do
                if [[ -f "${dir}coverage.json" ]]; then
                    local name
                    name=$(basename "$dir")
                    echo "- **$name**: See ${dir}index.html"
                fi
            done
        else
            echo "No bash coverage data available."
        fi

        echo ""
        echo "## Python Coverage (pytest-cov)"
        echo ""

        if [[ -f "${COVERAGE_DIR}/python/coverage.xml" ]]; then
            echo "- HTML Report: ${COVERAGE_DIR}/python/html/index.html"
            echo "- XML Report: ${COVERAGE_DIR}/python/coverage.xml"
        else
            echo "No Python coverage data available."
        fi

        echo ""
        echo "---"
        echo ""
        echo "## How to Improve Coverage"
        echo ""
        echo "1. Add more unit tests for uncovered functions"
        echo "2. Test edge cases and error paths"
        echo "3. Mock external dependencies (HCD, Kafka, Spark)"
        echo ""

    } > "$report_file"

    echo -e "${GREEN}✅ Combined report: ${report_file}${NC}"
}

# =============================================================================
# Main
# =============================================================================
main() {
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "  ARKEA POC - Code Coverage Runner"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""

    mkdir -p "$COVERAGE_DIR"

    local target="${1:-all}"

    case "$target" in
        "shell"|"bash")
            if check_kcov; then
                run_all_shell_coverage
            fi
            ;;
        "python"|"pytest")
            run_python_coverage
            ;;
        "all"|*)
            if check_kcov; then
                run_all_shell_coverage
            fi
            run_python_coverage
            ;;
    esac

    generate_combined_report

    echo ""
    echo -e "${GREEN}✅ Coverage analysis complete${NC}"
}

# Run main
main "$@"
