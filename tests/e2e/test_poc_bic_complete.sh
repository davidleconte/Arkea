#!/bin/bash
set -euo pipefail

# =============================================================================
# Test E2E : POC BIC Complet
# =============================================================================
# Date : 2025-12-02
# Description : Test end-to-end complet du POC BIC
# Usage : ./tests/e2e/test_poc_bic_complete.sh
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
BIC_DIR="$ARKEA_HOME/poc-design/bic"
TEST_KEYSPACE="bic_poc_test"

# =============================================================================
# Fonctions utilitaires
# =============================================================================

cleanup() {
    echo ""
    echo "🧹 Nettoyage..."

    if command -v cqlsh &> /dev/null; then
        cqlsh "${HCD_HOST:-localhost}" "${HCD_PORT:-9042}" <<EOF 2>/dev/null || true
DROP KEYSPACE IF EXISTS $TEST_KEYSPACE;
EOF
    fi

    echo "✅ Nettoyage terminé"
}

# Trap pour cleanup en cas d'erreur
trap cleanup EXIT

# =============================================================================
# Tests
# =============================================================================

test_suite_start "Test E2E POC BIC Complet"

# Test 1 : Structure du POC BIC
test_bic_structure() {
    assert_dir_exists "$BIC_DIR" "Répertoire poc-design/bic devrait exister"
    assert_dir_exists "$BIC_DIR/scripts" "Répertoire scripts BIC devrait exister"
    assert_dir_exists "$BIC_DIR/schemas" "Répertoire schemas BIC devrait exister"
    assert_file_exists "$BIC_DIR/README.md" "README.md BIC devrait exister"
}

# Test 2 : Schémas CQL existent
test_bic_schemas() {
    assert_file_exists "$BIC_DIR/schemas/01_create_bic_keyspace.cql" "Schéma keyspace devrait exister"
    assert_file_exists "$BIC_DIR/schemas/02_create_bic_tables.cql" "Schéma tables devrait exister"
    assert_file_exists "$BIC_DIR/schemas/03_create_bic_indexes.cql" "Schéma indexes devrait exister"
}

# Test 3 : Scripts principaux existent
test_bic_scripts() {
    assert_file_exists "$BIC_DIR/scripts/01_setup_bic_keyspace.sh" "Script setup keyspace devrait exister"
    assert_file_exists "$BIC_DIR/scripts/02_setup_bic_tables.sh" "Script setup tables devrait exister"
    assert_file_exists "$BIC_DIR/scripts/03_setup_bic_indexes.sh" "Script setup indexes devrait exister"
}

# Test 4 : HCD est démarré
test_hcd_running() {
    assert_port_open "${HCD_PORT:-9042}" "HCD devrait être démarré"
}

# Test 5 : Connectivité HCD
test_hcd_connectivity() {
    if ! command -v cqlsh &> /dev/null; then
        echo "⚠️ cqlsh non disponible, test ignoré"
        return 0
    fi

    if cqlsh "${HCD_HOST:-localhost}" "${HCD_PORT:-9042}" -e "SELECT release_version FROM system.local;" > /dev/null 2>&1; then
        assert_equal "0" "0" "Connectivité HCD vérifiée"
    else
        assert_equal "1" "0" "Échec de connexion à HCD"
    fi
}

# Test 6 : Scripts sont exécutables
test_bic_scripts_executable() {
    local scripts=(
        "$BIC_DIR/scripts/01_setup_bic_keyspace.sh"
        "$BIC_DIR/scripts/02_setup_bic_tables.sh"
        "$BIC_DIR/scripts/03_setup_bic_indexes.sh"
    )

    for script in "${scripts[@]}"; do
        if [ -f "$script" ]; then
            if [ -x "$script" ]; then
                assert_equal "0" "0" "Script $(basename "$script") est exécutable"
            else
                assert_equal "1" "0" "Script $(basename "$script") n'est pas exécutable"
            fi
        fi
    done
}

# Test 7 : Documentation existe
test_bic_documentation() {
    assert_dir_exists "$BIC_DIR/doc" "Répertoire doc BIC devrait exister"

    # Vérifier au moins un fichier de documentation
    local doc_count
    doc_count=$(find "$BIC_DIR/doc" -name "*.md" -type f 2>/dev/null | wc -l | tr -d ' ')
    if [ "$doc_count" -gt 0 ]; then
        assert_equal "0" "0" "Documentation BIC existe ($doc_count fichiers)"
    else
        assert_equal "1" "0" "Aucune documentation BIC trouvée"
    fi
}

# Exécuter les tests
test_bic_structure
test_bic_schemas
test_bic_scripts
test_hcd_running
test_hcd_connectivity
test_bic_scripts_executable
test_bic_documentation

# Résumé
test_suite_end

# Code de sortie basé sur les résultats
if [ $TEST_FAILED -eq 0 ]; then
    exit 0
else
    exit 1
fi
