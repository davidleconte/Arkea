#!/bin/bash
set -euo pipefail

# =============================================================================
# Script : Exécuter les Tests de Portabilité
# =============================================================================
# Date : 2025-12-02
# Description : Exécute tous les tests de portabilité
# =============================================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ARKEA_HOME="$(cd "$SCRIPT_DIR/.." && pwd)"

# Couleurs
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Compteurs
TOTAL_PASSED=0
TOTAL_FAILED=0

echo "🧪 Exécution des tests de portabilité..."
echo ""

# Test de portabilité
if [ -f "${SCRIPT_DIR}/unit/test_portability.sh" ]; then
    echo "📋 Test de portabilité..."
    if "${SCRIPT_DIR}/unit/test_portability.sh"; then
        TOTAL_PASSED=$((TOTAL_PASSED + 1))
    else
        TOTAL_FAILED=$((TOTAL_FAILED + 1))
    fi
    echo ""
fi

# Résumé
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
if [ $TOTAL_FAILED -eq 0 ]; then
    echo -e "${GREEN}✅ Tous les tests de portabilité sont passés !${NC}"
    exit 0
else
    echo -e "${RED}❌ $TOTAL_FAILED suite(s) de tests ont échoué${NC}"
    exit 1
fi
