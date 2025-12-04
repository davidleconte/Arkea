#!/bin/bash
# =============================================================================
# Configuration de Test pour ARKEA
# =============================================================================
# Date : 2025-12-02
# Usage : source tests/fixtures/test_config.sh
# =============================================================================

# Variables de test
export TEST_HCD_HOST="${TEST_HCD_HOST:-localhost}"
export TEST_HCD_PORT="${TEST_HCD_PORT:-9042}"
export TEST_KAFKA_BOOTSTRAP_SERVERS="${TEST_KAFKA_BOOTSTRAP_SERVERS:-localhost:9092}"
export TEST_KAFKA_ZOOKEEPER_CONNECT="${TEST_KAFKA_ZOOKEEPER_CONNECT:-localhost:2181}"

# Keyspace de test
export TEST_KEYSPACE="${TEST_KEYSPACE:-test_keyspace}"

# Timeout pour les tests
export TEST_TIMEOUT="${TEST_TIMEOUT:-30}"

# Mode verbose pour les tests
export TEST_VERBOSE="${TEST_VERBOSE:-false}"
