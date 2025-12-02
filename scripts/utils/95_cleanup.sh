#!/bin/bash
# =============================================================================
# Script de Nettoyage Automatique - ARKEA
# =============================================================================
# Date : 2025-12-02
# Usage : ./scripts/utils/95_cleanup.sh [--dry-run] [--age DAYS]
# =============================================================================

set -eo pipefail
# Note: 'u' désactivé pour permettre des variables optionnelles

# =============================================================================
# Configuration
# =============================================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ARKEA_HOME="$(cd "$SCRIPT_DIR/../.." && pwd)"

# Options par défaut
DRY_RUN=false
UNLOAD_AGE_DAYS=30  # Supprimer les UNLOAD_* de plus de 30 jours

# =============================================================================
# Fonctions Utilitaires
# =============================================================================

# Note: portable_functions.sh non chargé pour éviter les conflits
# Les fonctions d'affichage sont définies ci-dessous

# Définir les fonctions d'affichage (avec fallback si portable_functions.sh n'est pas disponible)
info() {
    if [ -n "${GREEN:-}" ] && [ -n "${NC:-}" ]; then
        echo -e "${GREEN}[INFO]${NC} $1"
    else
        echo "[INFO] $1"
    fi
}

warn() {
    if [ -n "${YELLOW:-}" ] && [ -n "${NC:-}" ]; then
        echo -e "${YELLOW}[WARN]${NC} $1"
    else
        echo "[WARN] $1"
    fi
}

error() {
    if [ -n "${RED:-}" ] && [ -n "${NC:-}" ]; then
        echo -e "${RED}[ERROR]${NC} $1"
    else
        echo "[ERROR] $1"
    fi
}

section() {
    if [ -n "${BLUE:-}" ] && [ -n "${NC:-}" ]; then
        echo -e "\n${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
        echo -e "${BLUE}$1${NC}"
        echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}\n"
    else
        echo ""
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        echo "$1"
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        echo ""
    fi
}

# =============================================================================
# Parsing des Arguments
# =============================================================================

while [[ $# -gt 0 ]]; do
    case $1 in
        --dry-run)
            DRY_RUN=true
            shift
            ;;
        --age)
            UNLOAD_AGE_DAYS="$2"
            shift 2
            ;;
        -h|--help)
            cat << EOF
Usage: $0 [OPTIONS]

Options:
    --dry-run          Afficher les actions sans les exécuter
    --age DAYS         Supprimer les UNLOAD_* de plus de DAYS jours (défaut: 30)
    -h, --help         Afficher cette aide

Exemples:
    $0                    # Nettoyage normal
    $0 --dry-run          # Simulation sans exécution
    $0 --age 7            # Supprimer les UNLOAD_* de plus de 7 jours
EOF
            exit 0
            ;;
        *)
            error "Option inconnue: $1"
            exit 1
            ;;
    esac
done

# =============================================================================
# Fonction de Nettoyage UNLOAD_*
# =============================================================================

cleanup_unloads() {
    section "Nettoyage des répertoires UNLOAD_*"

    local logs_dir="$ARKEA_HOME/logs/archive"
    local count=0
    local total_size=0

    if [ ! -d "$logs_dir" ]; then
        warn "Répertoire $logs_dir n'existe pas"
        return 0
    fi

    # Trouver tous les répertoires UNLOAD_* de plus de X jours
    if command -v find >/dev/null 2>&1; then
        while IFS= read -r unload_dir; do
            [ -z "$unload_dir" ] && continue

            # Extraire la date du nom (format: UNLOAD_YYYYMMDD-HHMMSS-XXXXXX)
            local dirname=$(basename "$unload_dir")
            if [[ "$dirname" =~ UNLOAD_([0-9]{8})- ]]; then
                local date_str="${BASH_REMATCH[1]}"
                local year="${date_str:0:4}"
                local month="${date_str:4:2}"
                local day="${date_str:6:2}"

                # Convertir en timestamp
                if [[ "$OSTYPE" == "darwin"* ]]; then
                    # macOS
                    local dir_timestamp=$(date -j -f "%Y-%m-%d" "$year-$month-$day" "+%s" 2>/dev/null || echo "0")
                else
                    # Linux
                    local dir_timestamp=$(date -d "$year-$month-$day" "+%s" 2>/dev/null || echo "0")
                fi

                local current_timestamp=$(date "+%s")
                local age_seconds=$((current_timestamp - dir_timestamp))
                local age_days=$((age_seconds / 86400))

                if [ "$age_days" -gt "$UNLOAD_AGE_DAYS" ]; then
                    local size=$(du -sk "$unload_dir" 2>/dev/null | cut -f1 || echo "0")
                    total_size=$((total_size + size))
                    count=$((count + 1))

                    if [ "$DRY_RUN" = true ]; then
                        info "[DRY-RUN] Supprimerait: $unload_dir (âge: ${age_days} jours, taille: ${size} KB)"
                    else
                        info "Suppression: $unload_dir (âge: ${age_days} jours, taille: ${size} KB)"
                        rm -rf "$unload_dir"
                    fi
                else
                    info "Conservé: $unload_dir (âge: ${age_days} jours < ${UNLOAD_AGE_DAYS} jours)"
                fi
            fi
        done < <(find "$logs_dir" -type d -name "UNLOAD_*" 2>/dev/null)
    fi

    if [ "$count" -eq 0 ]; then
        info "Aucun répertoire UNLOAD_* à supprimer"
    else
        if [ "$DRY_RUN" = true ]; then
            info "[DRY-RUN] $count répertoire(s) seraient supprimés (taille totale: ${total_size} KB)"
        else
            info "✅ $count répertoire(s) supprimé(s) (taille totale: ${total_size} KB)"
        fi
    fi
}

# =============================================================================
# Fonction de Nettoyage des Fichiers Temporaires
# =============================================================================

cleanup_temp_files() {
    section "Nettoyage des fichiers temporaires"

    local temp_patterns=(
        "*.tmp"
        "*.temp"
        "*.bak"
        "*.swp"
        "*.swo"
        "*~"
    )

    local count=0

    for pattern in "${temp_patterns[@]}"; do
        while IFS= read -r file; do
            [ -z "$file" ] && continue

            if [ "$DRY_RUN" = true ]; then
                info "[DRY-RUN] Supprimerait: $file"
            else
                info "Suppression: $file"
                rm -f "$file"
            fi
            count=$((count + 1))
        done < <(find "$ARKEA_HOME" -type f -name "$pattern" ! -path "*/.git/*" ! -path "*/binaire/*" ! -path "*/software/*" 2>/dev/null)
    done

    if [ "$count" -eq 0 ]; then
        info "Aucun fichier temporaire à supprimer"
    else
        if [ "$DRY_RUN" = true ]; then
            info "[DRY-RUN] $count fichier(s) temporaire(s) seraient supprimés"
        else
            info "✅ $count fichier(s) temporaire(s) supprimé(s)"
        fi
    fi
}

# =============================================================================
# Fonction de Nettoyage des Logs Anciens
# =============================================================================

cleanup_old_logs() {
    section "Nettoyage des logs anciens"

    local logs_dir="$ARKEA_HOME/logs"
    local log_age_days=90  # Supprimer les logs de plus de 90 jours

    if [ ! -d "$logs_dir" ]; then
        warn "Répertoire $logs_dir n'existe pas"
        return 0
    fi

    local count=0
    local total_size=0

    # Trouver les fichiers .log de plus de X jours
    if command -v find >/dev/null 2>&1; then
        while IFS= read -r log_file; do
            [ -z "$log_file" ] && continue

            if [[ "$OSTYPE" == "darwin"* ]]; then
                # macOS
                local file_age=$(stat -f "%m" "$log_file" 2>/dev/null || echo "0")
            else
                # Linux
                local file_age=$(stat -c "%Y" "$log_file" 2>/dev/null || echo "0")
            fi

            local current_timestamp=$(date "+%s")
            local age_seconds=$((current_timestamp - file_age))
            local age_days=$((age_seconds / 86400))

            if [ "$age_days" -gt "$log_age_days" ]; then
                local size=$(stat -f%z "$log_file" 2>/dev/null || stat -c%s "$log_file" 2>/dev/null || echo "0")
                total_size=$((total_size + size))
                count=$((count + 1))

                if [ "$DRY_RUN" = true ]; then
                    info "[DRY-RUN] Supprimerait: $log_file (âge: ${age_days} jours, taille: ${size} bytes)"
                else
                    info "Suppression: $log_file (âge: ${age_days} jours, taille: ${size} bytes)"
                    rm -f "$log_file"
                fi
            fi
        done < <(find "$logs_dir" -type f -name "*.log" 2>/dev/null)
    fi

    if [ "$count" -eq 0 ]; then
        info "Aucun log ancien à supprimer"
    else
        if [ "$DRY_RUN" = true ]; then
            info "[DRY-RUN] $count fichier(s) log seraient supprimés (taille totale: ${total_size} bytes)"
        else
            info "✅ $count fichier(s) log supprimé(s) (taille totale: ${total_size} bytes)"
        fi
    fi
}

# =============================================================================
# Fonction Principale
# =============================================================================

main() {
    section "🧹 Nettoyage Automatique - ARKEA"

    if [ "$DRY_RUN" = true ]; then
        warn "Mode DRY-RUN activé - Aucune action ne sera exécutée"
    fi

    info "Répertoire ARKEA: $ARKEA_HOME"
    info "Âge maximum UNLOAD_*: ${UNLOAD_AGE_DAYS} jours"

    # Exécuter les nettoyages
    cleanup_unloads
    cleanup_temp_files
    cleanup_old_logs

    section "✅ Nettoyage terminé"

    if [ "$DRY_RUN" = true ]; then
        info "Pour exécuter réellement, relancez sans --dry-run"
    fi
}

# =============================================================================
# Exécution
# =============================================================================

main "$@"
