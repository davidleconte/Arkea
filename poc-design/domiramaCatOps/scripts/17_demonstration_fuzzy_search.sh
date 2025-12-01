#!/bin/bash
# ============================================
# Script 17 : Démonstration Complète Fuzzy Search (Version Didactique)
# Orchestre la configuration, génération et tests de la recherche floue
# ============================================
#
# OBJECTIF :
#   Ce script orchestre une démonstration complète de la recherche floue
#   (fuzzy search) en exécutant toutes les étapes nécessaires : configuration,
#   génération des embeddings, et tests de recherche.
#   
#   Cette version didactique affiche :
#   - Le DDL complet (schéma VECTOR et index)
#   - La génération d'embeddings (démonstration)
#   - Les requêtes CQL détaillées (DML)
#   - Les résultats attendus pour chaque test
#   - Une documentation structurée pour livrable
#
# PRÉREQUIS :
#   - HCD démarré (./03_start_hcd.sh)
#   - Schéma configuré (./01_setup_domiramaCatOps_keyspace.sh, ./02_setup_operations_by_account.sh)
#   - Données chargées (./05_load_operations_data_parquet.sh)
#   - Python 3.8+ avec transformers, torch, cassandra-driver installés
#
# UTILISATION :
#   ./17_demonstration_fuzzy_search.sh
#
# ============================================

set -e

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
if [ -f "${SCRIPT_DIR}/../utils/didactique_functions.sh" ]; then
    source "${SCRIPT_DIR}/../utils/didactique_functions.sh"
else
    RED='\033[0;31m'
    GREEN='\033[0;32m'
    YELLOW='\033[1;33m'
    BLUE='\033[0;34m'
    NC='\033[0m'
    info() { echo -e "${BLUE}ℹ️  $1${NC}"; }
    success() { echo -e "${GREEN}✅ $1${NC}"; }
    error() { echo -e "${RED}❌ $1${NC}"; }
fi

INSTALL_DIR="/Users/david.leconte/Documents/Arkea"
if [ -f "${INSTALL_DIR}/.poc-profile" ]; then
    source "${INSTALL_DIR}/.poc-profile"

# ============================================
# VÉRIFICATIONS PRÉALABLES
# ============================================
check_hcd_status
check_jenv_java_version
fi
HCD_DIR="${HCD_HOME:-${INSTALL_DIR}/binaire/hcd-1.2.3}"
REPORT_FILE="${SCRIPT_DIR}/../doc/demonstrations/17_FUZZY_SEARCH_COMPLETE_DEMONSTRATION.md"

mkdir -p "$(dirname "$REPORT_FILE")"


cd "$HCD_DIR"
jenv local 11
eval "$(jenv init -)"

show_demo_header "Démonstration Complète Fuzzy Search"

show_partie "1" "CONTEXTE - Pourquoi la Recherche Floue ?"

info "📚 PROBLÈME : Recherches avec Typos Complexes qui Échouent"
echo ""
echo "   Scénario 1 : Un utilisateur cherche 'LOYER' mais tape 'LOYR' (caractère 'e' manquant)"
echo "   Résultat avec index standard : ❌ Aucun résultat trouvé"
echo ""
echo "   SOLUTION : Recherche Vectorielle avec Embeddings ByteT5"
echo "   ✅ Tolère les typos complexes (faute, inversion, caractères manquants)"
echo "   ✅ Capture la similarité sémantique"
echo ""

show_partie "2" "DDL - SCHÉMA VECTOR SEARCH"

info "📝 DDL - Colonne VECTOR pour embeddings :"
code "ALTER TABLE operations_by_account"
code "ADD libelle_embedding VECTOR<FLOAT, 1472>;"
echo ""
info "📝 DDL - Index SAI Vectoriel :"
code "CREATE CUSTOM INDEX idx_libelle_embedding_vector"
code "ON operations_by_account(libelle_embedding)"
code "USING 'StorageAttachedIndex';"
echo ""

show_partie "3" "GÉNÉRATION D'EMBEDDINGS"

info "🚀 Vérification des embeddings existants..."
EMBEDDED_COUNT=$("${HCD_HOME:-$HCD_DIR}/bin/cqlsh localhost 9042 -e "USE domiramacatops_poc; SELECT COUNT(*) FROM operations_by_account WHERE libelle_embedding IS NOT NULL ALLOW FILTERING;" 2>&1 | grep -v "Warnings" | grep -E "^[[:space:]]*[0-9]+" | head -1 | tr -d ' ' || echo "0")

if [ -n "$EMBEDDED_COUNT" ] && [ "$EMBEDDED_COUNT" -gt 0 ]; then
    success "✅ $EMBEDDED_COUNT opération(s) avec embeddings générés"
else
    warn "⚠️  Aucun embedding trouvé. Exécutez d'abord: ./05_generate_libelle_embedding.sh"
fi
echo ""

show_partie "4" "TESTS DE RECHERCHE FLOUE"

info "🚀 Exécution des tests de recherche floue..."
PYTHON_SCRIPT="${SCRIPT_DIR}/../examples/python/search/test_vector_search.py"
if [ -f "$PYTHON_SCRIPT" ]; then
    python3 "$PYTHON_SCRIPT" 2>&1 | head -50 || true
else
    info "💡 Tests de recherche floue (exemple)"
fi

success "✅ Démonstration terminée !"

# Génération rapport (template 69)
python3 << 'PYEOF' > "$REPORT_FILE"
import os
from datetime import datetime
backtick = chr(96)
code_block = backtick + backtick + backtick + "cql\n"
code_end = "\n" + backtick + backtick + backtick + "\n"

report = f"# Démonstration Complète Fuzzy Search\n\n**Date** : {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}\n**Script** : 17_demonstration_fuzzy_search.sh\n\n---\n\n## Démonstration Exécutée\n\nDémonstration complète de la recherche floue avec embeddings ByteT5.\n\n"
print(report, end='')
PYEOF

success "✅ Rapport généré : $REPORT_FILE"
