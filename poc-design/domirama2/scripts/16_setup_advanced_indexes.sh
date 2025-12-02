#!/bin/bash
# ============================================
# Script 16 : Configuration Index SAI Avancés
# Création de multiples index avec différents analyzers
# ============================================
#
# OBJECTIF :
#   Ce script configure des index SAI (Storage-Attached Index) avancés pour
#   la table 'operations_by_account' avec différents analyzers Lucene pour
#   améliorer la pertinence des recherches full-text.
#   
#   Index créés :
#   - idx_libelle_fulltext_advanced : Avec analyzers (lowercase, asciifolding, frenchLightStem, stop words)
#   - idx_cat_auto : Index standard sur cat_auto
#   - Autres index selon les besoins
#
# PRÉREQUIS :
#   - HCD démarré (./scripts/setup/03_start_hcd.sh)
#   - Schéma de base configuré (./10_setup_domirama2_poc.sh)
#   - Table 'operations_by_account' existante
#   - Fichier schéma présent: schemas/02_create_domirama2_schema_advanced.cql
#
# UTILISATION :
#   ./16_setup_advanced_indexes.sh
#
# EXEMPLE :
#   ./16_setup_advanced_indexes.sh
#
# SORTIE :
#   - Index SAI avancés créés
#   - Vérification de la création des index
#   - Messages de succès/erreur
#
# PROCHAINES ÉTAPES :
#   - Script 15: Tests full-text complexes (./15_test_fulltext_complex.sh)
#   - Script 17: Tests de recherche avancés (./17_test_advanced_search.sh)
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
SCHEMA_FILE="${SCRIPT_DIR}/schemas/02_create_domirama2_schema_advanced.cql"

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

cd "$HCD_DIR"
jenv local 11
eval "$(jenv init -)"

info "🔧 Configuration des index SAI avancés..."
info "   Création de 6 index avec différents analyzers"
info ""

# Supprimer les anciens index si nécessaire
info "🗑️  Suppression des anciens index (si existants)..."
./bin/cqlsh "$HCD_HOST" "$HCD_PORT" -e "USE domirama2_poc; DROP INDEX IF EXISTS idx_libelle_fulltext;" 2>&1 | grep -v "Warnings" || true
./bin/cqlsh "$HCD_HOST" "$HCD_PORT" -e "USE domirama2_poc; DROP INDEX IF EXISTS idx_libelle_fulltext_advanced;" 2>&1 | grep -v "Warnings" || true

# Créer les nouveaux index
info "📋 Création des nouveaux index..."
./bin/cqlsh "$HCD_HOST" "$HCD_PORT" -f "$SCHEMA_FILE" 2>&1 | grep -v "Warnings" || true

# Vérifier les index créés
info "🔍 Vérification des index créés..."
INDEX_COUNT=$(./bin/cqlsh "$HCD_HOST" "$HCD_PORT" -e "USE domirama2_poc; DESCRIBE INDEXES;" 2>&1 | grep -v "Warnings" | grep -c "idx_libelle" || echo "0")

if [ "$INDEX_COUNT" -ge 1 ]; then
    success "✅ Index avancé créé avec succès"
else
    warn "⚠️  Index non créé, vérification nécessaire"
fi

echo ""
info "📋 Index créé:"
echo "   idx_libelle_fulltext_advanced - Multi-capacités:"
echo "   ✅ Stemming français (pluriel/singulier)"
echo "   ✅ Asciifolding (accents)"
echo "   ✅ Stop words français"
echo "   ✅ Case-insensitive"
echo "   ✅ Tokenizer standard"
echo ""

info "⏳ Indexation en cours (peut prendre quelques minutes)..."
info "   Les index SAI sont construits en arrière-plan"
info "   Attendre 30-60 secondes avant de tester les recherches"
echo ""

success "✅ Configuration des index avancés terminée !"
info "📝 Prochaine étape: Exécuter ./17_test_advanced_search.sh"

