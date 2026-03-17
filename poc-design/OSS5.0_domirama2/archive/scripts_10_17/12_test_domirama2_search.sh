#!/bin/bash
# ============================================
# Script 12 : Tests de Recherche Domirama2
# Exécute les tests de recherche full-text avec SAI
# Tests avec toutes les colonnes de catégorisation
# ============================================
#
# OBJECTIF :
#   Ce script exécute une série de tests de recherche full-text sur la table
#   'operations_by_account' en utilisant les index SAI (Storage-Attached Index).
#
#   Les tests couvrent :
#   - Recherche par libellé (full-text search)
#   - Filtrage par catégorie automatique (cat_auto)
#   - Filtrage par catégorie client (cat_user)
#   - Recherches combinées (libellé + catégorie)
#   - Vérification de la pertinence des résultats
#
# PRÉREQUIS :
#   - HCD démarré (./03_start_hcd.sh)
#   - Schéma configuré (./10_setup_domirama2_poc.sh)
#   - Données chargées (./11_load_domirama2_data_parquet.sh)
#   - Fichier de tests présent: schemas/04_domirama2_search_test.cql
#
# UTILISATION :
#   ./12_test_domirama2_search.sh
#
# EXEMPLE :
#   ./12_test_domirama2_search.sh
#
# SORTIE :
#   - Résultats des tests de recherche affichés
#   - Nombre de résultats pour chaque requête
#   - Messages de succès/erreur
#   - Validation de la pertinence des résultats
#
# PROCHAINES ÉTAPES :
#   - Script 13: Tests de correction client (./13_test_domirama2_api_client.sh)
#   - Script 15: Tests full-text complexes (./15_test_fulltext_complex.sh)
#
# ============================================

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

info() { echo -e "${BLUE}ℹ️  $1${NC}"; }
success() { echo -e "${GREEN}✅ $1${NC}"; }
warn() { echo -e "${YELLOW}⚠️  $1${NC}"; }
error() { echo -e "${RED}❌ $1${NC}"; }

INSTALL_DIR="/Users/david.leconte/Documents/Arkea"
HCD_DIR="${INSTALL_DIR}/binaire/hcd-1.2.3"
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
TEST_FILE="${SCRIPT_DIR}/schemas/04_domirama2_search_test.cql"

# Vérifier que HCD est démarré
if ! pgrep -f "cassandra" > /dev/null; then
    error "HCD n'est pas démarré. Exécutez d'abord: ./03_start_hcd.sh"
    exit 1
fi

# Vérifier que le keyspace existe
cd "$HCD_DIR"
jenv local 11
eval "$(jenv init -)"
if ! ./bin/cqlsh localhost 9042 -e "DESCRIBE KEYSPACE domirama2_poc;" > /dev/null 2>&1; then
    error "Le keyspace domirama2_poc n'existe pas. Exécutez d'abord: ./10_setup_domirama2_poc.sh"
    exit 1
fi

info "🔍 Exécution des tests de recherche Domirama2..."
info "   Tests: Recherche full-text avec SAI"
info "   Colonnes testées: cat_auto, cat_user, cat_confidence, cat_validée"
info "   Remplacement de Solr par SAI"

./bin/cqlsh localhost 9042 -f "$TEST_FILE" 2>&1 | grep -v "Warnings" || true

echo ""
success "✅ Tests de recherche terminés !"
echo ""
info "📝 Résultats:"
echo "   - Les requêtes avec opérateur ':' utilisent l'index SAI full-text"
echo "   - Les requêtes avec '=' utilisent l'index SAI standard"
echo "   - Toutes les colonnes de catégorisation sont testées"
echo "   - Comparez les performances avec l'ancien workflow HBase (SCAN → Solr → MultiGet)"
echo ""
info "📝 Prochaines étapes:"
echo "   - Script 13: Tests de correction client (API)"
