#!/bin/bash
set -euo pipefail

# =============================================================================
# Test : Intégration POC domiramaCatOps
# =============================================================================
# Date : 2025-12-02
# Description : Tests d'intégration pour le POC domiramaCatOps
# =============================================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ARKEA_HOME="$(cd "$SCRIPT_DIR/../.." && pwd)"

# Charger le framework de tests
source "$ARKEA_HOME/tests/utils/test_framework.sh"

# Charger la configuration
if [ -f "$ARKEA_HOME/.poc-config.sh" ]; then
    source "$ARKEA_HOME/.poc-config.sh"
fi

# Début de la suite de tests
test_suite_start "Tests d'Intégration POC domiramaCatOps"

# =============================================================================
# Tests : Structure du POC domiramaCatOps
# =============================================================================

echo ""
echo "📋 Tests : Structure du POC domiramaCatOps"

# Test 1 : Répertoire domiramaCatOps existe
test_domiramaCatOps_directory_exists() {
    assert_dir_exists "$ARKEA_HOME/poc-design/domiramaCatOps" "Répertoire poc-design/domiramaCatOps devrait exister"
}

# Test 2 : Scripts domiramaCatOps existent
test_domiramaCatOps_scripts_exist() {
    assert_dir_exists "$ARKEA_HOME/poc-design/domiramaCatOps/scripts" "Répertoire poc-design/domiramaCatOps/scripts devrait exister"
}

# Test 3 : Schémas CQL existent
test_domiramaCatOps_schemas_exist() {
    assert_dir_exists "$ARKEA_HOME/poc-design/domiramaCatOps/schemas" "Répertoire poc-design/domiramaCatOps/schemas devrait exister"
}

# Test 4 : Documentation existe
test_domiramaCatOps_doc_exists() {
    assert_dir_exists "$ARKEA_HOME/poc-design/domiramaCatOps/doc" "Répertoire poc-design/domiramaCatOps/doc devrait exister"
    assert_file_exists "$ARKEA_HOME/poc-design/domiramaCatOps/README.md" "README.md domiramaCatOps devrait exister"
}

run_test test_domiramaCatOps_directory_exists "Répertoire domiramaCatOps existe"
run_test test_domiramaCatOps_scripts_exist "Scripts domiramaCatOps existent"
run_test test_domiramaCatOps_schemas_exist "Schémas CQL domiramaCatOps existent"
run_test test_domiramaCatOps_doc_exists "Documentation domiramaCatOps existe"

# Fin de la suite de tests
test_suite_end

# Code de sortie basé sur les résultats
if [ $TEST_FAILED -eq 0 ]; then
    exit 0
else
    exit 1
fi
