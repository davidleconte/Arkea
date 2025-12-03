#!/bin/bash
set -euo pipefail

# =============================================================================
# Script : Exécuter Tests Unitaires
# =============================================================================
# Date : 2025-12-02
# Description : Exécute tous les tests unitaires
# Usage : ./tests/run_unit_tests.sh
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

echo "🧪 Exécution des tests unitaires..."
echo ""

# Créer le répertoire de résultats si nécessaire
mkdir -p "$SCRIPT_DIR/results"

# Tests unitaires disponibles
UNIT_TESTS=(
    "test_portability.sh"
    "test_consistency.sh"
    "test_poc_config.sh"
    "test_portable_functions_example.sh"
)

# Exécuter chaque test unitaire
for test_file in "${UNIT_TESTS[@]}"; do
    test_path="$SCRIPT_DIR/unit/$test_file"

    if [ -f "$test_path" ]; then
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        echo "📋 Exécution : $test_file"
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

        if bash "$test_path"; then
            echo -e "${GREEN}✅ $test_file : PASSÉ${NC}"
            TOTAL_PASSED=$((TOTAL_PASSED + 1))
        else
            echo -e "${RED}❌ $test_file : ÉCHOUÉ${NC}"
            TOTAL_FAILED=$((TOTAL_FAILED + 1))
        fi
        echo ""
    else
        echo -e "${YELLOW}⚠️  Test non trouvé : $test_path${NC}"
    fi
done

# Résumé
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "📊 Résumé des Tests Unitaires"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo -e "${GREEN}✅ Tests passés  : $TOTAL_PASSED${NC}"
echo -e "${RED}❌ Tests échoués : $TOTAL_FAILED${NC}"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Code de sortie
if [ $TOTAL_FAILED -eq 0 ]; then
    exit 0
else
    exit 1
fi
