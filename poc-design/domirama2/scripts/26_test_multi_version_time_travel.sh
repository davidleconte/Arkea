#!/bin/bash
# ============================================
# Script 26 : Test Multi-Version avec Time Travel
# Démontre que la logique multi-version garantit :
# 1. Aucune perte de mise à jour client
# 2. Time travel : données correctes selon les dates
# 3. Priorité client > batch (cat_user > cat_auto)
# ============================================
#
# OBJECTIF :
#   Ce script démontre la logique multi-version avec time travel, garantissant
#   qu'aucune correction client ne sera perdue lors des ré-exécutions du batch.
#   
#   Fonctionnalités démontrées :
#   - Stratégie multi-version : batch écrit cat_auto, client écrit cat_user
#   - Time travel : récupération des données selon les dates (cat_date_user)
#   - Priorité client : cat_user prioritaire sur cat_auto si non nul
#   - Aucune perte : les corrections client ne sont jamais écrasées
#
# PRÉREQUIS :
#   - HCD démarré (./scripts/setup/03_start_hcd.sh)
#   - Schéma configuré (./10_setup_domirama2_poc.sh)
#   - Données chargées (./11_load_domirama2_data_parquet.sh)
#   - Python 3.8+ installé
#   - Script Python présent: examples/python/multi_version/test_multi_version_time_travel.py
#
# UTILISATION :
#   ./26_test_multi_version_time_travel.sh
#
# EXEMPLE :
#   ./26_test_multi_version_time_travel.sh
#
# SORTIE :
#   - Démonstration de la logique multi-version
#   - Tests de time travel avec différentes dates
#   - Validation qu'aucune correction client n'est perdue
#   - Messages de succès/erreur
#
# PROCHAINES ÉTAPES :
#   - Script 27: Export incrémental Parquet (./27_export_incremental_parquet.sh)
#   - Consulter la documentation: doc/09_README_MULTI_VERSION.md
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
echo "  🔄 TEST MULTI-VERSION AVEC TIME TRAVEL"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
info "📚 OBJECTIF : Démontrer que la logique multi-version garantit :"
echo "   1. ✅ Aucune perte de mise à jour client"
echo "   2. ✅ Time travel : données correctes selon les dates choisies"
echo "   3. ✅ Priorité client > batch (cat_user > cat_auto)"
echo ""
info "🔧 STRATÉGIE MULTI-VERSION :"
echo "   - Batch écrit UNIQUEMENT cat_auto et cat_confidence"
echo "   - Client écrit dans cat_user, cat_date_user, cat_validee"
echo "   - Application priorise cat_user si non nul"
echo "   - Time travel via cat_date_user pour déterminer la catégorie valide"
echo ""

python3 "$SCRIPT_DIR/examples/python/multi_version/test_multi_version_time_travel.py" 2>&1

echo ""
success "✅ Test terminé !"
info "📝 Script disponible: examples/python/multi_version/test_multi_version_time_travel.py"
echo ""
info "💡 Points clés démontrés :"
echo "   ✅ Les mises à jour client ne sont jamais perdues"
echo "   ✅ Le batch ne touche jamais cat_user (stratégie respectée)"
echo "   ✅ Time travel fonctionne correctement"
echo "   ✅ Priorité client > batch respectée"
echo ""

