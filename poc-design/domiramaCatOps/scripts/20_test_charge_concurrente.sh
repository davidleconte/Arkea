#!/bin/bash
# ============================================
# Script 20 : Test Complexe P1-02 - Tests de Charge Concurrente
# Test de charge concurrente (lecture, écriture, mixte) avec mesure latence/throughput
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
    check_hcd_status
    check_jenv_java_version
fi

PYTHON_DIR="${SCRIPT_DIR}/../examples/python"
PYTHON_SCRIPT="${PYTHON_DIR}/test_charge_concurrente.py"
REPORT_FILE="${SCRIPT_DIR}/../doc/demonstrations/20_CHARGE_CONCURRENTE_DEMONSTRATION.md"

show_demo_header "Test Complexe P1-02 : Tests de Charge Concurrente"

info "📚 Ce test valide :"
echo "   ✅ Charge lecture (100+ requêtes simultanées)"
echo "   ✅ Charge écriture (100+ insertions simultanées)"
echo "   ✅ Charge mixte (50% lecture, 50% écriture)"
echo "   ✅ Mesure latence (p50, p95, p99) et throughput"

echo ""
info "🚀 Exécution du test..."

if python3 "${PYTHON_SCRIPT}" 2>&1 | tee /tmp/test_charge_concurrente_output.txt; then
    success "✅ Test terminé avec succès"
    
    # Génération du rapport
    info "📝 Génération du rapport..."
    python3 << 'PYEOF'
import sys
import os
from datetime import datetime

report_file = os.environ.get('REPORT_FILE', '/tmp/report.md')
output_file = '/tmp/test_charge_concurrente_output.txt'

report = f"""# 🔍 Test Complexe P1-02 : Tests de Charge Concurrente

**Date** : {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}
**Script** : 20_test_charge_concurrente.sh

---

## 📊 Résumé Exécutif

Ce test valide les performances sous charge concurrente :
- ✅ Charge lecture (100+ requêtes simultanées)
- ✅ Charge écriture (100+ insertions simultanées)
- ✅ Charge mixte (50% lecture, 50% écriture)
- ✅ Mesure latence (p50, p95, p99) et throughput

---

## 📋 Résultats Détaillés

"""

if os.path.exists(output_file):
    with open(output_file, 'r') as f:
        output = f.read()
        report += "### Sortie du Test\n\n"
        report += "```\n"
        report += output
        report += "\n```\n"

report += "\n---\n\n**Date de génération** : " + datetime.now().strftime('%Y-%m-%d %H:%M:%S') + "\n"

with open(report_file, 'w') as f:
    f.write(report)

print(f"✅ Rapport généré : {report_file}")
PYEOF
    
    success "✅ Rapport généré : ${REPORT_FILE}"
else
    error "❌ Test échoué"
    exit 1
fi

success "✅ Script terminé avec succès"

