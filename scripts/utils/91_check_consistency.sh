#!/bin/bash
set -euo pipefail

# =============================================================================
# Script : Vérification de Cohérence du Projet ARKEA
# =============================================================================
# Date : 2025-12-02
# Usage : ./91_check_consistency.sh [--check-hardcoded-paths] [--check-scripts] [--check-docs] [--report]
# Description : Vérifie la cohérence du projet (chemins hardcodés, scripts standards, documentation)
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
CHECK_HARDCODED_PATHS=false
CHECK_SCRIPTS=false
CHECK_DOCS=false
GENERATE_REPORT=false
REPORT_FILE=""

# Compteurs
TOTAL_ISSUES=0
HARDCODED_PATHS_COUNT=0
SCRIPTS_WITHOUT_STANDARDS_COUNT=0
DOCS_ISSUES_COUNT=0

# =============================================================================
# Traitement des arguments
# =============================================================================

print_help() {
    echo "Usage: ./91_check_consistency.sh [OPTIONS]"
    echo ""
    echo "Options:"
    echo "  --check-hardcoded-paths : Vérifier les chemins hardcodés"
    echo "  --check-scripts         : Vérifier les scripts (set -euo pipefail)"
    echo "  --check-docs            : Vérifier la documentation (liens, références)"
    echo "  --report                : Générer un rapport (fichier .md)"
    echo "  --help                  : Affiche ce message d'aide"
    echo ""
    echo "Si aucune option n'est spécifiée, toutes les vérifications sont effectuées."
}

while [[ "$#" -gt 0 ]]; do
    case "$1" in
        --check-hardcoded-paths)
            CHECK_HARDCODED_PATHS=true
            ;;
        --check-scripts)
            CHECK_SCRIPTS=true
            ;;
        --check-docs)
            CHECK_DOCS=true
            ;;
        --report)
            GENERATE_REPORT=true
            REPORT_FILE="${ARKEA_HOME}/docs/consistency_report_$(date +%Y%m%d_%H%M%S).md"
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

# Si aucune option spécifiée, tout vérifier
if [ "$CHECK_HARDCODED_PATHS" = false ] && [ "$CHECK_SCRIPTS" = false ] && [ "$CHECK_DOCS" = false ]; then
    CHECK_HARDCODED_PATHS=true
    CHECK_SCRIPTS=true
    CHECK_DOCS=true
fi

# =============================================================================
# Fonction : Vérifier les Chemins Hardcodés
# =============================================================================

check_hardcoded_paths() {
    section "Vérification des Chemins Hardcodés"

    local count=0
    local files_with_hardcoded=()

    # Patterns à rechercher
    local patterns=(
        "${USER_HOME:-$HOME}"
        "/opt/homebrew"
        "INSTALL_DIR="
        "hardcod"
    )

    # Rechercher dans les fichiers (exclure .git, binaire, software)
    for pattern in "${patterns[@]}"; do
        while IFS= read -r file; do
            if [ -f "$file" ]; then
                if grep -q "$pattern" "$file" 2>/dev/null; then
                    files_with_hardcoded+=("$file")
                    count=$((count + 1))
                fi
            fi
        done < <(find "$ARKEA_HOME" -type f \
            ! -path "$ARKEA_HOME/.git/*" \
            ! -path "$ARKEA_HOME/binaire/*" \
            ! -path "$ARKEA_HOME/software/*" \
            ! -path "$ARKEA_HOME/logs/*" \
            \( -name "*.sh" -o -name "*.md" -o -name "*.py" \) 2>/dev/null)
    done

    # Dédupliquer
    local unique_files=($(printf '%s\n' "${files_with_hardcoded[@]}" | sort -u))

    if [ ${#unique_files[@]} -eq 0 ]; then
        info "✅ Aucun chemin hardcodé détecté"
    else
        warn "${#unique_files[@]} fichier(s) avec chemins hardcodés détecté(s)"
        for file in "${unique_files[@]}"; do
            local rel_path="${file#$ARKEA_HOME/}"
            echo "  ⚠️  $rel_path"
        done
        HARDCODED_PATHS_COUNT=${#unique_files[@]}
        TOTAL_ISSUES=$((TOTAL_ISSUES + ${#unique_files[@]}))
    fi
}

# =============================================================================
# Fonction : Vérifier les Scripts (set -euo pipefail)
# =============================================================================

check_scripts() {
    section "Vérification des Scripts (set -euo pipefail)"

    local count=0
    local scripts_without_standards=()

    # Rechercher les scripts sans set -euo pipefail
    while IFS= read -r script; do
        if [ -f "$script" ]; then
            # Vérifier si le script a set -euo pipefail dans les 5 premières lignes
            if ! head -5 "$script" | grep -q "set -euo pipefail"; then
                scripts_without_standards+=("$script")
                count=$((count + 1))
            fi
        fi
    done < <(find "$ARKEA_HOME" -type f -name "*.sh" \
        ! -path "$ARKEA_HOME/.git/*" \
        ! -path "$ARKEA_HOME/binaire/*" \
        ! -path "$ARKEA_HOME/software/*" \
        ! -path "$ARKEA_HOME/logs/*" \
        ! -path "*/archive/*" 2>/dev/null)

    if [ ${#scripts_without_standards[@]} -eq 0 ]; then
        info "✅ Tous les scripts ont set -euo pipefail"
    else
        warn "${#scripts_without_standards[@]} script(s) sans set -euo pipefail"
        for script in "${scripts_without_standards[@]}"; do
            local rel_path="${script#$ARKEA_HOME/}"
            echo "  ⚠️  $rel_path"
        done
        SCRIPTS_WITHOUT_STANDARDS_COUNT=${#scripts_without_standards[@]}
        TOTAL_ISSUES=$((TOTAL_ISSUES + ${#scripts_without_standards[@]}))
    fi
}

# =============================================================================
# Fonction : Vérifier la Documentation
# =============================================================================

check_docs() {
    section "Vérification de la Documentation"

    local count=0
    local docs_issues=()

    # Vérifier les liens relatifs dans les fichiers .md
    while IFS= read -r doc_file; do
        if [ -f "$doc_file" ]; then
            # Rechercher les liens relatifs potentiellement cassés
            while IFS= read -r line; do
                if [[ "$line" =~ \[.*\]\(([^)]+)\) ]]; then
                    local link="${BASH_REMATCH[1]}"
                    # Ignorer les liens http/https et les ancres
                    if [[ ! "$link" =~ ^(http|https|#) ]] && [[ "$link" =~ ^\.\.?/ ]]; then
                        local doc_dir="$(dirname "$doc_file")"
                        local target_file="$(cd "$doc_dir" && realpath -m "$link" 2>/dev/null || echo "")"
                        if [ ! -f "$target_file" ]; then
                            docs_issues+=("$doc_file: Lien cassé: $link")
                            count=$((count + 1))
                        fi
                    fi
                fi
            done < "$doc_file"
        fi
    done < <(find "$ARKEA_HOME" -type f -name "*.md" \
        ! -path "$ARKEA_HOME/.git/*" \
        ! -path "$ARKEA_HOME/binaire/*" \
        ! -path "$ARKEA_HOME/software/*" \
        ! -path "$ARKEA_HOME/logs/*" \
        ! -path "*/archive/*" 2>/dev/null)

    if [ $count -eq 0 ]; then
        info "✅ Aucun problème de documentation détecté"
    else
        warn "$count problème(s) de documentation détecté(s)"
        for issue in "${docs_issues[@]}"; do
            echo "  ⚠️  $issue"
        done
        DOCS_ISSUES_COUNT=$count
        TOTAL_ISSUES=$((TOTAL_ISSUES + count))
    fi
}

# =============================================================================
# Fonction : Générer le Rapport
# =============================================================================

generate_report() {
    if [ "$GENERATE_REPORT" = false ]; then
        return 0
    fi

    section "Génération du Rapport"

    cat > "$REPORT_FILE" <<EOF
# 📊 Rapport de Vérification de Cohérence - ARKEA

**Date** : $(date +%Y-%m-%d\ %H:%M:%S)
**Script** : \`91_check_consistency.sh\`

---

## 📋 Résumé

- **Total problèmes détectés** : $TOTAL_ISSUES
- **Chemins hardcodés** : $HARDCODED_PATHS_COUNT
- **Scripts sans standards** : $SCRIPTS_WITHOUT_STANDARDS_COUNT
- **Problèmes documentation** : $DOCS_ISSUES_COUNT

---

## 🔍 Détails

### Chemins Hardcodés

EOF

    if [ $HARDCODED_PATHS_COUNT -gt 0 ]; then
        echo "- ⚠️  $HARDCODED_PATHS_COUNT fichier(s) avec chemins hardcodés" >> "$REPORT_FILE"
    else
        echo "- ✅ Aucun chemin hardcodé détecté" >> "$REPORT_FILE"
    fi

    cat >> "$REPORT_FILE" <<EOF

### Scripts sans Standards

EOF

    if [ $SCRIPTS_WITHOUT_STANDARDS_COUNT -gt 0 ]; then
        echo "- ⚠️  $SCRIPTS_WITHOUT_STANDARDS_COUNT script(s) sans set -euo pipefail" >> "$REPORT_FILE"
    else
        echo "- ✅ Tous les scripts ont set -euo pipefail" >> "$REPORT_FILE"
    fi

    cat >> "$REPORT_FILE" <<EOF

### Documentation

EOF

    if [ $DOCS_ISSUES_COUNT -gt 0 ]; then
        echo "- ⚠️  $DOCS_ISSUES_COUNT problème(s) de documentation détecté(s)" >> "$REPORT_FILE"
    else
        echo "- ✅ Aucun problème de documentation détecté" >> "$REPORT_FILE"
    fi

    cat >> "$REPORT_FILE" <<EOF

---

**Généré automatiquement par** : \`91_check_consistency.sh\`
EOF

    info "Rapport généré : $REPORT_FILE"
}

# =============================================================================
# Exécution principale
# =============================================================================

section "Vérification de Cohérence - ARKEA"

info "Répertoire ARKEA: $ARKEA_HOME"

if [ "$CHECK_HARDCODED_PATHS" = true ]; then
    check_hardcoded_paths
fi

if [ "$CHECK_SCRIPTS" = true ]; then
    check_scripts
fi

if [ "$CHECK_DOCS" = true ]; then
    check_docs
fi

if [ "$GENERATE_REPORT" = true ]; then
    generate_report
fi

section "✅ Vérification terminée"

if [ $TOTAL_ISSUES -eq 0 ]; then
    info "✅ Aucun problème détecté !"
    exit 0
else
    warn "$TOTAL_ISSUES problème(s) détecté(s)"
    exit 1
fi
