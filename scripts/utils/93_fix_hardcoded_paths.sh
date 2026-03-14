#!/bin/bash
set -euo pipefail

# =============================================================================
# Script : Correction Automatique des Chemins Hardcodés
# =============================================================================
# Date : 2025-12-02
# Usage : ./93_fix_hardcoded_paths.sh [--dry-run] [--file FILE] [--help]
# Description : Corrige automatiquement les chemins hardcodés dans les fichiers
# =============================================================================

# Récupérer le répertoire racine du projet
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]:-${0}}")" && pwd)"
ARKEA_HOME="$(cd "$SCRIPT_DIR/../.." && pwd)"

# Charger les fonctions portables si disponibles
if [ -f "$ARKEA_HOME/scripts/utils/portable_functions.sh" ]; then
    source "$ARKEA_HOME/scripts/utils/portable_functions.sh"
else
    # Définir des fonctions de base si portable_functions.sh n'est pas disponible
    info() { echo -e "\033[0;32m[INFO]\033[0m $1"; }
    warn() { echo -e "\033[1;33m[WARN]\033[0m $1"; }
    error() { echo -e "\033[0;31m[ERROR]\033[0m $1"; }
    section() { echo -e "\n\033[0;34m━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\033[0m\n\033[0;34m$1\033[0m\n\033[0;34m━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\033[0m\n"; }
fi

# Variables de configuration
DRY_RUN=false
TARGET_FILE=""
BACKUP_DIR="${ARKEA_HOME}/.backup_hardcoded_paths_$(date +%Y%m%d_%H%M%S)"

# Patterns de chemins hardcodés à corriger
declare -A HARDCODED_PATTERNS=(
    ["${ARKEA_HOME}"]="\${ARKEA_HOME}"
    ["${USER_HOME:-$HOME}"]="\${USER_HOME:-$HOME}"
    ["/opt/homebrew"]="\${HOMEBREW_PREFIX:-/opt/homebrew}"
    ["INSTALL_DIR=\"${ARKEA_HOME}\""]="INSTALL_DIR=\"\${ARKEA_HOME}\""
    ["INSTALL_DIR=${ARKEA_HOME}"]="INSTALL_DIR=\${ARKEA_HOME}"
)

# =============================================================================
# Traitement des arguments
# =============================================================================

print_help() {
    echo "Usage: ./93_fix_hardcoded_paths.sh [OPTIONS]"
    echo ""
    echo "Options:"
    echo "  --dry-run    : Simule les corrections sans modifier les fichiers"
    echo "  --file FILE  : Corrige uniquement le fichier spécifié"
    echo "  --help       : Affiche ce message d'aide"
    echo ""
    echo "Exemples:"
    echo "  ./93_fix_hardcoded_paths.sh --dry-run"
    echo "  ./93_fix_hardcoded_paths.sh --file docs/CONFIGURATION_ENVIRONNEMENT.md"
    echo "  ./93_fix_hardcoded_paths.sh"
}

while [[ "$#" -gt 0 ]]; do
    case "$1" in
        --dry-run)
            DRY_RUN=true
            info "Mode DRY-RUN activé - Aucune modification ne sera effectuée"
            ;;
        --file)
            if [ -n "${2:-}" ] && [ -f "$2" ]; then
                TARGET_FILE="$2"
                shift
            else
                error "Erreur: L'option --file nécessite un fichier valide."
                print_help
                exit 1
            fi
            ;;
        --help)
            print_help
            exit 0
            ;;
        *)
            error "Option inconnue: $1"
            print_help
            exit 1
            ;;
    esac
    shift
done

# =============================================================================
# Fonction : Créer une sauvegarde
# =============================================================================

create_backup() {
    local file="$1"
    local backup_file="${BACKUP_DIR}${file#$ARKEA_HOME}"
    local backup_dir
    backup_dir="$(dirname "$backup_file")"

    if [ "$DRY_RUN" = false ]; then
        mkdir -p "$backup_dir"
        cp "$file" "$backup_file"
    fi
}

# =============================================================================
# Fonction : Corriger un fichier
# =============================================================================

fix_file() {
    local file="$1"
    local rel_path="${file#$ARKEA_HOME/}"
    local modified=false
    local changes=()

    # Vérifier si le fichier contient des chemins hardcodés
    local has_hardcoded=false
    for pattern in "${!HARDCODED_PATTERNS[@]}"; do
        if grep -q "$pattern" "$file" 2>/dev/null; then
            has_hardcoded=true
            break
        fi
    done

    if [ "$has_hardcoded" = false ]; then
        return 0
    fi

    # Créer une sauvegarde
    create_backup "$file"

    # Créer un fichier temporaire pour les modifications
    local temp_file="${file}.tmp"
    cp "$file" "$temp_file"

    # Appliquer les corrections
    for pattern in "${!HARDCODED_PATTERNS[@]}"; do
        local replacement="${HARDCODED_PATTERNS[$pattern]}"

        # Échapper les caractères spéciaux pour sed
        local escaped_pattern
        escaped_pattern=$(printf '%s\n' "$pattern" | sed 's/[[\.*^$()+?{|]/\\&/g')
        local escaped_replacement
        escaped_replacement=$(printf '%s\n' "$replacement" | sed 's/[[\.*^$()+?{|]/\\&/g')

        if grep -q "$pattern" "$temp_file" 2>/dev/null; then
            # Utiliser sed pour remplacer (compatible macOS et Linux)
            if [[ "$OSTYPE" == "darwin"* ]]; then
                sed -i '' "s|$escaped_pattern|$escaped_replacement|g" "$temp_file"
            else
                sed -i "s|$escaped_pattern|$escaped_replacement|g" "$temp_file"
            fi

            changes+=("$pattern → $replacement")
            modified=true
        fi
    done

    if [ "$modified" = true ]; then
        if [ "$DRY_RUN" = true ]; then
            info "[DRY-RUN] Corrigerait: $rel_path"
            for change in "${changes[@]}"; do
                echo "    - $change"
            done
        else
            mv "$temp_file" "$file"
            info "Corrigé: $rel_path"
            for change in "${changes[@]}"; do
                echo "    - $change"
            done
        fi
    else
        rm -f "$temp_file"
    fi
}

# =============================================================================
# Fonction : Trouver les fichiers à corriger
# =============================================================================

find_files_to_fix() {
    local files=()

    if [ -n "$TARGET_FILE" ]; then
        # Fichier spécifique
        if [ -f "$TARGET_FILE" ]; then
            files+=("$TARGET_FILE")
        else
            error "Fichier non trouvé: $TARGET_FILE"
            exit 1
        fi
    else
        # Rechercher tous les fichiers avec chemins hardcodés
        while IFS= read -r file; do
            if [ -f "$file" ]; then
                # Vérifier si le fichier contient des chemins hardcodés
                for pattern in "${!HARDCODED_PATTERNS[@]}"; do
                    if grep -q "$pattern" "$file" 2>/dev/null; then
                        files+=("$file")
                        break
                    fi
                done
            fi
        done < <(find "$ARKEA_HOME" -type f \
            ! -path "$ARKEA_HOME/.git/*" \
            ! -path "$ARKEA_HOME/binaire/*" \
            ! -path "$ARKEA_HOME/software/*" \
            ! -path "$ARKEA_HOME/logs/*" \
            ! -path "*/archive/*" \
            \( -name "*.sh" -o -name "*.md" -o -name "*.py" \) 2>/dev/null)
    fi

    printf '%s\n' "${files[@]}" | sort -u
}

# =============================================================================
# Exécution principale
# =============================================================================

section "Correction Automatique des Chemins Hardcodés - ARKEA"

info "Répertoire ARKEA: $ARKEA_HOME"

if [ "$DRY_RUN" = false ]; then
    mkdir -p "$BACKUP_DIR"
    info "Sauvegarde créée: $BACKUP_DIR"
fi

# Trouver les fichiers à corriger
mapfile -t files_to_fix < <(find_files_to_fix)

if [ ${#files_to_fix[@]} -eq 0 ]; then
    info "Aucun fichier avec chemins hardcodés détecté"
    exit 0
fi

info "${#files_to_fix[@]} fichier(s) à corriger"

# Corriger chaque fichier
fixed_count=0
for file in "${files_to_fix[@]}"; do
    if fix_file "$file"; then
        fixed_count=$((fixed_count + 1))
    fi
done

section "✅ Correction terminée"

if [ "$DRY_RUN" = true ]; then
    info "[DRY-RUN] $fixed_count fichier(s) seraient corrigés"
    info "Pour exécuter réellement, relancez sans --dry-run"
else
    info "$fixed_count fichier(s) corrigé(s)"
    info "Sauvegarde disponible dans: $BACKUP_DIR"
fi
