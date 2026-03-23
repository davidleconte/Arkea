#!/bin/bash
set -euo pipefail

# =============================================================================
# Test : Portabilité Cross-Platform
# =============================================================================
# Date : 2025-12-02
# Description : Tests de portabilité pour macOS, Linux, Windows (WSL2)
# =============================================================================

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ARKEA_HOME="$(cd "$SCRIPT_DIR/../.." && pwd)"

# Charger les fonctions portables
if [ -f "$ARKEA_HOME/scripts/utils/portable_functions.sh" ]; then
    source "$ARKEA_HOME/scripts/utils/portable_functions.sh"
else
    echo "❌ portable_functions.sh non trouvé"
    exit 1
fi

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
# Tests de Détection d'OS
# =============================================================================

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "🧪 Tests de Portabilité Cross-Platform"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Test 1 : Détection d'OS
echo "📋 Test 1 : Détection d'OS"
OS=$(detect_os)
if [[ "$OSTYPE" == "darwin"* ]]; then
    test_function "Détection macOS" "macos" "$OS"
elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
    test_function "Détection Linux" "linux" "$OS"
elif [[ "$OSTYPE" == *"wsl"* ]]; then
    test_function "Détection WSL2" "linux" "$OS"
else
    echo "⚠️  OS non reconnu: $OSTYPE"
fi
echo ""

# Test 2 : get_realpath
echo "📋 Test 2 : Fonction get_realpath"
TEST_PATH="/tmp/test_path"
REALPATH=$(get_realpath "$TEST_PATH")
if [ -n "$REALPATH" ]; then
    test_function "get_realpath retourne un chemin" "non-empty" "non-empty"
else
    test_function "get_realpath retourne un chemin" "non-empty" "empty"
fi
echo ""

# Test 3 : check_port
echo "📋 Test 3 : Fonction check_port"
if command -v nc &> /dev/null || command -v netstat &> /dev/null; then
    # Tester un port probablement libre (port aléatoire > 50000)
    RANDOM_PORT=$((50000 + RANDOM % 10000))
    if check_port "$RANDOM_PORT"; then
        test_function "check_port détecte port libre" "false" "true"
    else
        test_function "check_port détecte port libre" "false" "false"
    fi
else
    echo "⚠️  nc ou netstat non disponible, test ignoré"
fi
echo ""

# Test 4 : Configuration .poc-config.sh
echo "📋 Test 4 : Configuration .poc-config.sh"
if [ -f "$ARKEA_HOME/.poc-config.sh" ]; then
    source "$ARKEA_HOME/.poc-config.sh"
    if [ -n "${ARKEA_HOME:-}" ]; then
        test_function "ARKEA_HOME défini" "non-empty" "non-empty"
    else
        test_function "ARKEA_HOME défini" "non-empty" "empty"
    fi
else
    echo "⚠️  .poc-config.sh non trouvé"
fi
echo ""

# Test 5 : Chemins portables
echo "📋 Test 5 : Chemins portables"
if [ -n "${ARKEA_HOME:-}" ]; then
    # Vérifier que les scripts utilisent des variables et non des chemins littéraux
    # ARKEA_HOME sous $HOME est normal, ce qu'on vérifie c'est l'absence de
    # chemins littéraux comme /Users/xxx dans le code
    # Note: Use a temp file to avoid exit code issues with grep in set -e mode
    TEMP_FILE=$(mktemp)
    find "$ARKEA_HOME/scripts" -name "*.sh" -type f 2>/dev/null | while read -r file; do
        # Exclude the consistency checker itself: it intentionally embeds hardcoded-path patterns
        if [[ "$file" == *"scripts/utils/91_check_consistency.sh" ]]; then
            continue
        fi
        grep -E "/Users/|/home/[a-z]" "$file" 2>/dev/null | grep -v "regex\|pattern\|example\|template" >> "$TEMP_FILE" || true
    done
    HARDCODED_IN_SCRIPTS=$(wc -l < "$TEMP_FILE" | tr -d '[:space:]')
    rm -f "$TEMP_FILE"
    if [ "${HARDCODED_IN_SCRIPTS:-0}" -eq 0 ]; then
        test_function "Pas de chemins hardcodés dans scripts" "true" "true"
    else
        test_function "Pas de chemins hardcodés dans scripts" "true" "false"
    fi
else
    echo "⚠️  ARKEA_HOME non défini"
fi
echo ""

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
    echo "✅ Tous les tests de portabilité sont passés !"
    exit 0
else
    echo "❌ $FAILED test(s) ont échoué"
    exit 1
fi
