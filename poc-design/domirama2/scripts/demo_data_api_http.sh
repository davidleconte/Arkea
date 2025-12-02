#!/bin/bash
# ============================================
# Démonstration : Data API HCD via HTTP (curl)
# ============================================
#
# OBJECTIF :
#   Ce script démontre l'interaction directe avec la Data API HCD via HTTP
#   en utilisant curl, sans nécessiter de clients spécifiques (Python, Java, etc.).
#   Il est conforme à la documentation officielle DataStax.
#
#   Fonctionnalités :
#   - Génération du token d'authentification (format: Cassandra:BASE64-USERNAME:BASE64-PASSWORD)
#   - Requêtes HTTP directes (POST, GET) vers l'endpoint Data API
#   - Opérations CRUD via HTTP (findOne, insertOne, updateOne, deleteOne)
#   - Validation de la conformité avec la documentation officielle
#
# PRÉREQUIS :
#   - HCD démarré (./scripts/setup/03_start_hcd.sh)
#   - Schéma configuré (./10_setup_domirama2_poc.sh)
#   - Données chargées (./11_load_domirama2_data_parquet.sh)
#   - Stargate déployé (./39_deploy_stargate.sh)
#   - Endpoint Data API accessible (http://localhost:8080)
#   - curl installé
#   - jq installé (pour formater les réponses JSON)
#   - Variables d'environnement configurées (DATA_API_ENDPOINT, DATA_API_USERNAME, DATA_API_PASSWORD)
#
# UTILISATION :
#   ./demo_data_api_http.sh
#
# EXEMPLE :
#   ./demo_data_api_http.sh
#
# SORTIE :
#   - Résultats des requêtes HTTP affichés
#   - Validation de la conformité avec la documentation
#   - Messages de succès/erreur
#
# PROCHAINES ÉTAPES :
#   - Script 40: Démonstration complète Data API (./40_demo_data_api_complete.sh)
#   - Consulter la documentation: doc/18_README_DATA_API.md
#
# ============================================

set -euo pipefail

# Couleurs
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

info() { echo -e "${BLUE}ℹ️  $1${NC}"; }
success() { echo -e "${GREEN}✅ $1${NC}"; }
warn() { echo -e "${YELLOW}⚠️  $1${NC}"; }
error() { echo -e "${RED}❌ $1${NC}"; }
code() { echo -e "${CYAN}   $1${NC}"; }

# Configuration
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

if [ -f "$INSTALL_DIR/.poc-profile" ]; then
    source "$INSTALL_DIR/.poc-profile"
fi

# Utiliser HCD_HOST pour l'endpoint Data API (Stargate)
HCD_HOST="${HCD_HOST:-localhost}"
API_ENDPOINT="${API_ENDPOINT:-${DATA_API_ENDPOINT:-http://${HCD_HOST}:8080}}"
USERNAME="${USERNAME:-${DATA_API_USERNAME:-cassandra}}"
PASSWORD="${PASSWORD:-${DATA_API_PASSWORD:-cassandra}}"
KEYSPACE_NAME="domirama2_poc"
TABLE_NAME="operations_by_account"

# Générer le token (format : Cassandra:BASE64-USERNAME:BASE64-PASSWORD)
USERNAME_B64=$(echo -n "$USERNAME" | base64)
PASSWORD_B64=$(echo -n "$PASSWORD" | base64)
APPLICATION_TOKEN="Cassandra:${USERNAME_B64}:${PASSWORD_B64}"

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  🌐 DÉMONSTRATION : Data API HCD via HTTP (curl)"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "📚 Documentation : https://docs.datastax.com/en/hyper-converged-database/1.2/api-reference/dataapiclient.html"
echo "📚 Section : 'Use HTTP'"
echo ""

info "Configuration :"
code "  API_ENDPOINT : $API_ENDPOINT"
code "  KEYSPACE_NAME : $KEYSPACE_NAME"
code "  TABLE_NAME : $TABLE_NAME"
code "  APPLICATION_TOKEN : Cassandra:BASE64-USERNAME:BASE64-PASSWORD"
echo ""

# Vérifier que l'endpoint est accessible
info "Vérification de l'endpoint..."
HTTP_STATUS=$(curl -s -o /dev/null -w "%{http_code}" --connect-timeout 2 "$API_ENDPOINT/v1/status" 2>&1 || echo "000")

if [ "$HTTP_STATUS" != "200" ] && [ "$HTTP_STATUS" != "404" ]; then
    error "Endpoint non accessible (HTTP Status: $HTTP_STATUS)"
    warn "   → Stargate doit être déployé avec Podman"
    warn "   → Exécutez : ./39_deploy_stargate.sh"
    exit 1
fi

success "Endpoint accessible"
echo ""

# ============================================
# OPÉRATION 1 : INSERT - Insert a row (HTTP)
# ============================================

echo "=" * 80
info "📝 OPÉRATION 1 : INSERT - Insert a row (via HTTP)"
echo "=" * 80
echo ""

# Données de test
TEST_DATE_OP="2024-12-25T18:00:00Z"
TEST_NUMERO_OP=55555

INSERT_DATA=$(cat <<EOF
{
  "insertOne": {
    "document": {
      "code_si": "DEMO_HTTP",
      "contrat": "DEMO_001",
      "date_op": "$TEST_DATE_OP",
      "numero_op": $TEST_NUMERO_OP,
      "libelle": "DÉMONSTRATION HTTP DATA API",
      "montant": 222.22,
      "devise": "EUR",
      "cat_auto": "ALIMENTATION",
      "cat_confidence": 0.95
    }
  }
}
EOF
)

info "📄 Requête HTTP (conforme documentation) :"
code "  curl -X POST \"$API_ENDPOINT/v1/$KEYSPACE_NAME/$TABLE_NAME\" \\"
code "    --header \"Token: APPLICATION_TOKEN\" \\"
code "    --header \"Content-Type: application/json\" \\"
code "    --data '{...}'"
echo ""

info "🔄 Exécution..."
RESPONSE=$(curl -sS -L -X POST "$API_ENDPOINT/v1/$KEYSPACE_NAME/$TABLE_NAME" \
  --header "Token: $APPLICATION_TOKEN" \
  --header "Content-Type: application/json" \
  --data "$INSERT_DATA" 2>&1)

if echo "$RESPONSE" | grep -qE "(insertedId|status.*ok|success)"; then
    success "✅ INSERT RÉUSSI via HTTP !"
    echo "$RESPONSE" | jq . 2>/dev/null || echo "$RESPONSE"
    echo ""
    INSERT_OK=true
else
    error "❌ Erreur INSERT via HTTP"
    echo "$RESPONSE"
    echo ""
    INSERT_OK=false
fi

# ============================================
# OPÉRATION 2 : GET - Find a row (HTTP)
# ============================================

echo "=" * 80
info "📖 OPÉRATION 2 : GET - Find a row (via HTTP)"
echo "=" * 80
echo ""

FIND_ONE_DATA=$(cat <<EOF
{
  "findOne": {
    "filter": {
      "code_si": "DEMO_HTTP",
      "contrat": "DEMO_001",
      "date_op": "$TEST_DATE_OP",
      "numero_op": $TEST_NUMERO_OP
    }
  }
}
EOF
)

info "📄 Requête HTTP (conforme documentation) :"
code "  curl -X POST \"$API_ENDPOINT/v1/$KEYSPACE_NAME/$TABLE_NAME\" \\"
code "    --header \"Token: APPLICATION_TOKEN\" \\"
code "    --header \"Content-Type: application/json\" \\"
code "    --data '{\"findOne\": {\"filter\": {...}}}'"
echo ""

info "🔄 Exécution..."
RESPONSE=$(curl -sS -L -X POST "$API_ENDPOINT/v1/$KEYSPACE_NAME/$TABLE_NAME" \
  --header "Token: $APPLICATION_TOKEN" \
  --header "Content-Type: application/json" \
  --data "$FIND_ONE_DATA" 2>&1)

if echo "$RESPONSE" | grep -qE "(code_si|libelle|montant)"; then
    success "✅ GET RÉUSSI via HTTP !"
    echo "$RESPONSE" | jq . 2>/dev/null || echo "$RESPONSE"
    echo ""
    GET_OK=true
else
    warn "⚠️  GET via HTTP : Réponse inattendue"
    echo "$RESPONSE"
    echo ""
    GET_OK=false
fi

# ============================================
# OPÉRATION 3 : UPDATE - Update a row (HTTP)
# ============================================

echo "=" * 80
info "✏️  OPÉRATION 3 : UPDATE - Update a row (via HTTP)"
echo "=" * 80
echo ""

UPDATE_DATA=$(cat <<EOF
{
  "updateOne": {
    "filter": {
      "code_si": "DEMO_HTTP",
      "contrat": "DEMO_001",
      "date_op": "$TEST_DATE_OP",
      "numero_op": $TEST_NUMERO_OP
    },
    "update": {
      "\$set": {
        "libelle": "DÉMONSTRATION HTTP DATA API - MODIFIÉ",
        "montant": 444.44
      }
    }
  }
}
EOF
)

info "🔄 Exécution..."
RESPONSE=$(curl -sS -L -X POST "$API_ENDPOINT/v1/$KEYSPACE_NAME/$TABLE_NAME" \
  --header "Token: $APPLICATION_TOKEN" \
  --header "Content-Type: application/json" \
  --data "$UPDATE_DATA" 2>&1)

if echo "$RESPONSE" | grep -qE "(modifiedCount|status.*ok)"; then
    success "✅ UPDATE RÉUSSI via HTTP !"
    echo "$RESPONSE" | jq . 2>/dev/null || echo "$RESPONSE"
    echo ""
    UPDATE_OK=true
else
    warn "⚠️  UPDATE via HTTP : Réponse inattendue"
    echo "$RESPONSE"
    echo ""
    UPDATE_OK=false
fi

# ============================================
# OPÉRATION 4 : DELETE - Delete a row (HTTP)
# ============================================

echo "=" * 80
info "🗑️  OPÉRATION 4 : DELETE - Delete a row (via HTTP)"
echo "=" * 80
echo ""

DELETE_DATA=$(cat <<EOF
{
  "deleteOne": {
    "filter": {
      "code_si": "DEMO_HTTP",
      "contrat": "DEMO_001",
      "date_op": "$TEST_DATE_OP",
      "numero_op": $TEST_NUMERO_OP
    }
  }
}
EOF
)

info "🔄 Exécution..."
RESPONSE=$(curl -sS -L -X POST "$API_ENDPOINT/v1/$KEYSPACE_NAME/$TABLE_NAME" \
  --header "Token: $APPLICATION_TOKEN" \
  --header "Content-Type: application/json" \
  --data "$DELETE_DATA" 2>&1)

if echo "$RESPONSE" | grep -qE "(deletedCount|status.*ok)"; then
    success "✅ DELETE RÉUSSI via HTTP !"
    echo "$RESPONSE" | jq . 2>/dev/null || echo "$RESPONSE"
    echo ""
    DELETE_OK=true
else
    warn "⚠️  DELETE via HTTP : Réponse inattendue"
    echo "$RESPONSE"
    echo ""
    DELETE_OK=false
fi

# ============================================
# Résumé
# ============================================

echo "=" * 80
info "📊 RÉSUMÉ : Opérations CRUD via HTTP"
echo "=" * 80
echo ""

echo "┌─────────────────────────────────────────────────────────────┐"
echo "│  Opération                    │ Statut                      │"
echo "├─────────────────────────────────────────────────────────────┤"
printf "│  %-28s │ %-28s │\n" "INSERT (HTTP)" "$([ "$INSERT_OK" = true ] && echo '✅ RÉUSSI' || echo '❌ ÉCHOUÉ')"
printf "│  %-28s │ %-28s │\n" "GET (HTTP)" "$([ "$GET_OK" = true ] && echo '✅ RÉUSSI' || echo '❌ ÉCHOUÉ')"
printf "│  %-28s │ %-28s │\n" "UPDATE (HTTP)" "$([ "$UPDATE_OK" = true ] && echo '✅ RÉUSSI' || echo '❌ ÉCHOUÉ')"
printf "│  %-28s │ %-28s │\n" "DELETE (HTTP)" "$([ "$DELETE_OK" = true ] && echo '✅ RÉUSSI' || echo '❌ ÉCHOUÉ')"
echo "└─────────────────────────────────────────────────────────────┘"
echo ""

if [ "$INSERT_OK" = true ] && [ "$GET_OK" = true ] && [ "$UPDATE_OK" = true ] && [ "$DELETE_OK" = true ]; then
    success "✅ ✅ DÉMONSTRATION HTTP COMPLÈTE RÉUSSIE !"
    echo ""
    highlight "La Data API HCD fonctionne parfaitement via HTTP !"
    echo ""
    highlight "Toutes les opérations CRUD ont été testées avec succès :"
    code "   ✅ INSERT - insertOne (HTTP POST)"
    code "   ✅ GET - findOne (HTTP POST)"
    code "   ✅ UPDATE - updateOne (HTTP POST)"
    code "   ✅ DELETE - deleteOne (HTTP POST)"
    echo ""
else
    warn "⚠️  DÉMONSTRATION PARTIELLE"
    echo ""
    highlight "Certaines opérations ont échoué"
    highlight "Vérifiez que Stargate est déployé et accessible"
    echo ""
fi

success "✅ Démonstration terminée"
echo ""
