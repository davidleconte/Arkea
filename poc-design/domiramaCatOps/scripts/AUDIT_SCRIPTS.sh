#!/bin/bash
set -euo pipefail
# ============================================
# Script d'Audit : Analyse de tous les scripts .sh
# ============================================
#
# Ce script analyse tous les scripts .sh pour identifier :
# - Erreurs de syntaxe
# - Incohérences (chemins, variables)
# - Gaps (fonctions manquantes, vérifications manquantes)
# - Problèmes de dépendances
#

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
AUDIT_REPORT="${SCRIPT_DIR}/../doc/AUDIT_SCRIPTS_COMPLET.md"

echo "🔍 Audit des scripts .sh en cours..."
echo ""

# Liste des problèmes identifiés
ISSUES=()

# Fonction pour détecter les problèmes
check_script() {
    local script=$1
    local issues=()
    
    # Vérifier si le script existe
    if [ ! -f "$script" ]; then
        echo "❌ Script non trouvé: $script"
        return
    fi
    
    # Vérifier les patterns problématiques
    if grep -q "HCD_DIR=" "$script" && ! grep -q "HCD_HOME" "$script"; then
        issues+=("Utilise HCD_DIR au lieu de HCD_HOME")
    fi
    
    if grep -q "source.*\.poc-profile" "$script" && ! grep -q "source.*\.\.\/\.\.\/\.poc-profile" "$script" && ! grep -q "source.*INSTALL_DIR.*\.poc-profile" "$script"; then
        issues+=("Chemin vers .poc-profile peut être incorrect")
    fi
    
    if ! grep -q "source.*didactique_functions.sh" "$script" && ! grep -q "check_hcd_status\|check_jenv_java_version" "$script"; then
        issues+=("N'utilise pas les fonctions didactiques standardisées")
    fi
    
    if grep -q "cd.*HCD_DIR" "$script" && ! grep -q "cd.*\$HCD_DIR" "$script"; then
        issues+=("Utilise cd avec HCD_DIR sans variable")
    fi
    
    if grep -q "cqlsh" "$script" && ! grep -q "\$HCD_HOME/bin/cqlsh\|HCD_DIR/bin/cqlsh\|\./bin/cqlsh" "$script"; then
        issues+=("Utilise cqlsh sans chemin complet")
    fi
    
    if [ ${#issues[@]} -gt 0 ]; then
        echo "⚠️  $script:"
        for issue in "${issues[@]}"; do
            echo "   - $issue"
        done
        ISSUES+=("$script: ${issues[*]}")
    fi
}

# Analyser tous les scripts
for script in "$SCRIPT_DIR"/*.sh; do
    if [ -f "$script" ]; then
        check_script "$script"
    fi
done

echo ""
echo "📊 Total de problèmes identifiés: ${#ISSUES[@]}"
echo ""


