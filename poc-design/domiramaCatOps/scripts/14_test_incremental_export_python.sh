#!/bin/bash
# ============================================
# Script 14g : Wrapper Bash pour Export Python
# Wrapper pour utiliser le script Python d'export
# ============================================
#
# OBJECTIF :
#   Ce script est un wrapper bash pour le script Python d'export.
#   Il permet d'utiliser le script Python avec la même interface que le script bash.
#
# UTILISATION :
#   ./14_test_incremental_export_python.sh [start_date] [end_date] [output_path] [compression] [code_si] [contrat]
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

START_DATE="${1:-2024-06-01}"
END_DATE="${2:-2024-07-01}"
OUTPUT_PATH="${3:-/tmp/exports/domiramaCatOps/incremental_python}"
COMPRESSION="${4:-snappy}"
CODE_SI="${5:-}"
CONTRAT="${6:-}"

echo ""
info "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
info "  🎯 Export Incrémental Parquet (Version Python)"
info "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Vérifier que Python 3 est disponible
if ! command -v python3 &> /dev/null; then
    error "Python 3 n'est pas installé"
    exit 1
fi

# Vérifier que les modules Python sont installés
python3 << PYCHECK
import sys
missing = []
try:
    import cassandra
except ImportError:
    missing.append("cassandra-driver")
try:
    import pyarrow
except ImportError:
    missing.append("pyarrow")
try:
    import pandas
except ImportError:
    missing.append("pandas")

if missing:
    print(f"❌ Modules Python manquants : {', '.join(missing)}")
    print("   Installation : pip3 install cassandra-driver pyarrow pandas")
    sys.exit(1)
PYCHECK

if [ $? -ne 0 ]; then
    error "Modules Python manquants. Installation requise : pip3 install cassandra-driver pyarrow pandas"
    exit 1
fi

# Exécuter le script Python
info "🚀 Exécution du script Python..."
echo ""

python3 "${SCRIPT_DIR}/14_export_incremental_python.py" \
    "$START_DATE" \
    "$END_DATE" \
    "$OUTPUT_PATH" \
    "$COMPRESSION" \
    "${CODE_SI:-}" \
    "${CONTRAT:-}"

EXIT_CODE=$?

if [ $EXIT_CODE -eq 0 ]; then
    # Vérifier les fichiers Parquet créés
    PARQUET_COUNT=$(find "$OUTPUT_PATH" -name "*.parquet" 2>/dev/null | wc -l | tr -d ' ' || echo "0")
    
    if [ "$PARQUET_COUNT" -gt 0 ]; then
        success "✅ Export réussi : $PARQUET_COUNT fichiers Parquet créés"
        info "   Répertoire : $OUTPUT_PATH"
    else
        warn "⚠️  Aucun fichier Parquet créé"
    fi
else
    error "❌ Erreur lors de l'export"
    exit 1
fi

echo ""
success "✅ Export terminé"
