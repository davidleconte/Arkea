#!/bin/bash
set -euo pipefail

# =============================================================================
# Test : Configuration POC (.poc-config.sh)
# =============================================================================
# Date : 2025-12-02
# Description : Tests unitaires pour .poc-config.sh
# Usage : ./tests/unit/test_poc_config.sh
# =============================================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ARKEA_HOME="$(cd "$SCRIPT_DIR/../.." && pwd)"

# Charger le framework de tests
source "$ARKEA_HOME/tests/utils/test_framework.sh"

# Charger la configuration
if [ -f "$ARKEA_HOME/.poc-config.sh" ]; then
    source "$ARKEA_HOME/.poc-config.sh"
else
    echo "❌ .poc-config.sh non trouvé"
    exit 1
fi

# =============================================================================
# Tests
# =============================================================================

test_suite_start "Tests de configuration POC"

# Test 1 : ARKEA_HOME défini
test_arke_home_defined() {
    assert_var_defined "ARKEA_HOME" "ARKEA_HOME devrait être défini"
    assert_dir_exists "$ARKEA_HOME" "ARKEA_HOME devrait pointer vers un répertoire existant"
}

# Test 2 : Répertoires principaux définis
test_main_directories() {
    assert_var_defined "BINAIRE_DIR" "BINAIRE_DIR devrait être défini"
    assert_var_defined "SOFTWARE_DIR" "SOFTWARE_DIR devrait être défini"
    assert_var_defined "HCD_DATA_DIR" "HCD_DATA_DIR devrait être défini"
}

# Test 3 : HCD Configuration
test_hcd_config() {
    assert_var_defined "HCD_VERSION" "HCD_VERSION devrait être défini"
    assert_equal "$HCD_VERSION" "1.2.3" "HCD_VERSION devrait être 1.2.3"

    assert_var_defined "HCD_HOST" "HCD_HOST devrait être défini"
    assert_var_defined "HCD_PORT" "HCD_PORT devrait être défini"
    assert_equal "$HCD_PORT" "9042" "HCD_PORT devrait être 9042"
}

# Test 4 : Spark Configuration
test_spark_config() {
    if [ -n "${SPARK_HOME:-}" ]; then
        assert_dir_exists "$SPARK_HOME" "SPARK_HOME devrait pointer vers un répertoire existant"
    fi

    assert_var_defined "SPARK_VERSION" "SPARK_VERSION devrait être défini"
    assert_equal "$SPARK_VERSION" "3.5.1" "SPARK_VERSION devrait être 3.5.1"
}

# Test 5 : Kafka Configuration
test_kafka_config() {
    if [ -n "${KAFKA_HOME:-}" ]; then
        assert_dir_exists "$KAFKA_HOME" "KAFKA_HOME devrait pointer vers un répertoire existant"
    fi
}

# Test 6 : Chemins relatifs à ARKEA_HOME
test_paths_relative_to_arke_home() {
    if [ -n "${BINAIRE_DIR:-}" ]; then
        local expected_binaire="$ARKEA_HOME/binaire"
        if [ "$BINAIRE_DIR" = "$expected_binaire" ] || [ -d "$BINAIRE_DIR" ]; then
            echo "✅ BINAIRE_DIR correctement configuré"
            TEST_PASSED=$((TEST_PASSED + 1))
            TEST_TOTAL=$((TEST_TOTAL + 1))
        else
            echo "❌ BINAIRE_DIR incorrect"
            TEST_FAILED=$((TEST_FAILED + 1))
            TEST_TOTAL=$((TEST_TOTAL + 1))
            return 1
        fi
    fi
}

# Test 7 : Variables d'environnement par défaut
test_default_values() {
    # HCD_HOST devrait avoir une valeur par défaut
    if [ -z "${HCD_HOST:-}" ]; then
        echo "❌ HCD_HOST devrait avoir une valeur par défaut"
        TEST_FAILED=$((TEST_FAILED + 1))
        TEST_TOTAL=$((TEST_TOTAL + 1))
        return 1
    else
        echo "✅ HCD_HOST a une valeur par défaut: $HCD_HOST"
        TEST_PASSED=$((TEST_PASSED + 1))
        TEST_TOTAL=$((TEST_TOTAL + 1))
    fi
}

# Exécuter les tests
test_arke_home_defined
test_main_directories
test_hcd_config
test_spark_config
test_kafka_config
test_paths_relative_to_arke_home
test_default_values

# Résumé
test_suite_end

# Code de sortie basé sur les résultats
if [ "$TEST_FAILED" -eq 0 ]; then
    exit 0
else
    exit 1
fi
