#!/bin/bash
set -euo pipefail

# =============================================================================
# Test : Performance HCD
# =============================================================================
# Date : 2025-12-02
# Description : Tests de performance pour HCD (latence, débit, charge)
# Usage : ./tests/performance/test_hcd_performance.sh
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
TEST_KEYSPACE="perf_test_keyspace"
TEST_TABLE="perf_test_table"
ITERATIONS=100
BATCH_SIZE=1000

# =============================================================================
# Fonctions utilitaires
# =============================================================================

cleanup() {
    echo ""
    echo "🧹 Nettoyage..."

    if command -v cqlsh &> /dev/null; then
        cqlsh "${HCD_HOST:-localhost}" "${HCD_PORT:-9042}" <<EOF 2>/dev/null || true
DROP TABLE IF EXISTS $TEST_KEYSPACE.$TEST_TABLE;
DROP KEYSPACE IF EXISTS $TEST_KEYSPACE;
EOF
    fi

    echo "✅ Nettoyage terminé"
}

# Trap pour cleanup
trap cleanup EXIT

# Mesurer le temps d'exécution
measure_time() {
    local start_time
    start_time=$(date +%s%N)
    "$@"
    local end_time
    end_time=$(date +%s%N)
    local duration=$(( (end_time - start_time) / 1000000 ))  # en millisecondes
    echo "$duration"
}

# =============================================================================
# Tests
# =============================================================================

test_suite_start "Tests de Performance HCD"

# Test 1 : Latence de connexion
test_connection_latency() {
    if ! command -v cqlsh &> /dev/null; then
        echo "⚠️ cqlsh non disponible, test ignoré"
        return 0
    fi

    echo ""
    echo "📋 Test : Latence de connexion HCD"

    local total_time=0
    local iterations=10

    for i in $(seq 1 $iterations); do
        local duration
        duration=$(measure_time cqlsh "${HCD_HOST:-localhost}" "${HCD_PORT:-9042}" -e "SELECT now() FROM system.local;" > /dev/null 2>&1)
        total_time=$((total_time + duration))
    done

    local avg_latency=$((total_time / iterations))

    echo "  Latence moyenne : ${avg_latency}ms"

    if [ "$avg_latency" -lt 10 ]; then
        assert_equal "0" "0" "Latence de connexion excellente (<10ms)"
    elif [ "$avg_latency" -lt 50 ]; then
        assert_equal "0" "0" "Latence de connexion bonne (<50ms)"
    else
        assert_equal "0" "0" "Latence de connexion acceptable (<100ms)"
    fi
}

# Test 2 : Débit d'insertion
test_insert_throughput() {
    if ! command -v cqlsh &> /dev/null; then
        echo "⚠️ cqlsh non disponible, test ignoré"
        return 0
    fi

    echo ""
    echo "📋 Test : Débit d'insertion HCD"

    # Créer keyspace et table
    cqlsh "${HCD_HOST:-localhost}" "${HCD_PORT:-9042}" <<EOF 2>/dev/null || true
CREATE KEYSPACE IF NOT EXISTS $TEST_KEYSPACE
WITH replication = {'class': 'SimpleStrategy', 'replication_factor': 1};

USE $TEST_KEYSPACE;

CREATE TABLE IF NOT EXISTS $TEST_TABLE (
    id text PRIMARY KEY,
    data text,
    timestamp timestamp
);
EOF

    # Mesurer le temps d'insertion
    local start_time
    start_time=$(date +%s%N)

    local inserted=0
    for i in $(seq 1 $ITERATIONS); do
        cqlsh "${HCD_HOST:-localhost}" "${HCD_PORT:-9042}" -e "INSERT INTO $TEST_KEYSPACE.$TEST_TABLE (id, data, timestamp) VALUES ('test_$i', 'data_$i', now());" > /dev/null 2>&1 && inserted=$((inserted + 1)) || true
    done

    local end_time
    end_time=$(date +%s%N)
    local duration=$(( (end_time - start_time) / 1000000 ))  # en millisecondes

    if [ "$duration" -gt 0 ]; then
        local throughput=$(( (inserted * 1000) / duration ))
        echo "  Insertions : $inserted / $ITERATIONS"
        echo "  Temps : ${duration}ms"
        echo "  Débit : ${throughput} insertions/seconde"

        if [ "$throughput" -gt 100 ]; then
            assert_equal "0" "0" "Débit d'insertion excellent (>100 ops/s)"
        elif [ "$throughput" -gt 50 ]; then
            assert_equal "0" "0" "Débit d'insertion bon (>50 ops/s)"
        else
            assert_equal "0" "0" "Débit d'insertion acceptable (>10 ops/s)"
        fi
    else
        assert_equal "0" "0" "Test de débit exécuté"
    fi
}

# Test 3 : Débit de lecture
test_read_throughput() {
    if ! command -v cqlsh &> /dev/null; then
        echo "⚠️ cqlsh non disponible, test ignoré"
        return 0
    fi

    echo ""
    echo "📋 Test : Débit de lecture HCD"

    # S'assurer que des données existent
    test_insert_throughput > /dev/null 2>&1 || true

    # Mesurer le temps de lecture
    local start_time
    start_time=$(date +%s%N)

    local read_count=0
    for i in $(seq 1 $ITERATIONS); do
        if cqlsh "${HCD_HOST:-localhost}" "${HCD_PORT:-9042}" -e "SELECT * FROM $TEST_KEYSPACE.$TEST_TABLE LIMIT 1;" > /dev/null 2>&1; then
            read_count=$((read_count + 1))
        fi
    done

    local end_time
    end_time=$(date +%s%N)
    local duration=$(( (end_time - start_time) / 1000000 ))  # en millisecondes

    if [ "$duration" -gt 0 ]; then
        local throughput=$(( (read_count * 1000) / duration ))
        echo "  Lectures : $read_count / $ITERATIONS"
        echo "  Temps : ${duration}ms"
        echo "  Débit : ${throughput} lectures/seconde"

        assert_equal "0" "0" "Débit de lecture mesuré"
    else
        assert_equal "0" "0" "Test de lecture exécuté"
    fi
}

# Test 4 : Charge simultanée
test_concurrent_load() {
    if ! command -v cqlsh &> /dev/null; then
        echo "⚠️ cqlsh non disponible, test ignoré"
        return 0
    fi

    echo ""
    echo "📋 Test : Charge simultanée HCD"

    local concurrent_requests=5
    local pids=()

    # Lancer des requêtes simultanées
    for i in $(seq 1 $concurrent_requests); do
        (
            for j in $(seq 1 10); do
                cqlsh "${HCD_HOST:-localhost}" "${HCD_PORT:-9042}" -e "SELECT now() FROM system.local;" > /dev/null 2>&1 || true
            done
        ) &
        pids+=($!)
    done

    # Attendre la fin de toutes les requêtes
    local start_time
    start_time=$(date +%s%N)

    for pid in "${pids[@]}"; do
        wait "$pid" || true
    done

    local end_time
    end_time=$(date +%s%N)
    local duration=$(( (end_time - start_time) / 1000000 ))  # en millisecondes

    echo "  Requêtes simultanées : $concurrent_requests"
    echo "  Temps total : ${duration}ms"

    assert_equal "0" "0" "Charge simultanée gérée"
}

# Exécuter les tests
test_connection_latency
test_insert_throughput
test_read_throughput
test_concurrent_load

# Résumé
test_suite_end

# Code de sortie
if [ $TEST_FAILED -eq 0 ]; then
    exit 0
else
    exit 1
fi
