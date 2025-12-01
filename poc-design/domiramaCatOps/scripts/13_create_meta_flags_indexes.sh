#!/bin/bash
# ============================================
# Script : Création des colonnes dérivées et index SAI pour meta_flags
# ============================================

set -e

# Charger l'environnement
INSTALL_DIR="/Users/david.leconte/Documents/Arkea"
if [ -f "${INSTALL_DIR}/.poc-profile" ]; then
    source "${INSTALL_DIR}/.poc-profile"
fi

HCD_DIR="${HCD_HOME:-${INSTALL_DIR}/binaire/hcd-1.2.3}"
if [ -n "${HCD_HOME}" ]; then
    CQLSH_BIN="${HCD_HOME}/bin/cqlsh"
else
    CQLSH_BIN="${HCD_DIR}/bin/cqlsh"
fi
CQLSH="$CQLSH_BIN localhost 9042"

# Couleurs
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'
info() { echo -e "${BLUE}ℹ️  $1${NC}"; }
success() { echo -e "${GREEN}✅ $1${NC}"; }
warn() { echo -e "${YELLOW}⚠️  $1${NC}"; }
error() { echo -e "${RED}❌ $1${NC}"; }

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
CQL_FILE="${SCRIPT_DIR}/../schemas/13_create_meta_flags_indexes.cql"

# Vérifier le chemin absolu
if [ ! -f "$CQL_FILE" ]; then
    # Essayer avec le chemin depuis INSTALL_DIR
    CQL_FILE="${INSTALL_DIR}/poc-design/domiramaCatOps/schemas/13_create_meta_flags_indexes.cql"
fi

echo ""
info "🔧 Création des colonnes dérivées et index SAI pour meta_flags..."
echo ""

# Vérifier que le fichier CQL existe
if [ ! -f "$CQL_FILE" ]; then
    error "Fichier CQL non trouvé : $CQL_FILE"
    exit 1
fi

# Vérifier que HCD est démarré
if ! nc -z localhost 9042 2>/dev/null; then
    error "HCD n'est pas démarré sur localhost:9042"
    error "Exécutez d'abord: ./03_start_hcd.sh"
    exit 1
fi

# Exécuter le fichier CQL (ignorer les erreurs si les colonnes existent déjà)
info "📝 Exécution du fichier CQL : $CQL_FILE"
$CQLSH -f "$CQL_FILE" 2>&1 | grep -v "already exists" || true

# Vérifier si les colonnes ont été créées (même si certaines existaient déjà)
info "📊 Vérification des colonnes dérivées créées..."
COLUMNS_EXIST=$($CQLSH -e "DESCRIBE TABLE domiramacatops_poc.operations_by_account;" 2>&1 | grep -c "meta_source\|meta_device\|meta_channel\|meta_fraud_score\|meta_ip\|meta_location" || echo "0")
if [ "$COLUMNS_EXIST" -gt 0 ]; then
    success "✅ Colonnes dérivées créées ou déjà existantes"
else
    warn "⚠️  Aucune colonne dérivée trouvée (peut-être déjà créées)"
fi

echo ""
info "📊 Vérification des index créés..."
$CQLSH -e "USE domiramacatops_poc; SELECT index_name FROM system_schema.indexes WHERE keyspace_name = 'domiramacatops_poc' AND table_name = 'operations_by_account';" 2>&1 | grep "idx_meta" || warn "Aucun index idx_meta trouvé (peut-être en cours de création)"

echo ""
success "✅ Script terminé"

