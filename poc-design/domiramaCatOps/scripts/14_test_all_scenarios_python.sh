#!/bin/bash
# ============================================
# Script 14h : Tests Complets de Tous les Scénarios (Version Python)
# Exécute tous les tests complexes avec la solution Python
# ============================================
#
# OBJECTIF :
#   Ce script exécute tous les tests complexes identifiés dans l'audit
#   en utilisant la solution Python (alternative à DSBulk).
#
# UTILISATION :
#   ./14_test_all_scenarios_python.sh
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
info "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
info "  🎯 TESTS COMPLETS DE TOUS LES SCÉNARIOS - SCRIPT 14 (PYTHON)"
info "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Paramètres basés sur les données de test
CODE_SI="TEST_EXPORT"
CONTRAT="TEST_CONTRAT"
START_DATE="2024-06-01"
END_DATE="2024-07-01"

TOTAL_TESTS=0
PASSED_TESTS=0
FAILED_TESTS=0

# ============================================
# TEST 1 : Export TIMERANGE (par défaut)
# ============================================
echo ""
info "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
info "  TEST 1 : Export TIMERANGE (par défaut)"
info "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

TOTAL_TESTS=$((TOTAL_TESTS + 1))
OUTPUT_PATH="/tmp/exports/domiramaCatOps/test_all_python/TEST1_timerange"

python3 "${SCRIPT_DIR}/14_export_incremental_python.py" \
    "$START_DATE" "$END_DATE" "$OUTPUT_PATH" "snappy" \
    "$CODE_SI" "$CONTRAT" > /tmp/test1_python_output.log 2>&1

if [ $? -eq 0 ]; then
    PARQUET_COUNT=$(find "$OUTPUT_PATH" -name "*.parquet" 2>/dev/null | wc -l | tr -d ' ' || echo "0")
    if [ "$PARQUET_COUNT" -gt 0 ]; then
        success "✅ TEST 1 RÉUSSI : $PARQUET_COUNT fichiers Parquet créés"
        PASSED_TESTS=$((PASSED_TESTS + 1))
    else
        error "❌ TEST 1 ÉCHOUÉ : Aucun fichier Parquet créé"
        FAILED_TESTS=$((FAILED_TESTS + 1))
    fi
else
    error "❌ TEST 1 ÉCHOUÉ : Erreur lors de l'exécution"
    FAILED_TESTS=$((FAILED_TESTS + 1))
fi

# ============================================
# TEST 2 : Export STARTROW/STOPROW équivalent
# ============================================
echo ""
info "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
info "  TEST 2 : Export STARTROW/STOPROW équivalent"
info "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

TOTAL_TESTS=$((TOTAL_TESTS + 1))
OUTPUT_PATH="/tmp/exports/domiramaCatOps/test_all_python/TEST2_startrow_stoprow"

# Mode STARTROW/STOPROW : même script, mêmes paramètres (filtrage par partition)
python3 "${SCRIPT_DIR}/14_export_incremental_python.py" \
    "$START_DATE" "$END_DATE" "$OUTPUT_PATH" "snappy" \
    "$CODE_SI" "$CONTRAT" > /tmp/test2_python_output.log 2>&1

if [ $? -eq 0 ]; then
    PARQUET_COUNT=$(find "$OUTPUT_PATH" -name "*.parquet" 2>/dev/null | wc -l | tr -d ' ' || echo "0")
    if [ "$PARQUET_COUNT" -gt 0 ]; then
        success "✅ TEST 2 RÉUSSI : $PARQUET_COUNT fichiers Parquet créés"
        PASSED_TESTS=$((PASSED_TESTS + 1))
    else
        error "❌ TEST 2 ÉCHOUÉ : Aucun fichier Parquet créé"
        FAILED_TESTS=$((FAILED_TESTS + 1))
    fi
else
    error "❌ TEST 2 ÉCHOUÉ : Erreur lors de l'exécution"
    FAILED_TESTS=$((FAILED_TESTS + 1))
fi

# ============================================
# TEST 3 : Fenêtre glissante (mensuelle)
# ============================================
echo ""
info "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
info "  TEST 3 : Fenêtre glissante (mensuelle)"
info "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

TOTAL_TESTS=$((TOTAL_TESTS + 1))
OUTPUT_PATH="/tmp/exports/domiramaCatOps/test_all_python/TEST3_sliding_window"

# Utiliser le script de fenêtre glissante qui appelle le script Python
"${SCRIPT_DIR}/14_test_sliding_window_export.sh" "$START_DATE" "2024-08-31" "monthly" "$OUTPUT_PATH" "snappy" > /tmp/test3_python_output.log 2>&1

if [ $? -eq 0 ]; then
    PARQUET_COUNT=$(find "$OUTPUT_PATH" -name "*.parquet" 2>/dev/null | wc -l | tr -d ' ' || echo "0")
    if [ "$PARQUET_COUNT" -gt 0 ]; then
        success "✅ TEST 3 RÉUSSI : $PARQUET_COUNT fichiers Parquet créés"
        PASSED_TESTS=$((PASSED_TESTS + 1))
    else
        warn "⚠️  TEST 3 : Aucun fichier Parquet créé"
        FAILED_TESTS=$((FAILED_TESTS + 1))
    fi
else
    error "❌ TEST 3 ÉCHOUÉ : Erreur lors de l'exécution"
    FAILED_TESTS=$((FAILED_TESTS + 1))
fi

# ============================================
# RÉSUMÉ
# ============================================
echo ""
info "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
info "  📊 RÉSUMÉ DES TESTS"
info "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

info "Total tests : $TOTAL_TESTS"
success "Tests réussis : $PASSED_TESTS"
if [ $FAILED_TESTS -gt 0 ]; then
    error "Tests échoués : $FAILED_TESTS"
else
    success "Tests échoués : $FAILED_TESTS"
fi

SUCCESS_RATE=$((PASSED_TESTS * 100 / TOTAL_TESTS))
info "Taux de réussite : $SUCCESS_RATE%"

echo ""
if [ $FAILED_TESTS -eq 0 ]; then
    success "✅ TOUS LES TESTS SONT RÉUSSIS !"
    exit 0
else
    error "❌ CERTAINS TESTS ONT ÉCHOUÉ"
    exit 1
fi
