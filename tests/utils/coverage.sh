#!/bin/bash
set -euo pipefail

# =============================================================================
# Script : Mesure de Couverture de Tests
# =============================================================================
# Date : 2025-12-02
# Usage : ./tests/utils/coverage.sh [--format html|text]
# Description : Mesure la couverture de code des tests
# =============================================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ARKEA_HOME="$(cd "$SCRIPT_DIR/../.." && pwd)"

# Variables
COVERAGE_FORMAT="${1:-text}"
COVERAGE_DIR="$ARKEA_HOME/tests/coverage"
COVERAGE_REPORT="$COVERAGE_DIR/coverage.txt"

# Couleurs
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo "📊 Mesure de Couverture de Tests - ARKEA"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Créer le répertoire de couverture
mkdir -p "$COVERAGE_DIR"

# Compter les fichiers de test
UNIT_TESTS=$(find "$ARKEA_HOME/tests/unit" -name "test_*.sh" -type f 2>/dev/null | wc -l | tr -d ' ')
INTEGRATION_TESTS=$(find "$ARKEA_HOME/tests/integration" -name "test_*.sh" -type f 2>/dev/null | wc -l | tr -d ' ')
E2E_TESTS=$(find "$ARKEA_HOME/tests/e2e" -name "test_*.sh" -type f 2>/dev/null | wc -l | tr -d ' ')
TOTAL_TESTS=$((UNIT_TESTS + INTEGRATION_TESTS + E2E_TESTS))

# Compter les fichiers de code
SCRIPTS_COUNT=$(find "$ARKEA_HOME/scripts" -name "*.sh" -type f ! -path "*/archive/*" 2>/dev/null | wc -l | tr -d ' ')
PYTHON_COUNT=$(find "$ARKEA_HOME/scripts" -name "*.py" -type f ! -path "*/archive/*" 2>/dev/null | wc -l | tr -d ' ')
POC_SCRIPTS_COUNT=$(find "$ARKEA_HOME/poc-design" -name "*.sh" -type f ! -path "*/archive/*" 2>/dev/null | wc -l | tr -d ' ')
TOTAL_CODE=$((SCRIPTS_COUNT + PYTHON_COUNT + POC_SCRIPTS_COUNT))

# Calculer la couverture estimée (simplifié)
# En réalité, il faudrait utiliser un outil comme kcov pour bash ou coverage.py pour Python
if [ "$TOTAL_CODE" -gt 0 ]; then
    # Estimation basée sur le nombre de tests vs code
    # Ratio idéal : 1 test pour 10 lignes de code
    ESTIMATED_COVERAGE=$(( (TOTAL_TESTS * 100) / TOTAL_CODE ))
    if [ "$ESTIMATED_COVERAGE" -gt 100 ]; then
        ESTIMATED_COVERAGE=100
    fi
else
    ESTIMATED_COVERAGE=0
fi

# Générer le rapport
{
    echo "📊 Rapport de Couverture de Tests - ARKEA"
    echo "Date : $(date '+%Y-%m-%d %H:%M:%S')"
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "📋 Tests Disponibles"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "Tests unitaires      : $UNIT_TESTS"
    echo "Tests d'intégration  : $INTEGRATION_TESTS"
    echo "Tests E2E            : $E2E_TESTS"
    echo "Total tests          : $TOTAL_TESTS"
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "📝 Code à Tester"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "Scripts shell        : $SCRIPTS_COUNT"
    echo "Scripts Python       : $PYTHON_COUNT"
    echo "Scripts POCs         : $POC_SCRIPTS_COUNT"
    echo "Total code           : $TOTAL_CODE"
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "📈 Couverture Estimée"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "Couverture estimée   : $ESTIMATED_COVERAGE%"
    echo ""
    if [ "$ESTIMATED_COVERAGE" -ge 80 ]; then
        echo "✅ Couverture excellente (≥80%)"
    elif [ "$ESTIMATED_COVERAGE" -ge 60 ]; then
        echo "⚠️  Couverture bonne (60-79%)"
    elif [ "$ESTIMATED_COVERAGE" -ge 40 ]; then
        echo "⚠️  Couverture moyenne (40-59%)"
    else
        echo "❌ Couverture faible (<40%)"
    fi
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "🎯 Objectif"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "Objectif couverture  : 80%+"
    echo "Gap                  : $((80 - ESTIMATED_COVERAGE))%"
    echo ""
} > "$COVERAGE_REPORT"

# Afficher le rapport
cat "$COVERAGE_REPORT"

# Afficher le résumé
echo ""
if [ "$ESTIMATED_COVERAGE" -ge 80 ]; then
    echo -e "${GREEN}✅ Couverture estimée : $ESTIMATED_COVERAGE% (Objectif atteint)${NC}"
elif [ "$ESTIMATED_COVERAGE" -ge 60 ]; then
    echo -e "${YELLOW}⚠️  Couverture estimée : $ESTIMATED_COVERAGE% (Objectif : 80%+)${NC}"
else
    echo -e "${YELLOW}⚠️  Couverture estimée : $ESTIMATED_COVERAGE% (Objectif : 80%+)${NC}"
fi

echo ""
echo "📄 Rapport complet disponible : $COVERAGE_REPORT"
