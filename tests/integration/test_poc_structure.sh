#!/bin/bash
set -euo pipefail

# =============================================================================
# Test : Structure des POCs
# =============================================================================
# Date : 2025-12-02
# Description : Tests d'intégration de la structure des POCs
# =============================================================================

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ARKEA_HOME="$(cd "$SCRIPT_DIR/../.." && pwd)"

# Variables de test
PASSED=0
FAILED=0
TOTAL=0

# =============================================================================
# Fonction de test
# =============================================================================

test_function() {
    local test_name="$1"
    local expected="$2"
    local actual="$3"

    TOTAL=$((TOTAL + 1))

    if [ "$expected" = "$actual" ]; then
        echo "✅ $test_name"
        PASSED=$((PASSED + 1))
        return 0
    else
        echo "❌ $test_name (expected: $expected, got: $actual)"
        FAILED=$((FAILED + 1))
        return 1
    fi
}

# =============================================================================
# Tests de Structure des POCs
# =============================================================================

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "🧪 Tests d'Intégration : Structure des POCs"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Test chaque POC
for poc_dir in "$ARKEA_HOME/poc-design"/*; do
    if [ -d "$poc_dir" ]; then
        POC_NAME="$(basename "$poc_dir")"
        echo "📋 Test POC : $POC_NAME"

        # Test 1 : README.md
        if [ -f "$poc_dir/README.md" ]; then
            test_function "$POC_NAME : README.md existe" "true" "true"
        else
            test_function "$POC_NAME : README.md existe" "true" "false"
        fi

        # Test 2 : Répertoire scripts/
        if [ -d "$poc_dir/scripts" ]; then
            test_function "$POC_NAME : Répertoire scripts/ existe" "true" "true"
        else
            test_function "$POC_NAME : Répertoire scripts/ existe" "true" "false"
        fi

        # Test 3 : Répertoire doc/
        if [ -d "$poc_dir/doc" ]; then
            test_function "$POC_NAME : Répertoire doc/ existe" "true" "true"
        else
            test_function "$POC_NAME : Répertoire doc/ existe" "true" "false"
        fi

        # Test 4 : Au moins un script
        SCRIPT_COUNT=$(find "$poc_dir/scripts" -type f -name "*.sh" ! -path "*/archive/*" 2>/dev/null | wc -l | tr -d ' ')
        if [ "$SCRIPT_COUNT" -gt 0 ]; then
            test_function "$POC_NAME : Au moins un script existe" "true" "true"
        else
            test_function "$POC_NAME : Au moins un script existe" "true" "false"
        fi

        echo ""
    fi
done

# =============================================================================
# Résumé
# =============================================================================

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "📊 Résumé des Tests"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "Tests passés: $PASSED"
echo "Tests échoués: $FAILED"
echo "Total: $TOTAL"
echo ""

if [ $FAILED -eq 0 ]; then
    echo "✅ Tous les tests de structure des POCs sont passés !"
    exit 0
else
    echo "❌ $FAILED test(s) ont échoué"
    exit 1
fi
