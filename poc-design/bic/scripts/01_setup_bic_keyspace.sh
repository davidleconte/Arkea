#!/bin/bash
set -euo pipefail

# =============================================================================
# Script : Setup BIC Keyspace
# =============================================================================
# Date : 2025-12-01
# Description : Crée le keyspace bic_poc pour le POC BIC
# Usage : ./scripts/01_setup_bic_keyspace.sh
# Prérequis : HCD démarré (./scripts/setup/03_start_hcd.sh)
# =============================================================================

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BIC_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
if [ -f "${BIC_DIR}/utils/didactique_functions.sh" ]; then
    source "${BIC_DIR}/utils/didactique_functions.sh"
    setup_paths
else
    # Fallback si les fonctions ne sont pas disponibles
    export HCD_HOST="${HCD_HOST:-localhost}"
    export HCD_PORT="${HCD_PORT:-9042}"
fi

# Variables
KEYSPACE="bic_poc"
SCHEMA_FILE="${BIC_DIR}/schemas/01_create_bic_keyspace.cql"

# Configuration cqlsh
CQLSH_BIN="${HCD_DIR}/bin/cqlsh"
CQLSH="$CQLSH_BIN $HCD_HOST $HCD_PORT"

# Couleurs
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "🔧 Setup BIC Keyspace"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Vérifier que cqlsh est disponible
if [ ! -f "$CQLSH_BIN" ]; then
    echo -e "${RED}❌ Erreur: cqlsh non trouvé dans $CQLSH_BIN${NC}"
    echo "   Vérifiez que HCD_DIR est correctement configuré"
    exit 1
fi

# Vérifier que HCD est démarré
if ! $CQLSH -e "DESCRIBE KEYSPACES;" &>/dev/null; then
    echo -e "${RED}❌ Erreur: HCD n'est pas démarré ou n'est pas accessible${NC}"
    echo "   HCD_HOST: $HCD_HOST"
    echo "   HCD_PORT: $HCD_PORT"
    echo "   Exécutez d'abord: ${ARKEA_HOME:-$BIC_DIR/../../..}/scripts/setup/03_start_hcd.sh background"
    exit 1
fi

echo -e "${GREEN}✅ HCD est accessible${NC}"
echo ""

# Vérifier si le keyspace existe déjà
if $CQLSH -e "DESCRIBE KEYSPACE $KEYSPACE;" &>/dev/null; then
    echo -e "${YELLOW}⚠️  Le keyspace $KEYSPACE existe déjà${NC}"
    read -p "Voulez-vous le supprimer et le recréer ? (o/N) " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Oo]$ ]]; then
        echo "Suppression du keyspace existant..."
        $CQLSH -e "DROP KEYSPACE IF EXISTS $KEYSPACE;"
        echo -e "${GREEN}✅ Keyspace supprimé${NC}"
    else
        echo "Conservation du keyspace existant"
        exit 0
    fi
fi

# Créer le keyspace
echo "Création du keyspace $KEYSPACE..."
if [ -f "$SCHEMA_FILE" ]; then
    $CQLSH -f "$SCHEMA_FILE"
    echo -e "${GREEN}✅ Keyspace $KEYSPACE créé${NC}"
else
    echo -e "${RED}❌ Erreur: Fichier de schéma non trouvé: $SCHEMA_FILE${NC}"
    exit 1
fi

# Vérification
echo ""
echo "Vérification..."
if $CQLSH -e "DESCRIBE KEYSPACE $KEYSPACE;" &>/dev/null; then
    echo -e "${GREEN}✅ Keyspace $KEYSPACE créé avec succès${NC}"
    echo ""
    echo "Keyspace créé :"
    $CQLSH -e "DESCRIBE KEYSPACE $KEYSPACE;" | head -10
else
    echo -e "${RED}❌ Erreur: Le keyspace n'a pas été créé${NC}"
    exit 1
fi

echo ""
echo -e "${GREEN}✅ Setup terminé avec succès${NC}"
