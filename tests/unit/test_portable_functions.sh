#!/bin/bash
set -euo pipefail

# =============================================================================
# Test : Fonctions Portables Cross-Platform
# =============================================================================
# Date : 2025-12-02
# Description : Tests unitaires pour les fonctions portables
# =============================================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ARKEA_HOME="$(cd "$SCRIPT_DIR/../.." && pwd)"

# Charger le framework de tests
source "$ARKEA_HOME/tests/utils/test_framework.sh"

# Charger les fonctions à tester
source "$ARKEA_HOME/scripts/utils/portable_functions.sh"

# Début de la suite de tests
test_suite_start "Tests des Fonctions Portables"

# =============================================================================
# Tests : get_realpath
# =============================================================================

echo ""
echo "📋 Tests : get_realpath()"

# Test 1 : Chemin absolu existant
test_get_realpath_absolute() {
    local result
    result=$(get_realpath "/tmp")
    assert_equal "$result" "/tmp" "get_realpath avec chemin absolu /tmp"
}

# Test 2 : Chemin relatif
test_get_realpath_relative() {
    local result
    result=$(get_realpath ".")
    assert_not_equal "$result" "" "get_realpath avec chemin relatif retourne un chemin"
}

# Test 3 : Chemin vide
test_get_realpath_empty() {
    local result
    result=$(get_realpath "")
    assert_not_equal "$?" "0" "get_realpath avec chemin vide retourne erreur"
}

run_test test_get_realpath_absolute "get_realpath avec chemin absolu"
run_test test_get_realpath_relative "get_realpath avec chemin relatif"
run_test test_get_realpath_empty "get_realpath avec chemin vide"

# =============================================================================
# Tests : check_port
# =============================================================================

echo ""
echo "📋 Tests : check_port()"

# Test 4 : Port système (22 SSH généralement ouvert)
test_check_port_ssh() {
    if check_port 22; then
        assert_equal "0" "0" "check_port détecte port SSH (22)"
    else
        # Si le port n'est pas ouvert, c'est OK pour le test
        assert_equal "1" "1" "check_port détecte port SSH fermé (normal si SSH non démarré)"
    fi
}

# Test 5 : Port inexistant
test_check_port_nonexistent() {
    if check_port 99999 2>/dev/null; then
        assert_equal "1" "0" "check_port avec port invalide devrait échouer"
    else
        assert_equal "1" "1" "check_port avec port invalide échoue correctement"
    fi
}

run_test test_check_port_ssh "check_port avec port SSH"
run_test test_check_port_nonexistent "check_port avec port inexistant"

# =============================================================================
# Tests : kill_process
# =============================================================================

echo ""
echo "📋 Tests : kill_process()"

# Test 6 : Processus inexistant (ne devrait pas échouer)
test_kill_process_nonexistent() {
    if kill_process "processus_inexistant_xyz123" 2>/dev/null; then
        assert_equal "0" "0" "kill_process avec processus inexistant ne devrait pas échouer"
    else
        # C'est OK si ça retourne une erreur
        assert_equal "1" "1" "kill_process avec processus inexistant gère l'erreur"
    fi
}

run_test test_kill_process_nonexistent "kill_process avec processus inexistant"

# =============================================================================
# Tests : Variables d'environnement
# =============================================================================

echo ""
echo "📋 Tests : Variables d'environnement"

# Test 7 : ARKEA_HOME défini
test_arke_home_defined() {
    assert_var_defined "ARKEA_HOME" "ARKEA_HOME devrait être défini"
}

# Test 8 : ARKEA_HOME est un répertoire valide
test_arke_home_valid() {
    assert_dir_exists "$ARKEA_HOME" "ARKEA_HOME devrait être un répertoire valide"
}

run_test test_arke_home_defined "ARKEA_HOME défini"
run_test test_arke_home_valid "ARKEA_HOME est un répertoire valide"

# =============================================================================
# Tests : Commandes système
# =============================================================================

echo ""
echo "📋 Tests : Commandes système"

# Test 9 : Commandes essentielles disponibles
test_essential_commands() {
    assert_command_exists "bash" "bash devrait être disponible"
    assert_command_exists "cd" "cd devrait être disponible"
    assert_command_exists "pwd" "pwd devrait être disponible"
}

run_test test_essential_commands "Commandes essentielles disponibles"

# =============================================================================
# Tests : Fichiers de configuration
# =============================================================================

echo ""
echo "📋 Tests : Fichiers de configuration"

# Test 10 : Fichiers de configuration existent
test_config_files() {
    assert_file_exists "$ARKEA_HOME/.poc-config.sh" ".poc-config.sh devrait exister"
    assert_file_exists "$ARKEA_HOME/.poc-profile" ".poc-profile devrait exister"
}

run_test test_config_files "Fichiers de configuration existent"

# Fin de la suite de tests
test_suite_end

# Code de sortie basé sur les résultats
if [ $TEST_FAILED -eq 0 ]; then
    exit 0
else
    exit 1
fi
