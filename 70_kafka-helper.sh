#!/bin/bash

# Helper script pour utiliser les outils Kafka avec Java 17
# Usage: ./kafka-helper.sh <commande> [arguments...]

KAFKA_HOME=/opt/homebrew/opt/kafka

# Configurer Java 17
if [ -d "/opt/homebrew/opt/openjdk@17" ]; then
    export JAVA_HOME=/opt/homebrew/opt/openjdk@17/libexec/openjdk.jdk/Contents/Home
    export PATH="$JAVA_HOME/bin:$PATH"
elif command -v jenv &> /dev/null && jenv versions | grep -q "17"; then
    export JAVA_HOME=$(jenv prefix 17)
    export PATH="$JAVA_HOME/bin:$PATH"
else
    echo "❌ Java 17 non trouvé. Installez avec: brew install openjdk@17"
    exit 1
fi

# Exécuter la commande Kafka
if [ $# -eq 0 ]; then
    echo "Usage: ./kafka-helper.sh <commande-kafka> [arguments...]"
    echo ""
    echo "Exemples:"
    echo "  ./kafka-helper.sh kafka-topics.sh --list --bootstrap-server localhost:9092"
    echo "  ./kafka-helper.sh kafka-console-producer.sh --bootstrap-server localhost:9092 --topic test-topic"
    exit 1
fi

"$KAFKA_HOME/libexec/bin/$@"

