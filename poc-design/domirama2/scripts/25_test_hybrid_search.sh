#!/bin/bash
set -euo pipefail
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
#   - HCD démarré (./scripts/setup/03_start_hcd.sh)
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

set -euo pipefail

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
    SPARK_HOME="${SPARK_HOME:-${INSTALL_DIR}/binaire/spark-3.5.1}"
    HCD_HOST="${HCD_HOST:-localhost}"
    HCD_PORT="${HCD_PORT:-9042}"
fi
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"

# Vérifier que HCD est démarré
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
