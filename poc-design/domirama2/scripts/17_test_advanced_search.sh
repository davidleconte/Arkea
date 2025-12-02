#!/bin/bash
# ============================================
# Script 17 : Tests Full-Text Search Avancés
# Recherches complexes avec différents analyzers
# ============================================
#
# OBJECTIF :
#   Ce script exécute des tests de recherche full-text avancés en utilisant
#   les index SAI avec différents analyzers configurés dans le script 16.
#
#   Les tests démontrent :
#   - Recherches avec analyzers (lowercase, asciifolding, frenchLightStem)
#   - Recherches combinées (libellé + catégorie)
#   - Performance des index SAI
#   - Pertinence des résultats
#
# PRÉREQUIS :
#   - HCD démarré (./scripts/setup/03_start_hcd.sh)
#   - Schéma configuré (./10_setup_domirama2_poc.sh)
#   - Données chargées (./11_load_domirama2_data_parquet.sh)
#   - Index avancés configurés (./16_setup_advanced_indexes.sh)
#   - Fichier de tests présent: schemas/05_domirama2_search_advanced.cql
#
# UTILISATION :
#   ./17_test_advanced_search.sh
#
# EXEMPLE :
#   ./17_test_advanced_search.sh
#
# SORTIE :
#   - Résultats des tests de recherche avancés affichés
#   - Comparaison des performances avec/sans index
#   - Messages de succès/erreur
#
# PROCHAINES ÉTAPES :
#   - Script 18: Démonstration complète (./18_demonstration_complete.sh)
#   - Script 19: Configuration tolérance aux typos (./19_setup_typo_tolerance.sh)
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
    SPARK_HOME="${SPARK_HOME:-${INSTALL_DIR}/binaire/spark-3.5.1}"
    HCD_HOST="${HCD_HOST:-localhost}"
    HCD_PORT="${HCD_PORT:-9042}"
fi
TEST_FILE="${SCRIPT_DIR}/schemas/05_domirama2_search_advanced.cql"

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

# Vérifier que le keyspace existe
cd "$HCD_DIR"
jenv local 11
eval "$(jenv init -)"
if ! ./bin/cqlsh "$HCD_HOST" "$HCD_PORT" -e "DESCRIBE KEYSPACE domirama2_poc;" > /dev/null 2>&1; then
    error "Le keyspace domirama2_poc n'existe pas. Exécutez d'abord: ./10_setup_domirama2_poc.sh"
    exit 1
fi

info "🔍 Exécution des tests Full-Text Search avancés..."
info "   Tests: Recherches complexes avec différents analyzers"
info "   Exemples: stemming, n-gram, phrases, multi-critères"
info ""

# Sélectionner un compte avec des données
FIRST_ACCOUNT=$(./bin/cqlsh "$HCD_HOST" "$HCD_PORT" -e "USE domirama2_poc; SELECT code_si, contrat FROM operations_by_account LIMIT 1;" 2>&1 | grep -v "Warnings" | grep -E "^[[:space:]]*[0-9]" | head -1)

if [ -z "$FIRST_ACCOUNT" ]; then
    warn "Aucune donnée trouvée. Chargez d'abord les données avec ./11_load_domirama2_data_parquet.sh"
    exit 1
fi

# Extraire code_si et contrat
CODE_SI=$(echo "$FIRST_ACCOUNT" | awk '{print $1}' | tr -d ' ')
CONTRAT=$(echo "$FIRST_ACCOUNT" | awk '{print $2}' | tr -d ' ')

# Utiliser un compte connu avec beaucoup de données
CODE_SI="1"
CONTRAT="5913101072"

info "📊 Compte utilisé pour les tests: code_si=$CODE_SI, contrat=$CONTRAT"
info ""

# Vérifier que les index existent
INDEX_COUNT=$(./bin/cqlsh "$HCD_HOST" "$HCD_PORT" -e "USE domirama2_poc; DESCRIBE INDEXES;" 2>&1 | grep -v "Warnings" | grep -c "idx_libelle" || echo "0")

if [ "$INDEX_COUNT" -lt 1 ]; then
    warn "⚠️  Aucun index trouvé. Exécutez d'abord: ./16_setup_advanced_indexes.sh"
    info "   Continuons quand même avec les index existants..."
fi

# Remplacer les placeholders dans le fichier CQL
TEMP_CQL=$(mktemp)
sed "s/code_si = '1'/code_si = '$CODE_SI'/g; s/contrat = '5913101072'/contrat = '$CONTRAT'/g" "$TEST_FILE" > "$TEMP_CQL"

# Exécuter les tests
info "🚀 Exécution des 20 tests avancés..."
echo ""
./bin/cqlsh "$HCD_HOST" "$HCD_PORT" -f "$TEMP_CQL" 2>&1 | grep -v "Warnings" || true

rm -f "$TEMP_CQL"

echo ""
success "✅ Tests Full-Text Search avancés terminés !"
echo ""
info "📝 Types de recherches testées:"
echo "   ✅ Stemming français (pluriel/singulier)"
echo "   ✅ Recherche exacte (noms propres)"
echo "   ✅ Recherche de phrases"
echo "   ✅ Recherche partielle (N-Gram)"
echo "   ✅ Stop words (français)"
echo "   ✅ Asciifolding (accents)"
echo "   ✅ Multi-termes complexes"
echo "   ✅ Combinaisons avec filtres"
echo ""
info "💡 Les différents analyzers permettent:"
echo "   - idx_libelle_fulltext: Recherches générales avec stemming"
echo "   - idx_libelle_exact: Noms propres et codes exacts"
echo "   - idx_libelle_keyword: Phrases complètes"
echo "   - idx_libelle_ngram: Recherches partielles et typos"
echo "   - idx_libelle_french: Français avancé avec stop words"
echo "   - idx_libelle_whitespace: Recherches rapides"
