#!/bin/bash
# ============================================
# Script 14b : Export Fenêtre Glissante (Version Didactique)
# Exporte les données par fenêtres glissantes (mensuelles, hebdomadaires)
# Équivalent HBase: TIMERANGE avec fenêtre glissante
# ============================================
#
# OBJECTIF :
#   Ce script démontre l'export par fenêtre glissante, équivalent aux exports
#   périodiques HBase avec TIMERANGE.
#   
#   Fonctionnalités :
#   - Calcul automatique des fenêtres (mensuelles, hebdomadaires)
#   - Export de plusieurs fenêtres consécutives
#   - Idempotence (mode overwrite pour rejeux)
#
# PRÉREQUIS :
#   - HCD démarré (./03_start_hcd.sh)
#   - Schéma configuré (./01_setup_domiramaCatOps_keyspace.sh, ./02_setup_operations_by_account.sh)
#   - Données chargées (./05_load_operations_data_parquet.sh)
#   - DSBulk installé et configuré
#   - Spark 3.5.1 installé et configuré
#   - Java 11 configuré via jenv
#
# UTILISATION :
#   ./14_test_sliding_window_export.sh [start_date] [end_date] [window_type] [output_base_path] [compression]
#
# PARAMÈTRES :
#   $1 : Date de début (format: YYYY-MM-DD, optionnel, défaut: 2024-01-01)
#   $2 : Date de fin (format: YYYY-MM-DD, optionnel, défaut: 2024-06-30)
#   $3 : Type de fenêtre (monthly, weekly, optionnel, défaut: monthly)
#   $4 : Chemin de base de sortie (optionnel, défaut: /tmp/exports/domiramaCatOps/sliding_window)
#   $5 : Compression (optionnel, défaut: snappy)
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
    warn() { echo -e "${YELLOW}⚠️  $1${NC}"; }
fi

INSTALL_DIR="/Users/david.leconte/Documents/Arkea"
if [ -f "${INSTALL_DIR}/.poc-profile" ]; then
    source "${INSTALL_DIR}/.poc-profile"
fi

START_DATE="${1:-2024-01-01}"
END_DATE="${2:-2024-06-30}"
WINDOW_TYPE="${3:-monthly}"
OUTPUT_BASE_PATH="${4:-/tmp/exports/domiramaCatOps/sliding_window}"
COMPRESSION="${5:-snappy}"

echo ""
info "🎯 Export Fenêtre Glissante"
info "   Type : $WINDOW_TYPE"
info "   Période : $START_DATE → $END_DATE"
echo ""

# Calculer les fenêtres
python3 << PYEOF
from datetime import datetime, timedelta
import calendar

start = datetime.strptime("$START_DATE", "%Y-%m-%d")
end = datetime.strptime("$END_DATE", "%Y-%m-%d")
window_type = "$WINDOW_TYPE"

windows = []

if window_type == "monthly":
    current = start.replace(day=1)
    while current < end:
        # Premier jour du mois
        window_start = current
        # Dernier jour du mois
        last_day = calendar.monthrange(current.year, current.month)[1]
        window_end = current.replace(day=last_day) + timedelta(days=1)
        if window_end > end:
            window_end = end
        
        windows.append((window_start.strftime("%Y-%m-%d"), window_end.strftime("%Y-%m-%d"), current.strftime("%Y-%m")))
        # Passer au mois suivant
        if current.month == 12:
            current = current.replace(year=current.year + 1, month=1)
        else:
            current = current.replace(month=current.month + 1)

elif window_type == "weekly":
    current = start
    week_num = 1
    while current < end:
        window_start = current
        window_end = min(current + timedelta(days=7), end)
        windows.append((window_start.strftime("%Y-%m-%d"), window_end.strftime("%Y-%m-%d"), f"{current.strftime('%Y-%m')}-W{week_num:02d}"))
        current = window_end
        week_num += 1

# Afficher les fenêtres
for i, (ws, we, label) in enumerate(windows, 1):
    print(f"{i}|{ws}|{we}|{label}")
PYEOF

WINDOW_COUNT=0
while IFS='|' read -r num window_start window_end window_label; do
    if [ -z "$window_start" ]; then
        continue
    fi
    
    WINDOW_COUNT=$((WINDOW_COUNT + 1))
    WINDOW_OUTPUT_PATH="${OUTPUT_BASE_PATH}/${window_label}"
    
    echo ""
    info "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    info "  📅 Fenêtre $WINDOW_COUNT : $window_label ($window_start → $window_end)"
    info "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    
    # Appeler le script d'export principal
    "${SCRIPT_DIR}/14_test_incremental_export.sh" "$window_start" "$window_end" "$WINDOW_OUTPUT_PATH" "$COMPRESSION" "" "" "" "" "" "timerange"
    
    if [ $? -eq 0 ]; then
        success "✅ Fenêtre $WINDOW_COUNT exportée avec succès"
    else
        error "❌ Erreur lors de l'export de la fenêtre $WINDOW_COUNT"
        exit 1
    fi
    
done < <(python3 << PYEOF
from datetime import datetime, timedelta
import calendar

start = datetime.strptime("$START_DATE", "%Y-%m-%d")
end = datetime.strptime("$END_DATE", "%Y-%m-%d")
window_type = "$WINDOW_TYPE"

windows = []

if window_type == "monthly":
    current = start.replace(day=1)
    while current < end:
        window_start = current
        last_day = calendar.monthrange(current.year, current.month)[1]
        window_end = current.replace(day=last_day) + timedelta(days=1)
        if window_end > end:
            window_end = end
        windows.append((window_start.strftime("%Y-%m-%d"), window_end.strftime("%Y-%m-%d"), current.strftime("%Y-%m")))
        if current.month == 12:
            current = current.replace(year=current.year + 1, month=1)
        else:
            current = current.replace(month=current.month + 1)

elif window_type == "weekly":
    current = start
    week_num = 1
    while current < end:
        window_start = current
        window_end = min(current + timedelta(days=7), end)
        windows.append((window_start.strftime("%Y-%m-%d"), window_end.strftime("%Y-%m-%d"), f"{current.strftime('%Y-%m')}-W{week_num:02d}"))
        current = window_end
        week_num += 1

for i, (ws, we, label) in enumerate(windows, 1):
    print(f"{i}|{ws}|{we}|{label}")
PYEOF
)

echo ""
success "✅ Export fenêtre glissante terminé : $WINDOW_COUNT fenêtres exportées"
info "   Répertoire de base : $OUTPUT_BASE_PATH"
echo ""


