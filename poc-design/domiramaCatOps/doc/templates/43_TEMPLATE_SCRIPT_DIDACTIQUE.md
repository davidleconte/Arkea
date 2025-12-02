# 📋 Template : Script Shell Didactique pour Démonstrations

**Date** : 2025-01-XX  
**Objectif** : Template réutilisable pour créer des scripts de démonstration très didactiques  
**Contexte** : DomiramaCatOps POC

---

## 🎯 Principes du Template

Un script didactique doit :

1. **Afficher le DDL** : Schéma complet avec explications
2. **Afficher le DML** : Requêtes CQL détaillées avant exécution
3. **Afficher les résultats attendus** : Ce qu'on s'attend à trouver
4. **Afficher les résultats réels** : Ce qui a été obtenu
5. **Documenter la cinématique** : Chaque étape expliquée
6. **Générer un rapport** : Documentation structurée pour livrable

---

## 📝 Structure Standard

```bash
#!/bin/bash
# ============================================
# Script XX : [Nom] (Version Didactique)
# [Description]
# ============================================
#
# OBJECTIF :
#   [Description détaillée]
#
# PRÉREQUIS :
#   - [Liste des prérequis]
#
# UTILISATION :
#   ./XX_script.sh
#
# SORTIE :
#   - DDL complet affiché
#   - Requêtes CQL détaillées
#   - Résultats attendus vs réels
#   - Documentation structurée
#
# ============================================

set -e

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
# CONFIGURATION
# ============================================
INSTALL_DIR="/Users/david.leconte/Documents/Arkea"
HCD_DIR="${INSTALL_DIR}/binaire/hcd-1.2.3"
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
REPORT_FILE="${SCRIPT_DIR}/../doc/demonstrations/XX_DEMONSTRATION.md"

# Créer le répertoire de documentation
mkdir -p "$(dirname "$REPORT_FILE")"

# ============================================
# VÉRIFICATIONS
# ============================================
if ! pgrep -f "cassandra" > /dev/null; then
    error "HCD n'est pas démarré. Exécutez d'abord: ./scripts/setup/03_start_hcd.sh"
    exit 1
fi

cd "$HCD_DIR"
jenv local 11
eval "$(jenv init -)"

# ============================================
# EN-TÊTE DE DÉMONSTRATION
# ============================================
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  🎯 DÉMONSTRATION DIDACTIQUE : [Titre]"
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

# ============================================
# PARTIE 1: DDL - Schéma
# ============================================
echo ""
section "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
section "  📋 PARTIE 1: DDL - SCHÉMA"
section "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

info "📚 CONTEXTE - [Fonctionnalité] :"
echo ""
echo "   HBase :"
echo "      [Description équivalent HBase]"
echo ""
echo "   HCD :"
echo "      [Description équivalent HCD]"
echo ""

info "📝 DDL - [Description] :"
echo ""
code "[Commande CQL DDL]"
echo ""
info "   Explication :"
echo "      - [Point 1]"
echo "      - [Point 2]"
echo "      - [Point 3]"
echo ""

# Vérification
info "🔍 Vérification du schéma..."
# [Code de vérification]
success "✅ [Confirmation]"
echo ""

# ============================================
# PARTIE 2: Définition et Principe
# ============================================
echo ""
section "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
section "  📚 PARTIE 2: DÉFINITION - [Concept]"
section "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

info "📚 DÉFINITION - [Concept] :"
echo ""
echo "   [Explication détaillée]"
echo ""
echo "   Principe :"
echo "   1. [Étape 1]"
echo "   2. [Étape 2]"
echo "   3. [Étape 3]"
echo ""
echo "   Avantages :"
echo "   ✅ [Avantage 1]"
echo "   ✅ [Avantage 2]"
echo "   ✅ [Avantage 3]"
echo ""

# ============================================
# PARTIE 3: Tests
# ============================================
echo ""
section "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
section "  🧪 PARTIE 3: TESTS"
section "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Pour chaque test
for i in "${!tests[@]}"; do
    test_case="${tests[$i]}"
    
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "  TEST $((i+1))/${#tests[@]} : [Titre]"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    
    expected "📋 Résultat attendu :"
    echo "   [Description du résultat attendu]"
    echo ""
    
    info "📝 Requête CQL (DML) :"
    echo "   ┌─────────────────────────────────────────────────────────┐"
    code "[Requête CQL formatée]"
    echo "   └─────────────────────────────────────────────────────────┘"
    echo ""
    
    info "   Explication de la requête :"
    echo "      - [Point 1]"
    echo "      - [Point 2]"
    echo "      - [Point 3]"
    echo ""
    
    # Exécution
    echo "🚀 Exécution de la requête..."
    # [Code d'exécution]
    
    # Résultats
    result "📊 Résultats obtenus :"
    echo "   ┌─────────────────────────────────────────────────────────┐"
    # [Affichage des résultats]
    echo "   └─────────────────────────────────────────────────────────┘"
    echo ""
    
    # Validation
    # [Code de validation]
    echo ""
done

# ============================================
# PARTIE 4: Résumé et Conclusion
# ============================================
echo ""
section "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
section "  📊 PARTIE 4: RÉSUMÉ ET CONCLUSION"
section "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

info "📊 Résumé de la démonstration :"
echo ""
echo "   ✅ [Point 1]"
echo "   ✅ [Point 2]"
echo "   ✅ [Point 3]"
echo ""

info "💡 Avantages :"
echo ""
echo "   ✅ [Avantage 1]"
echo "   ✅ [Avantage 2]"
echo ""

info "⚠️  Limitations :"
echo ""
echo "   ⚠️  [Limitation 1]"
echo "   ⚠️  [Limitation 2]"
echo ""

success "✅ Démonstration terminée !"
info "📝 Documentation générée : $REPORT_FILE"
```

---

## 📋 Fonctions Utilitaires

### Affichage de Requête CQL Formatée

```bash
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
```

### Exécution de Requête avec Affichage

```bash
execute_and_display() {
    local query="$1"
    local description="$2"
    local expected="$3"
    
    expected "📋 Résultat attendu :"
    echo "   $expected"
    echo ""
    
    info "📝 Requête CQL (DML) :"
    show_cql_query "$query"
    echo ""
    
    info "   Explication :"
    echo "      [Explications détaillées]"
    echo ""
    
    echo "🚀 Exécution de la requête..."
    start_time=$(date +%s.%N)
    
    result=$(./bin/cqlsh localhost 9042 -e "$query" 2>&1)
    exit_code=$?
    end_time=$(date +%s.%N)
    duration=$(echo "$end_time - $start_time" | bc)
    
    if [ $exit_code -eq 0 ]; then
        success "✅ Requête exécutée en ${duration}s"
        echo ""
        result "📊 Résultats obtenus :"
        echo "   ┌─────────────────────────────────────────────────────────┐"
        echo "$result" | sed 's/^/   │ /'
        echo "   └─────────────────────────────────────────────────────────┘"
    else
        error "❌ Erreur lors de l'exécution"
        echo "$result"
    fi
}
```

### Génération de Rapport

```bash
generate_report() {
    local report_file="$1"
    local title="$2"
    
    cat > "$report_file" << EOF
# $title

**Date** : $(date +"%Y-%m-%d %H:%M:%S")  
**Script** : $0

---

## 📋 Table des Matières

1. [DDL : Schéma](#ddl-schéma)
2. [Définition](#définition)
3. [Tests](#tests)
4. [Résultats](#résultats)
5. [Conclusion](#conclusion)

---

## 📋 DDL : Schéma

\`\`\`cql
[DDL complet]
\`\`\`

## 📚 Définition

[Définition détaillée]

## 🧪 Tests

[Tests détaillés avec résultats]

## 📊 Résultats

[Résultats détaillés]

## ✅ Conclusion

[Conclusion]
EOF
}
```

---

## 🎯 Checklist pour Améliorer un Script

- [ ] Ajouter fonctions de couleur (info, success, warn, error, code, section, result, expected)
- [ ] Ajouter section DDL avec explications
- [ ] Ajouter section Définition/Principe
- [ ] Pour chaque test :
  - [ ] Afficher résultat attendu
  - [ ] Afficher requête CQL formatée
  - [ ] Expliquer la requête
  - [ ] Exécuter et afficher résultats
  - [ ] Valider les résultats
- [ ] Ajouter section Résumé/Conclusion
- [ ] Générer rapport de démonstration
- [ ] Ajouter vérifications (schéma, données, etc.)

---

## 📝 Exemple d'Utilisation

Voir les scripts de test dans `scripts/` pour des exemples complets.

---

**✅ Ce template est spécifiquement conçu pour les scripts de démonstration DomiramaCatOps !**


