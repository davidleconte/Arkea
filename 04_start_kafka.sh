#!/bin/bash

# Script de démarrage Kafka avec Java 17
# Kafka 4.1.1 nécessite Java 17+

set -e

KAFKA_HOME=/opt/homebrew/opt/kafka
KAFKA_CONFIG="$KAFKA_HOME/.bottle/etc/kafka/server.properties"
KAFKA_LOG_DIR="$KAFKA_HOME/libexec/logs"

# Vérifier que Kafka est installé
if [ ! -d "$KAFKA_HOME" ]; then
    echo "❌ Kafka non installé. Installez avec: brew install kafka"
    exit 1
fi

# Vérifier Java 17
echo "🔍 Vérification de Java 17..."
if [ -d "/opt/homebrew/opt/openjdk@17" ]; then
    export JAVA_HOME=/opt/homebrew/opt/openjdk@17/libexec/openjdk.jdk/Contents/Home
    export PATH="$JAVA_HOME/bin:$PATH"
    echo "✅ Java 17 trouvé via Homebrew"
elif command -v jenv &> /dev/null && jenv versions | grep -q "17"; then
    export JAVA_HOME=$(jenv prefix 17)
    export PATH="$JAVA_HOME/bin:$PATH"
    echo "✅ Java 17 trouvé via jenv"
else
    echo "⚠️  Java 17 non trouvé. Installation..."
    brew install openjdk@17
    export JAVA_HOME=/opt/homebrew/opt/openjdk@17/libexec/openjdk.jdk/Contents/Home
    export PATH="$JAVA_HOME/bin:$PATH"
fi

# Vérifier la version Java
JAVA_VERSION=$($JAVA_HOME/bin/java -version 2>&1 | head -1)
echo "Java utilisé: $JAVA_VERSION"

# Vérifier si Kafka est déjà en cours d'exécution
if lsof -Pi :9092 -sTCP:LISTEN -t >/dev/null 2>&1 ; then
    echo "⚠️  Kafka est déjà en cours d'exécution (port 9092 utilisé)"
    echo "Pour arrêter: pkill -f kafka.Kafka"
    exit 1
fi

# Créer répertoire de logs si nécessaire
mkdir -p "$KAFKA_LOG_DIR"

# Démarrer Kafka
cd "$KAFKA_HOME"

if [ "$1" = "background" ] || [ "$1" = "bg" ]; then
    echo "🚀 Démarrage de Kafka en arrière-plan..."
    nohup "$KAFKA_HOME/libexec/bin/kafka-server-start.sh" "$KAFKA_CONFIG" > "$KAFKA_LOG_DIR/kafka.log" 2>&1 &
    PID=$!
    echo "✅ Kafka démarré (PID: $PID)"
    echo "📋 Logs: $KAFKA_LOG_DIR/kafka.log"
    echo "🔍 Vérifier: tail -f $KAFKA_LOG_DIR/kafka.log"
    echo "🛑 Arrêter: pkill -f kafka.Kafka"
else
    echo "🚀 Démarrage de Kafka..."
    echo "📋 Logs dans: $KAFKA_LOG_DIR/"
    echo "🛑 Pour arrêter: Ctrl+C"
    echo ""
    "$KAFKA_HOME/libexec/bin/kafka-server-start.sh" "$KAFKA_CONFIG"
fi

