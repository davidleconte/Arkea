#!/bin/bash
set -euo pipefail

# =============================================================================
# Script : Exécuter Tous les Tests
# =============================================================================
# Date : 2025-12-01
# Description : Exécute tous les tests (unitaires, intégration, E2E)
# Usage : ./tests/run_all_tests.sh
# =============================================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ARKEA_HOME="$(cd "${SCRIPT_DIR}/.." && pwd)"

# Couleurs
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Compteurs
TOTAL_PASSED=0
TOTAL_FAILED=0

echo "🧪 Exécution de tous les tests..."
echo ""

# Tests unitaires
if [ -f "${SCRIPT_DIR}/run_unit_tests.sh" ]; then
    echo "📋 Tests unitaires..."
    if "${SCRIPT_DIR}/run_unit_tests.sh"; then
        TOTAL_PASSED=$((TOTAL_PASSED + 1))
    else
        TOTAL_FAILED=$((TOTAL_FAILED + 1))
    fi
    echo ""
fi

# Tests de portabilité
if [ -f "${SCRIPT_DIR}/run_portability_tests.sh" ]; then
    echo "📋 Tests de portabilité..."
    if "${SCRIPT_DIR}/run_portability_tests.sh"; then
        TOTAL_PASSED=$((TOTAL_PASSED + 1))
    else
        TOTAL_FAILED=$((TOTAL_FAILED + 1))
    fi
    echo ""
fi

# Tests de cohérence
if [ -f "${SCRIPT_DIR}/run_consistency_tests.sh" ]; then
    echo "📋 Tests de cohérence..."
    if "${SCRIPT_DIR}/run_consistency_tests.sh"; then
        TOTAL_PASSED=$((TOTAL_PASSED + 1))
    else
        TOTAL_FAILED=$((TOTAL_FAILED + 1))
    fi
    echo ""
fi

# Tests d'intégration
if [ -f "${SCRIPT_DIR}/run_integration_tests.sh" ]; then
    echo "📋 Tests d'intégration..."
    if "${SCRIPT_DIR}/run_integration_tests.sh"; then
        TOTAL_PASSED=$((TOTAL_PASSED + 1))
    else
        TOTAL_FAILED=$((TOTAL_FAILED + 1))
    fi
    echo ""
fi

# Tests E2E
if [ -f "${SCRIPT_DIR}/run_e2e_tests.sh" ]; then
    echo "📋 Tests E2E..."
    if "${SCRIPT_DIR}/run_e2e_tests.sh"; then
        TOTAL_PASSED=$((TOTAL_PASSED + 1))
    else
        TOTAL_FAILED=$((TOTAL_FAILED + 1))
    fi
    echo ""
fi

# Résumé
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
if [ $TOTAL_FAILED -eq 0 ]; then
    echo -e "${GREEN}✅ Tous les tests sont passés !${NC}"
    exit 0
else
    echo -e "${RED}❌ $TOTAL_FAILED suite(s) de tests ont échoué${NC}"
    exit 1
fi
