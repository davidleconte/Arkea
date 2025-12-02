#!/bin/bash
# ============================================
# Script 17 : Ajout de la colonne vectorielle e5-large
# Ajoute la colonne libelle_embedding_e5 pour multilingual-e5-large
# ============================================
#
# OBJECTIF :
#   Ce script ajoute une colonne vectorielle supplémentaire pour stocker
#   les embeddings du modèle 'intfloat/multilingual-e5-large' (1024 dimensions).
#
# PRÉREQUIS :
#   - HCD démarré
#   - Schéma de base créé (01_create_domiramaCatOps_schema.cql)
#
# UTILISATION :
#   ./17_add_e5_embedding_column.sh
#
# ============================================

set -euo pipefail

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
SCHEMA_DIR="${SCRIPT_DIR}/../schemas"
SCHEMA_FILE="${SCHEMA_DIR}/17_add_e5_embedding_column.cql"

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

echo ""
info "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
info "  🔧 Ajout de la Colonne Vectorielle e5-large"
info "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Vérifications
if [ ! -f "$CQLSH_BIN" ]; then
    error "cqlsh non trouvé : $CQLSH_BIN"
    exit 1
fi

if [ ! -f "$SCHEMA_FILE" ]; then
    error "Fichier schéma non trouvé : $SCHEMA_FILE"
    exit 1
fi

# Exécuter le schéma
info "📝 Exécution du schéma..."
echo "   Fichier : $(basename "$SCHEMA_FILE")"
echo ""

if "$CQLSH_BIN" "$HCD_HOST" "$HCD_PORT" -f "$SCHEMA_FILE" 2>&1; then
    success "✅ Colonne et index créés avec succès"
else
    error "❌ Erreur lors de la création"
    exit 1
fi

echo ""
info "📊 Vérification des index SAI..."
echo ""

# Compter les index
INDEX_COUNT=$("$CQLSH_BIN" "$HCD_HOST" "$HCD_PORT" -e "SELECT COUNT(*) as total FROM system_schema.indexes WHERE keyspace_name = 'domiramacatops_poc' AND table_name = 'operations_by_account' AND index_type = 'CUSTOM';" 2>/dev/null | grep -E "^[0-9]+" | head -1 | tr -d ' ' || echo "0")

if [ -n "$INDEX_COUNT" ] && [ "$INDEX_COUNT" -gt 0 ]; then
    info "   Total d'index SAI : $INDEX_COUNT/10"
    if [ "$INDEX_COUNT" -lt 10 ]; then
        success "   ✅ Limite non atteinte ($((10 - INDEX_COUNT)) index disponible(s))"
    else
        warn "   ⚠️  Limite atteinte (10/10 index)"
    fi
else
    warn "   ⚠️  Impossible de compter les index"
fi

echo ""
success "✅ Script terminé avec succès"
echo ""
