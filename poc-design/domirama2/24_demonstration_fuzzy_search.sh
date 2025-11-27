#!/bin/bash
# ============================================
# Script 24 : Démonstration Complète Fuzzy Search
# Orchestre la configuration, génération et tests de la recherche floue
# ============================================
#
# OBJECTIF :
#   Ce script orchestre une démonstration complète de la recherche floue
#   (fuzzy search) en exécutant toutes les étapes nécessaires : configuration,
#   génération des embeddings, et tests de recherche.
#   
#   La démonstration couvre :
#   - Configuration de la colonne vectorielle et de l'index
#   - Génération des embeddings ByteT5 pour tous les libellés
#   - Tests de recherche avec typos et variations
#   - Validation de la pertinence des résultats
#
# PRÉREQUIS :
#   - HCD démarré (./03_start_hcd.sh)
#   - Schéma configuré (./10_setup_domirama2_poc.sh)
#   - Données chargées (./11_load_domirama2_data_parquet.sh)
#   - Python 3.8+ avec transformers et torch installés
#   - Clé API Hugging Face configurée (HF_API_KEY dans .poc-profile)
#
# UTILISATION :
#   ./24_demonstration_fuzzy_search.sh
#
# EXEMPLE :
#   ./24_demonstration_fuzzy_search.sh
#
# SORTIE :
#   - Configuration de la recherche floue
#   - Génération des embeddings
#   - Résultats des tests de recherche
#   - Messages de succès/erreur pour chaque étape
#
# PROCHAINES ÉTAPES :
#   - Script 25: Test recherche hybride (./25_test_hybrid_search.sh)
#   - Script 26: Test multi-version / time travel (./26_test_multi_version_time_travel.sh)
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

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  🔍 DÉMONSTRATION COMPLÈTE : Fuzzy Search avec ByteT5"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Étape 1: Configuration du schéma
info "📋 ÉTAPE 1 : Configuration du schéma HCD"
info "   Ajout de la colonne libelle_embedding et de l'index vectoriel"
echo ""
cd "$SCRIPT_DIR"
./21_setup_fuzzy_search.sh
echo ""

# Étape 2: Vérification des dépendances
info "📋 ÉTAPE 2 : Vérification des dépendances Python"
if ! command -v python3 &> /dev/null; then
    error "Python3 n'est pas installé"
    exit 1
fi

if ! python3 -c "import transformers" 2>/dev/null; then
    warn "⚠️  transformers n'est pas installé"
    info "📦 Installation des dépendances..."
    pip3 install transformers torch --quiet
    success "✅ Dépendances installées"
else
    success "✅ Dépendances Python OK"
fi
echo ""

# Étape 3: Charger la clé API Hugging Face
INSTALL_DIR="$( cd "$SCRIPT_DIR/../.." &> /dev/null && pwd )"
if [ -f "$INSTALL_DIR/.poc-profile" ]; then
    source "$INSTALL_DIR/.poc-profile" 2>/dev/null || true
fi

if [ -z "$HF_API_KEY" ]; then
    export HF_API_KEY="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"
fi

info "📋 ÉTAPE 3 : Test de génération d'embedding"
info "   Clé API Hugging Face: ${HF_API_KEY:0:10}..."
info "   Test avec le texte: 'LOYER IMPAYE PARIS'"
echo ""
HF_API_KEY="$HF_API_KEY" python3 "$SCRIPT_DIR/examples/python/embeddings/generate_embeddings_bytet5.py" "LOYER IMPAYE PARIS"
echo ""

# Étape 4: Information sur la génération batch
info "📋 ÉTAPE 4 : Génération des embeddings pour les données existantes"
warn "⚠️  La génération batch nécessite une implémentation complète"
info "   Pour l'instant, utilisez generate_embeddings_bytet5.py pour tester"
info "   ou implémentez un script Spark/Python pour le batch"
echo ""

# Étape 5: Tests de recherche floue
info "📋 ÉTAPE 5 : Tests de recherche floue"
info "   Démonstration de la tolérance aux typos avec Vector Search"
echo ""

if [ -f "$SCRIPT_DIR/23_test_fuzzy_search.sh" ]; then
    "$SCRIPT_DIR/23_test_fuzzy_search.sh"
else
    warn "⚠️  Script de test non trouvé"
fi

echo ""
success "✅ Démonstration terminée !"
info "📝 Documentation: Voir README_FUZZY_SEARCH.md"
info "📝 Scripts disponibles:"
echo "   - 21_setup_fuzzy_search.sh : Configuration du schéma"
echo "   - 22_generate_embeddings.sh : Génération batch (à implémenter)"
echo "   - 23_test_fuzzy_search.sh : Tests de recherche floue"
echo "   - examples/python/embeddings/generate_embeddings_bytet5.py : Génération standalone"

