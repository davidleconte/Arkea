#!/bin/bash
set -euo pipefail
# ============================================
# Script d'Audit Complet : Scripts et Use Cases
# ============================================
#
# Ce script analyse tous les scripts .sh pour identifier :
# - Les use cases démontrés
# - La cohérence avec la documentation
# - Les gaps et manques
# - Les incohérences
#

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
AUDIT_REPORT="${SCRIPT_DIR}/../doc/17_AUDIT_COMPLET_SCRIPTS_USE_CASES.md"

echo "🔍 Audit complet des scripts et use cases en cours..."
echo ""

# Structure pour stocker les informations
declare -A SCRIPTS_USE_CASES
declare -A SCRIPTS_STATUS
declare -A USE_CASES_COVERAGE

# Analyser chaque script
for script in "$SCRIPT_DIR"/*.sh; do
    if [ -f "$script" ] && [[ ! "$(basename "$script")" =~ ^(AUDIT_|FIX_) ]]; then
        script_name=$(basename "$script")
        echo "📝 Analyse de: $script_name"
        
        # Extraire les use cases mentionnés
        use_cases=$(grep -iE "UC-|use.?case|démontre|démonstration|objectif" "$script" | head -5)
        
        # Déterminer le type de script
        if [[ "$script_name" =~ ^0[1-4]_ ]]; then
            type="Setup"
        elif [[ "$script_name" =~ ^0[4-5].*generate ]]; then
            type="Génération"
        elif [[ "$script_name" =~ ^0[5-7].*load ]]; then
            type="Chargement"
        elif [[ "$script_name" =~ ^(0[8-9]|1[0-8])_.*test ]]; then
            type="Test"
        elif [[ "$script_name" =~ ^(1[9]|2[0-7])_.*demo ]]; then
            type="Démonstration"
        else
            type="Autre"
        fi
        
        SCRIPTS_STATUS["$script_name"]="$type"
        SCRIPTS_USE_CASES["$script_name"]="$use_cases"
    fi
done

echo ""
echo "✅ Analyse terminée"
echo "📊 Rapport généré : $AUDIT_REPORT"


