#!/bin/bash
# ============================================
# Script : Préparation des données de test pour 11_test_feedbacks_counters.sh
# Insère des données de test cohérentes pour tous les tests
# ============================================

set -e

# Charger l'environnement
INSTALL_DIR="/Users/david.leconte/Documents/Arkea"
if [ -f "${INSTALL_DIR}/.poc-profile" ]; then
    source "${INSTALL_DIR}/.poc-profile"
fi

HCD_DIR="${HCD_HOME:-${INSTALL_DIR}/binaire/hcd-1.2.3}"
CQLSH_BIN="${HCD_DIR}/bin/cqlsh"
CQLSH="$CQLSH_BIN localhost 9042"

# Couleurs
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m'
info() { echo -e "${BLUE}ℹ️  $1${NC}"; }
success() { echo -e "${GREEN}✅ $1${NC}"; }

echo ""
info "🔧 Préparation des données de test pour feedback_par_libelle et feedback_par_ics..."
echo ""

# Valeurs de test cohérentes
TEST_TYPE_OPERATION="VIREMENT"
TEST_SENS_OPERATION="DEBIT"
TEST_LIBELLE_SIMPLIFIE="CARREFOUR MARKET"
TEST_CATEGORIE="ALIMENTATION"
TEST_CODE_ICS="ICS001"

# 1. Vérifier/Créer données feedback_par_libelle
info "📝 Vérification données feedback_par_libelle..."

CHECK_FEEDBACK_LIBELLE=$($CQLSH -e "USE domiramacatops_poc; SELECT COUNT(*) FROM feedback_par_libelle WHERE type_operation = '${TEST_TYPE_OPERATION}' AND sens_operation = '${TEST_SENS_OPERATION}' AND libelle_simplifie = '${TEST_LIBELLE_SIMPLIFIE}' AND categorie = '${TEST_CATEGORIE}';" 2>&1 | grep -E "^\s+[0-9]+" | tr -d ' ' || echo "0")

if [ "$CHECK_FEEDBACK_LIBELLE" = "0" ] || [ -z "$CHECK_FEEDBACK_LIBELLE" ]; then
    info "📝 Insertion données feedback_par_libelle avec compteurs à 0..."
    $CQLSH -e "USE domiramacatops_poc; INSERT INTO feedback_par_libelle (type_operation, sens_operation, libelle_simplifie, categorie, count_engine, count_client) VALUES ('${TEST_TYPE_OPERATION}', '${TEST_SENS_OPERATION}', '${TEST_LIBELLE_SIMPLIFIE}', '${TEST_CATEGORIE}', 0, 0);" 2>&1 | grep -vE "^Warnings|^$|^\([0-9]+ rows\)|coordinator|total|Executing|Read|Scanned|Merging|Tracing|Activity|Requests|responses|Parsing|Sending" || true
    success "✅ Données feedback_par_libelle insérées (compteurs initialisés à 0)"
else
    # Note: Les tables COUNTER ne permettent pas SET, seulement INCREMENT/DECREMENT
    # On ne peut pas réinitialiser à 0, mais on peut lire la valeur actuelle
    info "📝 Données feedback_par_libelle existent déjà"
    CURRENT_ENGINE=$($CQLSH -e "USE domiramacatops_poc; SELECT count_engine FROM feedback_par_libelle WHERE type_operation = '${TEST_TYPE_OPERATION}' AND sens_operation = '${TEST_SENS_OPERATION}' AND libelle_simplifie = '${TEST_LIBELLE_SIMPLIFIE}' AND categorie = '${TEST_CATEGORIE}';" 2>&1 | grep -E "^[[:space:]]*[0-9]+" | tr -d ' ' | head -1 || echo "0")
    CURRENT_CLIENT=$($CQLSH -e "USE domiramacatops_poc; SELECT count_client FROM feedback_par_libelle WHERE type_operation = '${TEST_TYPE_OPERATION}' AND sens_operation = '${TEST_SENS_OPERATION}' AND libelle_simplifie = '${TEST_LIBELLE_SIMPLIFIE}' AND categorie = '${TEST_CATEGORIE}';" 2>&1 | grep -E "^[[:space:]]*[0-9]+" | tr -d ' ' | head -1 || echo "0")
    info "   Valeurs actuelles : count_engine = $CURRENT_ENGINE, count_client = $CURRENT_CLIENT"
    success "✅ Données feedback_par_libelle existent (compteurs seront utilisés pour les tests)"
fi

echo ""

# 2. Vérifier/Créer données feedback_par_ics
info "📝 Vérification données feedback_par_ics..."

CHECK_FEEDBACK_ICS=$($CQLSH -e "USE domiramacatops_poc; SELECT COUNT(*) FROM feedback_par_ics WHERE type_operation = '${TEST_TYPE_OPERATION}' AND sens_operation = '${TEST_SENS_OPERATION}' AND code_ics = '${TEST_CODE_ICS}' AND categorie = '${TEST_CATEGORIE}';" 2>&1 | grep -E "^\s+[0-9]+" | tr -d ' ' || echo "0")

if [ "$CHECK_FEEDBACK_ICS" = "0" ] || [ -z "$CHECK_FEEDBACK_ICS" ]; then
    info "📝 Insertion données feedback_par_ics avec compteurs à 0..."
    $CQLSH -e "USE domiramacatops_poc; INSERT INTO feedback_par_ics (type_operation, sens_operation, code_ics, categorie, count_engine, count_client) VALUES ('${TEST_TYPE_OPERATION}', '${TEST_SENS_OPERATION}', '${TEST_CODE_ICS}', '${TEST_CATEGORIE}', 0, 0);" 2>&1 | grep -vE "^Warnings|^$|^\([0-9]+ rows\)|coordinator|total|Executing|Read|Scanned|Merging|Tracing|Activity|Requests|responses|Parsing|Sending" || true
    success "✅ Données feedback_par_ics insérées (compteurs initialisés à 0)"
else
    # Note: Les tables COUNTER ne permettent pas SET, seulement INCREMENT/DECREMENT
    # On ne peut pas réinitialiser à 0, mais on peut lire la valeur actuelle
    info "📝 Données feedback_par_ics existent déjà"
    CURRENT_ENGINE=$($CQLSH -e "USE domiramacatops_poc; SELECT count_engine FROM feedback_par_ics WHERE type_operation = '${TEST_TYPE_OPERATION}' AND sens_operation = '${TEST_SENS_OPERATION}' AND code_ics = '${TEST_CODE_ICS}' AND categorie = '${TEST_CATEGORIE}';" 2>&1 | grep -E "^[[:space:]]*[0-9]+" | tr -d ' ' | head -1 || echo "0")
    CURRENT_CLIENT=$($CQLSH -e "USE domiramacatops_poc; SELECT count_client FROM feedback_par_ics WHERE type_operation = '${TEST_TYPE_OPERATION}' AND sens_operation = '${TEST_SENS_OPERATION}' AND code_ics = '${TEST_CODE_ICS}' AND categorie = '${TEST_CATEGORIE}';" 2>&1 | grep -E "^[[:space:]]*[0-9]+" | tr -d ' ' | head -1 || echo "0")
    info "   Valeurs actuelles : count_engine = $CURRENT_ENGINE, count_client = $CURRENT_CLIENT"
    success "✅ Données feedback_par_ics existent (compteurs seront utilisés pour les tests)"
fi

echo ""
success "✅ Données de test préparées avec succès"
echo ""

