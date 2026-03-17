# 📋 Guide : Amélioration des Scripts pour Démonstrations Didactiques

**Date** : 2025-11-26
**Objectif** : Guide pour enrichir et améliorer les scripts .sh pour produire des démonstrations très didactiques

---

## 🎯 Objectifs de l'Amélioration

Les scripts améliorés doivent :

1. ✅ **Afficher le DDL** : Schéma complet avec explications détaillées
2. ✅ **Afficher le DML** : Requêtes CQL détaillées avant exécution
3. ✅ **Afficher les résultats attendus** : Ce qu'on s'attend à trouver
4. ✅ **Afficher les résultats réels** : Ce qui a été obtenu
5. ✅ **Documenter la cinématique** : Chaque étape expliquée
6. ✅ **Générer un rapport** : Documentation structurée pour livrable
7. ✅ **Affichage dans le terminal** : Tous les résultats visibles dans Cursor

---

## 📝 Structure Standard d'un Script Didactique

### 1. En-tête et Configuration

```bash
#!/bin/bash
# ============================================
# Script XX : [Nom] (Version Didactique)
# [Description]
# ============================================
#
# OBJECTIF :
#   [Description détaillée avec ce qui sera affiché]
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

# Couleurs
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
```

### 2. Configuration et Vérifications

```bash
INSTALL_DIR="${ARKEA_HOME}"
HCD_DIR="${INSTALL_DIR}/binaire/hcd-1.2.3"
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
REPORT_FILE="${SCRIPT_DIR}/doc/demonstrations/XX_DEMONSTRATION.md"

# Créer le répertoire de documentation
mkdir -p "$(dirname "$REPORT_FILE")"

# Vérifications
if ! pgrep -f "cassandra" > /dev/null; then
    error "HCD n'est pas démarré. Exécutez d'abord: ./scripts/setup/03_start_hcd.sh"
    exit 1
fi

cd "$HCD_DIR"
jenv local 11
eval "$(jenv init -)"
```

### 3. En-tête de Démonstration

```bash
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
```

### 4. PARTIE 1: DDL - Schéma

```bash
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
code "ALTER TABLE operations_by_account"
code "ADD [colonne] [type];"
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
```

### 5. PARTIE 2: Définition et Principe

```bash
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
```

### 6. PARTIE 3: Tests avec Affichage Détailé

```bash
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
    # Afficher la requête formatée ligne par ligne
    while IFS= read -r line; do
        if [ -n "$line" ]; then
            code "   │ $line"
        fi
    done <<< "$cql_query"
    echo "   └─────────────────────────────────────────────────────────┘"
    echo ""

    info "   Explication de la requête :"
    echo "      - [Point 1]"
    echo "      - [Point 2]"
    echo "      - [Point 3]"
    echo ""

    # Exécution
    echo "🚀 Exécution de la requête..."
    start_time=$(date +%s.%N)

    # Exécuter la requête
    result=$(./bin/cqlsh localhost 9042 -e "$cql_query" 2>&1)
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
        echo ""

        # Validation
        # [Code de validation]
    else
        error "❌ Erreur lors de l'exécution"
        echo "$result"
    fi

    echo ""
    echo "-" * 70
    echo ""
done
```

### 7. PARTIE 4: Résumé et Conclusion

```bash
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

## 🔧 Fonctions Utilitaires Réutilisables

### Fonction pour Afficher une Requête CQL Formatée

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

### Fonction pour Exécuter et Afficher une Requête

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
    echo "      $description"
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
        return 0
    else
        error "❌ Erreur lors de l'exécution"
        echo "$result"
        return 1
    fi
}
```

### Fonction pour Générer un Rapport

```bash
generate_report() {
    local report_file="$1"
    local title="$2"
    local content="$3"

    cat > "$report_file" << EOF
# $title

**Date** : $(date +"%Y-%m-%d %H:%M:%S")
**Script** : $(basename "$0")

---

$content
EOF
}
```

---

## 📋 Checklist pour Améliorer un Script

### Avant de Commencer

- [ ] Lire le script existant
- [ ] Identifier les fonctionnalités à démontrer
- [ ] Lister les requêtes CQL à afficher
- [ ] Définir les résultats attendus

### Structure

- [ ] Ajouter fonctions de couleur (info, success, warn, error, code, section, result, expected)
- [ ] Ajouter configuration (INSTALL_DIR, HCD_DIR, SCRIPT_DIR, REPORT_FILE)
- [ ] Ajouter vérifications (HCD démarré, dépendances, etc.)

### Contenu

- [ ] **PARTIE 1: DDL**
  - [ ] Afficher le contexte HBase → HCD
  - [ ] Afficher le DDL complet avec explications
  - [ ] Vérifier que le schéma existe

- [ ] **PARTIE 2: Définition**
  - [ ] Expliquer le concept
  - [ ] Expliquer le principe de fonctionnement
  - [ ] Lister les avantages

- [ ] **PARTIE 3: Tests**
  - [ ] Pour chaque test :
    - [ ] Afficher le titre et la description
    - [ ] Afficher le résultat attendu
    - [ ] Afficher la requête CQL formatée
    - [ ] Expliquer la requête
    - [ ] Exécuter la requête
    - [ ] Afficher les résultats réels
    - [ ] Valider les résultats

- [ ] **PARTIE 4: Résumé**
  - [ ] Résumer ce qui a été démontré
  - [ ] Lister les avantages
  - [ ] Mentionner les limitations
  - [ ] Générer le rapport

### Formatage

- [ ] Utiliser les fonctions de couleur appropriées
- [ ] Utiliser des séparateurs visuels (━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━)
- [ ] Formater les requêtes CQL dans des boîtes (┌─┐│└─┘)
- [ ] Aligner les résultats dans des tableaux

---

## 📝 Exemple Complet

Voir `23_test_fuzzy_search_v2_didactique.sh` pour un exemple complet de script didactique.

---

## 🚀 Prochaines Étapes

1. **Améliorer le script 25** : `25_test_hybrid_search.sh`
2. **Améliorer le script 32** : `32_demo_performance_comparison.sh`
3. **Améliorer le script 33** : `33_demo_colonnes_dynamiques_v2.sh`
4. **Améliorer le script 34** : `34_demo_replication_scope_v2.sh`
5. **Créer un script utilitaire** : Fonctions réutilisables pour tous les scripts

---

## 💡 Conseils

1. **Toujours afficher le CQL avant de l'exécuter** : Permet de comprendre ce qui va se passer
2. **Expliquer chaque partie** : Ne pas supposer que le lecteur connaît tout
3. **Valider les résultats** : Vérifier que les résultats correspondent aux attentes
4. **Générer un rapport** : Documentation structurée pour livrable
5. **Utiliser des couleurs** : Améliore la lisibilité dans le terminal
6. **Séparer visuellement** : Utiliser des séparateurs pour structurer l'affichage

---

**✅ Avec ce guide, vous pouvez améliorer tous les scripts pour produire des démonstrations très didactiques !**
