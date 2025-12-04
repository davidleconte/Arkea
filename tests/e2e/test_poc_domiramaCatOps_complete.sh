#!/bin/bash
set -euo pipefail

# =============================================================================
# Test E2E : POC domiramaCatOps Complet
# =============================================================================
# Date : 2025-12-02
# Description : Test end-to-end complet du POC domiramaCatOps
# Usage : ./tests/e2e/test_poc_domiramaCatOps_complete.sh
# Prérequis : HCD démarré
# =============================================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ARKEA_HOME="$(cd "$SCRIPT_DIR/../.." && pwd)"

# Charger le framework de tests
source "$ARKEA_HOME/tests/utils/test_framework.sh"

# Charger la configuration
if [ -f "$ARKEA_HOME/.poc-config.sh" ]; then
    source "$ARKEA_HOME/.poc-config.sh"
fi

# Variables de test
DOMIRAMACATOPS_DIR="$ARKEA_HOME/poc-design/domiramaCatOps"

# =============================================================================
# Tests
# =============================================================================

test_suite_start "Test E2E POC domiramaCatOps Complet"

# Test 1 : Structure du POC domiramaCatOps
test_domiramaCatOps_structure() {
    assert_dir_exists "$DOMIRAMACATOPS_DIR" "Répertoire poc-design/domiramaCatOps devrait exister"
    assert_dir_exists "$DOMIRAMACATOPS_DIR/scripts" "Répertoire scripts domiramaCatOps devrait exister"
    assert_dir_exists "$DOMIRAMACATOPS_DIR/schemas" "Répertoire schemas domiramaCatOps devrait exister"
    assert_file_exists "$DOMIRAMACATOPS_DIR/README.md" "README.md domiramaCatOps devrait exister"
}

# Test 2 : Schémas CQL existent
test_domiramaCatOps_schemas() {
    local schema_count
    schema_count=$(find "$DOMIRAMACATOPS_DIR/schemas" -name "*.cql" -type f 2>/dev/null | wc -l | tr -d ' ')
    if [ "$schema_count" -gt 0 ]; then
        assert_equal "0" "0" "Schémas CQL domiramaCatOps existent ($schema_count fichiers)"
    else
        assert_equal "1" "0" "Aucun schéma CQL domiramaCatOps trouvé"
    fi
}

# Test 3 : Scripts principaux existent
test_domiramaCatOps_scripts() {
    local script_count
    script_count=$(find "$DOMIRAMACATOPS_DIR/scripts" -name "*.sh" -type f ! -path "*/archive/*" 2>/dev/null | wc -l | tr -d ' ')
    if [ "$script_count" -gt 0 ]; then
        assert_equal "0" "0" "Scripts domiramaCatOps existent ($script_count fichiers)"
    else
        assert_equal "1" "0" "Aucun script domiramaCatOps trouvé"
    fi
}

# Test 4 : HCD est démarré
test_hcd_running() {
    assert_port_open "${HCD_PORT:-9042}" "HCD devrait être démarré"
}

# Test 5 : Documentation existe
test_domiramaCatOps_documentation() {
    assert_dir_exists "$DOMIRAMACATOPS_DIR/doc" "Répertoire doc domiramaCatOps devrait exister"

    local doc_count
    doc_count=$(find "$DOMIRAMACATOPS_DIR/doc" -name "*.md" -type f 2>/dev/null | wc -l | tr -d ' ')
    if [ "$doc_count" -gt 0 ]; then
        assert_equal "0" "0" "Documentation domiramaCatOps existe ($doc_count fichiers)"
    else
        assert_equal "1" "0" "Aucune documentation domiramaCatOps trouvée"
    fi
}

# Test 6 : Exemples Python existent
test_domiramaCatOps_examples() {
    if [ -d "$DOMIRAMACATOPS_DIR/examples" ]; then
        local python_count
        python_count=$(find "$DOMIRAMACATOPS_DIR/examples" -name "*.py" -type f 2>/dev/null | wc -l | tr -d ' ')
        if [ "$python_count" -gt 0 ]; then
            assert_equal "0" "0" "Exemples Python domiramaCatOps existent ($python_count fichiers)"
        else
            assert_equal "0" "0" "Répertoire examples existe mais vide (OK)"
        fi
    else
        assert_equal "0" "0" "Répertoire examples n'existe pas (optionnel)"
    fi
}

# Exécuter les tests
test_domiramaCatOps_structure
test_domiramaCatOps_schemas
test_domiramaCatOps_scripts
test_hcd_running
test_domiramaCatOps_documentation
test_domiramaCatOps_examples

# Résumé
test_suite_end

# Code de sortie basé sur les résultats
if [ $TEST_FAILED -eq 0 ]; then
    exit 0
else
    exit 1
fi
