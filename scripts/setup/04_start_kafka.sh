#!/bin/bash
set -euo pipefail

# Script de démarrage Kafka avec Java 17 (Cross-Platform)
# Kafka 4.1.1 nécessite Java 17+

# Charger la configuration centralisée
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ARKEA_HOME="${ARKEA_HOME:-$(cd "$SCRIPT_DIR/../.." && pwd)}"
if [ -f "${ARKEA_HOME}/.poc-config.sh" ]; then
    # shellcheck source=/dev/null
    source "${ARKEA_HOME}/.poc-config.sh"
fi

# Charger les fonctions portables
if [ -f "${ARKEA_HOME}/scripts/utils/portable_functions.sh" ]; then
    # shellcheck source=/dev/null
    source "${ARKEA_HOME}/scripts/utils/portable_functions.sh"
fi

# Variables (utiliser .poc-config.sh ou fallback)
KAFKA_HOME="${KAFKA_HOME:-}"
if [ -z "$KAFKA_HOME" ]; then
    # Détection automatique selon OS
    if [[ "$OSTYPE" == "darwin"* ]]; then
        HOMEBREW_PREFIX="${HOMEBREW_PREFIX:-/opt/homebrew}"
        if [ -d "${HOMEBREW_PREFIX}/opt/kafka" ]; then
            KAFKA_HOME="${HOMEBREW_PREFIX}/opt/kafka"
        elif [ -d "/usr/local/opt/kafka" ]; then
            KAFKA_HOME="/usr/local/opt/kafka"
        fi
    elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
        if [ -d "/opt/kafka" ]; then
            KAFKA_HOME="/opt/kafka"
        elif [ -d "/usr/local/kafka" ]; then
            KAFKA_HOME="/usr/local/kafka"
        elif [ -d "${ARKEA_HOME}/binaire/kafka" ]; then
            KAFKA_HOME="${ARKEA_HOME}/binaire/kafka"
        fi
    fi
fi

# Vérifier que Kafka est installé
if [ -z "$KAFKA_HOME" ] || [ ! -d "$KAFKA_HOME" ]; then
    echo "❌ Kafka non installé."
    if [[ "$OSTYPE" == "darwin"* ]]; then
        echo "   Installez avec: brew install kafka"
    else
        echo "   Installez avec: ./scripts/setup/02_install_kafka_linux.sh"
    fi
    exit 1
fi

# Configuration Kafka selon OS
if [[ "$OSTYPE" == "darwin"* ]]; then
    KAFKA_CONFIG="${KAFKA_HOME}/.bottle/etc/kafka/server.properties"
    KAFKA_LOG_DIR="${KAFKA_HOME}/libexec/logs"
    KAFKA_BIN="${KAFKA_HOME}/libexec/bin/kafka-server-start.sh"
else
    KAFKA_CONFIG="${KAFKA_HOME}/config/server.properties"
    KAFKA_LOG_DIR="${KAFKA_HOME}/logs"
    KAFKA_BIN="${KAFKA_HOME}/bin/kafka-server-start.sh"
fi

# Vérifier Java 17 (utiliser .poc-config.sh)
echo "🔍 Vérification de Java 17..."
if [ -n "${JAVA17_HOME:-}" ] && [ -d "${JAVA17_HOME}" ]; then
    export JAVA_HOME="$JAVA17_HOME"
    export PATH="$JAVA_HOME/bin:$PATH"
    echo "✅ Java 17 trouvé via configuration : $JAVA_HOME"
elif [[ "$OSTYPE" == "darwin"* ]]; then
    HOMEBREW_PREFIX="${HOMEBREW_PREFIX:-/opt/homebrew}"
    if [ -d "${HOMEBREW_PREFIX}/opt/openjdk@17/libexec/openjdk.jdk/Contents/Home" ]; then
        export JAVA_HOME="${HOMEBREW_PREFIX}/opt/openjdk@17/libexec/openjdk.jdk/Contents/Home"
        export PATH="$JAVA_HOME/bin:$PATH"
        echo "✅ Java 17 trouvé via Homebrew"
    elif [ -d "${HOMEBREW_PREFIX}/opt/openjdk@17" ]; then
        export JAVA_HOME="${HOMEBREW_PREFIX}/opt/openjdk@17"
        export PATH="$JAVA_HOME/bin:$PATH"
        echo "✅ Java 17 trouvé via Homebrew"
    fi
elif command -v jenv &> /dev/null && jenv versions | grep -q "17"; then
    JAVA_HOME="$(jenv prefix 17)"
    export JAVA_HOME
    export PATH="$JAVA_HOME/bin:$PATH"
    echo "✅ Java 17 trouvé via jenv"
fi

# Vérifier la version Java
if [ -n "${JAVA_HOME:-}" ]; then
    JAVA_VERSION=$("$JAVA_HOME/bin/java" -version 2>&1 | head -1)
    echo "Java utilisé: $JAVA_VERSION"
else
    echo "⚠️  Java 17 non trouvé. Installation requise."
    if [[ "$OSTYPE" == "darwin"* ]] && command -v brew &> /dev/null; then
        echo "Installation via Homebrew..."
        brew install openjdk@17
        HOMEBREW_PREFIX="${HOMEBREW_PREFIX:-/opt/homebrew}"
        if [ -d "${HOMEBREW_PREFIX}/opt/openjdk@17/libexec/openjdk.jdk/Contents/Home" ]; then
            export JAVA_HOME="${HOMEBREW_PREFIX}/opt/openjdk@17/libexec/openjdk.jdk/Contents/Home"
        else
            export JAVA_HOME="${HOMEBREW_PREFIX}/opt/openjdk@17"
        fi
        export PATH="$JAVA_HOME/bin:$PATH"
    else
        echo "Veuillez installer Java 17 manuellement."
        exit 1
    fi
fi

# Vérifier si Kafka est déjà en cours d'exécution (fonction portable)
if check_port "${KAFKA_PORT:-9192}"; then
    echo "⚠️  Kafka est déjà en cours d'exécution (port ${KAFKA_PORT:-9192} utilisé)"
    echo "Pour arrêter: kill_process kafka.Kafka"
    exit 1
fi

# Créer répertoire de logs si nécessaire
mkdir -p "$KAFKA_LOG_DIR"

# Créer répertoire de logs si nécessaire
mkdir -p "$KAFKA_LOG_DIR"

# Démarrer Kafka
cd "$KAFKA_HOME"

if [ "$1" = "background" ] || [ "$1" = "bg" ]; then
    echo "🚀 Démarrage de Kafka en arrière-plan..."
    nohup "$KAFKA_BIN" "$KAFKA_CONFIG" > "$KAFKA_LOG_DIR/kafka.log" 2>&1 &
    PID=$!
    echo "✅ Kafka démarré (PID: $PID)"
    echo "📋 Logs: $KAFKA_LOG_DIR/kafka.log"
    echo "🔍 Vérifier: tail -f $KAFKA_LOG_DIR/kafka.log"
    echo "🛑 Arrêter: kill_process kafka.Kafka"
else
    echo "🚀 Démarrage de Kafka..."
    echo "📋 Logs dans: $KAFKA_LOG_DIR/"
    echo "🛑 Pour arrêter: Ctrl+C"
    echo ""
    "$KAFKA_BIN" "$KAFKA_CONFIG"
fi
