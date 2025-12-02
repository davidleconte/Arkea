#!/bin/bash
# =============================================================================
# Script de Migration : Remplacement des Chemins Hardcodés
# =============================================================================
# Remplace tous les INSTALL_DIR hardcodés par setup_paths()
# Date : 2025-12-01
# =============================================================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ARKEA_HOME="${ARKEA_HOME:-$(cd "$SCRIPT_DIR/.." && pwd)}"

# Couleurs
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

info() { echo -e "${BLUE}ℹ️  $1${NC}"; }
success() { echo -e "${GREEN}✅ $1${NC}"; }
warn() { echo -e "${YELLOW}⚠️  $1${NC}"; }
error() { echo -e "${RED}❌ $1${NC}"; }

# Pattern à rechercher

# Répertoires à traiter
DIRS=(
    "$ARKEA_HOME/poc-design/domirama2/scripts"
    "$ARKEA_HOME/poc-design/domiramaCatOps/scripts"
    "$ARKEA_HOME/poc-design/domirama"
    "$ARKEA_HOME"
)

# Fonction pour vérifier si un script a déjà setup_paths()
has_setup_paths() {
    local file="$1"
    grep -q "setup_paths" "$file" 2>/dev/null || return 1
}

# Fonction pour vérifier si un script a INSTALL_DIR hardcodé
has_hardcoded_install_dir() {
    local file="$1"
    grep -qE "$HARDCODED_PATTERN|$HARDCODED_PATTERN_ALT" "$file" 2>/dev/null || return 1
}

# Fonction pour ajouter setup_paths() après set -euo pipefail
add_setup_paths() {
    local file="$1"
    local temp_file="${file}.tmp"
    
    # Lire le contenu
    local content
    content=$(cat "$file")
    
    # Vérifier si set -euo pipefail existe
    if ! echo "$content" | grep -q "^set -euo pipefail"; then
        warn "  ⚠️  Pas de 'set -euo pipefail' dans $file"
        return 1
    fi
    
    # Créer le bloc setup_paths
    local setup_block='# Configuration - Utiliser setup_paths si disponible
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
if [ -f "$SCRIPT_DIR/../utils/didactique_functions.sh" ]; then
    source "$SCRIPT_DIR/../utils/didactique_functions.sh"
    setup_paths
else
    # Fallback si les fonctions ne sont pas disponibles
    INSTALL_DIR="${ARKEA_HOME:-$(cd "$SCRIPT_DIR/../.." && pwd)}"
    HCD_DIR="${HCD_DIR:-${INSTALL_DIR}/binaire/hcd-1.2.3}"
    SPARK_HOME="${SPARK_HOME:-${INSTALL_DIR}/binaire/spark-3.5.1}"
    HCD_HOST="${HCD_HOST:-localhost}"
    HCD_PORT="${HCD_PORT:-9042}"
fi'
    
    # Insérer après set -euo pipefail
    local new_content
    new_content=$(echo "$content" | sed "/^set -euo pipefail/a\\
$setup_block")
    
    # Écrire le nouveau contenu
    echo "$new_content" > "$temp_file"
    mv "$temp_file" "$file"
}

# Fonction de remplacement
replace_hardcoded_paths() {
    local file="$1"
    local temp_file="${file}.tmp"
    
    # Lire le fichier
    local content
    content=$(cat "$file")
    
    # Vérifier si le fichier contient le pattern
    if ! has_hardcoded_install_dir "$file"; then
        return 0  # Pas de remplacement nécessaire
    fi
    
    # Si setup_paths n'existe pas, l'ajouter
    if ! has_setup_paths "$file"; then
        info "  ➕ Ajout de setup_paths() dans $file"
        add_setup_paths "$file"
        content=$(cat "$file")  # Relire après modification
    fi
    
    # Supprimer les lignes INSTALL_DIR hardcodées
    local new_content
    new_content=$(echo "$content" | sed -E "
        /INSTALL_DIR=.*\"\/Users\/david\.leconte\/Documents\/Arkea\"/d
        /INSTALL_DIR=.*\"\/Users\/david\.leconte/d
    ")
    
    # Écrire le nouveau contenu
    echo "$new_content" > "$temp_file"
    mv "$temp_file" "$file"
    
    success "  ✅ Migré: $(basename "$file")"
    return 0
}

# Fonction principale de traitement
process_file() {
    local file="$1"
    local relative_path="${file#$ARKEA_HOME/}"
    
    # Ignorer les fichiers de backup
    if [[ "$file" == *.bak ]] || [[ "$file" == *.tmp ]] || [[ "$file" == *archive* ]]; then
        return 0
    fi
    
    # Ignorer les fichiers non-shell
    if [[ "$file" != *.sh ]]; then
        return 0
    fi
    
    # Vérifier si le fichier a des chemins hardcodés
    if has_hardcoded_install_dir "$file"; then
        info "  📝 Traitement: $relative_path"
        replace_hardcoded_paths "$file"
        return 0
    fi
    
    return 0
}

# Fonction principale
main() {
    info "🚀 Démarrage de la migration des chemins hardcodés"
    info "   ARKEA_HOME: $ARKEA_HOME"
    echo ""
    
    local total_files=0
    local migrated_files=0
    local skipped_files=0
    
    # Traiter tous les fichiers
    for dir in "${DIRS[@]}"; do
        if [ ! -d "$dir" ]; then
            warn "  ⚠️  Répertoire non trouvé: $dir"
            continue
        fi
        
        info "📁 Traitement de: ${dir#$ARKEA_HOME/}"
        
        while IFS= read -r -d '' file; do
            total_files=$((total_files + 1))
            if process_file "$file"; then
                migrated_files=$((migrated_files + 1))
            else
                skipped_files=$((skipped_files + 1))
            fi
        done < <(find "$dir" -type f -name "*.sh" -print0 2>/dev/null || true)
        
        echo ""
    done
    
    # Résumé
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    success "✅ Migration terminée"
    info "   Fichiers traités: $total_files"
    success "   Fichiers migrés: $migrated_files"
    info "   Fichiers ignorés: $skipped_files"
    echo ""
    info "💡 Prochaines étapes:"
    info "   1. Vérifier que tous les scripts fonctionnent"
    info "   2. Tester sur une machine différente si possible"
    info "   3. Mettre à jour .poc-profile pour utiliser .poc-config.sh"
    echo ""
}

# Exécuter
main "$@"
