#!/bin/bash
# ============================================
# Script de Nettoyage : Suppression des Fichiers .md Obsolètes
# Basé sur : 24_AUDIT_FICHIERS_OBSOLETES.md
# ============================================

set -e

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
cd "$SCRIPT_DIR"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

info() { echo -e "${BLUE}ℹ️  $1${NC}"; }
success() { echo -e "${GREEN}✅ $1${NC}"; }
error() { echo -e "${RED}❌ $1${NC}"; }
warn() { echo -e "${YELLOW}⚠️  $1${NC}"; }

# Compteurs
DELETED=0
MISSING=0

delete_file() {
    local file="$1"
    if [ -f "$file" ]; then
        rm -f "$file"
        success "Supprimé : $file"
        DELETED=$((DELETED + 1))
    else
        warn "Non trouvé (déjà supprimé ?) : $file"
        MISSING=$((MISSING + 1))
    fi
}

info "🧹 Nettoyage des fichiers .md obsolètes dans doc/"
echo ""

# Étape 1 : Fichiers corrections script 14
info "📋 Étape 1 : Suppression fichiers corrections script 14 (8 fichiers)"
delete_file "14_CORRECTIONS_APPLIQUEES.md"
delete_file "14_RAPPORT_VERIFICATION_FINAL.md"
delete_file "14_VERIFICATION_COMPLETE_TESTS.md"
delete_file "14_RESUME_AMELIORATIONS_IMPLÉMENTEES.md"
delete_file "14_RESUME_SOLUTION_PYTHON.md"
delete_file "14_SOLUTION_ALTERNATIVE_PYTHON.md"
delete_file "14_SYNTHESE_FINALE.md"
delete_file "14_IMPLEMENTATION_P1_P2.md"
echo ""

# Étape 2 : Audits spécifiques par script
info "📋 Étape 2 : Suppression audits spécifiques par script (7 fichiers)"
delete_file "AUDIT_SCRIPTS_09.md"
delete_file "AUDIT_SCRIPT_10.md"
delete_file "AUDIT_SCRIPT_11.md"
delete_file "AUDIT_SCRIPT_12_ANALYSE_PROBLEMES.md"
delete_file "AUDIT_COUVERTURE_SCRIPT_12_INPUTS.md"
delete_file "AUDIT_COUVERTURE_SCRIPT_13_INPUTS.md"
delete_file "AUDIT_COUVERTURE_SCRIPT_14_INPUTS.md"
echo ""

# Étape 3 : Analyses temporaires
info "📋 Étape 3 : Suppression analyses temporaires (3 fichiers)"
delete_file "ANALYSE_DONNEES_TEST.md"
delete_file "ANALYSE_COHERENCE_ACCEPTED_AT.md"
delete_file "SOLUTIONS_CONTAINS_KEY_CONTAINS.md"
echo ""

# Résumé
echo ""
info "📊 Résumé du nettoyage :"
success "Fichiers supprimés : $DELETED"
warn "Fichiers non trouvés (déjà supprimés ?) : $MISSING"
echo ""

# Comptage final
REMAINING=$(find . -maxdepth 1 -name "*.md" -type f | grep -v "^./demonstrations/" | grep -v "^./templates/" | wc -l | tr -d ' ')
info "Fichiers .md restants : $REMAINING"

if [ $DELETED -gt 0 ]; then
    success "✅ Nettoyage terminé avec succès !"
else
    warn "⚠️  Aucun fichier supprimé (tous déjà supprimés ?)"
fi

