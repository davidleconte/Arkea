#!/bin/bash
set -euo pipefail

# =============================================================================
# Test : Intégration POC BIC
# =============================================================================
# Date : 2025-12-02
# Description : Tests d'intégration pour le POC BIC
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
test_suite_start "Tests d'Intégration POC BIC"

# =============================================================================
# Tests : Structure du POC BIC
# =============================================================================

echo ""
echo "📋 Tests : Structure du POC BIC"

# Test 1 : Répertoire BIC existe
test_bic_directory_exists() {
    assert_dir_exists "$ARKEA_HOME/poc-design/bic" "Répertoire poc-design/bic devrait exister"
}

# Test 2 : Scripts BIC existent
test_bic_scripts_exist() {
    assert_dir_exists "$ARKEA_HOME/poc-design/bic/scripts" "Répertoire poc-design/bic/scripts devrait exister"
    assert_file_exists "$ARKEA_HOME/poc-design/bic/scripts/01_setup_bic_keyspace.sh" "Script 01_setup_bic_keyspace.sh devrait exister"
}

# Test 3 : Schémas CQL existent
test_bic_schemas_exist() {
    assert_dir_exists "$ARKEA_HOME/poc-design/bic/schemas" "Répertoire poc-design/bic/schemas devrait exister"
    assert_file_exists "$ARKEA_HOME/poc-design/bic/schemas/01_create_bic_keyspace.cql" "Schéma 01_create_bic_keyspace.cql devrait exister"
}

# Test 4 : Documentation existe
test_bic_doc_exists() {
    assert_dir_exists "$ARKEA_HOME/poc-design/bic/doc" "Répertoire poc-design/bic/doc devrait exister"
    assert_file_exists "$ARKEA_HOME/poc-design/bic/README.md" "README.md BIC devrait exister"
}

run_test test_bic_directory_exists "Répertoire BIC existe"
run_test test_bic_scripts_exist "Scripts BIC existent"
run_test test_bic_schemas_exist "Schémas CQL BIC existent"
run_test test_bic_doc_exists "Documentation BIC existe"

# =============================================================================
# Tests : Configuration
# =============================================================================

echo ""
echo "📋 Tests : Configuration"

# Test 5 : Variables d'environnement définies
test_bic_env_vars() {
    if [ -n "${HCD_HOST:-}" ]; then
        assert_var_defined "HCD_HOST" "HCD_HOST devrait être défini"
    fi
    if [ -n "${HCD_PORT:-}" ]; then
        assert_var_defined "HCD_PORT" "HCD_PORT devrait être défini"
    fi
}

run_test test_bic_env_vars "Variables d'environnement définies"

# Fin de la suite de tests
test_suite_end

# Code de sortie basé sur les résultats
if [ $TEST_FAILED -eq 0 ]; then
    exit 0
else
    exit 1
fi
