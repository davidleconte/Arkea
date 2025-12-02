#!/bin/bash
# ============================================
# Script 14e : Ajout de Données de Test pour Export
# Ajoute des données pertinentes pour tester les exports
# ============================================
#
# OBJECTIF :
#   Ce script ajoute des données de test avec des valeurs connues
#   pour permettre de tester les exports TIMERANGE et STARTROW/STOPROW
#   sans utiliser ALLOW FILTERING.
#
# UTILISATION :
#   ./14_add_test_data_for_export.sh
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

if [ -n "${HCD_HOME}" ]; then
    CQLSH_BIN="${HCD_HOME}/bin/cqlsh"
else
    CQLSH_BIN="${INSTALL_DIR}/binaire/hcd-1.2.3/bin/cqlsh"
fi

echo ""
info "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
info "  📝 Ajout de Données de Test pour Export"
info "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Valeurs de test
CODE_SI_TEST="TEST_EXPORT"
CONTRAT_TEST="TEST_CONTRAT"

info "📊 Paramètres de test :"
info "   code_si : $CODE_SI_TEST"
info "   contrat : $CONTRAT_TEST"
info "   Périodes : 2024-06-01 → 2024-08-31 (3 mois)"
echo ""

# Générer des données de test avec Python pour les 3 mois
python3 << PYEOF
from datetime import datetime, timedelta
import subprocess
import sys

cqlsh_cmd = '${CQLSH_BIN} "$HCD_HOST" "$HCD_PORT"'.split()
code_si = "${CODE_SI_TEST}"
contrat = "${CONTRAT_TEST}"

# Périodes à couvrir : juin, juillet, août 2024
periods = [
    (datetime(2024, 6, 1), datetime(2024, 7, 1)),
    (datetime(2024, 7, 1), datetime(2024, 8, 1)),
    (datetime(2024, 8, 1), datetime(2024, 8, 31))
]

total_operations = []
numero_op = 1

for period_start, period_end in periods:
    print(f"📅 Génération données pour {period_start.strftime('%Y-%m')}...", file=sys.stderr)
    current_date = period_start
    period_operations = []
    
    # Générer environ 30-40 opérations par mois
    period_label = period_start.strftime("%Y-%m")
    while current_date < period_end and len(period_operations) < 40:
        date_op_cql = current_date.strftime("%Y-%m-%dT%H:%M:%S")
        
        # Insérer l'opération
        insert_query = f"INSERT INTO domiramacatops_poc.operations_by_account (code_si, contrat, date_op, numero_op, libelle, montant, devise, type_operation, cat_auto, cat_confidence) VALUES ('{code_si}', '{contrat}', '{date_op_cql}', {numero_op}, 'Test operation {numero_op} - {period_label}', {100.0 + numero_op}, 'EUR', 'VIREMENT', 'TEST_CATEGORY', 0.95)"
        
        try:
            result = subprocess.run(
                cqlsh_cmd + ['-e', insert_query],
                capture_output=True,
                text=True,
                timeout=10
            )
            if result.returncode == 0:
                period_operations.append(numero_op)
                total_operations.append(numero_op)
            else:
                print(f"Erreur pour opération {numero_op}: {result.stderr}", file=sys.stderr)
        except Exception as e:
            print(f"Exception pour opération {numero_op}: {e}", file=sys.stderr)
        
        numero_op += 1
        current_date += timedelta(hours=18)  # Environ 1.3 opérations par jour
    
    print(f"✅ {len(period_operations)} opérations ajoutées pour {period_start.strftime('%Y-%m')}", file=sys.stderr)

print(f"✅ {len(total_operations)} opérations de test ajoutées au total")
PYEOF

EXIT_CODE=$?

if [ $EXIT_CODE -eq 0 ]; then
    success "✅ Données de test ajoutées avec succès"
    
    # Vérifier les données
    info "🔍 Vérification des données ajoutées..."
    COUNT=$("$CQLSH_BIN" "$HCD_HOST" "$HCD_PORT" -e "USE domiramacatops_poc; SELECT COUNT(*) FROM operations_by_account WHERE code_si = '$CODE_SI_TEST' AND contrat = '$CONTRAT_TEST';" 2>&1 | grep -E "^[[:space:]]*[0-9]+[[:space:]]*$" | head -1 | tr -d ' ')
    
    if [ -n "$COUNT" ] && [ "$COUNT" -gt 0 ]; then
        success "✅ $COUNT opérations de test trouvées"
    else
        warn "⚠️  Aucune opération de test trouvée"
    fi
else
    error "❌ Erreur lors de l'ajout des données de test"
    exit 1
fi

echo ""
success "✅ Données de test prêtes pour les exports"
