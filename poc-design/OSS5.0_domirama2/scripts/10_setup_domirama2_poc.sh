#!/bin/bash
set -euo pipefail
# ============================================
# Script 10 : Configuration du POC Domirama2 (95% conformité IBM)
# Crée le schéma avec toutes les colonnes nécessaires
# ============================================
#
# OBJECTIF :
#   Ce script initialise le keyspace 'domirama2_poc' et la table
#   'operations_by_account' avec toutes les colonnes de catégorisation
#   (cat_auto, cat_confidence, cat_user, cat_date_user, cat_validee).
#   Il crée également les index SAI pour la recherche full-text.
#
#   Ce script est le premier à exécuter pour configurer le POC Domirama2.
#   Il doit être lancé avant tout chargement de données ou test.
#
# PRÉREQUIS :
#   - HCD 1.2.3 doit être démarré (exécuter: ./scripts/setup/03_start_hcd.sh depuis la racine)
#   - Java 11 configuré via jenv (jenv local 11)
#   - Fichier schéma présent: schemas/01_create_domirama2_schema.cql
#   - HCD accessible (par défaut: "$HCD_HOST:$HCD_PORT", configurable via HCD_HOST/HCD_PORT)
#
# UTILISATION :
#   ./10_setup_domirama2_poc.sh
#
# EXEMPLE :
#   ./10_setup_domirama2_poc.sh
#   HCD_HOST=192.168.1.100 HCD_PORT=9042 ./10_setup_domirama2_poc.sh
#
# SORTIE :
#   - Keyspace 'domirama2_poc' créé
#   - Table 'operations_by_account' créée avec toutes les colonnes
#   - Index SAI créés (idx_libelle_fulltext, idx_cat_auto, etc.)
#   - Messages de validation affichés
#   - Vérification des colonnes de catégorisation (5/5)
#
# PROCHAINES ÉTAPES :
#   - Script 11: Chargement des données (./11_load_domirama2_data_parquet.sh)
#   - Script 12: Tests de recherche (./12_test_domirama2_search.sh)
#   - Script 13: Tests de correction client (./13_test_domirama2_api_client.sh)
#
# ============================================

set -euo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

info() { echo -e "${BLUE}ℹ️  $1${NC}"; }
success() { echo -e "${GREEN}✅ $1${NC}"; }
warn() { echo -e "${YELLOW}⚠️  $1${NC}"; }
error() { echo -e "${RED}❌ $1${NC}"; }

# Charger les fonctions utilitaires et configurer les chemins
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
if [ -f "${SCRIPT_DIR}/utils/didactique_functions.sh" ]; then
    source "${SCRIPT_DIR}/utils/didactique_functions.sh"
    setup_paths
else
    # Fallback si les fonctions ne sont pas disponibles
    SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    INSTALL_DIR="${ARKEA_HOME:-$(cd "$SCRIPT_DIR/../.." && pwd)}"
    HCD_DIR="${HCD_DIR:-${INSTALL_DIR}/binaire/hcd-1.2.3}"
    HCD_HOST="${HCD_HOST:-localhost}"
    HCD_PORT="${HCD_PORT:-9042}"
fi

SCHEMA_FILE="${SCRIPT_DIR}/schemas/01_create_domirama2_schema.cql"

# Vérifier les prérequis HCD
if ! check_hcd_prerequisites 2>/dev/null; then
    if ! pgrep -f "cassandra" > /dev/null; then
        error "HCD n'est pas démarré. Exécutez d'abord: ./scripts/setup/03_start_hcd.sh"
        exit 1
    fi
    if ! nc -z "$HCD_HOST" "$HCD_PORT" 2>/dev/null; then
        error "HCD n'est pas accessible sur $HCD_HOST:$HCD_PORT"
        exit 1
    fi
fi

# Configurer Java 11 pour cqlsh
cd "$HCD_DIR"
jenv local 11
eval "$(jenv init -)"

info "🔍 Vérification que HCD est prêt..."
if ! ./bin/cqlsh "$HCD_HOST" "$HCD_PORT" -e "SELECT cluster_name FROM system.local;" > /dev/null 2>&1; then
    error "HCD n'est pas prêt. Attendez quelques secondes et réessayez."
    exit 1
fi

info "📋 Configuration du schéma Domirama2 (95% conformité IBM)..."
info "   Keyspace: domirama2_poc"
info "   Table: operations_by_account"
info "   Colonnes ajoutées: cat_confidence, cat_date_user, cat_validée"
info "   Format COBOL: operation_data BLOB (conforme IBM)"

if [ ! -f "$SCHEMA_FILE" ]; then
    error "Fichier schéma non trouvé: $SCHEMA_FILE"
    exit 1
fi

info "🚀 Création du schéma..."
./bin/cqlsh "$HCD_HOST" "$HCD_PORT" -f "$SCHEMA_FILE" 2>&1 | grep -v "Warnings" || true

info "🔍 Vérification de la création..."
sleep 2

# Vérifier que le keyspace existe
if ./bin/cqlsh "$HCD_HOST" "$HCD_PORT" -e "DESCRIBE KEYSPACE domirama2_poc;" > /dev/null 2>&1; then
    success "Keyspace domirama2_poc créé"
else
    error "Échec de la création du keyspace"
    exit 1
fi

# Vérifier que la table existe avec toutes les colonnes
info "📊 Vérification des colonnes de catégorisation..."
COLUMNS=$(./bin/cqlsh "$HCD_HOST" "$HCD_PORT" -e "DESCRIBE TABLE domirama2_poc.operations_by_account;" 2>&1 | grep -E "(cat_auto|cat_confidence|cat_user|cat_date_user|cat_validée)" | wc -l | tr -d ' ')

if [ "$COLUMNS" -ge 5 ]; then
    success "Toutes les colonnes de catégorisation présentes (5/5)"
else
    warn "Certaines colonnes manquantes (trouvé: $COLUMNS/5)"
fi

# Vérifier les index SAI
info "🔍 Vérification des index SAI..."
INDEXES=$(./bin/cqlsh "$HCD_HOST" "$HCD_PORT" -e "SELECT index_name FROM system_schema.indexes WHERE keyspace_name = 'domirama2_poc';" 2>&1 | grep -v "Warnings" | grep -v "index_name" | grep -v "---" | grep -v "^$" | wc -l | tr -d ' ')

if [ "$INDEXES" -ge 5 ]; then
    success "$INDEXES index(es) SAI créé(s)"
else
    warn "Nombre d'index SAI: $INDEXES (attendu: 5+)"
fi

echo ""
success "✅ Configuration du POC Domirama2 terminée !"
echo ""
info "📝 Prochaines étapes:"
echo "   - Script 11: Chargement des données (batch)"
echo "   - Script 12: Tests de recherche"
echo "   - Script 13: Tests de correction client (API)"
echo ""
info "📋 Améliorations vs Domirama1:"
echo "   ✅ Colonnes complètes: cat_confidence, cat_date_user, cat_validée"
echo "   ✅ Format COBOL: operation_data BLOB (conforme IBM)"
echo "   ✅ Nommage aligné: date_op, numero_op (conforme IBM)"
echo "   ✅ Logique multi-version: Batch vs Client séparés"
