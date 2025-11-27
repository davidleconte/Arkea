#!/bin/bash

# Script de démarrage rapide HCD
# Usage: ./start_hcd.sh [background]

set -e

HCD_DIR="/Users/david.leconte/Documents/Arkea/binaire/hcd-1.2.3"
LOG_DIR="${HCD_DIR}/logs"

# Vérifier que HCD est installé
if [ ! -d "$HCD_DIR" ]; then
    echo "❌ HCD non installé. Exécutez d'abord: ./install_hcd.sh"
    exit 1
fi

# Vérifier et configurer Java 11
if command -v jenv &> /dev/null; then
    # Utiliser jenv si disponible
    eval "$(jenv init -)" 2>/dev/null || true
    cd "$(dirname "$HCD_DIR")"
    if jenv versions | grep -q "11"; then
        jenv local 11 2>/dev/null || true
        eval "$(jenv init -)"
        export JAVA_HOME=$(jenv prefix 11)
        echo "✅ Java 11 configuré via jenv : $JAVA_HOME"
    fi
fi

# Si jenv n'est pas disponible ou n'a pas fonctionné, utiliser JAVA_HOME direct
if [ -z "$JAVA_HOME" ] || ! java -version 2>&1 | grep -q "11"; then
    if [ -d "/opt/homebrew/opt/openjdk@11/libexec/openjdk.jdk/Contents/Home" ]; then
        export JAVA_HOME=/opt/homebrew/opt/openjdk@11/libexec/openjdk.jdk/Contents/Home
        export PATH="$JAVA_HOME/bin:$PATH"
    elif [ -d "/opt/homebrew/opt/openjdk@11" ]; then
        export JAVA_HOME=/opt/homebrew/opt/openjdk@11
        export PATH="$JAVA_HOME/bin:$PATH"
    else
        echo "❌ Java 11 non trouvé. Veuillez installer Java 11."
        exit 1
    fi
fi

# Vérification finale
if ! java -version 2>&1 | grep -q "11"; then
    echo "⚠️  Attention : Java 11 non détecté. Version actuelle :"
    java -version
    echo "Continuez quand même ? (y/n)"
    read -r response
    if [ "$response" != "y" ]; then
        exit 1
    fi
fi

# Vérifier si HCD est déjà en cours d'exécution
if lsof -Pi :9042 -sTCP:LISTEN -t >/dev/null 2>&1 ; then
    echo "⚠️  HCD est déjà en cours d'exécution (port 9042 utilisé)"
    echo "Pour arrêter: pkill -f cassandra"
    exit 1
fi

cd "$HCD_DIR"

# Créer répertoire de logs si nécessaire
mkdir -p "$LOG_DIR"

# Démarrer HCD
if [ "$1" = "background" ] || [ "$1" = "bg" ]; then
    echo "🚀 Démarrage de HCD en arrière-plan..."
    nohup bin/hcd cassandra > "${LOG_DIR}/hcd.log" 2>&1 &
    PID=$!
    echo "✅ HCD démarré (PID: $PID)"
    echo "📋 Logs: ${LOG_DIR}/hcd.log"
    echo "🔍 Vérifier: tail -f ${LOG_DIR}/hcd.log"
    echo "🛑 Arrêter: pkill -f cassandra"
else
    echo "🚀 Démarrage de HCD..."
    echo "📋 Logs dans: ${LOG_DIR}/"
    echo "🛑 Pour arrêter: Ctrl+C"
    echo ""
    CASSANDRA_LOG_DIR="$LOG_DIR" bin/hcd cassandra
fi

