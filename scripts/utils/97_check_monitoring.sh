#!/bin/bash
set -euo pipefail

# =============================================================================
# Script : Vérification Monitoring
# =============================================================================
# Date : 2025-12-02
# Description : Vérifie que les services de monitoring sont démarrés
# Usage : ./scripts/utils/97_check_monitoring.sh
# =============================================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ARKEA_HOME="$(cd "$SCRIPT_DIR/../.." && pwd)"

# Charger les fonctions portables
if [ -f "$ARKEA_HOME/scripts/utils/portable_functions.sh" ]; then
    source "$ARKEA_HOME/scripts/utils/portable_functions.sh"
else
    check_port() {
        local port="$1"
        if command -v lsof &> /dev/null; then
            lsof -Pi :"$port" -sTCP:LISTEN -t >/dev/null 2>&1
        elif command -v nc &> /dev/null; then
            nc -z localhost "$port" >/dev/null 2>&1
        else
            return 1
        fi
    }
fi

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "📊 Vérification Monitoring - ARKEA"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Vérifier Prometheus
if check_port 9090; then
    echo "✅ Prometheus : Démarré (port 9090)"
else
    echo "❌ Prometheus : Non démarré (port 9090)"
fi

# Vérifier Grafana
if check_port 3000; then
    echo "✅ Grafana : Démarré (port 3000)"
else
    echo "❌ Grafana : Non démarré (port 3000)"
fi

# Vérifier Alertmanager
if check_port 9093; then
    echo "✅ Alertmanager : Démarré (port 9093)"
else
    echo "⚠️  Alertmanager : Non démarré (port 9093) - Optionnel"
fi

# Vérifier JMX Exporter HCD
if check_port 7072; then
    echo "✅ JMX Exporter HCD : Démarré (port 7072)"
else
    echo "⚠️  JMX Exporter HCD : Non démarré (port 7072) - Optionnel"
fi

# Vérifier JMX Exporter Kafka
if check_port 7073; then
    echo "✅ JMX Exporter Kafka : Démarré (port 7073)"
else
    echo "⚠️  JMX Exporter Kafka : Non démarré (port 7073) - Optionnel"
fi

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "💡 Pour démarrer les services de monitoring :"
echo "   Voir docs/GUIDE_MONITORING.md"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
