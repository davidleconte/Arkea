#!/bin/bash
# ============================================
# Script 20 : Test Complexe P1-04 - Cohérence Transactionnelle Multi-Tables
# Test de cohérence transactionnelle entre plusieurs tables
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
PYTHON_SCRIPT="${PYTHON_DIR}/test_coherence_transactionnelle.py"
REPORT_FILE="${SCRIPT_DIR}/../doc/demonstrations/20_COHERENCE_TRANSACTIONNELLE_DEMONSTRATION.md"

show_demo_header "Test Complexe P1-04 : Cohérence Transactionnelle Multi-Tables"

info "📚 Ce test valide :"
echo "   ✅ Cohérence référentielle (foreign keys équivalents)"
echo "   ✅ Cohérence temporelle (dates cohérentes)"
echo "   ✅ Cohérence compteurs (feedbacks_count = SUM feedbacks)"
echo "   ✅ Cohérence historique (historique_opposition → opposition_categorisation)"
echo "   ✅ Cohérence règles (cat_auto doit exister dans regles_personnalisees)"

echo ""
info "🚀 Exécution du test..."

if python3 "${PYTHON_SCRIPT}" 2>&1 | tee /tmp/test_coherence_transactionnelle_output.txt; then
    success "✅ Test terminé avec succès"
    
    # Génération du rapport
    info "📝 Génération du rapport..."
    python3 << 'PYEOF'
import sys
import os
from datetime import datetime

report_file = os.environ.get('REPORT_FILE', '/tmp/report.md')
output_file = '/tmp/test_coherence_transactionnelle_output.txt'

report = f"""# 🔍 Test Complexe P1-04 : Cohérence Transactionnelle Multi-Tables

**Date** : {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}
**Script** : 20_test_coherence_transactionnelle.sh

---

## 📊 Résumé Exécutif

Ce test valide la cohérence transactionnelle entre plusieurs tables :
- ✅ Cohérence référentielle (foreign keys équivalents)
- ✅ Cohérence temporelle (dates cohérentes)
- ✅ Cohérence compteurs (feedbacks_count = SUM feedbacks)
- ✅ Cohérence historique (historique_opposition → opposition_categorisation)
- ✅ Cohérence règles (cat_auto doit exister dans regles_personnalisees)

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

