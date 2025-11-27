#!/bin/bash
# ============================================
# Script 09 : Tests de recherche Domirama
# Teste la recherche full-text avec SAI
# ============================================

set -e

# Couleurs pour les messages
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

info() {
    echo -e "${BLUE}ℹ️  $1${NC}"
}

success() {
    echo -e "${GREEN}✅ $1${NC}"
}

warn() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

error() {
    echo -e "${RED}❌ $1${NC}"
}

# Variables
INSTALL_DIR="/Users/david.leconte/Documents/Arkea"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
HCD_DIR="${INSTALL_DIR}/binaire/hcd-1.2.3"
TEST_FILE="${SCRIPT_DIR}/domirama_search_test.cql"

# Vérifier que HCD est démarré
if ! pgrep -f "cassandra" > /dev/null; then
    error "HCD n'est pas démarré. Exécutez d'abord: ./03_start_hcd.sh"
    exit 1
fi

# Vérifier que le fichier de test existe
if [ ! -f "$TEST_FILE" ]; then
    error "Fichier de test non trouvé: $TEST_FILE"
    exit 1
fi

cd "$HCD_DIR"
jenv local 11
eval "$(jenv init -)"

info "🔍 Exécution des tests de recherche Domirama..."
info "   Tests: Recherche full-text avec SAI"
info "   Remplacement de Solr par SAI"

# Vérifier que le schéma existe
if ! ./bin/cqlsh localhost 9042 -e "DESCRIBE KEYSPACE domirama_poc" 2>&1 | grep -q "domirama_poc"; then
    error "Le keyspace domirama_poc n'existe pas. Exécutez d'abord: ./07_setup_domirama_poc.sh"
    exit 1
fi

# Vérifier que des données existent
COUNT=$(./bin/cqlsh localhost 9042 -e "USE domirama_poc; SELECT COUNT(*) FROM operations_by_account;" 2>&1 | grep -v "Warnings" | tail -1 | tr -d ' ')
if [ -z "$COUNT" ] || [ "$COUNT" -eq 0 ]; then
    warn "Aucune donnée trouvée. Chargez d'abord les données avec: ./08_load_domirama_data.sh"
    echo ""
    info "Exécution des tests quand même (certains peuvent échouer)..."
fi

echo ""
info "📋 Exécution des tests de recherche..."
echo ""

# Exécuter les tests
./bin/cqlsh localhost 9042 -f "$TEST_FILE" 2>&1 | grep -v "Warnings" | grep -v "Using" || true

echo ""
success "✅ Tests de recherche terminés !"
echo ""
info "📝 Résultats:"
echo "   - Les requêtes avec opérateur ':' utilisent l'index SAI full-text"
echo "   - Les requêtes avec '=' utilisent l'index SAI standard"
echo "   - Comparez les performances avec l'ancien workflow HBase (SCAN → Solr → MultiGet)"




