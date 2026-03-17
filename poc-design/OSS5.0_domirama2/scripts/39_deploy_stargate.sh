#!/bin/bash
set -euo pipefail
# ============================================
# Script 39 : Déploiement Stargate pour Data API
# ============================================
#
# OBJECTIF :
#   Ce script déploie Stargate (gateway HTTP pour HCD) pour rendre la Data API
#   accessible via HTTP REST/GraphQL, permettant d'utiliser la Data API sans
#   nécessiter de drivers binaires CQL.
#
#   Fonctionnalités :
#   - Déploiement de Stargate avec Podman (conforme aux contraintes)
#   - Configuration de l'endpoint Data API (http://localhost:8080)
#   - Vérification de la disponibilité
#   - Support des opérations CRUD via HTTP
#
# PRÉREQUIS :
#   - HCD démarré (./scripts/setup/03_start_hcd.sh)
#   - Schéma configuré (./10_setup_domirama2_poc.sh)
#   - Podman installé et configuré (Docker non autorisé)
#   - Port 8080 disponible
#   - Variables d'environnement configurées (DATA_API_ENDPOINT, DATA_API_USERNAME, DATA_API_PASSWORD)
#
# UTILISATION :
#   ./39_deploy_stargate.sh
#
# EXEMPLE :
#   ./39_deploy_stargate.sh
#
# SORTIE :
#   - Stargate déployé et démarré
#   - Endpoint Data API accessible (http://localhost:8080)
#   - Vérification de la disponibilité
#   - Messages de succès/erreur
#
# PROCHAINES ÉTAPES :
#   - Script 38: Vérification endpoint (./38_verifier_endpoint_data_api.sh)
#   - Script 40: Démonstration complète Data API (./40_demo_data_api_complete.sh)
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

STARGATE_IMAGE="stargateio/stargate-4.0:v1.0.84"
STARGATE_CONTAINER="stargate"
STARGATE_PORT=8080

# ============================================
# Vérifications Préalables
# ============================================

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  🚀 Déploiement Stargate pour Data API HCD"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

info "Référence : https://docs.datastax.com/en/hyper-converged-database/1.2/api-reference/dataapiclient.html"
info "Utilisation : Podman (au lieu de Docker)"
echo ""

# Vérifier Podman
info "Vérification de Podman..."
if ! command -v podman &> /dev/null; then
    error "Podman n'est pas installé"
    error "Installez Podman : brew install podman (sur macOS)"
    exit 1
fi
success "Podman disponible"

# Vérifier que Podman fonctionne
if ! podman info &> /dev/null; then
    error "Podman n'est pas démarré"
    error "Démarrez Podman : podman machine start"
    exit 1
fi
success "Podman fonctionne"

# Utiliser podman comme commande (alias pour compatibilité)
CONTAINER_CMD="podman"

# Vérifier que HCD est démarré
info "Vérification que HCD est démarré..."
if ! nc -z "$HCD_HOST" "$HCD_PORT" 2>/dev/null; then
    error "HCD n'est pas démarré sur "$HCD_HOST:$HCD_PORT""
    error "Exécutez d'abord: ./scripts/setup/03_start_hcd.sh"
    exit 1
fi
success "HCD est démarré"

echo ""

# ============================================
# Partie 1 : Vérifier si Stargate existe déjà
# ============================================

echo ""
info "📋 Partie 1 : Vérification Stargate existant"
echo ""

EXISTING_CONTAINER=$($CONTAINER_CMD ps -a --filter "name=$STARGATE_CONTAINER" --format "{{.Names}}" 2>/dev/null | head -1 || true)

if [ -n "$EXISTING_CONTAINER" ]; then
    success "Conteneur Stargate trouvé : $EXISTING_CONTAINER"

    # Vérifier si le conteneur est en cours d'exécution
    if $CONTAINER_CMD ps --filter "name=$STARGATE_CONTAINER" --format "{{.Names}}" 2>/dev/null | grep -q "$STARGATE_CONTAINER"; then
        success "Stargate est déjà en cours d'exécution"

        # Tester l'endpoint
        info "Test de l'endpoint..."
        if curl -s -o /dev/null -w "%{http_code}" --connect-timeout 2 "http://localhost:$STARGATE_PORT/v1/status" 2>&1 | grep -qE "200|404"; then
            success "Endpoint Data API accessible sur http://localhost:$STARGATE_PORT"
            echo ""
            highlight "Stargate est déjà déployé et fonctionnel"
            highlight "Vous pouvez utiliser la Data API maintenant"
            echo ""
            info "Pour tester :"
            code "  python3 examples/python/data_api/examples/01_connect_data_api.py"
            echo ""
            exit 0
        else
            warn "Endpoint non accessible, redémarrage du conteneur..."
            $CONTAINER_CMD restart "$STARGATE_CONTAINER" 2>/dev/null || true
            sleep 5
        fi
    else
        warn "Conteneur arrêté, démarrage..."
        $CONTAINER_CMD start "$STARGATE_CONTAINER" 2>/dev/null || {
            error "Impossible de démarrer le conteneur existant"
            info "Suppression et recréation..."
            $CONTAINER_CMD rm -f "$STARGATE_CONTAINER" 2>/dev/null || true
            EXISTING_CONTAINER=""
        }
    fi
else
    info "Aucun conteneur Stargate trouvé, déploiement nécessaire"
fi

echo ""

# ============================================
# Partie 2 : Télécharger l'Image Stargate
# ============================================

if [ -z "$EXISTING_CONTAINER" ]; then
    echo ""
    info "📋 Partie 2 : Téléchargement de l'Image Stargate"
    echo ""

    info "Image : $STARGATE_IMAGE"
    info "Téléchargement en cours..."

    if $CONTAINER_CMD pull "$STARGATE_IMAGE" 2>&1 | grep -E "(Pulling|Downloading|Downloaded|Already exists)"; then
        success "Image Stargate téléchargée"
    else
        error "Échec du téléchargement de l'image"
        exit 1
    fi

    echo ""
fi

# ============================================
# Partie 3 : Déployer Stargate
# ============================================

if [ -z "$EXISTING_CONTAINER" ]; then
    echo ""
    info "📋 Partie 3 : Déploiement Stargate"
    echo ""

    info "Configuration :"
    code "  Container : $STARGATE_CONTAINER"
    code "  Ports : 8080, 8081, 8082"
    code "  Cluster Seed : "$HCD_HOST:$HCD_PORT""
    code "  Mode : DEVELOPER_MODE=true"
    echo ""

    info "Démarrage du conteneur Stargate..."

    $CONTAINER_CMD run -d \
        --name "$STARGATE_CONTAINER" \
        -p 8080:8080 \
        -p 8081:8081 \
        -p 8082:8082 \
        -e CLUSTER_NAME=local \
        -e CLUSTER_VERSION=4.0 \
        -e DEVELOPER_MODE=true \
        -e CLUSTER_SEED="$HCD_HOST:$HCD_PORT" \
        -e DSE=1 \
        "$STARGATE_IMAGE" 2>&1 | grep -E "(Created|Started|Error|^[a-f0-9]+)" || {
        error "Échec du déploiement Stargate"
        exit 1
    }

    success "Conteneur Stargate créé"

    # Attendre que Stargate démarre
    info "Attente du démarrage de Stargate (30 secondes)..."
    sleep 30
fi

echo ""

# ============================================
# Partie 4 : Vérification
# ============================================

echo ""
info "📋 Partie 4 : Vérification du Déploiement"
echo ""

# Vérifier que le conteneur est en cours d'exécution
info "Vérification du conteneur..."
if $CONTAINER_CMD ps --filter "name=$STARGATE_CONTAINER" --format "{{.Names}}" 2>/dev/null | grep -q "$STARGATE_CONTAINER"; then
    success "Conteneur Stargate en cours d'exécution"
else
    error "Conteneur Stargate non démarré"
    info "Logs du conteneur :"
    $CONTAINER_CMD logs "$STARGATE_CONTAINER" 2>&1 | tail -20
    exit 1
fi

echo ""

# Test de l'endpoint HTTP
info "Test de l'endpoint HTTP (http://localhost:$STARGATE_PORT/v1/status)..."
MAX_RETRIES=10
RETRY=0
HTTP_STATUS="000"

while [ $RETRY -lt $MAX_RETRIES ]; do
    HTTP_STATUS=$(curl -s -o /dev/null -w "%{http_code}" --connect-timeout 2 "http://localhost:$STARGATE_PORT/v1/status" 2>&1 || echo "000")

    if [ "$HTTP_STATUS" = "200" ] || [ "$HTTP_STATUS" = "404" ]; then
        success "Endpoint accessible (HTTP Status: $HTTP_STATUS)"
        break
    fi

    RETRY=$((RETRY + 1))
    if [ $RETRY -lt $MAX_RETRIES ]; then
        info "Tentative $RETRY/$MAX_RETRIES... (attente 5 secondes)"
        sleep 5
    fi
done

if [ "$HTTP_STATUS" != "200" ] && [ "$HTTP_STATUS" != "404" ]; then
    warn "Endpoint non accessible après $MAX_RETRIES tentatives"
    warn "HTTP Status: $HTTP_STATUS"
    info "Vérification des logs..."
    $CONTAINER_CMD logs "$STARGATE_CONTAINER" 2>&1 | tail -30
    warn "Stargate peut nécessiter plus de temps pour démarrer"
    warn "Vérifiez avec : podman logs $STARGATE_CONTAINER"
else
    success "Stargate est accessible"
fi

echo ""

# ============================================
# Partie 5 : Configuration Variables
# ============================================

echo ""
info "📋 Partie 5 : Configuration Variables d'Environnement"
echo ""

API_ENDPOINT="http://localhost:$STARGATE_PORT"

# Mettre à jour .poc-profile
if [ -f "$INSTALL_DIR/.poc-profile" ]; then
    # Mettre à jour ou ajouter API_ENDPOINT
    if grep -q "^export API_ENDPOINT=" "$INSTALL_DIR/.poc-profile"; then
        sed -i.bak "s|^export API_ENDPOINT=.*|export API_ENDPOINT=\"$API_ENDPOINT\"|" "$INSTALL_DIR/.poc-profile"
        success "API_ENDPOINT mis à jour dans .poc-profile"
    else
        echo "" >> "$INSTALL_DIR/.poc-profile"
        echo "# Data API Endpoint (Stargate)" >> "$INSTALL_DIR/.poc-profile"
        echo "export API_ENDPOINT=\"$API_ENDPOINT\"" >> "$INSTALL_DIR/.poc-profile"
        success "API_ENDPOINT ajouté à .poc-profile"
    fi

    # S'assurer que DATA_API_ENDPOINT est aussi défini (pour compatibilité)
    if ! grep -q "^export DATA_API_ENDPOINT=" "$INSTALL_DIR/.poc-profile"; then
        echo "export DATA_API_ENDPOINT=\"$API_ENDPOINT\"" >> "$INSTALL_DIR/.poc-profile"
    fi
fi

info "Endpoint configuré : $API_ENDPOINT"
code "  Utilisez : source .poc-profile pour charger les variables"

echo ""

# ============================================
# Partie 6 : Test avec Client Python
# ============================================

echo ""
info "📋 Partie 6 : Test avec Client Python"
echo ""

if python3 -c "import astrapy" 2>/dev/null; then
    success "Client astrapy installé"

    info "Test de connexion avec le client Python..."

    # Créer un script de test temporaire
    TEST_SCRIPT=$(mktemp /tmp/test_stargate_XXXXXX.py)
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
    print("✅ Connexion Data API réussie !")
    print(f"   Endpoint : {API_ENDPOINT}")
    sys.exit(0)
except Exception as e:
    print(f"❌ Erreur : {e}")
    sys.exit(1)
EOF

    # Exécuter le test
    if API_ENDPOINT="$API_ENDPOINT" python3 "$TEST_SCRIPT" 2>&1; then
        success "Test de connexion réussi"
    else
        warn "Test de connexion échoué"
        warn "   → Vérifiez que Stargate est complètement démarré"
        warn "   → Attendez quelques secondes et réessayez"
    fi

    rm -f "$TEST_SCRIPT"
else
    warn "Client astrapy non installé"
    code "   → Installer avec : pip3 install \"astrapy>=2.0,<3.0\""
fi

echo ""

# ============================================
# Résumé
# ============================================

echo ""
success "✅ Déploiement Stargate terminé"
echo ""
info "📋 Résumé :"
code "  ✅ Conteneur Stargate : Déployé"
code "  ✅ Endpoint : http://localhost:$STARGATE_PORT"
code "  ✅ Variables : Configurées dans .poc-profile"
echo ""
info "🎯 Prochaines étapes :"
code "  1. Charger les variables : source .poc-profile"
code "  2. Tester : python3 examples/python/data_api/examples/01_connect_data_api.py"
code "  3. Vérifier : ./38_verifier_endpoint_data_api.sh"
echo ""
info "💡 Commandes utiles :"
code "  podman logs $STARGATE_CONTAINER  # Voir les logs"
code "  podman stop $STARGATE_CONTAINER  # Arrêter Stargate"
code "  podman start $STARGATE_CONTAINER # Démarrer Stargate"
code "  podman rm -f $STARGATE_CONTAINER # Supprimer Stargate"
echo ""
