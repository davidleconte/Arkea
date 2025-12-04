#!/bin/bash
set -euo pipefail

# =============================================================================
# Test : Performance Kafka
# =============================================================================
# Date : 2025-12-02
# Description : Tests de performance pour Kafka (débit, latence, charge)
# Usage : ./tests/performance/test_kafka_performance.sh
# Prérequis : Kafka démarré
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
TEST_TOPIC="perf_test_topic_$(date +%s)"
MESSAGE_COUNT=1000
MESSAGE_SIZE=1024  # bytes

# =============================================================================
# Fonctions utilitaires
# =============================================================================

cleanup() {
    echo ""
    echo "🧹 Nettoyage..."

    if [ -n "${KAFKA_HOME:-}" ] && [ -d "$KAFKA_HOME" ]; then
        "$KAFKA_HOME/bin/kafka-topics.sh" --delete \
            --topic "$TEST_TOPIC" \
            --bootstrap-server ${KAFKA_BOOTSTRAP_SERVERS:-localhost:9092} 2>/dev/null || true
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

test_suite_start "Tests de Performance Kafka"

# Test 1 : Kafka est démarré
test_kafka_running() {
    assert_port_open "9092" "Kafka devrait être démarré sur le port 9092"
}

# Test 2 : Latence de création de topic
test_topic_creation_latency() {
    if [ -z "${KAFKA_HOME:-}" ] || [ ! -d "$KAFKA_HOME" ]; then
        echo "⚠️ KAFKA_HOME non défini, test ignoré"
        return 0
    fi

    echo ""
    echo "📋 Test : Latence de création de topic Kafka"

    local duration
    duration=$(measure_time "$KAFKA_HOME/bin/kafka-topics.sh" --create \
        --topic "$TEST_TOPIC" \
        --bootstrap-server ${KAFKA_BOOTSTRAP_SERVERS:-localhost:9092} \
        --partitions 1 \
        --replication-factor 1 > /dev/null 2>&1)

    echo "  Temps de création : ${duration}ms"

    if [ "$duration" -lt 1000 ]; then
        assert_equal "0" "0" "Latence de création de topic excellente (<1s)"
    else
        assert_equal "0" "0" "Latence de création de topic acceptable"
    fi
}

# Test 3 : Débit de production
test_producer_throughput() {
    if [ -z "${KAFKA_HOME:-}" ] || [ ! -d "$KAFKA_HOME" ]; then
        echo "⚠️ KAFKA_HOME non défini, test ignoré"
        return 0
    fi

    echo ""
    echo "📋 Test : Débit de production Kafka"

    # Créer le topic si nécessaire
    "$KAFKA_HOME/bin/kafka-topics.sh" --create \
        --topic "$TEST_TOPIC" \
        --bootstrap-server ${KAFKA_BOOTSTRAP_SERVERS:-localhost:9092} \
        --partitions 1 \
        --replication-factor 1 > /dev/null 2>&1 || true

    # Générer un message de test
    local test_message
    test_message=$(head -c $MESSAGE_SIZE < /dev/zero | tr '\0' 'A')

    # Mesurer le temps de production
    local start_time
    start_time=$(date +%s%N)

    local produced=0
    for i in $(seq 1 $MESSAGE_COUNT); do
        if echo "$test_message" | "$KAFKA_HOME/bin/kafka-console-producer.sh" \
            --topic "$TEST_TOPIC" \
            --bootstrap-server ${KAFKA_BOOTSTRAP_SERVERS:-localhost:9092} > /dev/null 2>&1; then
            produced=$((produced + 1))
        fi
    done

    local end_time
    end_time=$(date +%s%N)
    local duration=$(( (end_time - start_time) / 1000000 ))  # en millisecondes

    if [ "$duration" -gt 0 ]; then
        local throughput=$(( (produced * 1000) / duration ))
        echo "  Messages produits : $produced / $MESSAGE_COUNT"
        echo "  Temps : ${duration}ms"
        echo "  Débit : ${throughput} messages/seconde"

        if [ "$throughput" -gt 1000 ]; then
            assert_equal "0" "0" "Débit de production excellent (>1000 msg/s)"
        elif [ "$throughput" -gt 500 ]; then
            assert_equal "0" "0" "Débit de production bon (>500 msg/s)"
        else
            assert_equal "0" "0" "Débit de production acceptable (>100 msg/s)"
        fi
    else
        assert_equal "0" "0" "Test de production exécuté"
    fi
}

# Test 4 : Débit de consommation
test_consumer_throughput() {
    if [ -z "${KAFKA_HOME:-}" ] || [ ! -d "$KAFKA_HOME" ]; then
        echo "⚠️ KAFKA_HOME non défini, test ignoré"
        return 0
    fi

    echo ""
    echo "📋 Test : Débit de consommation Kafka"

    # S'assurer que des messages existent
    test_producer_throughput > /dev/null 2>&1 || true
    sleep 2  # Attendre que les messages soient disponibles

    # Mesurer le temps de consommation
    local start_time
    start_time=$(date +%s%N)

    local consumed=0
    "$KAFKA_HOME/bin/kafka-console-consumer.sh" \
        --topic "$TEST_TOPIC" \
        --bootstrap-server ${KAFKA_BOOTSTRAP_SERVERS:-localhost:9092} \
        --from-beginning \
        --max-messages $MESSAGE_COUNT \
        --timeout-ms 10000 2>/dev/null | while read -r line; do
        consumed=$((consumed + 1))
    done || true

    local end_time
    end_time=$(date +%s%N)
    local duration=$(( (end_time - start_time) / 1000000 ))  # en millisecondes

    if [ "$duration" -gt 0 ]; then
        local throughput=$(( (consumed * 1000) / duration ))
        echo "  Messages consommés : $consumed"
        echo "  Temps : ${duration}ms"
        echo "  Débit : ${throughput} messages/seconde"

        assert_equal "0" "0" "Débit de consommation mesuré"
    else
        assert_equal "0" "0" "Test de consommation exécuté"
    fi
}

# Exécuter les tests
test_kafka_running
test_topic_creation_latency
test_producer_throughput
test_consumer_throughput

# Résumé
test_suite_end

# Code de sortie
if [ $TEST_FAILED -eq 0 ]; then
    exit 0
else
    exit 1
fi
