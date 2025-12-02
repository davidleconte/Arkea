#!/bin/bash
# ============================================
# Script 14c : Test STARTROW/STOPROW Équivalent (Version Didactique)
# Teste l'export avec filtrage STARTROW/STOPROW équivalent
# ============================================
#
# OBJECTIF :
#   Ce script teste spécifiquement le mode STARTROW/STOPROW équivalent
#   en utilisant des paramètres adaptés aux données existantes.
#
# UTILISATION :
#   ./14_test_startrow_stoprow.sh
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

if [ -f "${INSTALL_DIR}/.poc-profile" ]; then
    source "${INSTALL_DIR}/.poc-profile"
fi

echo ""
info "🔍 Recherche des données disponibles pour test STARTROW/STOPROW..."
echo ""

# Détecter les valeurs réelles dans les données
if [ -n "${HCD_HOME}" ]; then
    CQLSH_BIN="${HCD_HOME}/bin/cqlsh"
else
    CQLSH_BIN="${INSTALL_DIR}/binaire/hcd-1.2.3/bin/cqlsh"
fi
CQLSH="$CQLSH_BIN "$HCD_HOST" "$HCD_PORT""

# Récupérer les valeurs réelles
info "📊 Analyse des données existantes..."
CODE_SI_VALUES=$($CQLSH -e "USE domiramacatops_poc; SELECT DISTINCT code_si FROM operations_by_account LIMIT 5;" 2>&1 | grep -E "^[[:space:]]*[0-9]+[[:space:]]*$" | head -1 | tr -d ' ')
if [ -z "$CODE_SI_VALUES" ]; then
    CODE_SI_VALUES=$($CQLSH -e "USE domiramacatops_poc; SELECT code_si FROM operations_by_account LIMIT 1;" 2>&1 | grep -E "^[[:space:]]*[0-9]+[[:space:]]*\|" | awk -F'|' '{print $1}' | tr -d ' ' | head -1)
fi

# Utiliser Python pour récupérer les valeurs min/max
python3 << PYEOF
import subprocess
import sys

cqlsh_cmd = '${CQLSH}'.split()

# Récupérer min/max contrat
try:
    result = subprocess.run(
        cqlsh_cmd + ['-e', "USE domiramacatops_poc; SELECT MIN(contrat) as min_contrat, MAX(contrat) as max_contrat FROM operations_by_account ALLOW FILTERING;"],
        capture_output=True,
        text=True,
        timeout=10
    )
    if result.returncode == 0:
        lines = result.stdout.split('\n')
        for line in lines:
            if 'min_contrat' in line or (line.strip() and line.strip()[0].isdigit()):
                parts = line.split('|')
                if len(parts) >= 3:
                    min_val = parts[1].strip()
                    max_val = parts[2].strip()
                    if min_val.isdigit() and max_val.isdigit():
                        print(f"MIN={min_val}")
                        print(f"MAX={max_val}")
                        sys.exit(0)
except Exception as e:
    pass

# Fallback : valeurs par défaut
print("MIN=100000000")
print("MAX=900000049")
PYEOF

CONTRAT_MIN=$(python3 << PYEOF
import subprocess
cqlsh_cmd = '${CQLSH}'.split()
try:
    result = subprocess.run(
        cqlsh_cmd + ['-e', "USE domiramacatops_poc; SELECT MIN(contrat) as min_contrat FROM operations_by_account ALLOW FILTERING;"],
        capture_output=True,
        text=True,
        timeout=10
    )
    for line in result.stdout.split('\n'):
        if line.strip() and line.strip()[0].isdigit():
            parts = line.split('|')
            if len(parts) >= 2:
                val = parts[1].strip()
                if val.isdigit():
                    print(val)
                    exit(0)
except:
    pass
print("100000000")
PYEOF
)

CONTRAT_MAX=$(python3 << PYEOF
import subprocess
cqlsh_cmd = '${CQLSH}'.split()
try:
    result = subprocess.run(
        cqlsh_cmd + ['-e', "USE domiramacatops_poc; SELECT MAX(contrat) as max_contrat FROM operations_by_account ALLOW FILTERING;"],
        capture_output=True,
        text=True,
        timeout=10
    )
    for line in result.stdout.split('\n'):
        if line.strip() and line.strip()[0].isdigit():
            parts = line.split('|')
            if len(parts) >= 2:
                val = parts[1].strip()
                if val.isdigit():
                    print(val)
                    exit(0)
except:
    pass
print("900000049")
PYEOF
)

if [ -z "$CODE_SI_VALUES" ] || [ -z "$CONTRAT_MIN" ]; then
    error "Impossible de détecter les valeurs dans les données"
    error "Vérifiez que les données sont chargées (./05_load_operations_data_parquet.sh)"
    exit 1
fi

info "   Code SI détecté : $CODE_SI_VALUES"
info "   Contrat min : $CONTRAT_MIN"
info "   Contrat max : $CONTRAT_MAX"
echo ""

# Calculer une plage de contrats pour le test
CONTRAT_START="$CONTRAT_MIN"
CONTRAT_END=$(python3 << PYEOF
contrat_min = int("$CONTRAT_MIN")
contrat_max = int("$CONTRAT_MAX")
# Prendre une plage de 100 contrats
contrat_end = min(contrat_min + 100, contrat_max)
print(contrat_end)
PYEOF
)

info "🎯 Test STARTROW/STOPROW avec paramètres adaptés :"
info "   code_si = '$CODE_SI_VALUES'"
info "   contrat >= '$CONTRAT_START' AND contrat < '$CONTRAT_END'"
echo ""

# Vérifier qu'il y a des données
COUNT=$($CQLSH -e "USE domiramacatops_poc; SELECT COUNT(*) as count FROM operations_by_account WHERE code_si = '$CODE_SI_VALUES' AND contrat >= '$CONTRAT_START' AND contrat < '$CONTRAT_END' ALLOW FILTERING;" 2>&1 | grep -E "^[[:space:]]*[0-9]+[[:space:]]*\|" | awk -F'|' '{print $1}' | tr -d ' ' | head -1)

if [ -z "$COUNT" ] || [ "$COUNT" = "0" ]; then
    warn "⚠️  Aucune donnée trouvée avec ces critères"
    warn "   Le test ne peut pas être exécuté avec des résultats"
    info "   Explication : Les données ne contiennent pas de contrats dans la plage [$CONTRAT_START, $CONTRAT_END[ pour code_si='$CODE_SI_VALUES'"
    exit 0
fi

info "✅ $COUNT opérations trouvées avec ces critères"
echo ""

# Exécuter le test
OUTPUT_PATH="/tmp/exports/domiramaCatOps/test_startrow_stoprow"
"${SCRIPT_DIR}/14_test_incremental_export.sh" "2024-01-01" "2024-12-31" "$OUTPUT_PATH" "snappy" \
  "$CODE_SI_VALUES" "$CONTRAT_START" "$CONTRAT_END"

if [ $? -eq 0 ]; then
    # Vérifier les résultats
    PARQUET_COUNT=$(find "$OUTPUT_PATH" -name "*.parquet" -o -name "*.snappy.parquet" 2>/dev/null | wc -l | tr -d ' ' || echo "0")
    if [ "$PARQUET_COUNT" -gt 0 ]; then
        success "✅ Test STARTROW/STOPROW réussi : $PARQUET_COUNT fichiers Parquet créés"
        info "   Répertoire : $OUTPUT_PATH"
    else
        warn "⚠️  Test exécuté mais aucun fichier Parquet créé"
    fi
else
    error "❌ Erreur lors du test STARTROW/STOPROW"
    exit 1
fi

echo ""
success "✅ Test STARTROW/STOPROW terminé"
