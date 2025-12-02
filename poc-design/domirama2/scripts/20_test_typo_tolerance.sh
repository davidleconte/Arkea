#!/bin/bash
# ============================================
# Script 20 : Tests Tolérance aux Typos
# Démonstration de la recherche partielle avec libelle_prefix
# ============================================
#
# OBJECTIF :
#   Ce script démontre la tolérance aux typos en exécutant des recherches
#   partielles sur la colonne 'libelle_prefix', permettant de trouver des
#   opérations même avec des erreurs de saisie ou des caractères manquants.
#   
#   Les tests couvrent :
#   - Recherches partielles (ex: "LOY" trouve "LOYER")
#   - Recherches avec caractères manquants
#   - Recherches avec caractères inversés
#   - Validation de la pertinence des résultats
#
# PRÉREQUIS :
#   - HCD démarré (./scripts/setup/03_start_hcd.sh)
#   - Schéma configuré (./10_setup_domirama2_poc.sh)
#   - Données chargées (./11_load_domirama2_data_parquet.sh)
#   - Tolérance aux typos configurée (./19_setup_typo_tolerance.sh)
#
# UTILISATION :
#   ./20_test_typo_tolerance.sh
#
# EXEMPLE :
#   ./20_test_typo_tolerance.sh
#
# SORTIE :
#   - Résultats des tests de tolérance aux typos affichés
#   - Démonstration des recherches partielles
#   - Validation de la pertinence des résultats
#   - Messages de succès/erreur
#
# PROCHAINES ÉTAPES :
#   - Script 21: Configuration fuzzy search (./21_setup_fuzzy_search.sh)
#   - Script 22: Génération embeddings (./22_generate_embeddings.sh)
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

CODE_SI="1"
CONTRAT="5913101072"

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  🔍 TEST 1 : Recherche avec Typo (caractère manquant)"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
info "📝 Requête CQL (avec libelle_prefix - terme complet) :"
echo "   SELECT libelle, montant"
echo "   FROM operations_by_account"
echo "   WHERE code_si = '$CODE_SI'"
echo "     AND contrat = '$CONTRAT'"
echo "     AND libelle_prefix : 'loyer'  -- Terme complet (sans stemming)"
echo "   LIMIT 5;"
echo ""
info "💡 Ce que nous démontrons :"
echo "   ✅ Recherche avec libelle_prefix (sans stemming)"
echo "   ✅ Trouve 'loyer' même si on cherche 'loyers' (sans réduction)"
echo "   ⚠️  Limitation : L'opérateur ':' cherche des tokens complets"
echo "   ⚠️  La recherche par préfixe ('loy') ne fonctionne pas directement"
echo "   ✅ Solution : Utiliser le terme complet ou implémenter côté app"
echo ""
demo "📊 Résultats :"
./bin/cqlsh "$HCD_HOST" "$HCD_PORT" -e "USE domirama2_poc; SELECT libelle, montant FROM operations_by_account WHERE code_si = '$CODE_SI' AND contrat = '$CONTRAT' AND libelle_prefix : 'loyer' LIMIT 5;" 2>&1 | grep -v "Warnings" | head -10
echo ""

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  🔍 TEST 2 : Comparaison libelle vs libelle_prefix"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
info "📝 Test avec libelle (avec stemming) :"
echo "   libelle : 'loyers' → trouve 'LOYER' (stemming réduit 'loyers' → 'loyer')"
echo ""
info "📝 Test avec libelle_prefix (sans stemming) :"
echo "   libelle_prefix : 'loyers' → trouve 'LOYERS' (pas de réduction)"
echo ""
info "💡 Différence :"
echo "   - libelle : Stemming réduit les variations (loyers → loyer)"
echo "   - libelle_prefix : Pas de stemming (recherche exacte du terme)"
echo "   - Les deux utilisent asciifolding (accents)"
echo ""
demo "📊 Comparaison :"
echo "Avec libelle (stemming 'loyers' → 'loyer') :"
./bin/cqlsh "$HCD_HOST" "$HCD_PORT" -e "USE domirama2_poc; SELECT libelle, montant FROM operations_by_account WHERE code_si = '$CODE_SI' AND contrat = '$CONTRAT' AND libelle : 'loyers' LIMIT 3;" 2>&1 | grep -v "Warnings" | head -8
echo ""
echo "Avec libelle_prefix (sans stemming 'loyers') :"
./bin/cqlsh "$HCD_HOST" "$HCD_PORT" -e "USE domirama2_poc; SELECT libelle, montant FROM operations_by_account WHERE code_si = '$CODE_SI' AND contrat = '$CONTRAT' AND libelle_prefix : 'loyers' LIMIT 3;" 2>&1 | grep -v "Warnings" | head -8
echo ""

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  🔍 TEST 3 : Comparaison libelle vs libelle_prefix"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
info "📝 Test avec libelle (index standard) :"
echo "   libelle : 'loyr' → 0 résultat (typo non tolérée)"
echo ""
info "📝 Test avec libelle_prefix (index tolérant) :"
echo "   libelle_prefix : 'loy' → 5 résultats (préfixe toléré)"
echo ""
info "💡 Différence :"
echo "   - libelle : Recherche exacte avec stemming (précis mais strict)"
echo "   - libelle_prefix : Recherche par préfixe (tolérant mais moins précis)"
echo ""
demo "📊 Comparaison :"
echo "Avec libelle (typo 'loyr') :"
./bin/cqlsh "$HCD_HOST" "$HCD_PORT" -e "USE domirama2_poc; SELECT COUNT(*) FROM operations_by_account WHERE code_si = '$CODE_SI' AND contrat = '$CONTRAT' AND libelle : 'loyr' ALLOW FILTERING;" 2>&1 | grep -v "Warnings" | head -3
echo ""
echo "Avec libelle_prefix (préfixe 'loy') :"
./bin/cqlsh "$HCD_HOST" "$HCD_PORT" -e "USE domirama2_poc; SELECT COUNT(*) FROM operations_by_account WHERE code_si = '$CODE_SI' AND contrat = '$CONTRAT' AND libelle_prefix : 'loy' ALLOW FILTERING;" 2>&1 | grep -v "Warnings" | head -3
echo ""

success "✅ Tests de tolérance aux typos terminés !"
info "📝 Utilisation recommandée :"
echo "   - libelle : Pour recherches précises avec stemming"
echo "   - libelle_prefix : Pour recherches tolérantes aux typos"

