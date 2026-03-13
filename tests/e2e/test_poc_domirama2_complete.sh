#!/bin/bash
set -euo pipefail

# =============================================================================
# Test E2E : POC domirama2 Complet
# =============================================================================
# Date : 2025-12-02
# Description : Test end-to-end complet du POC domirama2
# Usage : ./tests/e2e/test_poc_domirama2_complete.sh
# Prérequis : HCD démarré
# =============================================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ARKEA_HOME="$(cd "$SCRIPT_DIR/../.." && pwd)"

# Cleanup on exit
cleanup() {
    echo "[CLEANUP] Test domirama2 E2E finished"
}
trap cleanup EXIT

# Charger le framework de tests
source "$ARKEA_HOME/tests/utils/test_framework.sh"

# Charger la configuration
if [ -f "$ARKEA_HOME/.poc-config.sh" ]; then
    source "$ARKEA_HOME/.poc-config.sh"
fi

# Variables de test
DOMIRAMA2_DIR="$ARKEA_HOME/poc-design/domirama2"

# =============================================================================
# Tests
# =============================================================================

test_suite_start "Test E2E POC domirama2 Complet"

# Test 1 : Structure du POC domirama2
test_domirama2_structure() {
    assert_dir_exists "$DOMIRAMA2_DIR" "Répertoire poc-design/domirama2 devrait exister"
    assert_dir_exists "$DOMIRAMA2_DIR/scripts" "Répertoire scripts domirama2 devrait exister"
    assert_dir_exists "$DOMIRAMA2_DIR/schemas" "Répertoire schemas domirama2 devrait exister"
    assert_file_exists "$DOMIRAMA2_DIR/README.md" "README.md domirama2 devrait exister"
}

# Test 2 : Schémas CQL existent
test_domirama2_schemas() {
    local schema_count
    schema_count=$(find "$DOMIRAMA2_DIR/schemas" -name "*.cql" -type f 2>/dev/null | wc -l | tr -d ' ')
    if [ "$schema_count" -gt 0 ]; then
        assert_equal "0" "0" "Schémas CQL domirama2 existent ($schema_count fichiers)"
    else
        assert_equal "1" "0" "Aucun schéma CQL domirama2 trouvé"
    fi
}

# Test 3 : Scripts principaux existent
test_domirama2_scripts() {
    local script_count
    script_count=$(find "$DOMIRAMA2_DIR/scripts" -name "*.sh" -type f ! -path "*/archive/*" 2>/dev/null | wc -l | tr -d ' ')
    if [ "$script_count" -gt 0 ]; then
        assert_equal "0" "0" "Scripts domirama2 existent ($script_count fichiers)"
    else
        assert_equal "1" "0" "Aucun script domirama2 trouvé"
    fi
}

# Test 4 : HCD est démarré
test_hcd_running() {
    assert_port_open "${HCD_PORT:-9042}" "HCD devrait être démarré"
}

# Test 5 : Documentation existe
test_domirama2_documentation() {
    assert_dir_exists "$DOMIRAMA2_DIR/doc" "Répertoire doc domirama2 devrait exister"

    local doc_count
    doc_count=$(find "$DOMIRAMA2_DIR/doc" -name "*.md" -type f 2>/dev/null | wc -l | tr -d ' ')
    if [ "$doc_count" -gt 0 ]; then
        assert_equal "0" "0" "Documentation domirama2 existe ($doc_count fichiers)"
    else
        assert_equal "1" "0" "Aucune documentation domirama2 trouvée"
    fi
}

# Test 6 : Exemples existent
test_domirama2_examples() {
    if [ -d "$DOMIRAMA2_DIR/examples" ]; then
        local example_count
        example_count=$(find "$DOMIRAMA2_DIR/examples" -type f 2>/dev/null | wc -l | tr -d ' ')
        if [ "$example_count" -gt 0 ]; then
            assert_equal "0" "0" "Exemples domirama2 existent ($example_count fichiers)"
        else
            assert_equal "0" "0" "Répertoire examples existe mais vide (OK)"
        fi
    else
        assert_equal "0" "0" "Répertoire examples n'existe pas (optionnel)"
    fi
}

# Exécuter les tests
test_domirama2_structure
test_domirama2_schemas
test_domirama2_scripts
test_hcd_running
test_domirama2_documentation
test_domirama2_examples

# Résumé
test_suite_end

# Code de sortie basé sur les résultats
if [ $TEST_FAILED -eq 0 ]; then
    exit 0
else
    exit 1
fi
