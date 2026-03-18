#!/bin/bash
set -euo pipefail

# =============================================================================
# ⚠️ LEGACY BINARY START SCRIPT (HCD 1.2.3)
# For modern OSS Cassandra 5.0 (Podman leg), use: make start
# Usage: ./start_hcd.sh [background]
# =============================================================================

# Charger la configuration centralisée
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ARKEA_HOME="${ARKEA_HOME:-$(cd "$SCRIPT_DIR/../.." && pwd)}"
if [ -f "${ARKEA_HOME}/.poc-config.sh" ]; then
    # shellcheck source=/dev/null
    source "${ARKEA_HOME}/.poc-config.sh"
fi

# Garde-fou: script binaire autorisé uniquement en leg binary
if [ "${ARKEA_LEG:-podman}" != "binary" ] && [ "${ARKEA_ENABLE_BINARY_LEG:-0}" != "1" ]; then
    echo "❌ ERROR: Binary leg is disabled by policy (ARKEA_LEG=${ARKEA_LEG:-podman})."
    echo "   Use OSS 5.0 path: ARKEA_LEG=podman make start"
    echo "   To force binary leg: ARKEA_ENABLE_BINARY_LEG=1 ARKEA_LEG=binary make start"
    exit 1
fi

# Charger les fonctions portables
if [ -f "${ARKEA_HOME}/scripts/utils/portable_functions.sh" ]; then
    # shellcheck source=/dev/null
    source "${ARKEA_HOME}/scripts/utils/portable_functions.sh"
fi

# Variables (utiliser .poc-config.sh ou fallback)
HCD_DIR="${HCD_DIR:-${HCD_HOME:-${ARKEA_HOME}/binaire/hcd-1.2.3}}"
LOG_DIR="${HCD_DIR}/logs"

# Vérifier que HCD est installé
if [ ! -d "$HCD_DIR" ]; then
    echo "❌ HCD non installé. Exécutez d'abord: ./scripts/setup/01_install_hcd.sh"
    exit 1
fi

# Vérifier et configurer Java 11 (utiliser .poc-config.sh)
if [ -z "${JAVA_HOME:-}" ] || ! java -version 2>&1 | grep -q "11"; then
    if command -v jenv &> /dev/null; then
        eval "$(jenv init -)" 2>/dev/null || true
        if jenv versions | grep -q "11"; then
            JAVA_HOME="$(jenv prefix 11)"
            export JAVA_HOME
            export PATH="$JAVA_HOME/bin:$PATH"
            echo "✅ Java 11 configuré via jenv : $JAVA_HOME"
        fi
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

# Vérifier si HCD est déjà en cours d'exécution (fonction portable)
if check_port "${HCD_PORT:-9042}"; then
    echo "⚠️  HCD est déjà en cours d'exécution (port ${HCD_PORT:-9042} utilisé)"
    echo "Pour arrêter: kill_process cassandra"
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
    echo "🛑 Arrêter: kill_process cassandra"
else
    echo "🚀 Démarrage de HCD..."
    echo "📋 Logs dans: ${LOG_DIR}/"
    echo "🛑 Pour arrêter: Ctrl+C"
    echo ""
    CASSANDRA_LOG_DIR="$LOG_DIR" bin/hcd cassandra
fi
