#!/bin/bash
# ============================================
# Script de Correction Systématique des Scripts
# ============================================
#
# Ce script corrige systématiquement tous les scripts .sh pour :
# - Standardiser l'utilisation de HCD_HOME vs HCD_DIR
# - Utiliser les fonctions didactiques standardisées
# - Corriger les chemins vers cqlsh
# - Ajouter les vérifications manquantes
#

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"

echo "🔧 Correction systématique des scripts en cours..."
echo ""

# Fonction pour corriger un script
fix_script() {
    local script=$1
    local fixed=0
    
    echo "📝 Correction de: $(basename "$script")"
    
    # 1. Remplacer HCD_DIR par HCD_HOME dans les nouveaux scripts (ceux qui utilisent les fonctions didactiques)
    if grep -q "source.*didactique_functions.sh" "$script" && grep -q "HCD_DIR=" "$script"; then
        # Garder HCD_DIR pour compatibilité mais utiliser HCD_HOME pour cqlsh
        if ! grep -q "HCD_HOME.*bin/cqlsh" "$script"; then
            sed -i.bak 's|"\$HCD_DIR"/bin/cqlsh|"${HCD_HOME:-$HCD_DIR}/bin/cqlsh|g' "$script"
            sed -i.bak 's|\./bin/cqlsh|"${HCD_HOME:-$HCD_DIR}/bin/cqlsh|g' "$script"
            fixed=1
        fi
    fi
    
    # 2. Ajouter source .poc-profile si manquant (pour scripts qui utilisent les fonctions didactiques)
    if grep -q "source.*didactique_functions.sh" "$script" && ! grep -q "source.*\.poc-profile" "$script"; then
        # Ajouter après le source didactique_functions.sh
        sed -i.bak '/source.*didactique_functions.sh/a\
source "$(dirname "${BASH_SOURCE[0]}")/../../.poc-profile"
' "$script"
        fixed=1
    fi
    
    # 3. Remplacer les vérifications manuelles par les fonctions standardisées
    if grep -q "pgrep -f.*cassandra" "$script" && grep -q "source.*didactique_functions.sh" "$script"; then
        if ! grep -q "check_hcd_status" "$script"; then
            # Remplacer la vérification manuelle par check_hcd_status
            sed -i.bak '/if ! pgrep -f "cassandra"/,/fi/d' "$script"
            # Ajouter check_hcd_status après show_partie ou au début
            if grep -q "show_partie.*VÉRIFICATIONS" "$script"; then
                sed -i.bak '/show_partie.*VÉRIFICATIONS/a\
check_hcd_status\
check_jenv_java_version
' "$script"
            else
                sed -i.bak '/source.*\.poc-profile/a\
\
# ============================================\
# VÉRIFICATIONS PRÉALABLES\
# ============================================\
check_hcd_status\
check_jenv_java_version
' "$script"
            fi
            fixed=1
        fi
    fi
    
    # 4. Corriger les scripts qui utilisent cqlsh sans chemin complet
    if grep -q "cqlsh" "$script" && ! grep -q "\$HCD_HOME.*cqlsh\|\$HCD_DIR.*cqlsh\|\./bin/cqlsh" "$script"; then
        # Déterminer quelle variable utiliser
        if grep -q "HCD_HOME" "$script"; then
            sed -i.bak 's|cqlsh|"${HCD_HOME}/bin/cqlsh"|g' "$script"
        elif grep -q "HCD_DIR" "$script"; then
            sed -i.bak 's|cqlsh|"${HCD_DIR}/bin/cqlsh"|g' "$script"
        else
            # Ajouter HCD_HOME
            sed -i.bak '/source.*\.poc-profile/a\
\
# HCD_HOME devrait être défini par .poc-profile\
HCD_DIR="${HCD_HOME:-${INSTALL_DIR}/binaire/hcd-1.2.3}"
' "$script"
            sed -i.bak 's|cqlsh|"${HCD_HOME:-$HCD_DIR}/bin/cqlsh"|g' "$script"
        fi
        fixed=1
    fi
    
    # 5. Standardiser l'utilisation de execute_cql_query pour les scripts récents
    if grep -q "source.*didactique_functions.sh" "$script" && grep -q "\$HCD_HOME.*cqlsh.*-e" "$script"; then
        # Remplacer les appels directs par execute_cql_query (optionnel, à faire manuellement)
        # Cette partie nécessite une analyse plus fine
        :
    fi
    
    if [ $fixed -eq 1 ]; then
        echo "   ✅ Corrigé"
        rm -f "${script}.bak"
    else
        echo "   ℹ️  Aucune correction nécessaire"
    fi
    echo ""
}

# Corriger tous les scripts
for script in "$SCRIPT_DIR"/*.sh; do
    if [ -f "$script" ] && [ "$(basename "$script")" != "FIX_SCRIPTS.sh" ] && [ "$(basename "$script")" != "AUDIT_SCRIPTS.sh" ]; then
        fix_script "$script"
    fi
done

echo "✅ Correction terminée !"


