#!/bin/bash
set -euo pipefail

# Helper script pour utiliser les outils Kafka avec Java 17
# Usage: ./kafka-helper.sh <commande> [arguments...]

# Charger la configuration centralisée
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ARKEA_HOME="${ARKEA_HOME:-$(cd "$SCRIPT_DIR/../.." && pwd)}"

# Charger .poc-config.sh si disponible
if [ -f "${ARKEA_HOME}/.poc-config.sh" ]; then
    source "${ARKEA_HOME}/.poc-config.sh"
fi

# Déterminer KAFKA_HOME
if [ -z "${KAFKA_HOME:-}" ]; then
    # Détection automatique
    HOMEBREW_PREFIX="${HOMEBREW_PREFIX:-/opt/homebrew}"
    if [ -d "${HOMEBREW_PREFIX}/opt/kafka" ]; then
        KAFKA_HOME="${HOMEBREW_PREFIX}/opt/kafka"
    elif [ -d "${ARKEA_HOME}/binaire/kafka" ]; then
        KAFKA_HOME="${ARKEA_HOME}/binaire/kafka"
    elif [ -d "${HOME}/kafka" ]; then
        KAFKA_HOME="${HOME}/kafka"
    else
        echo "❌ Kafka non trouvé. Définissez KAFKA_HOME ou installez Kafka."
        exit 1
    fi
fi

# Configurer Java 17
if [ -z "${JAVA_HOME:-}" ]; then
    # Détection automatique
    HOMEBREW_PREFIX="${HOMEBREW_PREFIX:-/opt/homebrew}"
    if [ -d "${HOMEBREW_PREFIX}/opt/openjdk@17" ]; then
        export JAVA_HOME="${HOMEBREW_PREFIX}/opt/openjdk@17/libexec/openjdk.jdk/Contents/Home"
        export PATH="$JAVA_HOME/bin:$PATH"
    elif command -v jenv &> /dev/null && jenv versions | grep -q "17"; then
        export JAVA_HOME=$(jenv prefix 17)
        export PATH="$JAVA_HOME/bin:$PATH"
    elif [ -d "${ARKEA_HOME}/binaire/java" ]; then
        export JAVA_HOME="${ARKEA_HOME}/binaire/java"
        export PATH="$JAVA_HOME/bin:$PATH"
    else
        echo "❌ Java 17 non trouvé. Installez avec: brew install openjdk@17"
        exit 1
    fi
fi

# Exécuter la commande Kafka
if [ $# -eq 0 ]; then
    echo "Usage: ./kafka-helper.sh <commande-kafka> [arguments...]"
    echo ""
    echo "Exemples:"
    echo "  ./kafka-helper.sh kafka-topics.sh --list --bootstrap-server ${KAFKA_BOOTSTRAP_SERVERS:-${KAFKA_BOOTSTRAP_SERVERS:-localhost:9092}}"
    echo "  ./kafka-helper.sh kafka-console-producer.sh --bootstrap-server ${KAFKA_BOOTSTRAP_SERVERS:-${KAFKA_BOOTSTRAP_SERVERS:-localhost:9092}} --topic test-topic"
    exit 1
fi

"$KAFKA_HOME/libexec/bin/$@"
