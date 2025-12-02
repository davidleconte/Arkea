#!/bin/bash
# ============================================
# Script 21 : Test Complexe P2-03 - Recherche avec Filtres Multiples Combinés
# Test de recherche avec filtres multiples (vector, full-text, date, montant, catégorie)
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
    check_hcd_status
    check_jenv_java_version
fi

PYTHON_DIR="${SCRIPT_DIR}/../examples/python"
PYTHON_SCRIPT="${PYTHON_DIR}/test_filtres_multiples.py"
REPORT_FILE="${SCRIPT_DIR}/../doc/demonstrations/21_FILTRES_MULTIPLES_DEMONSTRATION.md"

show_demo_header "Test Complexe P2-03 : Recherche avec Filtres Multiples Combinés"

info "📚 Ce test valide :"
echo "   ✅ Vector + Full-Text + Filtres (date, montant, catégorie) simultanément"
echo "   ✅ Optimisation requête (ordre des filtres)"
echo "   ✅ Performance avec filtres multiples"
echo "   ✅ Validation résultats (tous les filtres respectés)"

echo ""
info "🚀 Exécution du test..."

if python3 "${PYTHON_SCRIPT}" 2>&1 | tee /tmp/test_filtres_multiples_output.txt; then
    success "✅ Test terminé avec succès"
    
    # Génération du rapport
    info "📝 Génération du rapport..."
    export REPORT_FILE
    python3 << 'PYEOF'
import sys
import os
from datetime import datetime

report_file = os.environ.get('REPORT_FILE', '/tmp/report.md')
output_file = '/tmp/test_filtres_multiples_output.txt'

report = f"""# 🔍 Test Complexe P2-03 : Recherche avec Filtres Multiples Combinés

**Date** : {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}
**Script** : 21_test_filtres_multiples.sh

---

## 📊 Résumé Exécutif

Ce test valide la recherche avec filtres multiples :
- ✅ Vector + Full-Text + Filtres (date, montant, catégorie) simultanément
- ✅ Optimisation requête (ordre des filtres)
- ✅ Performance avec filtres multiples
- ✅ Validation résultats (tous les filtres respectés)

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
