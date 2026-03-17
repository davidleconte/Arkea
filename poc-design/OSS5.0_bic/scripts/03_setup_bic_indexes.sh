#!/bin/bash
set -euo pipefail

# =============================================================================
# Script : Setup BIC Indexes
# =============================================================================
# Date : 2025-12-01
# Description : Crée les index SAI pour le POC BIC
# Usage : ./scripts/03_setup_bic_indexes.sh
# Prérequis : Tables créées (./scripts/02_setup_bic_tables.sh)
# =============================================================================

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BIC_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
if [ -f "${BIC_DIR}/utils/didactique_functions.sh" ]; then
    source "${BIC_DIR}/utils/didactique_functions.sh"
    setup_paths
else
    export HCD_HOST="${HCD_HOST:-localhost}"
    export HCD_PORT="${HCD_PORT:-9042}"
fi

# Variables
KEYSPACE="bic_poc"
SCHEMA_FILE="${BIC_DIR}/schemas/03_create_bic_indexes.cql"

# Configuration cqlsh - OSS5.0 Podman mode
if [ "$HCD_DIR" = "podman" ] || [ -z "$HCD_DIR" ]; then
    if podman ps --filter "name=arkea-hcd" --format "{{.Names}}" 2>/dev/null | grep -q "arkea-hcd"; then
        CQLSH="podman exec arkea-hcd cqlsh localhost 9042"
        PODMAN_MODE=true
    else
        echo "ERROR: Container arkea-hcd not running. Run 'make demo' first."
        exit 1
    fi
else
    CQLSH_BIN="${HCD_DIR}/bin/cqlsh"
    CQLSH="$CQLSH_BIN $HCD_HOST $HCD_PORT"
    PODMAN_MODE=false
fi

# Couleurs
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "🔧 Setup BIC Indexes (SAI)"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Vérifier que cqlsh est disponible
if [ "$PODMAN_MODE" = "true" ]; then
    echo -e "${GREEN}✅ Mode Podman: arkea-hcd détecté${NC}"
elif [ ! -f "$CQLSH_BIN" ]; then
    echo -e "${RED}❌ Erreur: cqlsh non trouvé dans $CQLSH_BIN${NC}"
    exit 1
fi

# Vérifier que HCD est démarré
if ! $CQLSH -e "DESCRIBE KEYSPACES;" &>/dev/null; then
    echo -e "${RED}❌ Erreur: HCD n'est pas démarré${NC}"
    exit 1
fi

# Vérifier que le keyspace existe
if ! $CQLSH -e "DESCRIBE KEYSPACE $KEYSPACE;" &>/dev/null; then
    echo -e "${RED}❌ Erreur: Le keyspace $KEYSPACE n'existe pas${NC}"
    echo "   Exécutez d'abord: ./scripts/01_setup_bic_keyspace.sh"
    exit 1
fi

echo -e "${GREEN}✅ Keyspace $KEYSPACE existe${NC}"
echo ""

# Créer les index
echo "Création des index SAI..."
if [ -f "$SCHEMA_FILE" ]; then
    if [ "$PODMAN_MODE" = "true" ]; then
        podman cp "$SCHEMA_FILE" arkea-hcd:/tmp/$(basename "$SCHEMA_FILE")
        podman exec arkea-hcd cqlsh localhost 9042 -f /tmp/$(basename "$SCHEMA_FILE")
    else
        $CQLSH -f "$SCHEMA_FILE"
    fi
    echo -e "${GREEN}✅ Index créés${NC}"
else
    echo -e "${RED}❌ Erreur: Fichier de schéma non trouvé: $SCHEMA_FILE${NC}"
    exit 1
fi

# Vérification
echo ""
echo "Vérification..."
INDEXES=$($CQLSH -e "SELECT index_name FROM system_schema.indexes WHERE keyspace_name = '$KEYSPACE';" 2>/dev/null | grep -c "idx_" || echo "0")
if [ "$INDEXES" -gt 0 ]; then
    echo -e "${GREEN}✅ $INDEXES index(es) créé(s)${NC}"
    echo ""
    echo "Index créés :"
    $CQLSH -e "SELECT index_name FROM system_schema.indexes WHERE keyspace_name = '$KEYSPACE';" 2>/dev/null | grep "idx_" | sed 's/^[[:space:]]*//' | while read index; do
        echo "  - $index"
    done
else
    echo -e "${YELLOW}⚠️  Aucun index trouvé (peut prendre quelques secondes pour être visible)${NC}"
fi

echo ""
echo -e "${GREEN}✅ Setup terminé avec succès${NC}"
