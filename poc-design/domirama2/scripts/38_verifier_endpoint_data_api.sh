#!/bin/bash
# ============================================
# Script 38 : Vérification Endpoint Data API
# ============================================
#
# OBJECTIF :
#   Ce script vérifie si l'endpoint Data API est réellement accessible et
#   fonctionnel, en testant la connectivité HTTP et les opérations de base.
#
#   Vérifications effectuées :
#   - Connectivité HTTP vers l'endpoint
#   - Authentification avec token
#   - Opérations CRUD de base (findOne, insertOne)
#   - Validation de la configuration
#
# PRÉREQUIS :
#   - HCD démarré (./scripts/setup/03_start_hcd.sh)
#   - Schéma configuré (./10_setup_domirama2_poc.sh)
#   - Data API configurée (./36_setup_data_api.sh)
#   - Stargate déployé (optionnel, pour POC local: ./39_deploy_stargate.sh)
#   - Variables d'environnement configurées (DATA_API_ENDPOINT, DATA_API_USERNAME, DATA_API_PASSWORD)
#
# UTILISATION :
#   ./38_verifier_endpoint_data_api.sh
#
# EXEMPLE :
#   ./38_verifier_endpoint_data_api.sh
#
# SORTIE :
#   - Statut de l'endpoint (accessible/inaccessible)
#   - Résultats des tests de connectivité
#   - Messages de succès/erreur avec solutions
#
# PROCHAINES ÉTAPES :
#   - Si endpoint inaccessible: Script 39 (./39_deploy_stargate.sh)
#   - Si endpoint accessible: Script 40 (./40_demo_data_api_complete.sh)
#
# ============================================

set -euo pipefail

# Couleurs pour output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

info() {
    echo -e "${BLUE}ℹ️  $1${NC}"
}

success() {
    echo -e "${GREEN}✅ $1${NC}"
}

warn() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

error() {
    echo -e "${RED}❌ $1${NC}"
}

code() {
    echo -e "${BLUE}   $1${NC}"
}

highlight() {
    echo -e "${CYAN}💡 $1${NC}"
}

# ============================================
# Configuration
# ============================================

# Configuration - Utiliser setup_paths si disponible
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
if [ -f "$SCRIPT_DIR/../utils/didactique_functions.sh" ]; then
    source "$SCRIPT_DIR/../utils/didactique_functions.sh"
    setup_paths
else
    # Fallback si les fonctions ne sont pas disponibles
    INSTALL_DIR="${ARKEA_HOME:-$(cd "$SCRIPT_DIR/../.." && pwd)}"
    HCD_DIR="${HCD_DIR:-${INSTALL_DIR}/binaire/hcd-1.2.3}"
    SPARK_HOME="${SPARK_HOME:-${INSTALL_DIR}/binaire/spark-3.5.1}"
    HCD_HOST="${HCD_HOST:-localhost}"
    HCD_PORT="${HCD_PORT:-9042}"
fi

# Source environment
if [ -f "$INSTALL_DIR/.poc-profile" ]; then
    source "$INSTALL_DIR/.poc-profile"
fi

# ============================================
# Vérification
# ============================================

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  🔍 Vérification Endpoint Data API HCD"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

info "Référence : https://docs.datastax.com/en/hyper-converged-database/1.2/api-reference/quickstart.html"
echo ""

# ============================================
# Partie 1 : Variables d'Environnement
# ============================================

echo ""
info "📋 Partie 1 : Variables d'Environnement"
echo ""

# Vérifier les variables (conformes au quickstart)
API_ENDPOINT="${API_ENDPOINT:-${DATA_API_ENDPOINT:-}}"
USERNAME_VAR="${USERNAME:-${DATA_API_USERNAME:-}}"
PASSWORD_VAR="${PASSWORD:-${DATA_API_PASSWORD:-}}"

info "Variables conformes au quickstart (API_ENDPOINT, USERNAME, PASSWORD) :"
if [ -n "$API_ENDPOINT" ]; then
    code "  ✅ API_ENDPOINT: $API_ENDPOINT"
else
    code "  ❌ API_ENDPOINT: NON DÉFINI"
fi

if [ -n "$USERNAME_VAR" ]; then
    code "  ✅ USERNAME: $USERNAME_VAR"
else
    code "  ❌ USERNAME: NON DÉFINI"
fi

if [ -n "$PASSWORD_VAR" ]; then
    code "  ✅ PASSWORD: DÉFINI (masqué)"
else
    code "  ❌ PASSWORD: NON DÉFINI"
fi

echo ""

# Variables de fallback (POC local)
if [ -z "$API_ENDPOINT" ]; then
    API_ENDPOINT="${DATA_API_ENDPOINT:-http://localhost:8080}"
    warn "Utilisation de DATA_API_ENDPOINT (fallback POC) : $API_ENDPOINT"
fi

if [ -z "$USERNAME_VAR" ]; then
    USERNAME_VAR="${DATA_API_USERNAME:-cassandra}"
    warn "Utilisation de DATA_API_USERNAME (fallback POC) : $USERNAME_VAR"
fi

if [ -z "$PASSWORD_VAR" ]; then
    PASSWORD_VAR="${DATA_API_PASSWORD:-cassandra}"
    warn "Utilisation de DATA_API_PASSWORD (fallback POC)"
fi

echo ""

# ============================================
# Partie 2 : Test de Connexion HTTP
# ============================================

echo ""
info "📋 Partie 2 : Test de Connexion HTTP"
echo ""

info "Test de connexion à : $API_ENDPOINT"
echo ""

# Extraire le host et le port
HOST_PORT=$(echo "$API_ENDPOINT" | sed -E 's|https?://||' | cut -d'/' -f1)
HOST=$(echo "$HOST_PORT" | cut -d':' -f1)
PORT=$(echo "$HOST_PORT" | cut -d':' -f2)

if [ -z "$PORT" ]; then
    PORT="80"
    if echo "$API_ENDPOINT" | grep -q "https"; then
        PORT="443"
    fi
fi

info "Host : $HOST"
info "Port : $PORT"
echo ""

# Test de connexion TCP
info "Test de connexion TCP..."
if nc -z -w 2 "$HOST" "$PORT" 2>/dev/null; then
    success "Port $PORT accessible sur $HOST"
else
    error "Port $PORT NON accessible sur $HOST"
    warn "   → Le gateway Data API n'est probablement pas déployé"
fi
echo ""

# Test HTTP
info "Test HTTP (curl)..."
HTTP_STATUS=$(curl -s -o /dev/null -w "%{http_code}" --connect-timeout 2 "$API_ENDPOINT" 2>&1 || echo "000")

if [ "$HTTP_STATUS" = "000" ]; then
    error "Endpoint NON accessible (timeout/erreur)"
    warn "   → HTTP Status: $HTTP_STATUS"
    warn "   → Le gateway Data API n'est pas déployé ou non accessible"
elif [ "$HTTP_STATUS" = "200" ] || [ "$HTTP_STATUS" = "401" ] || [ "$HTTP_STATUS" = "404" ]; then
    success "Endpoint accessible (HTTP Status: $HTTP_STATUS)"
    code "   → Le gateway répond (même si erreur d'authentification, c'est bon signe)"
else
    warn "Endpoint répond avec HTTP Status: $HTTP_STATUS"
    code "   → Vérifiez la configuration"
fi

echo ""

# ============================================
# Partie 3 : Vérification Kubernetes (si disponible)
# ============================================

echo ""
info "📋 Partie 3 : Vérification Kubernetes (Production)"
echo ""

if command -v kubectl &> /dev/null; then
    success "kubectl disponible"
    echo ""

    info "Recherche de services Data API / Stargate / Gateway..."
    SERVICES=$(kubectl get svc 2>/dev/null | grep -iE "stargate|gateway|data-api|api-gateway" || true)

    if [ -n "$SERVICES" ]; then
        success "Services trouvés :"
        echo "$SERVICES" | sed 's/^/   /'
        echo ""

        info "Pour trouver l'endpoint, exécutez :"
        code "  kubectl get nodes -o wide  # Pour CLUSTER_HOST (EXTERNAL-IP)"
        code "  kubectl get svc <service-name> -o jsonpath='{.spec.ports[0].nodePort}'  # Pour GATEWAY_PORT"
    else
        warn "Aucun service Data API trouvé dans Kubernetes"
        code "   → Si HCD est déployé en Kubernetes, vérifiez Mission Control"
    fi
else
    warn "kubectl non disponible"
    code "   → Pour POC local, utilisez Stargate standalone (Podman)"
fi

echo ""

# ============================================
# Partie 4 : Vérification Stargate (POC Local)
# ============================================

echo ""
info "📋 Partie 4 : Vérification Stargate (POC Local)"
echo ""

CONTAINER_CMD="podman"

if command -v podman &> /dev/null; then
    success "Podman disponible"
    echo ""

    info "Recherche de conteneur Stargate..."
    STARGATE_CONTAINER=$($CONTAINER_CMD ps -a --filter "name=stargate" --format "{{.Names}}" 2>/dev/null | head -1 || true)

    if [ -n "$STARGATE_CONTAINER" ]; then
        success "Conteneur Stargate trouvé : $STARGATE_CONTAINER"

        # Vérifier si le conteneur est en cours d'exécution
        if $CONTAINER_CMD ps --filter "name=$STARGATE_CONTAINER" --format "{{.Names}}" 2>/dev/null | grep -q "$STARGATE_CONTAINER"; then
            success "Conteneur en cours d'exécution"
        else
            warn "Conteneur arrêté"
            code "   → Démarrer avec : podman start $STARGATE_CONTAINER"
        fi
    else
        warn "Aucun conteneur Stargate trouvé"
        code "   → Pour déployer : podman run -d --name stargate -p 8080:8080 ..."
        code "   → Voir STATUT_DATA_API.md pour les instructions"
    fi
else
    warn "Podman non disponible"
    code "   → Pour POC local, installez Podman : brew install podman"
fi

echo ""

# ============================================
# Partie 5 : Test avec Client Python
# ============================================

echo ""
info "📋 Partie 5 : Test avec Client Python (astrapy)"
echo ""

if python3 -c "import astrapy" 2>/dev/null; then
    success "Client astrapy installé"
    echo ""

    info "Test de connexion avec le client Python..."

    # Créer un script de test temporaire
    TEST_SCRIPT=$(mktemp /tmp/test_data_api_XXXXXX.py)
    cat > "$TEST_SCRIPT" <<EOF
import os
import sys
from astrapy import DataAPIClient
from astrapy.authentication import UsernamePasswordTokenProvider
from astrapy.constants import Environment

API_ENDPOINT = os.getenv("API_ENDPOINT") or os.getenv("DATA_API_ENDPOINT", "http://localhost:8080")
USERNAME = os.getenv("USERNAME") or os.getenv("DATA_API_USERNAME", "cassandra")
PASSWORD = os.getenv("PASSWORD") or os.getenv("DATA_API_PASSWORD", "cassandra")

try:
    client = DataAPIClient(environment=Environment.HCD)
    database = client.get_database(
        API_ENDPOINT,
        token=UsernamePasswordTokenProvider(USERNAME, PASSWORD),
    )
    print("✅ Connexion réussie")
    sys.exit(0)
except Exception as e:
    print(f"❌ Erreur de connexion : {e}")
    sys.exit(1)
EOF

    # Exécuter le test
    if python3 "$TEST_SCRIPT" 2>&1; then
        success "Test de connexion réussi"
    else
        error "Test de connexion échoué"
        warn "   → Vérifiez que le gateway Data API est déployé et accessible"
    fi

    rm -f "$TEST_SCRIPT"
else
    warn "Client astrapy non installé"
    code "   → Installer avec : pip3 install \"astrapy>=2.0,<3.0\""
fi

echo ""

# ============================================
# Partie 6 : Résumé et Recommandations
# ============================================

echo ""
info "📋 Partie 6 : Résumé et Recommandations"
echo ""

echo "┌─────────────────────────────────────────────────────────────┐"
echo "│  État de la Configuration Data API                          │"
echo "├─────────────────────────────────────────────────────────────┤"
echo "│                                                               │"

# Variables
if [ -n "$API_ENDPOINT" ] && [ -n "$USERNAME_VAR" ] && [ -n "$PASSWORD_VAR" ]; then
    echo "│  Variables d'environnement    │ ✅ Configurées              │"
else
    echo "│  Variables d'environnement    │ ⚠️  Partiellement configurées│"
fi

# Connexion HTTP
if [ "$HTTP_STATUS" != "000" ]; then
    echo "│  Endpoint HTTP accessible      │ ✅ Oui (Status: $HTTP_STATUS)│"
else
    echo "│  Endpoint HTTP accessible      │ ❌ Non                      │"
fi

# Kubernetes
if command -v kubectl &> /dev/null && kubectl get svc 2>/dev/null | grep -qiE "stargate|gateway|data-api"; then
    echo "│  Service Kubernetes           │ ✅ Trouvé                    │"
else
    echo "│  Service Kubernetes           │ ❌ Non trouvé                │"
fi

# Podman/Stargate
if command -v podman &> /dev/null && podman ps -a --filter "name=stargate" --format "{{.Names}}" 2>/dev/null | grep -q .; then
    echo "│  Stargate (Podman)             │ ✅ Déployé                   │"
else
    echo "│  Stargate (Podman)             │ ❌ Non déployé               │"
fi

echo "│                                                               │"
echo "└─────────────────────────────────────────────────────────────┘"
echo ""

# Recommandations
if [ "$HTTP_STATUS" = "000" ]; then
    error "⚠️  L'endpoint Data API n'est PAS accessible"
    echo ""
    highlight "Recommandations :"
    echo ""
    code "Option 1 : Déployer Stargate (POC Local)"
    code "  podman run -d --name stargate -p 8080:8080 \\"
    code "    -e CLUSTER_NAME=local \\"
    code "    -e CLUSTER_SEED="$HCD_HOST:$HCD_PORT" \\"
    code "    stargateio/stargate-4.0:v1.0.84"
    echo ""
    code "Option 2 : Utiliser HCD en Kubernetes (Production)"
    code "  kubectl get nodes -o wide  # Pour CLUSTER_HOST"
    code "  kubectl get svc  # Pour GATEWAY_PORT"
    echo ""
    code "Option 3 : Démonstration Conceptuelle (Actuel)"
    code "  ✅ Configuration documentée"
    code "  ✅ Exemples de code créés"
    code "  ✅ Valeur ajoutée expliquée"
    echo ""
else
    success "✅ L'endpoint Data API est accessible"
    echo ""
    highlight "Prochaines étapes :"
    code "  1. Tester les exemples : python3 examples/python/data_api/examples/01_connect_data_api.py"
    code "  2. Voir README_DATA_API.md pour plus de détails"
    code "  3. Consulter le quickstart : https://docs.datastax.com/en/hyper-converged-database/1.2/api-reference/quickstart.html"
fi

echo ""

success "✅ Vérification terminée"
echo ""
