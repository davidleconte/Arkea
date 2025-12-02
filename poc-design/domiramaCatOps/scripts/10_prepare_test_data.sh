#!/bin/bash
# ============================================
# Script : Préparation des données de test pour 10_test_regles_personnalisees.sh
# Insère des données de test cohérentes pour tous les tests
# ============================================

set -euo pipefail

# Charger l'environnement
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

if [ -f "${INSTALL_DIR}/.poc-profile" ]; then
    source "${INSTALL_DIR}/.poc-profile"
fi

HCD_DIR="${HCD_HOME:-${INSTALL_DIR}/binaire/hcd-1.2.3}"
CQLSH_BIN="${HCD_DIR}/bin/cqlsh"
CQLSH="$CQLSH_BIN "$HCD_HOST" "$HCD_PORT""

# Couleurs
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m'
info() { echo -e "${BLUE}ℹ️  $1${NC}"; }
success() { echo -e "${GREEN}✅ $1${NC}"; }

echo ""
info "🔧 Préparation des données de test pour regles_personnalisees..."
echo ""

# Valeurs de test cohérentes
TEST_CODE_EFS="1"

# 1. Vérifier si la règle CARREFOUR MARKET existe déjà
info "📝 Vérification règle CARREFOUR MARKET..."

CHECK_RULE=$($CQLSH -e "USE domiramacatops_poc; SELECT COUNT(*) FROM regles_personnalisees WHERE code_efs = '${TEST_CODE_EFS}' AND type_operation = 'VIREMENT' AND sens_operation = 'DEBIT' AND libelle_simplifie = 'CARREFOUR MARKET';" 2>&1 | grep -E "^\s+[0-9]+" | tr -d ' ' || echo "0")

if [ "$CHECK_RULE" = "0" ] || [ -z "$CHECK_RULE" ]; then
    info "📝 Insertion règle CARREFOUR MARKET..."
    $CQLSH -e "USE domiramacatops_poc; INSERT INTO regles_personnalisees (code_efs, type_operation, sens_operation, libelle_simplifie, categorie_cible, priorite, actif, created_at) VALUES ('${TEST_CODE_EFS}', 'VIREMENT', 'DEBIT', 'CARREFOUR MARKET', 'ALIMENTATION', 100, true, toTimestamp(now()));" 2>&1 | grep -vE "^Warnings|^$|^\([0-9]+ rows\)|coordinator|total|Executing|Read|Scanned|Merging|Tracing|Activity|Requests|responses|Parsing|Sending" || true
    success "✅ Règle CARREFOUR MARKET insérée"
else
    success "✅ Règle CARREFOUR MARKET existe déjà"
fi

echo ""

# 2. Insérer quelques règles supplémentaires pour les tests de filtrage
info "📝 Insertion règles supplémentaires pour tests de filtrage..."

# Règle avec catégorie ALIMENTATION et actif = true
$CQLSH -e "USE domiramacatops_poc; INSERT INTO regles_personnalisees (code_efs, type_operation, sens_operation, libelle_simplifie, categorie_cible, priorite, actif, created_at) VALUES ('${TEST_CODE_EFS}', 'CB', 'DEBIT', 'SUPERMARCHE TEST', 'ALIMENTATION', 80, true, toTimestamp(now()));" 2>&1 | grep -vE "^Warnings|^$|^\([0-9]+ rows\)|coordinator|total|Executing|Read|Scanned|Merging|Tracing|Activity|Requests|responses|Parsing|Sending" || true

# Règle avec actif = false
$CQLSH -e "USE domiramacatops_poc; INSERT INTO regles_personnalisees (code_efs, type_operation, sens_operation, libelle_simplifie, categorie_cible, priorite, actif, created_at) VALUES ('${TEST_CODE_EFS}', 'CB', 'CREDIT', 'REGLE INACTIVE', 'TRANSPORT', 50, false, toTimestamp(now()));" 2>&1 | grep -vE "^Warnings|^$|^\([0-9]+ rows\)|coordinator|total|Executing|Read|Scanned|Merging|Tracing|Activity|Requests|responses|Parsing|Sending" || true

success "✅ Règles supplémentaires insérées"

echo ""
success "✅ Données de test préparées avec succès"
echo ""
