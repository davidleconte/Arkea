#!/bin/bash
set -euo pipefail
# ============================================
# Script de Correction : Mise à jour des liens après réorganisation
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

info "🔗 Mise à jour des liens dans tous les fichiers .md..."

UPDATED=0

# Fonction pour mettre à jour les liens dans un fichier
update_links() {
    local file="$1"
    local old_name="$2"
    local new_path="$3"

    if [ ! -f "$file" ]; then
        return
    fi

    local current_dir=$(dirname "$file")
    local relative_path

    # Calculer le chemin relatif
    if [[ "$current_dir" == "." ]]; then
        relative_path="$new_path"
    elif [[ "$current_dir" == *"demonstrations"* ]] || [[ "$current_dir" == *"templates"* ]]; then
        relative_path="../$new_path"
    else
        # Depuis une catégorie vers une autre
        relative_path="../$new_path"
    fi

    # Mettre à jour les liens markdown
    if grep -q "$old_name" "$file" 2>/dev/null; then
        # Pattern 1: [texte](fichier.md)
        sed -i.bak "s|(\\([^)]*\\)${old_name//\//\\/})|(\\1${relative_path//\//\\/})|g" "$file" 2>/dev/null || true
        # Pattern 2: [texte](../doc/fichier.md)
        sed -i.bak "s|(\\([^)]*\\)\\.\\./doc/${old_name//\//\\/})|(\\1../doc/${relative_path//\//\\/})|g" "$file" 2>/dev/null || true
        # Pattern 3: [texte](doc/fichier.md)
        sed -i.bak "s|(\\([^)]*\\)doc/${old_name//\//\\/})|(\\1doc/${relative_path//\//\\/})|g" "$file" 2>/dev/null || true
        rm -f "${file}.bak" 2>/dev/null || true
        ((UPDATED++))
    fi
}

# Créer le mapping
for category in design guides implementation results corrections audits; do
    if [ -d "$category" ]; then
        for file in "$category"/*.md; do
            if [ -f "$file" ]; then
                old_name=$(basename "$file")
                new_path="$category/$old_name"

                # Mettre à jour dans tous les fichiers
                for target_category in design guides implementation results corrections audits demonstrations templates; do
                    if [ -d "$target_category" ]; then
                        for target_file in "$target_category"/*.md; do
                            if [ -f "$target_file" ]; then
                                update_links "$target_file" "$old_name" "$new_path"
                            fi
                        done
                    fi
                done
            fi
        done
    fi
done

# Mettre à jour INDEX.md s'il existe
if [ -f "INDEX.md" ]; then
    for category in design guides implementation results corrections audits; do
        if [ -d "$category" ]; then
            for file in "$category"/*.md; do
                if [ -f "$file" ]; then
                    old_name=$(basename "$file")
                    new_path="$category/$old_name"
                    update_links "INDEX.md" "$old_name" "$new_path"
                fi
            done
        fi
    done
fi

success "Liens mis à jour : $UPDATED fichiers modifiés"
