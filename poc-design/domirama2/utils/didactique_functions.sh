#!/bin/bash
# ============================================
# Fonctions Utilitaires pour Scripts Didactiques
# ============================================
#
# Ce fichier contient des fonctions réutilisables pour créer
# des scripts de démonstration très didactiques.
#
# UTILISATION :
#   source utils/didactique_functions.sh
#
# ============================================

# ============================================
# CONFIGURATION DES COULEURS
# ============================================
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
BOLD='\033[1m'
NC='\033[0m'

# ============================================
# FONCTIONS D'AFFICHAGE
# ============================================

info() { echo -e "${BLUE}ℹ️  $1${NC}"; }
success() { echo -e "${GREEN}✅ $1${NC}"; }
warn() { echo -e "${YELLOW}⚠️  $1${NC}"; }
error() { echo -e "${RED}❌ $1${NC}"; }
demo() { echo -e "${CYAN}🎯 $1${NC}"; }
code() { echo -e "${MAGENTA}📝 $1${NC}"; }
section() { echo -e "${BOLD}${CYAN}$1${NC}"; }
result() { echo -e "${GREEN}📊 $1${NC}"; }
expected() { echo -e "${YELLOW}📋 $1${NC}"; }

# ============================================
# FONCTION : Afficher une Requête CQL Formatée
# ============================================
#
# Usage: show_cql_query "$cql_query"
#
show_cql_query() {
    local query="$1"
    echo "   ┌─────────────────────────────────────────────────────────┐"
    while IFS= read -r line; do
        if [ -n "$line" ]; then
            code "   │ $line"
        fi
    done <<< "$query"
    echo "   └─────────────────────────────────────────────────────────┘"
}

# ============================================
# FONCTION : Afficher un DDL Formaté
# ============================================
#
# Usage: show_ddl "$ddl_query"
#
show_ddl() {
    local ddl="$1"
    echo ""
    info "📝 DDL - [Description] :"
    echo ""
    while IFS= read -r line; do
        if [ -n "$line" ]; then
            code "$line"
        fi
    done <<< "$ddl"
    echo ""
}

# ============================================
# FONCTION : Exécuter et Afficher une Requête CQL
# ============================================
#
# Usage: execute_and_display "$cql_query" "Description" "Résultat attendu"
#
execute_and_display() {
    local query="$1"
    local description="$2"
    local expected="$3"
    local cqlsh_bin="${HCD_DIR}/bin/cqlsh"
    
    if [ -z "$expected" ]; then
        expected="Résultats de la requête"
    fi
    
    expected "📋 Résultat attendu :"
    echo "   $expected"
    echo ""
    
    info "📝 Requête CQL (DML) :"
    show_cql_query "$query"
    echo ""
    
    if [ -n "$description" ]; then
        info "   Explication de la requête :"
        echo "      $description"
        echo ""
    fi
    
    echo "🚀 Exécution de la requête..."
    start_time=$(date +%s.%N)
    
    # Exécuter la requête
    result=$("$cqlsh_bin" localhost 9042 -e "$query" 2>&1)
    exit_code=$?
    end_time=$(date +%s.%N)
    
    # Calculer la durée (macOS compatible)
    if command -v bc &> /dev/null; then
        duration=$(echo "$end_time - $start_time" | bc)
    else
        # Fallback pour macOS sans bc
        duration=$(python3 -c "print($end_time - $start_time)")
    fi
    
    if [ $exit_code -eq 0 ]; then
        success "✅ Requête exécutée en ${duration}s"
        echo ""
        result "📊 Résultats obtenus :"
        echo "   ┌─────────────────────────────────────────────────────────┐"
        echo "$result" | sed 's/^/   │ /'
        echo "   └─────────────────────────────────────────────────────────┘"
        echo ""
        return 0
    else
        error "❌ Erreur lors de l'exécution"
        echo "   ┌─────────────────────────────────────────────────────────┐"
        echo "$result" | sed 's/^/   │ /'
        echo "   └─────────────────────────────────────────────────────────┘"
        echo ""
        return 1
    fi
}

# ============================================
# FONCTION : Afficher une Section de Test
# ============================================
#
# Usage: show_test_section "Titre" "Description" "Résultat attendu"
#
show_test_section() {
    local title="$1"
    local description="$2"
    local expected="$3"
    local test_num="${4:-1}"
    local total_tests="${5:-1}"
    
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "  TEST $test_num/$total_tests : $title"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    
    if [ -n "$description" ]; then
        info "📝 Description : $description"
        echo ""
    fi
    
    if [ -n "$expected" ]; then
        expected "📋 Résultat attendu :"
        echo "   $expected"
        echo ""
    fi
}

# ============================================
# FONCTION : Afficher le Contexte HBase → HCD
# ============================================
#
# Usage: show_hbase_context "Fonctionnalité" "Description HBase" "Description HCD"
#
show_hbase_context() {
    local feature="$1"
    local hbase_desc="$2"
    local hcd_desc="$3"
    
    info "📚 CONTEXTE - $feature :"
    echo ""
    echo "   HBase :"
    echo "      $hbase_desc"
    echo ""
    echo "   HCD :"
    echo "      $hcd_desc"
    echo ""
}

# ============================================
# FONCTION : Afficher une Partie de Démonstration
# ============================================
#
# Usage: show_partie "Numéro" "Titre"
#
show_partie() {
    local num="$1"
    local title="$2"
    
    echo ""
    section "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    section "  📋 PARTIE $num: $title"
    section "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
}

# ============================================
# FONCTION : Générer un Rapport de Démonstration
# ============================================
#
# Usage: generate_report "$report_file" "Titre" "$content"
#
generate_report() {
    local report_file="$1"
    local title="$2"
    local content="$3"
    
    mkdir -p "$(dirname "$report_file")"
    
    cat > "$report_file" << EOF
# $title

**Date** : $(date +"%Y-%m-%d %H:%M:%S")  
**Script** : $(basename "${BASH_SOURCE[1]}")

---

## 📋 Table des Matières

1. [DDL : Schéma](#ddl-schéma)
2. [Définition](#définition)
3. [Tests](#tests)
4. [Résultats](#résultats)
5. [Conclusion](#conclusion)

---

$content

---

**✅ Démonstration terminée avec succès !**
EOF
    
    success "📝 Rapport généré : $report_file"
}

# ============================================
# FONCTION : Vérifier le Schéma
# ============================================
#
# Usage: check_schema "colonne" "index"
#
check_schema() {
    local column="$1"
    local index="$2"
    local cqlsh_bin="${HCD_DIR}/bin/cqlsh"
    
    info "🔍 Vérification du schéma..."
    
    if [ -n "$column" ]; then
        column_check=$("$cqlsh_bin" localhost 9042 -e "USE domirama2_poc; DESCRIBE TABLE operations_by_account;" 2>&1 | grep -c "$column" || echo "0")
        if [ "$column_check" -gt 0 ]; then
            success "✅ Colonne $column présente dans le schéma"
        else
            warn "⚠️  Colonne $column non trouvée"
            return 1
        fi
    fi
    
    if [ -n "$index" ]; then
        index_check=$("$cqlsh_bin" localhost 9042 -e "USE domirama2_poc; DESCRIBE INDEX $index;" 2>&1 | grep -c "$index" || echo "0")
        if [ "$index_check" -gt 0 ]; then
            success "✅ Index $index présent"
        else
            warn "⚠️  Index $index non trouvé"
            return 1
        fi
    fi
    
    return 0
}

# ============================================
# FONCTION : Afficher l'En-tête de Démonstration
# ============================================
#
# Usage: show_demo_header "Titre"
#
show_demo_header() {
    local title="$1"
    
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "  🎯 DÉMONSTRATION DIDACTIQUE : $title"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    info "📚 Cette démonstration affiche :"
    echo "   ✅ DDL complet (schéma et index)"
    echo "   ✅ Requêtes CQL détaillées (DML)"
    echo "   ✅ Résultats attendus pour chaque test"
    echo "   ✅ Résultats réels obtenus"
    echo "   ✅ Cinématique complète de chaque étape"
    echo "   ✅ Documentation structurée générée automatiquement"
    echo ""
}

# ============================================
# FONCTION : Afficher le Résumé et Conclusion
# ============================================
#
# Usage: show_summary "Points démontrés" "Avantages" "Limitations"
#
show_summary() {
    local points="$1"
    local advantages="$2"
    local limitations="$3"
    
    echo ""
    section "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    section "  📊 PARTIE FINALE: RÉSUMÉ ET CONCLUSION"
    section "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    
    info "📊 Résumé de la démonstration :"
    echo ""
    while IFS= read -r line; do
        if [ -n "$line" ]; then
            echo "   ✅ $line"
        fi
    done <<< "$points"
    echo ""
    
    if [ -n "$advantages" ]; then
        info "💡 Avantages :"
        echo ""
        while IFS= read -r line; do
            if [ -n "$line" ]; then
                echo "   ✅ $line"
            fi
        done <<< "$advantages"
        echo ""
    fi
    
    if [ -n "$limitations" ]; then
        info "⚠️  Limitations :"
        echo ""
        while IFS= read -r line; do
            if [ -n "$line" ]; then
                echo "   ⚠️  $line"
            fi
        done <<< "$limitations"
        echo ""
    fi
}




