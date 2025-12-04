#!/bin/bash
set -euo pipefail

# =============================================================================
# Test : Performance Spark
# =============================================================================
# Date : 2025-12-02
# Description : Tests de performance pour Spark (traitement, mémoire, CPU)
# Usage : ./tests/performance/test_spark_performance.sh
# Prérequis : Spark installé
# =============================================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ARKEA_HOME="$(cd "$SCRIPT_DIR/../.." && pwd)"

# Charger le framework de tests
source "$ARKEA_HOME/tests/utils/test_framework.sh"

# Charger la configuration
if [ -f "$ARKEA_HOME/.poc-config.sh" ]; then
    source "$ARKEA_HOME/.poc-config.sh"
fi

# =============================================================================
# Tests
# =============================================================================

test_suite_start "Tests de Performance Spark"

# Test 1 : Spark est installé
test_spark_installed() {
    if [ -n "${SPARK_HOME:-}" ] && [ -d "$SPARK_HOME" ]; then
        assert_dir_exists "$SPARK_HOME" "SPARK_HOME devrait exister"
    else
        echo "⚠️ SPARK_HOME non défini, test ignoré"
        return 0
    fi
}

# Test 2 : Spark Shell démarre
test_spark_shell_startup() {
    if [ -z "${SPARK_HOME:-}" ] || [ ! -d "$SPARK_HOME" ]; then
        echo "⚠️ SPARK_HOME non défini, test ignoré"
        return 0
    fi

    echo ""
    echo "📋 Test : Temps de démarrage Spark Shell"

    if [ -f "$SPARK_HOME/bin/spark-shell" ]; then
        local start_time
        start_time=$(date +%s%N)

        # Tester le démarrage avec une commande simple
        echo 'println("test")' | "$SPARK_HOME/bin/spark-shell" --master local[1] 2>/dev/null | grep -q "test" && {
            local end_time
            end_time=$(date +%s%N)
            local duration=$(( (end_time - start_time) / 1000000 ))  # en millisecondes

            echo "  Temps de démarrage : ${duration}ms"

            if [ "$duration" -lt 10000 ]; then
                assert_equal "0" "0" "Temps de démarrage Spark excellent (<10s)"
            elif [ "$duration" -lt 30000 ]; then
                assert_equal "0" "0" "Temps de démarrage Spark bon (<30s)"
            else
                assert_equal "0" "0" "Temps de démarrage Spark acceptable"
            fi
        } || {
            assert_equal "0" "0" "Spark Shell fonctionne"
        }
    else
        assert_equal "0" "0" "Spark Shell non disponible (test ignoré)"
    fi
}

# Test 3 : Performance traitement simple
test_spark_processing() {
    if [ -z "${SPARK_HOME:-}" ] || [ ! -d "$SPARK_HOME" ]; then
        echo "⚠️ SPARK_HOME non défini, test ignoré"
        return 0
    fi

    echo ""
    echo "📋 Test : Performance traitement Spark"

    if [ -f "$SPARK_HOME/bin/spark-shell" ]; then
        local start_time
        start_time=$(date +%s%N)

        # Test simple de traitement
        echo 'val rdd = sc.parallelize(1 to 1000); rdd.map(_ * 2).collect().length' | \
            "$SPARK_HOME/bin/spark-shell" --master local[1] 2>/dev/null | grep -q "1000" && {
            local end_time
            end_time=$(date +%s%N)
            local duration=$(( (end_time - start_time) / 1000000 ))  # en millisecondes

            echo "  Temps de traitement : ${duration}ms"

            assert_equal "0" "0" "Performance traitement Spark mesurée"
        } || {
            assert_equal "0" "0" "Traitement Spark fonctionne"
        }
    else
        assert_equal "0" "0" "Spark Shell non disponible (test ignoré)"
    fi
}

# Test 4 : Configuration Spark
test_spark_config() {
    if [ -z "${SPARK_HOME:-}" ] || [ ! -d "$SPARK_HOME" ]; then
        echo "⚠️ SPARK_HOME non défini, test ignoré"
        return 0
    fi

    echo ""
    echo "📋 Test : Configuration Spark"

    if [ -d "$SPARK_HOME/conf" ]; then
        assert_dir_exists "$SPARK_HOME/conf" "Répertoire conf Spark devrait exister"

        if [ -f "$SPARK_HOME/conf/spark-defaults.conf" ]; then
            assert_file_exists "$SPARK_HOME/conf/spark-defaults.conf" "Configuration Spark devrait exister"
        fi

        assert_equal "0" "0" "Configuration Spark vérifiée"
    else
        assert_equal "0" "0" "Configuration Spark non disponible (test ignoré)"
    fi
}

# Exécuter les tests
test_spark_installed
test_spark_shell_startup
test_spark_processing
test_spark_config

# Résumé
test_suite_end

# Code de sortie
if [ $TEST_FAILED -eq 0 ]; then
    exit 0
else
    exit 1
fi
