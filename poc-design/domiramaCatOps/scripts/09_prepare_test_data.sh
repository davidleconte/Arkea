#!/bin/bash
# ============================================
# Script : Préparation des données de test pour 09_test_acceptation_opposition.sh
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
info "🔧 Préparation des données de test pour acceptation_client et opposition_categorisation..."
echo ""

# Valeurs de test cohérentes
TEST_CODE_EFS="1"
TEST_NO_CONTRAT="100000043"
TEST_NO_PSE="PSE002"
TEST_NO_PSE_2="PSE001"

# 1. Insérer données acceptation_client (plusieurs cas de test)
info "📝 Insertion données acceptation_client..."

# Cas 1 : Acceptation true
$CQLSH -e "USE domiramacatops_poc; INSERT INTO acceptation_client (code_efs, no_contrat, no_pse, accepted, accepted_at, updated_at, updated_by) VALUES ('${TEST_CODE_EFS}', '${TEST_NO_CONTRAT}', '${TEST_NO_PSE}', true, toTimestamp(now()), toTimestamp(now()), 'TEST_SCRIPT');" 2>&1 | grep -vE "^Warnings|^$|^\([0-9]+ rows\)|coordinator|total|Executing|Read|Scanned|Merging|Tracing|Activity|Requests|responses|Parsing|Sending" || true
success "✅ Acceptation true insérée (code_efs=${TEST_CODE_EFS}, contrat=${TEST_NO_CONTRAT}, pse=${TEST_NO_PSE})"

# Cas 2 : Acceptation false (pour tester le refus)
$CQLSH -e "USE domiramacatops_poc; INSERT INTO acceptation_client (code_efs, no_contrat, no_pse, accepted, accepted_at, updated_at, updated_by) VALUES ('${TEST_CODE_EFS}', '${TEST_NO_CONTRAT}', '${TEST_NO_PSE_2}', false, toTimestamp(now()), toTimestamp(now()), 'TEST_SCRIPT');" 2>&1 | grep -vE "^Warnings|^$|^\([0-9]+ rows\)|coordinator|total|Executing|Read|Scanned|Merging|Tracing|Activity|Requests|responses|Parsing|Sending" || true
success "✅ Acceptation false insérée (code_efs=${TEST_CODE_EFS}, contrat=${TEST_NO_CONTRAT}, pse=${TEST_NO_PSE_2})"

echo ""

# 2. Vérifier/Créer données opposition_categorisation
info "📝 Vérification données opposition_categorisation..."

# Vérifier si PSE001 existe déjà
CHECK_OPPOSITION=$($CQLSH -e "USE domiramacatops_poc; SELECT COUNT(*) FROM opposition_categorisation WHERE code_efs = '${TEST_CODE_EFS}' AND no_pse = '${TEST_NO_PSE_2}';" 2>&1 | grep -E "^\s+[0-9]+" | tr -d ' ' || echo "0")

if [ "$CHECK_OPPOSITION" = "0" ] || [ -z "$CHECK_OPPOSITION" ]; then
    $CQLSH -e "USE domiramacatops_poc; INSERT INTO opposition_categorisation (code_efs, no_pse, opposed, opposed_at, updated_at, updated_by) VALUES ('${TEST_CODE_EFS}', '${TEST_NO_PSE_2}', false, toTimestamp(now()), toTimestamp(now()), 'TEST_SCRIPT');" 2>&1 | grep -vE "^Warnings|^$|^\([0-9]+ rows\)|coordinator|total|Executing|Read|Scanned|Merging|Tracing|Activity|Requests|responses|Parsing|Sending" || true
    success "✅ Opposition false insérée (code_efs=${TEST_CODE_EFS}, pse=${TEST_NO_PSE_2})"
else
    success "✅ Opposition existe déjà (code_efs=${TEST_CODE_EFS}, pse=${TEST_NO_PSE_2})"
fi

echo ""
success "✅ Données de test préparées avec succès"
echo ""
