#!/bin/bash
set -euo pipefail

# =============================================================================
# Test : Intégration POC domirama2
# =============================================================================
# Date : 2025-12-02
# Description : Tests d'intégration pour le POC domirama2
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
test_suite_start "Tests d'Intégration POC domirama2"

# =============================================================================
# Tests : Structure du POC domirama2
# =============================================================================

echo ""
echo "📋 Tests : Structure du POC domirama2"

# Test 1 : Répertoire domirama2 existe
test_domirama2_directory_exists() {
    assert_dir_exists "$ARKEA_HOME/poc-design/domirama2" "Répertoire poc-design/domirama2 devrait exister"
}

# Test 2 : Scripts domirama2 existent
test_domirama2_scripts_exist() {
    assert_dir_exists "$ARKEA_HOME/poc-design/domirama2/scripts" "Répertoire poc-design/domirama2/scripts devrait exister"
}

# Test 3 : Schémas CQL existent
test_domirama2_schemas_exist() {
    assert_dir_exists "$ARKEA_HOME/poc-design/domirama2/schemas" "Répertoire poc-design/domirama2/schemas devrait exister"
}

# Test 4 : Documentation existe
test_domirama2_doc_exists() {
    assert_dir_exists "$ARKEA_HOME/poc-design/domirama2/doc" "Répertoire poc-design/domirama2/doc devrait exister"
    assert_file_exists "$ARKEA_HOME/poc-design/domirama2/README.md" "README.md domirama2 devrait exister"
}

run_test test_domirama2_directory_exists "Répertoire domirama2 existe"
run_test test_domirama2_scripts_exist "Scripts domirama2 existent"
run_test test_domirama2_schemas_exist "Schémas CQL domirama2 existent"
run_test test_domirama2_doc_exists "Documentation domirama2 existe"

# Fin de la suite de tests
test_suite_end

# Code de sortie basé sur les résultats
if [ $TEST_FAILED -eq 0 ]; then
    exit 0
else
    exit 1
fi
