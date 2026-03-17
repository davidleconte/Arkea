#!/bin/bash
set -euo pipefail
# ============================================
# Démonstration Complète : Multi-Version avec Time Travel
# Version améliorée avec fichiers temporaires
# ============================================
#
# OBJECTIF :
#   Ce script orchestre une démonstration complète de la logique multi-version
#   avec time travel, garantissant qu'aucune correction client ne sera perdue
#   lors des ré-exécutions du batch.
#
#   Fonctionnalités démontrées :
#   - Stratégie multi-version : batch écrit cat_auto, client écrit cat_user
#   - Time travel : récupération des données selon les dates (cat_date_user)
#   - Priorité client : cat_user prioritaire sur cat_auto si non nul
#   - Aucune perte : les corrections client ne sont jamais écrasées
#   - DDL complet : création du schéma avec toutes les colonnes nécessaires
#   - Flux de données : chargement batch, corrections client, time travel
#
# PRÉREQUIS :
#   - HCD démarré (./scripts/setup/03_start_hcd.sh)
#   - Java 11 configuré via jenv
#   - Python 3.8+ installé
#   - Script Python présent: examples/python/multi_version/test_multi_version_time_travel.py
#
# UTILISATION :
#   ./demo_multi_version_complete_v2.sh
#
# EXEMPLE :
#   ./demo_multi_version_complete_v2.sh
#
# SORTIE :
#   - DDL complet avec toutes les colonnes
#   - Chargement des données batch
#   - Corrections client simulées
#   - Démonstration du time travel
#   - Validation qu'aucune correction client n'est perdue
#   - Messages de succès/erreur pour chaque étape
#
# PROCHAINES ÉTAPES :
#   - Script 26: Test multi-version / time travel (./26_test_multi_version_time_travel.sh)
#   - Consulter la documentation: doc/09_README_MULTI_VERSION.md
#
# ============================================

set -euo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
NC='\033[0m'

info() { echo -e "${BLUE}ℹ️  $1${NC}"; }
success() { echo -e "${GREEN}✅ $1${NC}"; }
warn() { echo -e "${YELLOW}⚠️  $1${NC}"; }
error() { echo -e "${RED}❌ $1${NC}"; }
code() { echo -e "${MAGENTA}📝 $1${NC}"; }

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
