#!/bin/bash
# ============================================
# Script 25 : Test de la Recherche Hybride
# Démonstration de la combinaison Full-Text + Vector Search
# ============================================
#
# OBJECTIF :
#   Ce script démontre la recherche hybride qui combine deux approches
#   complémentaires pour améliorer la pertinence des résultats :
#   1. Full-Text Search (SAI) : Filtre initial pour la précision
#   2. Vector Search (ByteT5) : Tri par similarité pour tolérer les typos
#   
#   La recherche hybride offre une meilleure pertinence que chaque
#   approche seule, en combinant précision et tolérance aux erreurs.
#   Elle inclut un fallback automatique si Full-Text ne trouve rien.
#
# PRÉREQUIS :
#   - HCD démarré (./03_start_hcd.sh)
#   - Schéma configuré (./10_setup_domirama2_poc.sh)
#   - Données chargées (./11_load_domirama2_data_parquet.sh)
#   - Fuzzy search configuré (./21_setup_fuzzy_search.sh)
#   - Embeddings générés (./22_generate_embeddings.sh)
#   - Python 3.8+ avec transformers et torch installés
#   - Clé API Hugging Face configurée (HF_API_KEY dans .poc-profile)
#
# UTILISATION :
#   ./25_test_hybrid_search.sh
#
# EXEMPLE :
#   ./25_test_hybrid_search.sh
#
# SORTIE :
#   - Résultats de recherche pour plusieurs requêtes de test
#   - Comparaison Full-Text vs Vector vs Hybride
#   - Démonstration de la tolérance aux typos
#   - Messages de succès/erreur
#
# PROCHAINES ÉTAPES :
#   - Consulter la documentation: doc/08_README_HYBRID_SEARCH.md
#   - Tester d'autres requêtes en modifiant examples/python/search/hybrid_search.py
#
# ============================================

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

info() { echo -e "${BLUE}ℹ️  $1${NC}"; }
success() { echo -e "${GREEN}✅ $1${NC}"; }
warn() { echo -e "${YELLOW}⚠️  $1${NC}"; }
error() { echo -e "${RED}❌ $1${NC}"; }
demo() { echo -e "${CYAN}🎯 $1${NC}"; }

INSTALL_DIR="/Users/david.leconte/Documents/Arkea"
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"

# Vérifier que HCD est démarré
if ! pgrep -f "cassandra" > /dev/null; then
    error "HCD n'est pas démarré. Exécutez d'abord: ./03_start_hcd.sh"
    exit 1
fi

cd "$INSTALL_DIR"
source .poc-profile 2>/dev/null || true

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  🔍 DÉMONSTRATION : Recherche Hybride (Full-Text + Vector)"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
info "📚 DÉFINITION - Recherche Hybride :"
echo "   Combinaison de deux approches complémentaires :"
echo "   1. Full-Text Search (SAI) : Filtre initial pour la précision"
echo "   2. Vector Search (ByteT5) : Tri par similarité pour tolérer les typos"
echo ""
info "💡 Avantages :"
echo "   ✅ Précision du Full-Text (filtre les résultats pertinents)"
echo "   ✅ Tolérance aux typos du Vector Search (tri par similarité)"
echo "   ✅ Fallback automatique si Full-Text ne trouve rien"
echo "   ✅ Meilleure pertinence que chaque approche seule"
echo ""

python3 "$SCRIPT_DIR/examples/python/search/hybrid_search.py" 2>&1

echo ""
success "✅ Démonstration terminée !"
info "📝 Script disponible: examples/python/search/hybrid_search.py"

