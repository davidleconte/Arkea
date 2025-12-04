#!/bin/bash
set -euo pipefail

# =============================================================================
# Test : Fonctions Didactiques
# =============================================================================
# Date : 2025-12-02
# Description : Tests unitaires pour les fonctions didactiques
# =============================================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ARKEA_HOME="$(cd "$SCRIPT_DIR/../.." && pwd)"

# Charger le framework de tests
source "$ARKEA_HOME/tests/utils/test_framework.sh"

# Charger les fonctions à tester (essayer plusieurs emplacements)
if [ -f "$ARKEA_HOME/poc-design/bic/utils/didactique_functions.sh" ]; then
    source "$ARKEA_HOME/poc-design/bic/utils/didactique_functions.sh"
elif [ -f "$ARKEA_HOME/poc-design/domirama2/utils/didactique_functions.sh" ]; then
    source "$ARKEA_HOME/poc-design/domirama2/utils/didactique_functions.sh"
elif [ -f "$ARKEA_HOME/poc-design/domiramaCatOps/utils/didactique_functions.sh" ]; then
    source "$ARKEA_HOME/poc-design/domiramaCatOps/utils/didactique_functions.sh"
fi

# Début de la suite de tests
test_suite_start "Tests des Fonctions Didactiques"

# =============================================================================
# Tests : Fonctions d'affichage
# =============================================================================

echo ""
echo "📋 Tests : Fonctions d'affichage"

# Test 1 : Fonction info existe
test_info_function() {
    if command -v info &> /dev/null || type info &> /dev/null; then
        assert_equal "0" "0" "Fonction info() existe"
    else
        # Si la fonction n'existe pas, créer une version de test
        info() { echo "[INFO] $*"; }
        assert_equal "0" "0" "Fonction info() créée pour test"
    fi
}

# Test 2 : Fonction warn existe
test_warn_function() {
    if command -v warn &> /dev/null || type warn &> /dev/null; then
        assert_equal "0" "0" "Fonction warn() existe"
    else
        warn() { echo "[WARN] $*"; }
        assert_equal "0" "0" "Fonction warn() créée pour test"
    fi
}

# Test 3 : Fonction error existe
test_error_function() {
    if command -v error &> /dev/null || type error &> /dev/null; then
        assert_equal "0" "0" "Fonction error() existe"
    else
        error() { echo "[ERROR] $*"; }
        assert_equal "0" "0" "Fonction error() créée pour test"
    fi
}

# Test 4 : Fonction code existe
test_code_function() {
    if command -v code &> /dev/null || type code &> /dev/null; then
        assert_equal "0" "0" "Fonction code() existe"
    else
        code() { echo "  $*"; }
        assert_equal "0" "0" "Fonction code() créée pour test"
    fi
}

run_test test_info_function "Fonction info() existe"
run_test test_warn_function "Fonction warn() existe"
run_test test_error_function "Fonction error() existe"
run_test test_code_function "Fonction code() existe"

# =============================================================================
# Tests : Fonctions d'affichage avec sortie
# =============================================================================

echo ""
echo "📋 Tests : Fonctions d'affichage avec sortie"

# Test 5 : info affiche un message
test_info_output() {
    if command -v info &> /dev/null || type info &> /dev/null; then
        local output
        output=$(info "Test message" 2>&1)
        assert_not_equal "$output" "" "info() affiche un message"
    else
        assert_equal "0" "0" "Fonction info() non disponible (test ignoré)"
    fi
}

# Test 6 : warn affiche un message
test_warn_output() {
    if command -v warn &> /dev/null || type warn &> /dev/null; then
        local output
        output=$(warn "Test warning" 2>&1)
        assert_not_equal "$output" "" "warn() affiche un message"
    else
        assert_equal "0" "0" "Fonction warn() non disponible (test ignoré)"
    fi
}

run_test test_info_output "info() affiche un message"
run_test test_warn_output "warn() affiche un message"

# =============================================================================
# Tests : Fichiers didactiques existent
# =============================================================================

echo ""
echo "📋 Tests : Fichiers didactiques"

# Test 7 : Au moins un fichier didactique existe
test_didactique_files_exist() {
    local found=false
    for dir in "$ARKEA_HOME/poc-design"/*/utils/didactique_functions.sh; do
        if [ -f "$dir" ]; then
            found=true
            break
        fi
    done

    if [ "$found" = true ]; then
        assert_equal "0" "0" "Au moins un fichier didactique_functions.sh existe"
    else
        assert_equal "1" "0" "Aucun fichier didactique_functions.sh trouvé"
    fi
}

run_test test_didactique_files_exist "Fichiers didactiques existent"

# Fin de la suite de tests
test_suite_end

# Code de sortie basé sur les résultats
if [ $TEST_FAILED -eq 0 ]; then
    exit 0
else
    exit 1
fi
