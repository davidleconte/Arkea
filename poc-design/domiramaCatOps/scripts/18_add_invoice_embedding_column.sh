#!/bin/bash
# ============================================
# Script 18 : Ajout Colonne Embedding Facturation
# Ajoute la colonne et l'index pour le modèle spécialisé facturation
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
info "  📝 Ajout Colonne Embedding Facturation"
info "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Vérifications
if [ ! -d "$HCD_DIR" ]; then
    error "HCD_DIR non trouvé: $HCD_DIR"
    exit 1
fi

CQLSH_BIN="${HCD_DIR}/bin/cqlsh"

if [ ! -f "$CQLSH_BIN" ]; then
    error "cqlsh non trouvé: $CQLSH_BIN"
    exit 1
fi

# Exécuter le schéma
info "📝 Exécution du schéma..."
echo "   Fichier : 18_add_invoice_embedding_column.cql"
if "$CQLSH_BIN" "$HCD_HOST" "$HCD_PORT" -f "${SCRIPT_DIR}/../schemas/18_add_invoice_embedding_column.cql"; then
    success "✅ Schéma exécuté avec succès"
else
    error "❌ Erreur lors de la création"
    exit 1
fi

# Vérifier les index SAI
info "🔍 Vérification des index SAI..."
INDEX_COUNT=$("$CQLSH_BIN" "$HCD_HOST" "$HCD_PORT" -e "SELECT count(*) FROM system_schema.indexes WHERE keyspace_name = 'domiramacatops_poc' AND table_name = 'operations_by_account' AND kind = 'CUSTOM' ALLOW FILTERING;" 2>&1 | grep -E '^[[:space:]]*[0-9]+$' | tr -d '[:space:]')
info "   Nombre d'index SAI : $INDEX_COUNT"

if [ "$INDEX_COUNT" -le 10 ]; then
    success "✅ Nombre d'index SAI ($INDEX_COUNT) est dans la limite (<= 10)"
else
    warn "⚠️  Nombre d'index SAI ($INDEX_COUNT) dépasse la limite (10)"
fi

# Vérifier la colonne
info "🔍 Vérification de la colonne..."
if "$CQLSH_BIN" "$HCD_HOST" "$HCD_PORT" -e "DESCRIBE TABLE domiramacatops_poc.operations_by_account;" 2>&1 | grep -q "libelle_embedding_invoice"; then
    success "✅ Colonne libelle_embedding_invoice créée"
else
    warn "⚠️  Colonne libelle_embedding_invoice non trouvée"
fi

echo ""
success "✅ Script terminé avec succès"
echo ""
