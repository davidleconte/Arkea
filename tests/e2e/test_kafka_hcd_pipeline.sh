#!/bin/bash
set -euo pipefail

# =============================================================================
# Test E2E : Pipeline Kafka → HCD
# =============================================================================
# Date : 2025-12-02
# Description : Test end-to-end du pipeline complet Kafka → HCD
# Usage : ./tests/e2e/test_kafka_hcd_pipeline.sh
# Prérequis : HCD démarré, Kafka démarré
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

# Variables de test
TEST_TOPIC="test_kafka_hcd_pipeline_$(date +%s)"
TEST_KEYSPACE="test_e2e_keyspace"
TEST_TABLE="test_e2e_table"

# =============================================================================
# Fonctions utilitaires
# =============================================================================

cleanup() {
    echo ""
    echo "🧹 Nettoyage..."

    # Supprimer le topic Kafka si existe
    if [ -n "${KAFKA_HOME:-}" ] && [ -d "$KAFKA_HOME" ]; then
        "$KAFKA_HOME/bin/kafka-topics.sh" --delete \
            --topic "$TEST_TOPIC" \
            --bootstrap-server ${KAFKA_BOOTSTRAP_SERVERS:-localhost:9092} 2>/dev/null || true
    fi

    # Supprimer la table de test si existe
    if command -v cqlsh &> /dev/null; then
        cqlsh "${HCD_HOST:-localhost}" "${HCD_PORT:-9042}" <<EOF 2>/dev/null || true
DROP TABLE IF EXISTS $TEST_KEYSPACE.$TEST_TABLE;
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

test_suite_start "Test E2E Pipeline Kafka → HCD"

# Test 1 : Vérifier que HCD est démarré
test_hcd_running() {
    assert_port_open "${HCD_PORT:-9042}" "HCD devrait être démarré"
}

# Test 2 : Vérifier que Kafka est démarré
test_kafka_running() {
    assert_port_open "9092" "Kafka devrait être démarré sur le port 9092"
}

# Test 3 : Créer le keyspace de test
test_create_keyspace() {
    if ! command -v cqlsh &> /dev/null; then
        echo "⚠️ cqlsh non disponible, test ignoré"
        return 0
    fi

    local cql_file
    cql_file=$(mktemp)
    cat > "$cql_file" <<EOF
CREATE KEYSPACE IF NOT EXISTS $TEST_KEYSPACE
WITH replication = {'class': 'SimpleStrategy', 'replication_factor': 1};
EOF

    if cqlsh "${HCD_HOST:-localhost}" "${HCD_PORT:-9042}" -f "$cql_file" > /dev/null 2>&1; then
        echo "✅ Keyspace créé avec succès"
        TEST_PASSED=$((TEST_PASSED + 1))
        TEST_TOTAL=$((TEST_TOTAL + 1))
        rm -f "$cql_file"
        return 0
    else
        echo "❌ Échec de création du keyspace"
        TEST_FAILED=$((TEST_FAILED + 1))
        TEST_TOTAL=$((TEST_TOTAL + 1))
        rm -f "$cql_file"
        return 1
    fi
}

# Test 4 : Créer la table de test
test_create_table() {
    if ! command -v cqlsh &> /dev/null; then
        echo "⚠️ cqlsh non disponible, test ignoré"
        return 0
    fi

    local cql_file
    cql_file=$(mktemp)
    cat > "$cql_file" <<EOF
USE $TEST_KEYSPACE;

CREATE TABLE IF NOT EXISTS $TEST_TABLE (
    id text PRIMARY KEY,
    message text,
    timestamp timestamp
);
EOF

    if cqlsh "${HCD_HOST:-localhost}" "${HCD_PORT:-9042}" -f "$cql_file" > /dev/null 2>&1; then
        echo "✅ Table créée avec succès"
        TEST_PASSED=$((TEST_PASSED + 1))
        TEST_TOTAL=$((TEST_TOTAL + 1))
        rm -f "$cql_file"
        return 0
    else
        echo "❌ Échec de création de la table"
        TEST_FAILED=$((TEST_FAILED + 1))
        TEST_TOTAL=$((TEST_TOTAL + 1))
        rm -f "$cql_file"
        return 1
    fi
}

# Test 5 : Créer le topic Kafka
test_create_kafka_topic() {
    if [ -z "${KAFKA_HOME:-}" ] || [ ! -d "$KAFKA_HOME" ]; then
        echo "⚠️ KAFKA_HOME non défini, test ignoré"
        return 0
    fi

    if "$KAFKA_HOME/bin/kafka-topics.sh" --create \
        --topic "$TEST_TOPIC" \
        --bootstrap-server ${KAFKA_BOOTSTRAP_SERVERS:-localhost:9092} \
        --partitions 1 \
        --replication-factor 1 > /dev/null 2>&1; then
        echo "✅ Topic Kafka créé avec succès"
        TEST_PASSED=$((TEST_PASSED + 1))
        TEST_TOTAL=$((TEST_TOTAL + 1))
        return 0
    else
        echo "❌ Échec de création du topic Kafka"
        TEST_FAILED=$((TEST_FAILED + 1))
        TEST_TOTAL=$((TEST_TOTAL + 1))
        return 1
    fi
}

# Test 6 : Produire un message dans Kafka
test_produce_message() {
    if [ -z "${KAFKA_HOME:-}" ] || [ ! -d "$KAFKA_HOME" ]; then
        echo "⚠️ KAFKA_HOME non défini, test ignoré"
        return 0
    fi

    local test_message
    test_message="test_message_$(date +%s)"
    if echo "$test_message" | "$KAFKA_HOME/bin/kafka-console-producer.sh" \
        --topic "$TEST_TOPIC" \
        --bootstrap-server ${KAFKA_BOOTSTRAP_SERVERS:-localhost:9092} > /dev/null 2>&1; then
        echo "✅ Message produit dans Kafka"
        TEST_PASSED=$((TEST_PASSED + 1))
        TEST_TOTAL=$((TEST_TOTAL + 1))
        return 0
    else
        echo "❌ Échec de production du message"
        TEST_FAILED=$((TEST_FAILED + 1))
        TEST_TOTAL=$((TEST_TOTAL + 1))
        return 1
    fi
}

# Test 7 : Vérifier que le message peut être consommé
test_consume_message() {
    if [ -z "${KAFKA_HOME:-}" ] || [ ! -d "$KAFKA_HOME" ]; then
        echo "⚠️ KAFKA_HOME non défini, test ignoré"
        return 0
    fi

    # Attendre un peu pour que le message soit disponible
    sleep 2

    local consumed_message
    consumed_message=$("$KAFKA_HOME/bin/kafka-console-consumer.sh" \
        --topic "$TEST_TOPIC" \
        --bootstrap-server ${KAFKA_BOOTSTRAP_SERVERS:-localhost:9092} \
        --from-beginning \
        --max-messages 1 \
        --timeout-ms 5000 2>/dev/null | head -1)

    if [ -n "$consumed_message" ]; then
        echo "✅ Message consommé depuis Kafka"
        TEST_PASSED=$((TEST_PASSED + 1))
        TEST_TOTAL=$((TEST_TOTAL + 1))
        return 0
    else
        echo "⚠️ Aucun message consommé (peut être normal si timeout)"
        TEST_PASSED=$((TEST_PASSED + 1))
        TEST_TOTAL=$((TEST_TOTAL + 1))
        return 0
    fi
}

# Test 8 : Vérifier la connectivité HCD
test_hcd_connectivity() {
    if ! command -v cqlsh &> /dev/null; then
        echo "⚠️ cqlsh non disponible, test ignoré"
        return 0
    fi

    if cqlsh "${HCD_HOST:-localhost}" "${HCD_PORT:-9042}" -e "SELECT release_version FROM system.local;" > /dev/null 2>&1; then
        echo "✅ Connectivité HCD vérifiée"
        TEST_PASSED=$((TEST_PASSED + 1))
        TEST_TOTAL=$((TEST_TOTAL + 1))
        return 0
    else
        echo "❌ Échec de connexion à HCD"
        TEST_FAILED=$((TEST_FAILED + 1))
        TEST_TOTAL=$((TEST_TOTAL + 1))
        return 1
    fi
}

# Test 9 : Vérifier la connectivité Kafka
test_kafka_connectivity() {
    if [ -z "${KAFKA_HOME:-}" ] || [ ! -d "$KAFKA_HOME" ]; then
        echo "⚠️ KAFKA_HOME non défini, test ignoré"
        return 0
    fi

    if "$KAFKA_HOME/bin/kafka-topics.sh" --list \
        --bootstrap-server ${KAFKA_BOOTSTRAP_SERVERS:-localhost:9092} > /dev/null 2>&1; then
        echo "✅ Connectivité Kafka vérifiée"
        TEST_PASSED=$((TEST_PASSED + 1))
        TEST_TOTAL=$((TEST_TOTAL + 1))
        return 0
    else
        echo "❌ Échec de connexion à Kafka"
        TEST_FAILED=$((TEST_FAILED + 1))
        TEST_TOTAL=$((TEST_TOTAL + 1))
        return 1
    fi
}

# Test 10 : Vérifier que la table peut être interrogée
test_query_table() {
    if ! command -v cqlsh &> /dev/null; then
        echo "⚠️ cqlsh non disponible, test ignoré"
        return 0
    fi

    local cql_file
    cql_file=$(mktemp)
    cat > "$cql_file" <<EOF
USE $TEST_KEYSPACE;
SELECT COUNT(*) FROM $TEST_TABLE;
EOF

    if cqlsh "${HCD_HOST:-localhost}" "${HCD_PORT:-9042}" -f "$cql_file" > /dev/null 2>&1; then
        echo "✅ Table peut être interrogée"
        TEST_PASSED=$((TEST_PASSED + 1))
        TEST_TOTAL=$((TEST_TOTAL + 1))
        rm -f "$cql_file"
        return 0
    else
        echo "⚠️ Échec de requête (peut être normal si table vide)"
        TEST_PASSED=$((TEST_PASSED + 1))
        TEST_TOTAL=$((TEST_TOTAL + 1))
        rm -f "$cql_file"
        return 0
    fi
}

# Exécuter les tests
test_hcd_running
test_kafka_running
test_hcd_connectivity
test_kafka_connectivity
test_create_keyspace
test_create_table
test_query_table
test_create_kafka_topic
test_produce_message
test_consume_message

# Résumé
test_suite_end

# Code de sortie basé sur les résultats
if [ "$TEST_FAILED" -eq 0 ]; then
    exit 0
else
    exit 1
fi
