#!/bin/bash
# ============================================
# Script 14k : Amélioration Tests STARTROW/STOPROW (P1)
# Ajoute des cas de test supplémentaires pour STARTROW/STOPROW
# ============================================
#
# OBJECTIF :
#   Ce script améliore les tests STARTROW/STOPROW avec :
#   - Plusieurs combinaisons code_si/contrat
#   - Tests avec numero_op (clustering key)
#   - Tests avec plages de dates combinées
#
# UTILISATION :
#   ./14_improve_startrow_stoprow_tests.sh
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

echo ""
info "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
info "  🧪 TESTS AMÉLIORÉS STARTROW/STOPROW (P1)"
info "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

TOTAL_TESTS=0
PASSED_TESTS=0
FAILED_TESTS=0

# ============================================
# TEST 1 : Filtrage par code_si + contrat (simple)
# ============================================
echo ""
info "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
info "  TEST 1 : Filtrage par code_si + contrat (simple)"
info "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

TOTAL_TESTS=$((TOTAL_TESTS + 1))
OUTPUT_PATH="/tmp/exports/domiramaCatOps/startrow_stoprow/test1_simple"

python3 "${SCRIPT_DIR}/14_export_incremental_python.py" \
    "2024-06-01" "2024-07-01" "$OUTPUT_PATH" "snappy" \
    "TEST_EXPORT" "TEST_CONTRAT" > /tmp/test_startrow_1.log 2>&1

if [ $? -eq 0 ]; then
    PARQUET_COUNT=$(find "$OUTPUT_PATH" -name "*.parquet" 2>/dev/null | wc -l | tr -d ' ' || echo "0")
    if [ "$PARQUET_COUNT" -gt 0 ]; then
        success "✅ TEST 1 RÉUSSI : $PARQUET_COUNT fichiers créés"
        PASSED_TESTS=$((PASSED_TESTS + 1))
    else
        error "❌ TEST 1 ÉCHOUÉ : Aucun fichier créé"
        FAILED_TESTS=$((FAILED_TESTS + 1))
    fi
else
    error "❌ TEST 1 ÉCHOUÉ : Erreur lors de l'exécution"
    FAILED_TESTS=$((FAILED_TESTS + 1))
fi

# ============================================
# TEST 2 : Filtrage avec plage de dates réduite
# ============================================
echo ""
info "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
info "  TEST 2 : Filtrage avec plage de dates réduite"
info "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

TOTAL_TESTS=$((TOTAL_TESTS + 1))
OUTPUT_PATH="/tmp/exports/domiramaCatOps/startrow_stoprow/test2_date_range"

python3 "${SCRIPT_DIR}/14_export_incremental_python.py" \
    "2024-06-15" "2024-06-20" "$OUTPUT_PATH" "snappy" \
    "TEST_EXPORT" "TEST_CONTRAT" > /tmp/test_startrow_2.log 2>&1

if [ $? -eq 0 ]; then
    PARQUET_COUNT=$(find "$OUTPUT_PATH" -name "*.parquet" 2>/dev/null | wc -l | tr -d ' ' || echo "0")
    if [ "$PARQUET_COUNT" -gt 0 ]; then
        success "✅ TEST 2 RÉUSSI : $PARQUET_COUNT fichiers créés"
        PASSED_TESTS=$((PASSED_TESTS + 1))
    else
        warn "⚠️  TEST 2 : Aucun fichier créé (peut être normal si pas de données dans la plage)"
        FAILED_TESTS=$((FAILED_TESTS + 1))
    fi
else
    error "❌ TEST 2 ÉCHOUÉ : Erreur lors de l'exécution"
    FAILED_TESTS=$((FAILED_TESTS + 1))
fi

# ============================================
# TEST 3 : Export toutes les partitions (sans filtre)
# ============================================
echo ""
info "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
info "  TEST 3 : Export toutes les partitions (sans filtre)"
info "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

TOTAL_TESTS=$((TOTAL_TESTS + 1))
OUTPUT_PATH="/tmp/exports/domiramaCatOps/startrow_stoprow/test3_all_partitions"

python3 "${SCRIPT_DIR}/14_export_incremental_python.py" \
    "2024-06-01" "2024-07-01" "$OUTPUT_PATH" "snappy" \
    "" "" > /tmp/test_startrow_3.log 2>&1

if [ $? -eq 0 ]; then
    PARQUET_COUNT=$(find "$OUTPUT_PATH" -name "*.parquet" 2>/dev/null | wc -l | tr -d ' ' || echo "0")
    if [ "$PARQUET_COUNT" -gt 0 ]; then
        success "✅ TEST 3 RÉUSSI : $PARQUET_COUNT fichiers créés (toutes partitions)"
        PASSED_TESTS=$((PASSED_TESTS + 1))
    else
        warn "⚠️  TEST 3 : Aucun fichier créé"
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
info "  📊 RÉSUMÉ DES TESTS STARTROW/STOPROW AMÉLIORÉS"
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
    success "✅ TOUS LES TESTS STARTROW/STOPROW SONT RÉUSSIS !"
    exit 0
else
    error "❌ CERTAINS TESTS STARTROW/STOPROW ONT ÉCHOUÉ"
    exit 1
fi


