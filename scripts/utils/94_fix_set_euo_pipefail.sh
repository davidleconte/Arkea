#!/bin/bash
set -euo pipefail

# =============================================================================
# Script : Correction Automatique de set -euo pipefail
# =============================================================================
# Date : 2025-12-02
# Usage : ./94_fix_set_euo_pipefail.sh [--dry-run] [--directory DIR]
# Description : Ajoute set -euo pipefail aux scripts qui en manquent
# =============================================================================

# Récupérer le répertoire racine du projet
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]:-${0}}")" && pwd)"
ARKEA_HOME="$(cd "$SCRIPT_DIR/../.." && pwd)"

# Définir les fonctions de base
info() { echo -e "\033[0;32m[INFO]\033[0m $1"; }
warn() { echo -e "\033[1;33m[WARN]\033[0m $1"; }
error() { echo -e "\033[0;31m[ERROR]\033[0m $1"; }
section() { echo -e "\n\033[0;34m━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\033[0m\n\033[0;34m$1\033[0m\n\033[0;34m━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\033[0m\n"; }

# Variables de configuration
DRY_RUN=false
TARGET_DIR="${ARKEA_HOME}"

# Traitement des arguments
while [[ "$#" -gt 0 ]]; do
    case "$1" in
        --dry-run)
            DRY_RUN=true
            info "Mode DRY-RUN activé - Aucune modification ne sera appliquée."
            ;;
        --directory)
            if [ -n "$2" ] && [ -d "$2" ]; then
                TARGET_DIR="$2"
                shift
            else
                error "Erreur: L'option --directory nécessite un répertoire valide."
                exit 1
            fi
            ;;
        --help)
            echo "Usage: ./94_fix_set_euo_pipefail.sh [--dry-run] [--directory DIR]"
            echo ""
            echo "Options:"
            echo "  --dry-run    : Simule les corrections sans modifier les fichiers."
            echo "  --directory  : Répertoire cible (défaut: ARKEA_HOME)."
            echo "  --help       : Affiche ce message d'aide."
            exit 0
            ;;
        *)
            error "Option inconnue: $1"
            exit 1
            ;;
    esac
    shift
done

# Fonction pour corriger un script
fix_script() {
    local script="$1"
    local modified=false

    # Vérifier que c'est un script bash
    if ! head -1 "$script" | grep -q "^#!/bin/bash"; then
        return 0
    fi

    # Vérifier si set -euo pipefail existe déjà
    if head -5 "$script" | grep -q "set -euo pipefail"; then
        return 0
    fi

    # Vérifier si set -e existe (à remplacer)
    if head -5 "$script" | grep -q "^set -e$"; then
        if [ "$DRY_RUN" = true ]; then
            warn "[DRY-RUN] Remplacer 'set -e' par 'set -euo pipefail' dans $script"
        else
            # Remplacer set -e par set -euo pipefail
            if [[ "$OSTYPE" == "darwin"* ]]; then
                sed -i '' 's/^set -e$/set -euo pipefail/' "$script"
            else
                sed -i 's/^set -e$/set -euo pipefail/' "$script"
            fi
            info "Remplacé 'set -e' par 'set -euo pipefail' dans $script"
            modified=true
        fi
    else
        # Ajouter set -euo pipefail après le shebang
        if [ "$DRY_RUN" = true ]; then
            warn "[DRY-RUN] Ajouter 'set -euo pipefail' après le shebang dans $script"
        else
            # Créer un fichier temporaire
            local tmp_file=$(mktemp)
            {
                head -1 "$script"
                echo "set -euo pipefail"
                tail -n +2 "$script"
            } > "$tmp_file"
            mv "$tmp_file" "$script"
            info "Ajouté 'set -euo pipefail' dans $script"
            modified=true
        fi
    fi

    if [ "$modified" = true ] && [ "$DRY_RUN" = false ]; then
        return 0
    fi
}

# Exécution principale
section "Correction automatique de set -euo pipefail"

count=0
fixed=0

# Rechercher tous les scripts
while IFS= read -r -d '' script; do
    count=$((count + 1))
    if fix_script "$script"; then
        fixed=$((fixed + 1))
    fi
done < <(find "$TARGET_DIR" -type f -name "*.sh" ! -path "*/archive/*" ! -path "*/.git/*" ! -path "*/node_modules/*" -print0 2>/dev/null)

info "Processus terminé."
info "Scripts analysés : $count"
if [ "$DRY_RUN" = true ]; then
    info "Scripts à corriger : $fixed"
else
    info "Scripts corrigés : $fixed"
fi
