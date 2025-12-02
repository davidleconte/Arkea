#!/bin/bash
# ============================================
# Script 16 : Tests Fuzzy Search Complets (Tous les tests supplémentaires)
# Orchestre tous les tests supplémentaires pour la recherche floue
# ============================================
#
# OBJECTIF :
#   Ce script exécute tous les tests supplémentaires pour la recherche floue
#   avec vector search, couvrant performance, robustesse, accents, etc.
#
# PRÉREQUIS :
#   - HCD démarré
#   - Schéma configuré
#   - Données chargées
#   - Embeddings générés
#   - Python 3.8+ avec transformers, torch, cassandra-driver installés
#
# UTILISATION :
#   ./16_test_fuzzy_search_complete.sh
#
# ============================================

set -euo pipefail

# Configuration - Utiliser setup_paths si disponible
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
if [ -f "$SCRIPT_DIR/../utils/didactique_functions.sh" ]; then
    source "$SCRIPT_DIR/../utils/didactique_functions.sh"
    setup_paths
else
    # Fallback si les fonctions ne sont pas disponibles
    INSTALL_DIR="${ARKEA_HOME:-$(cd "$SCRIPT_DIR/../.." && pwd)}"
    HCD_DIR="${HCD_DIR:-${INSTALL_DIR}/binaire/hcd-1.2.3}"
    SPARK_HOME="${SPARK_HOME:-${INSTALL_DIR}/binaire/spark-3.5.1}"
    HCD_HOST="${HCD_HOST:-localhost}"
    HCD_PORT="${HCD_PORT:-9042}"
fi

if [ -f "${INSTALL_DIR}/.poc-profile" ]; then
    source "${INSTALL_DIR}/.poc-profile"
fi

HCD_DIR="${HCD_HOME:-${INSTALL_DIR}/binaire/hcd-1.2.3}"
REPORT_FILE="${SCRIPT_DIR}/../doc/demonstrations/16_FUZZY_SEARCH_COMPLETE_DEMONSTRATION.md"
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
info "  🔍 TESTS FUZZY SEARCH COMPLETS - Tous les Tests Supplémentaires"
info "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Vérifications
if ! command -v python3 &> /dev/null; then
    error "Python 3 n'est pas installé"
    exit 1
fi

# Liste des tests à exécuter
TESTS=(
    "test_vector_search_performance.py:Tests de Performance"
    "test_vector_search_comparative.py:Tests Comparatifs Vector vs Full-Text"
    "test_vector_search_limits.py:Tests de Limites"
    "test_vector_search_robustness.py:Tests de Robustesse"
    "test_vector_search_accents.py:Tests avec Accents/Diacritiques"
    "test_vector_search_abbreviations.py:Tests avec Abréviations"
    "test_vector_search_consistency.py:Tests de Cohérence"
    "test_vector_search_synonyms.py:Tests avec Synonymes"
    "test_vector_search_multilang.py:Tests Multilingues"
    "test_vector_search_multiworld.py:Tests Multi-Mots vs Mots Uniques"
    "test_vector_search_threshold.py:Tests avec Seuils de Similarité"
    "test_vector_search_temporal.py:Tests avec Filtres Temporels Combinés"
    "test_vector_search_volume.py:Tests avec Données Volumineuses"
    "test_vector_search_precision.py:Tests de Précision/Recall"
)

# Compteurs
TOTAL_TESTS=${#TESTS[@]}
PASSED_TESTS=0
FAILED_TESTS=0

# Créer le répertoire de rapport
mkdir -p "$(dirname "$REPORT_FILE")"

# Exécuter chaque test
echo ""
info "📊 Exécution de $TOTAL_TESTS tests..."
echo ""

for test_info in "${TESTS[@]}"; do
    IFS=':' read -r test_file test_name <<< "$test_info"
    test_path="${PYTHON_DIR}/${test_file}"
    
    if [ ! -f "$test_path" ]; then
        warn "⚠️  Test non trouvé : $test_file"
        ((FAILED_TESTS++))
        continue
    fi
    
    info "🧪 Exécution : $test_name"
    echo "   Fichier : $test_file"
    echo ""
    
    if python3 "$test_path" 2>&1; then
        success "✅ $test_name : RÉUSSI"
        ((PASSED_TESTS++))
    else
        error "❌ $test_name : ÉCHOUÉ"
        ((FAILED_TESTS++))
    fi
    
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
done

# Générer le rapport détaillé
python3 "${SCRIPT_DIR}/16_generate_detailed_report.py"

# Résumé final
echo ""
info "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
info "  📋 RÉSUMÉ FINAL"
info "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "   Total de tests : $TOTAL_TESTS"
echo "   Tests réussis  : $PASSED_TESTS"
echo "   Tests échoués  : $FAILED_TESTS"
echo "   Taux de réussite : $((PASSED_TESTS * 100 / TOTAL_TESTS))%"
echo ""

if [ $FAILED_TESTS -eq 0 ]; then
    success "✅ Tous les tests sont passés !"
else
    warn "⚠️  $FAILED_TESTS test(s) ont échoué"
fi

echo ""
success "✅ Rapport généré : $REPORT_FILE"
echo ""

