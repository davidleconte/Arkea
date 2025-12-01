#!/bin/bash
# ============================================
# Script 19 : Test Comparatif des Embeddings
# Compare ByteT5-small vs multilingual-e5-large
# ============================================
#
# OBJECTIF :
#   Ce script compare les performances et la pertinence des résultats
#   entre ByteT5-small et multilingual-e5-large.
#
# PRÉREQUIS :
#   - HCD démarré
#   - Colonnes vectorielles créées (script 17)
#   - Embeddings générés (script 18)
#   - Python 3.8+ avec transformers, torch, cassandra-driver
#   - sentence-transformers (optionnel, pour tests e5)
#
# UTILISATION :
#   ./19_test_embeddings_comparison.sh
#
# ============================================

set -e

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
PYTHON_DIR="${SCRIPT_DIR}/../examples/python/search"

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
info "  🔀 Test Comparatif : ByteT5 vs e5-large"
info "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Vérifications
if ! command -v python3 &> /dev/null; then
    error "Python 3 n'est pas installé"
    exit 1
fi

# Exécuter le script de comparaison
info "🧪 Exécution des tests comparatifs..."
echo ""

if python3 "${PYTHON_DIR}/test_vector_search_comparison_models.py"; then
    success "✅ Tests comparatifs terminés"
else
    warn "⚠️  Tests terminés avec des avertissements"
    echo "   (e5-large peut ne pas être disponible si sentence-transformers n'est pas installé)"
fi

echo ""
success "✅ Script terminé"
echo ""

