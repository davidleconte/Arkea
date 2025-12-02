#!/bin/bash
# ============================================
# Script de Migration : Mise à jour des Scripts Shell
# ============================================
#
# Ce script met à jour automatiquement tous les scripts shell pour :
# 1. Remplacer les chemins hardcodés par la détection automatique
# 2. Ajouter set -euo pipefail au lieu de set -e
# 3. Remplacer localhost 9042 par $HCD_HOST $HCD_PORT
#
# UTILISATION :
#   ./migrate_scripts.sh [--dry-run]
#
# ============================================

set -euo pipefail

DRY_RUN="${1:-}"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

# Liste des scripts à migrer (exclure ce script et les archives)
SCRIPTS=$(find . -maxdepth 1 -name "*.sh" -type f ! -name "migrate_scripts.sh" | sort)

info() { echo "ℹ️  $1"; }
success() { echo "✅ $1"; }
warn() { echo "⚠️  $1"; }
error() { echo "❌ $1"; }

info "Début de la migration des scripts..."

for script in $SCRIPTS; do
    script_name=$(basename "$script")
    info "Traitement de $script_name..."

    # Créer une copie de sauvegarde
    if [ "$DRY_RUN" != "--dry-run" ]; then
        cp "$script" "${script}.bak"
    fi

    # Lire le contenu du script
    content=$(cat "$script")
    modified=false

    # 1. Remplacer set -e par set -euo pipefail (si pas déjà présent)
    if echo "$content" | grep -q "^set -e$" && ! echo "$content" | grep -q "set -euo pipefail"; then
        content=$(echo "$content" | sed 's/^set -e$/set -euo pipefail/')
        modified=true
        info "  → set -e remplacé par set -euo pipefail"
    fi

    # 2. Remplacer les chemins hardcodés INSTALL_DIR
        # Trouver la ligne avec INSTALL_DIR hardcodé
        # Remplacer par le bloc de détection automatique

        new_block='# Charger les fonctions utilitaires et configurer les chemins
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
if [ -f "${SCRIPT_DIR}/utils/didactique_functions.sh" ]; then
    source "${SCRIPT_DIR}/utils/didactique_functions.sh"
    setup_paths
else
    # Fallback si les fonctions ne sont pas disponibles
    SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    INSTALL_DIR="${ARKEA_HOME:-$(cd "$SCRIPT_DIR/../.." && pwd)}"
    HCD_DIR="${HCD_DIR:-${INSTALL_DIR}/binaire/hcd-1.2.3}"
    SPARK_HOME="${SPARK_HOME:-${INSTALL_DIR}/binaire/spark-3.5.1}"
    HCD_HOST="${HCD_HOST:-localhost}"
    HCD_PORT="${HCD_PORT:-9042}"
fi'

        # Remplacer le bloc (approximation - nécessite un traitement plus précis)
        content=$(echo "$content" | sed '/INSTALL_DIR="\/Users\/david\.leconte\/Documents\/Arkea"/,/HCD_DIR=/{
            /INSTALL_DIR=/c\
# Charger les fonctions utilitaires et configurer les chemins\
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"\
if [ -f "${SCRIPT_DIR}/utils/didactique_functions.sh" ]; then\
    source "${SCRIPT_DIR}/utils/didactique_functions.sh"\
    setup_paths\
else\
    # Fallback si les fonctions ne sont pas disponibles\
    SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"\
    INSTALL_DIR="${ARKEA_HOME:-$(cd "$SCRIPT_DIR/../.." && pwd)}"\
    HCD_DIR="${HCD_DIR:-${INSTALL_DIR}/binaire/hcd-1.2.3}"\
    SPARK_HOME="${SPARK_HOME:-${INSTALL_DIR}/binaire/spark-3.5.1}"\
    HCD_HOST="${HCD_HOST:-localhost}"\
    HCD_PORT="${HCD_PORT:-9042}"\
fi
            /HCD_DIR=/d
            /SPARK_HOME=/d
            /SCRIPT_DIR=/d
        }')
        modified=true
        info "  → Chemins hardcodés remplacés par détection automatique"
    fi

    # 3. Remplacer localhost 9042 par $HCD_HOST $HCD_PORT
    if echo "$content" | grep -q "localhost 9042"; then
        content=$(echo "$content" | sed 's/localhost 9042/"$HCD_HOST" "$HCD_PORT"/g')
        modified=true
        info "  → localhost 9042 remplacé par \$HCD_HOST \$HCD_PORT"
    fi

    if echo "$content" | grep -q "localhost:9042"; then
        content=$(echo "$content" | sed 's/localhost:9042/$HCD_HOST:$HCD_PORT/g')
        modified=true
        info "  → localhost:9042 remplacé par \$HCD_HOST:\$HCD_PORT"
    fi

    # 4. Ajouter vérification HCD si absente
    if ! echo "$content" | grep -q "check_hcd_prerequisites"; then
        # Chercher la première vérification HCD et la remplacer
        if echo "$content" | grep -q 'pgrep -f "cassandra"'; then
            content=$(echo "$content" | sed '/pgrep -f "cassandra"/{
                a\
# Vérifier les prérequis HCD\
if ! check_hcd_prerequisites 2>/dev/null; then
                N
                s/.*error.*HCD.*/    if ! pgrep -f "cassandra" > \/dev\/null; then\
        error "HCD n'\''est pas démarré. Exécutez d'\''abord: .\/03_start_hcd.sh"\
        exit 1\
    fi\
    if ! nc -z "$HCD_HOST" "$HCD_PORT" 2>\/dev\/null; then\
        error "HCD n'\''est pas accessible sur $HCD_HOST:$HCD_PORT"\
        exit 1\
    fi\
fi/
            }')
            modified=true
            info "  → Vérification HCD améliorée"
        fi
    fi

    # Écrire le contenu modifié
    if [ "$modified" = true ] && [ "$DRY_RUN" != "--dry-run" ]; then
        echo "$content" > "$script"
        success "  → $script_name mis à jour"
    elif [ "$modified" = true ]; then
        warn "  → $script_name serait modifié (dry-run)"
    else
        info "  → $script_name déjà à jour"
    fi
done

if [ "$DRY_RUN" != "--dry-run" ]; then
    success "Migration terminée ! Les fichiers originaux sont sauvegardés avec l'extension .bak"
else
    warn "Mode dry-run : aucun fichier n'a été modifié"
fi
