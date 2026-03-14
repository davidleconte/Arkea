#!/bin/bash
set -euo pipefail

# =============================================================================
# Script : Génération Automatique de Documentation
# =============================================================================
# Date : 2025-12-02
# Usage : ./92_generate_docs.sh [--index] [--scripts] [--pocs]
# Description : Génère automatiquement la documentation (index, listes, tableaux)
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
GENERATE_INDEX=false
GENERATE_SCRIPTS=false
GENERATE_POCS=false

# =============================================================================
# Traitement des arguments
# =============================================================================

print_help() {
    echo "Usage: ./92_generate_docs.sh [OPTIONS]"
    echo ""
    echo "Options:"
    echo "  --index   : Générer l'index de documentation"
    echo "  --scripts : Générer la liste des scripts"
    echo "  --pocs    : Générer le tableau comparatif des POCs"
    echo "  --help    : Affiche ce message d'aide"
    echo ""
    echo "Si aucune option n'est spécifiée, toutes les générations sont effectuées."
}

while [[ "$#" -gt 0 ]]; do
    case "$1" in
        --index)
            GENERATE_INDEX=true
            ;;
        --scripts)
            GENERATE_SCRIPTS=true
            ;;
        --pocs)
            GENERATE_POCS=true
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

# Si aucune option spécifiée, tout générer
if [ "$GENERATE_INDEX" = false ] && [ "$GENERATE_SCRIPTS" = false ] && [ "$GENERATE_POCS" = false ]; then
    GENERATE_INDEX=true
    GENERATE_SCRIPTS=true
    GENERATE_POCS=true
fi

# =============================================================================
# Fonction : Générer l'Index de Documentation
# =============================================================================

generate_index() {
    section "Génération de l'Index de Documentation"

    local index_file="$ARKEA_HOME/docs/INDEX_AUTO_GENERATED.md"

    cat > "$index_file" <<EOF
# 📚 Index Automatique de la Documentation - ARKEA

**Date de génération** : $(date +%Y-%m-%d\ %H:%M:%S)
**Généré par** : \`92_generate_docs.sh\`

---

## 📋 Documentation Principale

EOF

    # Lister les fichiers .md dans docs/ (exclure les fichiers auto-générés)
    find "$ARKEA_HOME/docs" -maxdepth 1 -type f -name "*.md" ! -name "*AUTO*" ! -name "*GENERATED*" | sort | while IFS= read -r doc_file; do
        local filename
        filename="$(basename "$doc_file")"
        local title
        title="$(head -1 "$doc_file" | sed 's/^# //' | sed 's/^## //')"
        echo "- **[$filename]($filename)** : $title" >> "$index_file"
    done

    cat >> "$index_file" <<EOF

---

## 📁 Documentation par POC

EOF

    # Lister les POCs
    for poc_dir in "$ARKEA_HOME/poc-design"/*; do
        if [ -d "$poc_dir" ] && [ -f "$poc_dir/README.md" ]; then
            local poc_name
            poc_name="$(basename "$poc_dir")"
            echo "### $poc_name" >> "$index_file"
            echo "" >> "$index_file"
            echo "- **[README.md](../poc-design/$poc_name/README.md)**" >> "$index_file"
            echo "" >> "$index_file"
        fi
    done

    cat >> "$index_file" <<EOF

---

**Note** : Ce fichier est généré automatiquement. Ne pas modifier manuellement.

EOF

    info "Index généré : $index_file"
}

# =============================================================================
# Fonction : Générer la Liste des Scripts
# =============================================================================

generate_scripts_list() {
    section "Génération de la Liste des Scripts"

    local scripts_file="$ARKEA_HOME/docs/SCRIPTS_LIST_AUTO_GENERATED.md"

    cat > "$scripts_file" <<EOF
# 📜 Liste Automatique des Scripts - ARKEA

**Date de génération** : $(date +%Y-%m-%d\ %H:%M:%S)
**Généré par** : \`92_generate_docs.sh\`

---

## 📋 Scripts Utilitaires (scripts/utils/)

EOF

    # Lister les scripts dans scripts/utils/
    find "$ARKEA_HOME/scripts/utils" -type f -name "*.sh" | sort | while IFS= read -r script; do
        local filename
        filename="$(basename "$script")"
        local rel_path="${script#$ARKEA_HOME/}"
        local description=""

        # Extraire la description depuis les commentaires
        if head -20 "$script" | grep -q "Description :"; then
            description="$(head -20 "$script" | grep "Description :" | head -1 | sed 's/.*Description : //')"
        fi

        echo "- **\`$filename\`** : $description" >> "$scripts_file"
        echo "  - Chemin : \`$rel_path\`" >> "$scripts_file"
        echo "" >> "$scripts_file"
    done

    cat >> "$scripts_file" <<EOF

---

## 📋 Scripts par POC

EOF

    # Lister les scripts par POC
    for poc_dir in "$ARKEA_HOME/poc-design"/*; do
        if [ -d "$poc_dir/scripts" ]; then
            local poc_name
            poc_name="$(basename "$poc_dir")"
            echo "### $poc_name" >> "$scripts_file"
            echo "" >> "$scripts_file"

            find "$poc_dir/scripts" -type f -name "*.sh" ! -path "*/archive/*" | sort | while IFS= read -r script; do
                local filename
                filename="$(basename "$script")"
                local rel_path="${script#$ARKEA_HOME/}"
                echo "- \`$filename\` : \`$rel_path\`" >> "$scripts_file"
            done

            echo "" >> "$scripts_file"
        fi
    done

    cat >> "$scripts_file" <<EOF

---

**Note** : Ce fichier est généré automatiquement. Ne pas modifier manuellement.

EOF

    info "Liste des scripts générée : $scripts_file"
}

# =============================================================================
# Fonction : Générer le Tableau Comparatif des POCs
# =============================================================================

generate_pocs_comparison() {
    section "Génération du Tableau Comparatif des POCs"

    local comparison_file="$ARKEA_HOME/docs/POCS_COMPARISON_AUTO_GENERATED.md"

    cat > "$comparison_file" <<EOF
# 📊 Tableau Comparatif Automatique des POCs - ARKEA

**Date de génération** : $(date +%Y-%m-%d\ %H:%M:%S)
**Généré par** : \`92_generate_docs.sh\`

---

## 📋 Statistiques par POC

| POC | Scripts | Documentation | Schémas | Statut |
|-----|---------|---------------|---------|--------|
EOF

    # Générer les statistiques pour chaque POC
    for poc_dir in "$ARKEA_HOME/poc-design"/*; do
        if [ -d "$poc_dir" ]; then
            local poc_name
            poc_name="$(basename "$poc_dir")"
            local scripts_count=0
            local docs_count=0
            local schemas_count=0

            if [ -d "$poc_dir/scripts" ]; then
                scripts_count=$(find "$poc_dir/scripts" -type f -name "*.sh" ! -path "*/archive/*" 2>/dev/null | wc -l | tr -d ' ')
            fi

            if [ -d "$poc_dir/doc" ]; then
                docs_count=$(find "$poc_dir/doc" -type f -name "*.md" ! -path "*/archive/*" 2>/dev/null | wc -l | tr -d ' ')
            fi

            if [ -d "$poc_dir/schemas" ]; then
                schemas_count=$(find "$poc_dir/schemas" -type f -name "*.cql" 2>/dev/null | wc -l | tr -d ' ')
            fi

            local status="✅"
            if [ ! -f "$poc_dir/README.md" ]; then
                status="⚠️"
            fi

            echo "| $poc_name | $scripts_count | $docs_count | $schemas_count | $status |" >> "$comparison_file"
        fi
    done

    cat >> "$comparison_file" <<EOF

---

## 📋 Détails par POC

EOF

    # Générer les détails pour chaque POC
    for poc_dir in "$ARKEA_HOME/poc-design"/*; do
        if [ -d "$poc_dir" ] && [ -f "$poc_dir/README.md" ]; then
            local poc_name
            poc_name="$(basename "$poc_dir")"
            echo "### $poc_name" >> "$comparison_file"
            echo "" >> "$comparison_file"
            echo "- **README** : [README.md](../poc-design/$poc_name/README.md)" >> "$comparison_file"
            echo "" >> "$comparison_file"
        fi
    done

    cat >> "$comparison_file" <<EOF

---

**Note** : Ce fichier est généré automatiquement. Ne pas modifier manuellement.

EOF

    info "Tableau comparatif généré : $comparison_file"
}

# =============================================================================
# Exécution principale
# =============================================================================

section "Génération Automatique de Documentation - ARKEA"

info "Répertoire ARKEA: $ARKEA_HOME"

if [ "$GENERATE_INDEX" = true ]; then
    generate_index
fi

if [ "$GENERATE_SCRIPTS" = true ]; then
    generate_scripts_list
fi

if [ "$GENERATE_POCS" = true ]; then
    generate_pocs_comparison
fi

section "✅ Génération terminée"

info "Documentation générée avec succès !"
