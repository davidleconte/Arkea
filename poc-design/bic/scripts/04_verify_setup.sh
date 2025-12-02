#!/bin/bash
set -euo pipefail

# =============================================================================
# Script : Vérification du Setup BIC
# =============================================================================
# Date : 2025-12-01
# Description : Vérifie que le setup BIC est complet et fonctionnel
# Usage : ./scripts/04_verify_setup.sh
# Prérequis : Setup complet (01, 02, 03)
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

# Configuration cqlsh
CQLSH_BIN="${HCD_DIR}/bin/cqlsh"
CQLSH="$CQLSH_BIN $HCD_HOST $HCD_PORT"

# Couleurs
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "🔍 Vérification du Setup BIC"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

ERRORS=0

# 1. Vérifier HCD
echo "1. Vérification de HCD..."
if $CQLSH -e "DESCRIBE KEYSPACES;" &>/dev/null; then
    echo -e "${GREEN}   ✅ HCD est accessible${NC}"
else
    echo -e "${RED}   ❌ HCD n'est pas accessible${NC}"
    ERRORS=$((ERRORS + 1))
fi

# 2. Vérifier le keyspace
echo ""
echo "2. Vérification du keyspace $KEYSPACE..."
if $CQLSH -e "DESCRIBE KEYSPACE $KEYSPACE;" &>/dev/null; then
    echo -e "${GREEN}   ✅ Keyspace $KEYSPACE existe${NC}"
    
    # Afficher les détails
    REPLICATION=$($CQLSH -e "DESCRIBE KEYSPACE $KEYSPACE;" 2>/dev/null | grep "replication_factor" | head -1)
    echo "      $REPLICATION"
else
    echo -e "${RED}   ❌ Keyspace $KEYSPACE n'existe pas${NC}"
    ERRORS=$((ERRORS + 1))
fi

# 3. Vérifier les tables
echo ""
echo "3. Vérification des tables..."
TABLES=$($CQLSH -e "USE $KEYSPACE; DESCRIBE TABLES;" 2>/dev/null | grep -v "^$" | grep -v "^-" | grep -v "keyspace" | wc -l | tr -d ' ')
if [ "$TABLES" -gt 0 ]; then
    echo -e "${GREEN}   ✅ $TABLES table(s) trouvée(s)${NC}"
    $CQLSH -e "USE $KEYSPACE; DESCRIBE TABLES;" 2>/dev/null | grep -v "^$" | grep -v "^-" | grep -v "keyspace" | while read table; do
        echo "      - $table"
    done
else
    echo -e "${RED}   ❌ Aucune table trouvée${NC}"
    ERRORS=$((ERRORS + 1))
fi

# 4. Vérifier les index
echo ""
echo "4. Vérification des index SAI..."
INDEXES=$($CQLSH -e "SELECT index_name FROM system_schema.indexes WHERE keyspace_name = '$KEYSPACE';" 2>/dev/null | grep -c "idx_" || echo "0")
if [ "$INDEXES" -gt 0 ] && [ "$INDEXES" != "0" ]; then
    echo -e "${GREEN}   ✅ $INDEXES index(es) trouvé(s)${NC}"
    $CQLSH -e "SELECT index_name FROM system_schema.indexes WHERE keyspace_name = '$KEYSPACE';" 2>/dev/null | grep "idx_" | sed 's/^[[:space:]]*//' | while read index; do
        echo "      - $index"
    done
else
    echo -e "${YELLOW}   ⚠️  Aucun index trouvé${NC}"
fi

# 5. Test de connexion
echo ""
echo "5. Test de connexion..."
if $CQLSH -e "USE $KEYSPACE; SELECT COUNT(*) FROM interactions_by_client LIMIT 1;" &>/dev/null; then
    echo -e "${GREEN}   ✅ Connexion et requête test réussis${NC}"
else
    echo -e "${YELLOW}   ⚠️  Requête test échouée (table peut être vide)${NC}"
fi

# Résumé
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
if [ $ERRORS -eq 0 ]; then
    echo -e "${GREEN}✅ Vérification terminée - Tout est OK${NC}"
    exit 0
else
    echo -e "${RED}❌ Vérification terminée - $ERRORS erreur(s) détectée(s)${NC}"
    exit 1
fi

