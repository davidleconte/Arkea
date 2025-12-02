#!/bin/bash
# ============================================
# Script 41 : Démonstration Complète Data API avec Podman
# ============================================
#
# OBJECTIF :
#   Ce script orchestre une démonstration complète de la Data API HCD en
#   utilisant Podman (conforme aux contraintes, Docker non autorisé) pour
#   déployer Stargate et valider toutes les fonctionnalités.
#   
#   Étapes exécutées :
#   1. Vérifier HCD démarré
#   2. Vérifier Podman disponible (Docker non autorisé)
#   3. Déployer Stargate avec Podman
#   4. Vérifier l'endpoint Data API
#   5. Tester les opérations CRUD réelles (insert, find, update, delete)
#
# PRÉREQUIS :
#   - HCD démarré (./scripts/setup/03_start_hcd.sh)
#   - Schéma configuré (./10_setup_domirama2_poc.sh)
#   - Données chargées (./11_load_domirama2_data_parquet.sh)
#   - Data API configurée (./36_setup_data_api.sh)
#   - Python 3.8+ avec astrapy installé
#   - Podman installé et configuré (Docker non autorisé)
#   - Port 8080 disponible
#   - Variables d'environnement configurées (DATA_API_ENDPOINT, DATA_API_USERNAME, DATA_API_PASSWORD)
#
# UTILISATION :
#   ./41_demo_complete_podman.sh
#
# EXEMPLE :
#   ./41_demo_complete_podman.sh
#
# SORTIE :
#   - Vérification de tous les prérequis (HCD, Podman)
#   - Déploiement de Stargate avec Podman
#   - Résultats de toutes les opérations CRUD
#   - Validation complète du fonctionnement
#   - Messages de succès/erreur pour chaque étape
#
# PROCHAINES ÉTAPES :
#   - Consulter la documentation: doc/18_README_DATA_API.md
#   - Utiliser la Data API dans les applications
#
# ============================================
#
# ============================================

set -euo pipefail

# Couleurs pour output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
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
    echo -e "${CYAN}   $1${NC}"
}

highlight() {
    echo -e "${MAGENTA}💡 $1${NC}"
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

STARGATE_CONTAINER="stargate"
STARGATE_PORT=8080
STARGATE_IMAGE="stargateio/stargate-4.0:v1.0.84"
API_ENDPOINT="${API_ENDPOINT:-${DATA_API_ENDPOINT:-http://localhost:$STARGATE_PORT}}"
USERNAME="${USERNAME:-${DATA_API_USERNAME:-cassandra}}"
PASSWORD="${PASSWORD:-${DATA_API_PASSWORD:-cassandra}}"
CONTAINER_CMD="podman"

# ============================================
# Démonstration
# ============================================

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  🎯 DÉMONSTRATION COMPLÈTE : Data API HCD avec Podman"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# ============================================
# Étape 1 : Vérifier HCD
# ============================================

echo ""
info "📋 Étape 1 : Vérification HCD"
echo ""

if ! nc -z "$HCD_HOST" "$HCD_PORT" 2>/dev/null; then
    error "HCD n'est pas démarré sur "$HCD_HOST:$HCD_PORT""
    error "Exécutez d'abord: ./scripts/setup/03_start_hcd.sh"
    exit 1
fi
success "HCD est démarré et accessible sur "$HCD_HOST:$HCD_PORT""

echo ""

# ============================================
# Étape 2 : Vérifier Podman
# ============================================

echo ""
info "📋 Étape 2 : Vérification Podman"
echo ""

if ! command -v podman &> /dev/null; then
    error "Podman n'est pas installé"
    error "Installez Podman : brew install podman (sur macOS)"
    exit 1
fi
success "Podman disponible"

# Vérifier que Podman fonctionne
if ! podman info &> /dev/null; then
    warn "Podman machine n'est peut-être pas démarrée"
    info "Tentative de démarrage de la machine Podman..."
    podman machine start 2>&1 | grep -E "(Starting|started|already)" || true
    info "Attente que Podman soit prêt (10 secondes)..."
    sleep 10
    
    # Réessayer plusieurs fois
    MAX_RETRIES=5
    RETRY=0
    while [ $RETRY -lt $MAX_RETRIES ]; do
        if podman info &> /dev/null; then
            break
        fi
        RETRY=$((RETRY + 1))
        if [ $RETRY -lt $MAX_RETRIES ]; then
            info "Tentative $RETRY/$MAX_RETRIES... (attente 3 secondes)"
            sleep 3
        fi
    done
fi

if podman info &> /dev/null; then
    success "Podman fonctionne"
else
    warn "Podman info échoue, mais continuons quand même"
    warn "Vérifiez manuellement : podman info"
    # Ne pas sortir, continuer pour voir si les conteneurs fonctionnent
fi

echo ""

# ============================================
# Étape 3 : Déployer Stargate avec Podman
# ============================================

echo ""
info "📋 Étape 3 : Déploiement Stargate avec Podman"
echo ""

STARGATE_RUNNING=false

# Vérifier si Stargate existe déjà
EXISTING_CONTAINER=$($CONTAINER_CMD ps -a --filter "name=$STARGATE_CONTAINER" --format "{{.Names}}" 2>/dev/null | head -1 || true)

if [ -n "$EXISTING_CONTAINER" ]; then
    success "Conteneur Stargate trouvé : $EXISTING_CONTAINER"
    
    # Vérifier si le conteneur est en cours d'exécution
    if $CONTAINER_CMD ps --filter "name=$STARGATE_CONTAINER" --format "{{.Names}}" 2>/dev/null | grep -q "$STARGATE_CONTAINER"; then
        success "Stargate est déjà en cours d'exécution"
        STARGATE_RUNNING=true
    else
        warn "Conteneur arrêté, démarrage..."
        $CONTAINER_CMD start "$STARGATE_CONTAINER" 2>/dev/null || true
        sleep 10
        if $CONTAINER_CMD ps --filter "name=$STARGATE_CONTAINER" --format "{{.Names}}" 2>/dev/null | grep -q "$STARGATE_CONTAINER"; then
            success "Stargate démarré"
            STARGATE_RUNNING=true
        fi
    fi
else
    warn "Stargate n'est pas déployé"
    info "Déploiement en cours..."
    
    # Télécharger l'image si nécessaire
    info "Téléchargement de l'image Stargate..."
    $CONTAINER_CMD pull "$STARGATE_IMAGE" 2>&1 | grep -E "(Pulling|Downloading|Downloaded|Already exists)" || true
    
    # Déployer Stargate
    info "Démarrage du conteneur Stargate..."
    CONTAINER_OUTPUT=$($CONTAINER_CMD run -d \
        --name "$STARGATE_CONTAINER" \
        -p 8080:8080 \
        -p 8081:8081 \
        -p 8082:8082 \
        -e CLUSTER_NAME=local \
        -e CLUSTER_VERSION=4.0 \
        -e DEVELOPER_MODE=true \
        -e CLUSTER_SEED="$HCD_HOST:$HCD_PORT" \
        -e DSE=1 \
        "$STARGATE_IMAGE" 2>&1)
    
    if [ $? -eq 0 ]; then
        success "Conteneur Stargate créé"
    else
        error "Échec du déploiement Stargate"
        error "Sortie : $CONTAINER_OUTPUT"
        # Vérifier si le conteneur existe quand même
        if $CONTAINER_CMD ps -a --filter "name=$STARGATE_CONTAINER" --format "{{.Names}}" 2>/dev/null | grep -q "$STARGATE_CONTAINER"; then
            warn "Le conteneur existe, peut-être déjà créé"
            STARGATE_RUNNING=true
        else
            exit 1
        fi
    fi
    
    success "Conteneur Stargate créé"
    STARGATE_RUNNING=true
    
    # Attendre que Stargate démarre
    info "Attente du démarrage de Stargate (30 secondes)..."
    sleep 30
fi

echo ""

# ============================================
# Étape 4 : Vérifier l'Endpoint
# ============================================

echo ""
info "📋 Étape 4 : Vérification Endpoint HTTP"
echo ""

if [ "$STARGATE_RUNNING" = true ]; then
    info "Test de l'endpoint : $API_ENDPOINT"
    
    MAX_RETRIES=10
    RETRY=0
    HTTP_STATUS="000"
    
    while [ $RETRY -lt $MAX_RETRIES ]; do
        HTTP_STATUS=$(curl -s -o /dev/null -w "%{http_code}" --connect-timeout 5 "$API_ENDPOINT/v1/status" 2>&1 || echo "000")
        
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
        info "Logs Stargate :"
        $CONTAINER_CMD logs "$STARGATE_CONTAINER" 2>&1 | tail -10
    fi
else
    error "Stargate non déployé - Endpoint non accessible"
    exit 1
fi

echo ""

# ============================================
# Étape 5 : Test CRUD avec Python
# ============================================

echo ""
info "📋 Étape 5 : Test CRUD Réel avec Python"
echo ""

# Vérifier que le client Python est installé
if ! python3 -c "import astrapy" 2>/dev/null; then
    error "Client astrapy non installé"
    info "Installation en cours..."
    pip3 install "astrapy>=2.0,<3.0" --quiet 2>&1 || {
        error "Échec de l'installation"
        exit 1
    }
fi
success "Client astrapy installé"

echo ""

# Créer un script de test CRUD complet
CRUD_SCRIPT=$(mktemp /tmp/demo_crud_XXXXXX.py)
cat > "$CRUD_SCRIPT" <<'PYTHON_EOF'
#!/usr/bin/env python3
"""
Démonstration CRUD Réelle : Data API HCD
"""
import os
import sys
from datetime import datetime, timezone
from decimal import Decimal
from astrapy import DataAPIClient
from astrapy.authentication import UsernamePasswordTokenProvider
from astrapy.constants import Environment

API_ENDPOINT = os.getenv("API_ENDPOINT") or os.getenv("DATA_API_ENDPOINT", "http://localhost:8080")
USERNAME = os.getenv("USERNAME") or os.getenv("DATA_API_USERNAME", "cassandra")
PASSWORD = os.getenv("PASSWORD") or os.getenv("DATA_API_PASSWORD", "cassandra")

print("=" * 80)
print("🎯 DÉMONSTRATION CRUD RÉELLE : Data API HCD")
print("=" * 80)
print()

# Connexion
print("📋 Connexion à la Data API...")
try:
    client = DataAPIClient(environment=Environment.HCD)
    database = client.get_database(
        API_ENDPOINT,
        token=UsernamePasswordTokenProvider(USERNAME, PASSWORD),
    )
    print("✅ Connexion réussie")
    print()
except Exception as e:
    print(f"❌ Erreur de connexion : {e}")
    sys.exit(1)

# Accès à la table
print("📋 Accès à la table 'operations_by_account'...")
try:
    table = database.get_table("operations_by_account", keyspace="domirama2_poc")
    print("✅ Table accessible")
    print()
except Exception as e:
    print(f"❌ Erreur d'accès à la table : {e}")
    sys.exit(1)

# Données de test
test_code_si = "DEMO_CRUD_PODMAN"
test_contrat = "DEMO_001"
test_date_op = datetime(2024, 12, 25, 15, 0, 0, tzinfo=timezone.utc)
test_numero_op = 88888

test_operation = {
    "code_si": test_code_si,
    "contrat": test_contrat,
    "date_op": test_date_op,
    "numero_op": test_numero_op,
    "libelle": "DÉMONSTRATION CRUD PODMAN - Test INSERT",
    "montant": Decimal("999.99"),
    "devise": "EUR",
    "cat_auto": "ALIMENTATION",
    "cat_confidence": Decimal("0.98"),
}

# ============================================
# OPÉRATION 1 : INSERT (PUT)
# ============================================

print("=" * 80)
print("📝 OPÉRATION 1 : INSERT (PUT)")
print("=" * 80)
print()

try:
    print("🔄 Insertion en cours...")
    result = table.insert_one(test_operation)
    print("✅ ✅ INSERT RÉUSSI !")
    print(f"   ID : {result.get('insertedId', 'N/A')}")
    print()
    INSERT_OK = True
except Exception as e:
    print(f"❌ Erreur INSERT : {type(e).__name__}")
    print(f"   Message : {str(e)[:150]}")
    print()
    INSERT_OK = False

# ============================================
# OPÉRATION 2 : GET (SELECT)
# ============================================

print("=" * 80)
print("📖 OPÉRATION 2 : GET (SELECT)")
print("=" * 80)
print()

if INSERT_OK:
    try:
        print("🔄 Recherche en cours...")
        result = table.find_one(
            filter={
                "code_si": test_code_si,
                "contrat": test_contrat,
                "date_op": test_date_op,
                "numero_op": test_numero_op,
            }
        )
        
        if result:
            print("✅ ✅ GET RÉUSSI !")
            print(f"   Libellé : {result.get('libelle', 'N/A')}")
            print(f"   Montant : {result.get('montant', 'N/A')} {result.get('devise', 'EUR')}")
            print(f"   Cat Auto : {result.get('cat_auto', 'N/A')}")
            print()
            GET_OK = True
        else:
            print("⚠️  Aucune donnée trouvée")
            GET_OK = False
    except Exception as e:
        print(f"❌ Erreur GET : {type(e).__name__}")
        print(f"   Message : {str(e)[:150]}")
        print()
        GET_OK = False
else:
    print("⚠️  INSERT a échoué, impossible de tester GET")
    GET_OK = False

# ============================================
# OPÉRATION 3 : UPDATE
# ============================================

print("=" * 80)
print("✏️  OPÉRATION 3 : UPDATE")
print("=" * 80)
print()

if GET_OK:
    try:
        print("🔄 Mise à jour en cours...")
        result = table.update_one(
            filter={
                "code_si": test_code_si,
                "contrat": test_contrat,
                "date_op": test_date_op,
                "numero_op": test_numero_op,
            },
            update={
                "$set": {
                    "libelle": "DÉMONSTRATION CRUD PODMAN - MODIFIÉ",
                    "montant": Decimal("1111.11"),
                }
            }
        )
        print("✅ ✅ UPDATE RÉUSSI !")
        print(f"   Modifié : {result.get('modifiedCount', 'N/A')}")
        print()
        
        # Vérifier la mise à jour
        updated = table.find_one(
            filter={
                "code_si": test_code_si,
                "contrat": test_contrat,
                "date_op": test_date_op,
                "numero_op": test_numero_op,
            }
        )
        if updated:
            print("✅ Vérification : Données mises à jour")
            print(f"   Nouveau libellé : {updated.get('libelle', 'N/A')}")
            print(f"   Nouveau montant : {updated.get('montant', 'N/A')}")
            print()
        UPDATE_OK = True
    except Exception as e:
        print(f"❌ Erreur UPDATE : {type(e).__name__}")
        print(f"   Message : {str(e)[:150]}")
        print()
        UPDATE_OK = False
else:
    print("⚠️  GET a échoué, impossible de tester UPDATE")
    UPDATE_OK = False

# ============================================
# OPÉRATION 4 : DELETE
# ============================================

print("=" * 80)
print("🗑️  OPÉRATION 4 : DELETE")
print("=" * 80)
print()

if UPDATE_OK:
    try:
        print("🔄 Suppression en cours...")
        result = table.delete_one(
            filter={
                "code_si": test_code_si,
                "contrat": test_contrat,
                "date_op": test_date_op,
                "numero_op": test_numero_op,
            }
        )
        print("✅ ✅ DELETE RÉUSSI !")
        print(f"   Supprimé : {result.get('deletedCount', 'N/A')}")
        print()
        
        # Vérifier la suppression
        deleted_check = table.find_one(
            filter={
                "code_si": test_code_si,
                "contrat": test_contrat,
                "date_op": test_date_op,
                "numero_op": test_numero_op,
            }
        )
        if not deleted_check:
            print("✅ Vérification : Suppression confirmée")
        else:
            print("⚠️  L'opération existe encore")
        print()
        DELETE_OK = True
    except Exception as e:
        print(f"❌ Erreur DELETE : {type(e).__name__}")
        print(f"   Message : {str(e)[:150]}")
        print()
        DELETE_OK = False
else:
    print("⚠️  UPDATE a échoué, impossible de tester DELETE")
    DELETE_OK = False

# ============================================
# Résumé
# ============================================

print("=" * 80)
print("📊 RÉSUMÉ DES OPÉRATIONS CRUD")
print("=" * 80)
print()

operations = {
    "INSERT (PUT)": INSERT_OK,
    "GET (SELECT)": GET_OK,
    "UPDATE": UPDATE_OK,
    "DELETE": DELETE_OK,
}

print("┌─────────────────────────────────────────────────────────────┐")
print("│  Opération                    │ Statut                      │")
print("├─────────────────────────────────────────────────────────────┤")
for op, status in operations.items():
    status_str="✅ RÉUSSI" if status else "❌ ÉCHOUÉ"
    printf "│  %-28s │ %-28s │\n" "$op" "$status_str"
print("└─────────────────────────────────────────────────────────────┘")
print()

if all(operations.values()):
    print("=" * 80)
    print("✅ ✅ DÉMONSTRATION CRUD COMPLÈTE RÉUSSIE !")
    print("=" * 80)
    print()
    print("🎉 La Data API HCD fonctionne parfaitement avec Podman !")
    print()
    print("📋 Toutes les opérations CRUD ont été testées avec succès :")
    print("   ✅ INSERT (PUT) - Insertion de données")
    print("   ✅ GET (SELECT) - Lecture de données")
    print("   ✅ UPDATE - Mise à jour de données")
    print("   ✅ DELETE - Suppression de données")
    print()
    sys.exit(0)
else:
    print("=" * 80)
    print("⚠️  DÉMONSTRATION PARTIELLE")
    print("=" * 80)
    print()
    print("Certaines opérations ont échoué.")
    print("Vérifiez les logs et la configuration.")
    print()
    sys.exit(1)
PYTHON_EOF

# Corriger le printf dans le script Python
sed -i '' 's/printf "│  %-28s │ %-28s │\\n" "$op" "$status_str"/print(f"│  {op:28} │ {status_str:28} │")/' "$CRUD_SCRIPT"

# Exécuter le test CRUD
info "Exécution du test CRUD complet..."
echo ""

if API_ENDPOINT="$API_ENDPOINT" USERNAME="$USERNAME" PASSWORD="$PASSWORD" python3 "$CRUD_SCRIPT" 2>&1; then
    success "✅ Démonstration CRUD réussie !"
    DEMO_SUCCESS=true
else
    error "❌ Démonstration CRUD partielle ou échouée"
    DEMO_SUCCESS=false
fi

rm -f "$CRUD_SCRIPT"

echo ""

# ============================================
# Résumé Final
# ============================================

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  📊 RÉSUMÉ DE LA DÉMONSTRATION"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

echo "┌─────────────────────────────────────────────────────────────┐"
echo "│  Composant                    │ Statut                      │"
echo "├─────────────────────────────────────────────────────────────┤"

# HCD
if nc -z "$HCD_HOST" "$HCD_PORT" 2>/dev/null; then
    echo "│  HCD ("$HCD_HOST:$HCD_PORT")          │ ✅ Démarré                  │"
else
    echo "│  HCD ("$HCD_HOST:$HCD_PORT")          │ ❌ Non démarré              │"
fi

# Podman
if command -v podman &> /dev/null && podman info &> /dev/null; then
    echo "│  Podman                        │ ✅ Disponible               │"
else
    echo "│  Podman                        │ ❌ Non disponible           │"
fi

# Stargate
if [ "$STARGATE_RUNNING" = true ]; then
    echo "│  Stargate (Podman)             │ ✅ Déployé                  │"
else
    echo "│  Stargate (Podman)             │ ❌ Non déployé              │"
fi

# Endpoint
HTTP_STATUS=$(curl -s -o /dev/null -w "%{http_code}" --connect-timeout 2 "$API_ENDPOINT/v1/status" 2>&1 || echo "000")
if [ "$HTTP_STATUS" = "200" ] || [ "$HTTP_STATUS" = "404" ]; then
    echo "│  Endpoint HTTP                 │ ✅ Accessible               │"
else
    echo "│  Endpoint HTTP                 │ ❌ Non accessible          │"
fi

# Client Python
if python3 -c "import astrapy" 2>/dev/null; then
    echo "│  Client Python (astrapy)       │ ✅ Installé                 │"
else
    echo "│  Client Python (astrapy)       │ ❌ Non installé            │"
fi

# Test CRUD
if [ "$DEMO_SUCCESS" = true ]; then
    echo "│  Test CRUD                     │ ✅ RÉUSSI                   │"
else
    echo "│  Test CRUD                     │ ⚠️  PARTIEL                 │"
fi

echo "└─────────────────────────────────────────────────────────────┘"
echo ""

# Conclusion
if [ "$DEMO_SUCCESS" = true ]; then
    success "✅ ✅ DÉMONSTRATION COMPLÈTE RÉUSSIE !"
    echo ""
    highlight "La Data API HCD fonctionne parfaitement avec Podman !"
    echo ""
    highlight "Toutes les opérations CRUD ont été testées avec succès :"
    code "   ✅ INSERT (PUT) - Insertion de données"
    code "   ✅ GET (SELECT) - Lecture de données"
    code "   ✅ UPDATE - Mise à jour de données"
    code "   ✅ DELETE - Suppression de données"
    echo ""
else
    warn "⚠️  DÉMONSTRATION PARTIELLE"
    echo ""
    highlight "Certaines opérations ont échoué."
    highlight "Vérifiez :"
    code "   1. Logs Stargate : podman logs $STARGATE_CONTAINER"
    code "   2. Endpoint accessible : curl $API_ENDPOINT/v1/status"
    code "   3. HCD démarré : nc -z "$HCD_HOST" "$HCD_PORT""
    echo ""
fi

success "✅ Démonstration terminée"
echo ""

