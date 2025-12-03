#!/bin/bash
set -euo pipefail

# =============================================================================
# Test : Fonctions Portables - Exemple
# =============================================================================
# Date : 2025-12-02
# Description : Exemple de test unitaire pour portable_functions.sh
# Usage : ./tests/unit/test_portable_functions_example.sh
# =============================================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ARKEA_HOME="$(cd "$SCRIPT_DIR/../.." && pwd)"

# Charger le framework de tests
source "$ARKEA_HOME/tests/utils/test_framework.sh"

# Charger les fonctions à tester
if [ -f "$ARKEA_HOME/scripts/utils/portable_functions.sh" ]; then
    source "$ARKEA_HOME/scripts/utils/portable_functions.sh"
else
    echo "❌ portable_functions.sh non trouvé"
    exit 1
fi

# =============================================================================
# Tests
# =============================================================================

test_suite_start "Tests des fonctions portables"

# Test 1 : get_realpath avec chemin absolu
test_get_realpath_absolute() {
    local result
    result=$(get_realpath "$ARKEA_HOME")
    assert_equal "$result" "$ARKEA_HOME" "get_realpath avec chemin absolu"
}

# Test 2 : get_realpath avec chemin relatif
test_get_realpath_relative() {
    local result
    cd "$ARKEA_HOME"
    result=$(get_realpath ".")
    assert_equal "$result" "$ARKEA_HOME" "get_realpath avec chemin relatif"
}

# Test 3 : check_port avec port fermé (port improbable)
test_check_port_closed() {
    local port=99999  # Port improbable
    if check_port "$port"; then
        echo "❌ Port $port devrait être fermé"
        return 1
    else
        echo "✅ Port $port correctement détecté comme fermé"
        TEST_PASSED=$((TEST_PASSED + 1))
        TEST_TOTAL=$((TEST_TOTAL + 1))
        return 0
    fi
}

# Test 4 : Vérification de commandes système
test_system_commands() {
    assert_command_exists "bash" "Bash devrait être disponible"
    assert_command_exists "ls" "ls devrait être disponible"
}

# Test 5 : Vérification de fichiers de configuration
test_config_files() {
    assert_file_exists "$ARKEA_HOME/.poc-config.sh" ".poc-config.sh devrait exister"
    assert_file_exists "$ARKEA_HOME/.gitignore" ".gitignore devrait exister"
}

# Exécuter les tests
test_get_realpath_absolute
test_get_realpath_relative
test_check_port_closed
test_system_commands
test_config_files

# Résumé
test_suite_end

# Code de sortie basé sur les résultats
if [ "$TEST_FAILED" -eq 0 ]; then
    exit 0
else
    exit 1
fi
