#!/bin/bash
# ============================================
# Script 14d : Tests Complets de Tous les Scénarios (Version Didactique)
# Exécute tous les tests complexes pour valider le fonctionnement complet
# ============================================
#
# OBJECTIF :
#   Ce script exécute tous les tests complexes identifiés dans l'audit
#   avec les paramètres adaptés aux données existantes.
#
# UTILISATION :
#   ./14_test_all_scenarios.sh
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
info "  🎯 TESTS COMPLETS DE TOUS LES SCÉNARIOS - SCRIPT 14"
info "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Paramètres basés sur les données réelles
CODE_SI="6"
CONTRAT_START="600000040"
CONTRAT_END="600000050"
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
OUTPUT_PATH="/tmp/exports/domiramaCatOps/test_all/TEST1_timerange"

"${SCRIPT_DIR}/14_test_incremental_export.sh" "$START_DATE" "$END_DATE" "$OUTPUT_PATH" "snappy" > /tmp/test1_output.log 2>&1

if [ $? -eq 0 ]; then
    PARQUET_COUNT=$(find "$OUTPUT_PATH" -name "*.parquet" -o -name "*.snappy.parquet" 2>/dev/null | wc -l | tr -d ' ' || echo "0")
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
OUTPUT_PATH="/tmp/exports/domiramaCatOps/test_all/TEST2_startrow_stoprow"

"${SCRIPT_DIR}/14_test_incremental_export.sh" "$START_DATE" "$END_DATE" "$OUTPUT_PATH" "snappy" \
  "$CODE_SI" "$CONTRAT_START" "$CONTRAT_END" > /tmp/test2_output.log 2>&1

if [ $? -eq 0 ]; then
    PARQUET_COUNT=$(find "$OUTPUT_PATH" -name "*.parquet" -o -name "*.snappy.parquet" 2>/dev/null | wc -l | tr -d ' ' || echo "0")
    if [ "$PARQUET_COUNT" -gt 0 ]; then
        success "✅ TEST 2 RÉUSSI : $PARQUET_COUNT fichiers Parquet créés"
        PASSED_TESTS=$((PASSED_TESTS + 1))
    else
        warn "⚠️  TEST 2 : Aucun fichier Parquet créé (peut être normal si aucune donnée ne correspond)"
        # Vérifier si c'est normal (aucune donnée) ou une erreur
        if grep -q "0 opérations exportées" /tmp/test2_output.log; then
            warn "   Explication : Aucune donnée ne correspond aux critères de filtrage"
        else
            error "❌ TEST 2 ÉCHOUÉ : Erreur inattendue"
            FAILED_TESTS=$((FAILED_TESTS + 1))
        fi
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
OUTPUT_PATH="/tmp/exports/domiramaCatOps/test_all/TEST3_sliding_window"

"${SCRIPT_DIR}/14_test_sliding_window_export.sh" "$START_DATE" "2024-08-31" "monthly" "$OUTPUT_PATH" "snappy" > /tmp/test3_output.log 2>&1

if [ $? -eq 0 ]; then
    PARQUET_COUNT=$(find "$OUTPUT_PATH" -name "*.parquet" -o -name "*.snappy.parquet" 2>/dev/null | wc -l | tr -d ' ' || echo "0")
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


