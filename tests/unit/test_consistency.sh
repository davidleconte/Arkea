#!/bin/bash
set -euo pipefail

# =============================================================================
# Test : Cohérence du Projet
# =============================================================================
# Date : 2025-12-02
# Description : Tests de cohérence (structure, conventions, documentation)
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
# Tests de Structure
# =============================================================================

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "🧪 Tests de Cohérence du Projet"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Test 1 : Structure des répertoires
echo "📋 Test 1 : Structure des répertoires"
REQUIRED_DIRS=("scripts" "docs" "poc-design" "tests")
for dir in "${REQUIRED_DIRS[@]}"; do
    if [ -d "$ARKEA_HOME/$dir" ]; then
        test_function "Répertoire $dir existe" "true" "true"
    else
        test_function "Répertoire $dir existe" "true" "false"
    fi
done
echo ""

# Test 2 : Fichiers de configuration
echo "📋 Test 2 : Fichiers de configuration"
REQUIRED_FILES=(".poc-config.sh" ".poc-profile" "README.md" "LICENSE")
for file in "${REQUIRED_FILES[@]}"; do
    if [ -f "$ARKEA_HOME/$file" ]; then
        test_function "Fichier $file existe" "true" "true"
    else
        test_function "Fichier $file existe" "true" "false"
    fi
done
echo ""

# Test 3 : Scripts avec set -euo pipefail
echo "📋 Test 3 : Scripts avec set -euo pipefail"
SCRIPTS_WITHOUT_STANDARDS=0
while IFS= read -r script; do
    if [ -f "$script" ]; then
        if ! head -5 "$script" | grep -q "set -euo pipefail"; then
            SCRIPTS_WITHOUT_STANDARDS=$((SCRIPTS_WITHOUT_STANDARDS + 1))
        fi
    fi
done < <(find "$ARKEA_HOME/scripts" -type f -name "*.sh" \
    ! -path "$ARKEA_HOME/.git/*" \
    ! -path "*/archive/*" 2>/dev/null)

if [ $SCRIPTS_WITHOUT_STANDARDS -eq 0 ]; then
    test_function "Tous les scripts ont set -euo pipefail" "0" "$SCRIPTS_WITHOUT_STANDARDS"
else
    test_function "Tous les scripts ont set -euo pipefail" "0" "$SCRIPTS_WITHOUT_STANDARDS"
fi
echo ""

# Test 4 : Chemins hardcodés dans les scripts
echo "📋 Test 4 : Chemins hardcodés dans les scripts"
HARDCODED_PATHS=0
# On vérifie uniquement les scripts shell, pas les docs ni les outils de migration
# Note: Use temp file to avoid exit code issues with grep in set -e mode
TEMP_FILE=$(mktemp)
find "$ARKEA_HOME/scripts" -type f -name "*.sh" ! -path "*/archive/*" 2>/dev/null | while read -r file; do
    grep -E "/Users/|/home/[a-z]" "$file" 2>/dev/null | grep -v "^[[:space:]]*#" | grep -v "\${" >> "$TEMP_FILE" || true
done
HARDCODED_PATHS=$(wc -l < "$TEMP_FILE" | tr -d '[:space:]')
rm -f "$TEMP_FILE"

# Note: On tolère quelques chemins dans les exemples/commentaires
if [ "${HARDCODED_PATHS:-0}" -lt 10 ]; then
    test_function "Peu de chemins hardcodés (< 10)" "true" "true"
else
    test_function "Peu de chemins hardcodés (< 10)" "true" "false"
fi
echo ""

# Test 5 : Documentation des POCs
echo "📋 Test 5 : Documentation des POCs"
POCS_WITH_README=0
TOTAL_POCS=0
for poc_dir in "$ARKEA_HOME/poc-design"/*; do
    if [ -d "$poc_dir" ]; then
        TOTAL_POCS=$((TOTAL_POCS + 1))
        if [ -f "$poc_dir/README.md" ]; then
            POCS_WITH_README=$((POCS_WITH_README + 1))
        fi
    fi
done

if [ $POCS_WITH_README -eq $TOTAL_POCS ] && [ $TOTAL_POCS -gt 0 ]; then
    test_function "Tous les POCs ont un README.md" "true" "true"
else
    test_function "Tous les POCs ont un README.md" "true" "false"
fi
echo ""

# Test 6 : Scripts utilitaires
echo "📋 Test 6 : Scripts utilitaires"
REQUIRED_UTILS=("90_list_scripts.sh" "91_check_consistency.sh" "92_generate_docs.sh" "93_fix_hardcoded_paths.sh" "95_cleanup.sh")
for util in "${REQUIRED_UTILS[@]}"; do
    if [ -f "$ARKEA_HOME/scripts/utils/$util" ]; then
        test_function "Script utilitaire $util existe" "true" "true"
    else
        test_function "Script utilitaire $util existe" "true" "false"
    fi
done
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
    echo "✅ Tous les tests de cohérence sont passés !"
    exit 0
else
    echo "❌ $FAILED test(s) ont échoué"
    exit 1
fi
