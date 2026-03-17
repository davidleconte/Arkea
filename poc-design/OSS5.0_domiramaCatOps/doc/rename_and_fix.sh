#!/bin/bash
set -euo pipefail
# ============================================
# Script de Renommage et Correction - Fichiers .md
# Basé sur : 25_AUDIT_RENOMMAGE_ENRICHISSEMENT.md
# ============================================

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

# Phase 1 : Renumérotation Critique (14 → 13)
info "🔄 Phase 1 : Renumérotation Critique (14 → 13)"
echo ""

if [ -f "14_AUDIT_COMPLET_USE_CASES_MECE.md" ]; then
    mv "14_AUDIT_COMPLET_USE_CASES_MECE.md" "13_AUDIT_COMPLET_USE_CASES_MECE.md"
    success "Renommé : 14_AUDIT_COMPLET_USE_CASES_MECE.md → 13_AUDIT_COMPLET_USE_CASES_MECE.md"
else
    warn "Fichier non trouvé : 14_AUDIT_COMPLET_USE_CASES_MECE.md (déjà renommé ?)"
fi

echo ""

# Phase 2 : Mise à jour des références
info "🔗 Phase 2 : Mise à jour des références vers 13_AUDIT_COMPLET_USE_CASES_MECE.md"
echo ""

REFERENCE_COUNT=0

# Chercher et remplacer les références
for file in *.md; do
    if [ -f "$file" ] && grep -q "14_AUDIT_COMPLET_USE_CASES_MECE" "$file" 2>/dev/null; then
        sed -i.bak "s/14_AUDIT_COMPLET_USE_CASES_MECE/13_AUDIT_COMPLET_USE_CASES_MECE/g" "$file"
        rm -f "${file}.bak"
        success "Mis à jour : $file"
        ((REFERENCE_COUNT++))
    fi
done

if [ $REFERENCE_COUNT -eq 0 ]; then
    warn "Aucune référence trouvée à mettre à jour"
else
    success "Références mises à jour : $REFERENCE_COUNT fichier(s)"
fi

echo ""

# Résumé
info "📊 Résumé des actions :"
success "✅ Renumérotation critique effectuée"
success "✅ Références mises à jour : $REFERENCE_COUNT fichier(s)"

echo ""
success "✅ Script terminé avec succès !"
warn "⚠️  Note : Les autres actions (enrichissement, corrections) doivent être faites manuellement"
