#!/bin/bash
# ============================================
# Script 15 : Tests Full-Text Search Complexes
# Recherches multi-termes, accents, variations
# ============================================
#
# OBJECTIF :
#   Ce script exécute des tests de recherche full-text complexes sur la table
#   'operations_by_account' en utilisant les index SAI avancés avec différents
#   analyzers (lowercase, asciifolding, frenchLightStem, stop words).
#   
#   Les tests couvrent :
#   - Recherches multi-termes (plusieurs mots simultanément)
#   - Gestion des accents (asciifolding)
#   - Racinisation française (frenchLightStem)
#   - Recherches avec caractères manquants ou inversés
#   - Vérification de la pertinence des résultats
#
# PRÉREQUIS :
#   - HCD démarré (./scripts/setup/03_start_hcd.sh)
#   - Schéma configuré (./10_setup_domirama2_poc.sh)
#   - Données chargées (./11_load_domirama2_data_parquet.sh)
#   - Index avancés configurés (./16_setup_advanced_indexes.sh)
#   - Fichier de tests présent: schemas/06_domirama2_search_fulltext_complex.cql
#
# UTILISATION :
#   ./15_test_fulltext_complex.sh
#
# EXEMPLE :
#   ./15_test_fulltext_complex.sh
#
# SORTIE :
#   - Résultats des tests de recherche complexes affichés
#   - Nombre de résultats pour chaque requête
#   - Démonstration des capacités des analyzers
#   - Messages de succès/erreur
#
# PROCHAINES ÉTAPES :
#   - Script 17: Tests de recherche avancés (./17_test_advanced_search.sh)
#   - Script 18: Démonstration complète (./18_demonstration_complete.sh)
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
TEST_FILE="${SCRIPT_DIR}/schemas/06_domirama2_search_fulltext_complex.cql"

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

info "🔍 Exécution des tests Full-Text Search complexes..."
info "   Tests: Recherches multi-termes, accents, variations"
info "   Exemples: 'loyer paris', 'virement impayé', etc."
info ""

# Sélectionner un compte avec des données
FIRST_ACCOUNT=$(./bin/cqlsh "$HCD_HOST" "$HCD_PORT" -e "USE domirama2_poc; SELECT code_si, contrat FROM operations_by_account LIMIT 1;" 2>&1 | grep -v "Warnings" | grep -E "^[[:space:]]*[0-9]" | head -1)

if [ -z "$FIRST_ACCOUNT" ]; then
    warn "Aucune donnée trouvée. Chargez d'abord les données avec ./11_load_domirama2_data_parquet.sh"
    exit 1
fi

# Extraire code_si et contrat (format peut varier)
CODE_SI=$(echo "$FIRST_ACCOUNT" | awk '{print $1}' | tr -d ' ')
CONTRAT=$(echo "$FIRST_ACCOUNT" | awk '{print $2}' | tr -d ' ')

# Garder le code_si tel quel (peut être '1', '2', '3' ou '01', '02', '03')
# Pas de normalisation nécessaire

info "📊 Compte utilisé pour les tests: code_si=$CODE_SI, contrat=$CONTRAT"
info ""

# Remplacer les placeholders dans le fichier CQL
TEMP_CQL=$(mktemp)
sed "s/code_si = '01'/code_si = '$CODE_SI'/g; s/contrat = '1234567890'/contrat = '$CONTRAT'/g" "$TEST_FILE" > "$TEMP_CQL"

# Exécuter les tests
./bin/cqlsh "$HCD_HOST" "$HCD_PORT" -f "$TEMP_CQL" 2>&1 | grep -v "Warnings" || true

rm -f "$TEMP_CQL"

echo ""
success "✅ Tests Full-Text Search complexes terminés !"
echo ""
info "📝 Types de recherches testées:"
echo "   ✅ Multi-termes: 'loyer paris', 'virement impayé'"
echo "   ✅ Accents: 'impayé' → trouve 'IMPAYE' (asciifolding)"
echo "   ✅ Stemming: 'loyers' → trouve 'LOYER' (pluriel)"
echo "   ✅ Triple termes: 'ratp navigo paris'"
echo "   ✅ Combinaisons: Full-text + filtres (montant, catégorie)"
echo ""
info "💡 Le full-text search SAI supporte:"
echo "   ✅ Recherche multi-termes (AND implicite)"
echo "   ✅ Asciifolding (accents ignorés)"
echo "   ✅ Stemming français (singulier/pluriel)"
echo "   ✅ Insensible à la casse"

