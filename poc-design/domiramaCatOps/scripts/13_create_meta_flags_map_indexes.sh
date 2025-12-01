#!/bin/bash
# ============================================
# Script : Création des index SAI sur KEYS et VALUES de meta_flags
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
# Chemin relatif depuis scripts/ vers schemas/
CQL_FILE="${SCRIPT_DIR}/../schemas/13_create_meta_flags_map_indexes.cql"
# Vérifier si le fichier existe, sinon utiliser le chemin absolu
if [ ! -f "$CQL_FILE" ]; then
    INSTALL_DIR="/Users/david.leconte/Documents/Arkea"
    CQL_FILE="${INSTALL_DIR}/poc-design/domiramaCatOps/schemas/13_create_meta_flags_map_indexes.cql"
fi

echo ""
info "🔧 Création des index SAI sur KEYS et VALUES de meta_flags..."
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

# Vérifier le nombre d'index existants
info "📊 Vérification du nombre d'index existants..."
CURRENT_INDEX_COUNT=$($CQLSH -e "USE domiramacatops_poc; SELECT COUNT(*) FROM system_schema.indexes WHERE keyspace_name = 'domiramacatops_poc' AND table_name = 'operations_by_account';" 2>&1 | grep -E "\([0-9]+ rows\)" | grep -oE "[0-9]+" | head -1 || echo "0")

info "   Index SAI actuels : $CURRENT_INDEX_COUNT/10"
if [ "$CURRENT_INDEX_COUNT" -ge 10 ]; then
    error "❌ Limite de 10 index SAI atteinte. Impossible de créer de nouveaux index."
    exit 1
elif [ "$CURRENT_INDEX_COUNT" -ge 9 ]; then
    warn "⚠️  Limite proche (9/10). Seulement 1 index peut être créé."
else
    info "✅ Place disponible : $((10 - CURRENT_INDEX_COUNT)) index"
fi

# Exécuter le fichier CQL
info "📝 Exécution du fichier CQL : $CQL_FILE"
$CQLSH -f "$CQL_FILE"

if [ $? -eq 0 ]; then
    success "✅ Index SAI créés avec succès"
else
    error "❌ Erreur lors de la création des index SAI"
    exit 1
fi

echo ""
info "📊 Vérification des index créés..."
$CQLSH -e "USE domiramacatops_poc; SELECT index_name FROM system_schema.indexes WHERE keyspace_name = 'domiramacatops_poc' AND table_name = 'operations_by_account' AND index_name IN ('idx_meta_flags_keys', 'idx_meta_flags_values');"

echo ""
success "✅ Script terminé"

