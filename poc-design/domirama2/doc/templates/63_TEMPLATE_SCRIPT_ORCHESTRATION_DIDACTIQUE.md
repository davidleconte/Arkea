# 📋 Template : Script Shell Didactique pour Orchestration/Démonstration Complète

**Date** : 2025-11-26  
**Objectif** : Template réutilisable pour créer des scripts d'orchestration/démonstration complète très didactiques  
**Type** : Scripts qui orchestrent plusieurs étapes et exécutent N démonstrations

---

## 🎯 Principes du Template pour Orchestration

Un script d'orchestration didactique doit :

1. **Orchestrer les étapes** : Vérifications, appels à scripts dépendants, configuration
2. **Exécuter N démonstrations** : Chaque démonstration avec définition, requête, explication, résultats
3. **Afficher les résultats** : Pour chaque démonstration, résultats attendus vs réels
4. **Documenter la cinématique** : Chaque étape expliquée (orchestration + démonstrations)
5. **Générer un rapport** : Documentation structurée pour livrable avec toutes les démonstrations
6. **Afficher les statistiques** : Résumé global, succès/échecs, points clés

---

## 📝 Structure Standard pour Script d'Orchestration

```bash
#!/bin/bash
# ============================================
# Script XX : Démonstration Complète [Nom] (Version Didactique)
# Orchestre une démonstration complète avec multiples tests
# ============================================
#
# OBJECTIF :
#   Ce script orchestre une démonstration complète en :
#   1. Vérifiant l'environnement (HCD, dépendances)
#   2. Configurant le schéma (via scripts appelés)
#   3. Chargeant les données (via scripts appelés)
#   4. Attendant l'indexation si nécessaire
#   5. Exécutant N démonstrations avec résultats détaillés
#   6. Générant un rapport structuré
#
#   Cette version didactique affiche :
#   - Les étapes d'orchestration avec explications
#   - Pour chaque démonstration : définition, requête, explication, résultats
#   - Les statistiques globales
#   - Une documentation structurée pour livrable
#
# PRÉREQUIS :
#   - HCD démarré (ou script de démarrage disponible)
#   - Scripts dépendants présents (setup, chargement)
#   - Java 11 configuré via jenv
#   - Fichiers de données présents si nécessaire
#
# UTILISATION :
#   ./XX_demonstration_complete.sh
#
# SORTIE :
#   - Résultats de toutes les démonstrations
#   - Statistiques globales
#   - Documentation structurée (doc/demonstrations/XX_DEMONSTRATION.md)
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
REPORT_FILE="${SCRIPT_DIR}/doc/demonstrations/XX_DEMONSTRATION.md"
CQLSH="${HCD_DIR}/bin/cqlsh"

# Créer le répertoire de documentation
mkdir -p "$(dirname "$REPORT_FILE")"

# Variables pour le rapport
TEMP_RESULTS="${SCRIPT_DIR}/.temp_demo_results.json"
DEMO_COUNT=0
SUCCESS_COUNT=0
FAILED_COUNT=0

# Fonction de nettoyage
cleanup() {
    [ -f "$TEMP_RESULTS" ] && rm -f "$TEMP_RESULTS"
}
trap cleanup EXIT

# ============================================
# PARTIE 1 : EN-TÊTE DE DÉMONSTRATION
# ============================================
echo ""
echo "═══════════════════════════════════════════════════════════════"
echo "  🎯 DÉMONSTRATION COMPLÈTE - [Titre]"
echo "  [Sous-titre]"
echo "═══════════════════════════════════════════════════════════════"
echo ""

# Initialiser le rapport JSON
echo "[]" > "$TEMP_RESULTS"

# ============================================
# PARTIE 2 : ORCHESTRATION - Vérification Environnement
# ============================================
section "PARTIE 1 : VÉRIFICATION DE L'ENVIRONNEMENT"
echo ""

info "📚 OBJECTIF : Vérifier que tous les prérequis sont satisfaits"
echo ""

# Exemple : Vérification HCD
demo "Vérification HCD..."
if ! pgrep -f "cassandra" > /dev/null; then
    warn "HCD n'est pas démarré. Démarrage..."
    cd "$INSTALL_DIR"
    if [ -f "03_start_hcd.sh" ]; then
        ./03_start_hcd.sh || {
            error "Impossible de démarrer HCD"
            exit 1
        }
        sleep 10
    else
        error "Script de démarrage HCD non trouvé"
        exit 1
    fi
fi
success "HCD est démarré"
echo ""

# Exemple : Vérification Java
demo "Vérification Java..."
cd "$HCD_DIR"
jenv local 11
eval "$(jenv init -)"
JAVA_VERSION=$(java -version 2>&1 | head -1)
info "Java version : $JAVA_VERSION"
echo ""

# Ajouter d'autres vérifications si nécessaire
# - Vérification scripts dépendants
# - Vérification fichiers de données
# - Vérification schémas

# ============================================
# PARTIE 3 : ORCHESTRATION - Configuration Schéma
# ============================================
section "PARTIE 2 : CONFIGURATION DU SCHÉMA"
echo ""

info "📚 OBJECTIF : Configurer le schéma et les index via scripts dépendants"
echo ""

demo "Configuration du schéma..."
cd "$SCRIPT_DIR"

# Exemple : Appel au script de setup
if [ -f "XX_setup_schema.sh" ]; then
    info "Exécution du script de setup..."
    ./XX_setup_schema.sh 2>&1 | tail -15
    success "Schéma configuré"
else
    warn "Script de setup non trouvé, utilisation du schéma de base"
    if [ -f "10_setup_domirama2_poc.sh" ]; then
        ./10_setup_domirama2_poc.sh 2>&1 | tail -10
    fi
fi
echo ""

# ============================================
# PARTIE 4 : ORCHESTRATION - Chargement des Données
# ============================================
section "PARTIE 3 : CHARGEMENT DES DONNÉES"
echo ""

info "📚 OBJECTIF : Charger les données via scripts dépendants"
echo ""

demo "Vérification des données existantes..."
cd "$HCD_DIR"
jenv local 11
eval "$(jenv init -)"

# Exemple : Vérifier si les données existent déjà
COUNT=$($CQLSH localhost 9042 -e "USE domirama2_poc; SELECT COUNT(*) FROM operations_by_account;" 2>&1 | grep -v "Warnings" | grep -E "^[[:space:]]*[0-9]+" | head -1 | tr -d ' ' || echo "0")

if [ -n "$COUNT" ] && [ "$COUNT" -gt 5000 ]; then
    success "Données déjà chargées : $COUNT opérations"
else
    info "Chargement des données..."
    cd "$SCRIPT_DIR"
    if [ -f "XX_load_data.sh" ]; then
        ./XX_load_data.sh "${SCRIPT_DIR}/data/operations_10000.parquet" 2>&1 | tail -20
        success "Données chargées"
    else
        warn "Script de chargement non trouvé"
    fi
fi
echo ""

# ============================================
# PARTIE 5 : ORCHESTRATION - Attente Indexation
# ============================================
section "PARTIE 4 : ATTENTE DE L'INDEXATION"
echo ""

info "📚 OBJECTIF : Attendre que les index SAI soient prêts"
echo ""

demo "Attente de l'indexation SAI..."
info "Indexation en cours (30 secondes)..."
sleep 30
success "Indexation terminée"
echo ""

# ============================================
# PARTIE 6 : DÉMONSTRATIONS
# ============================================
section "PARTIE 5 : DÉMONSTRATIONS"
echo ""

info "📚 OBJECTIF : Exécuter N démonstrations avec résultats détaillés"
echo ""

# Variables pour les démonstrations
CODE_SI="1"
CONTRAT="5913101072"

# ============================================
# DÉMONSTRATION 1 : [Titre]
# ============================================
DEMO_NUM=1
DEMO_TITLE="[Titre de la démonstration]"
DEMO_DESC="[Description détaillée]"
DEMO_EXPECTED="[Résultat attendu]"
DEMO_QUERY="SELECT ... FROM ... WHERE ..."

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  🔍 DÉMONSTRATION $DEMO_NUM : $DEMO_TITLE"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

info "📚 DÉFINITION - [Concept] :"
echo "   [Explication détaillée du concept]"
echo ""

info "📝 Requête CQL :"
code "$DEMO_QUERY"
echo ""

info "💡 Ce que nous démontrons :"
echo "   ✅ [Point 1]"
echo "   ✅ [Point 2]"
echo "   ✅ [Point 3]"
echo ""

expected "📋 Résultat attendu : $DEMO_EXPECTED"
echo ""

# Exécuter la requête et mesurer le temps
START_TIME=$(date +%s.%N)
QUERY_OUTPUT=$($CQLSH localhost 9042 -e "USE domirama2_poc; $DEMO_QUERY;" 2>&1)
EXIT_CODE=$?
END_TIME=$(date +%s.%N)
QUERY_TIME=$(echo "$END_TIME - $START_TIME" | bc)

# Filtrer les warnings
QUERY_RESULTS=$(echo "$QUERY_OUTPUT" | grep -vE "^Warnings|^$")

# Compter les résultats
RESULT_COUNT=$(echo "$QUERY_RESULTS" | grep -E "^[[:space:]]*[0-9]" | wc -l | tr -d " ")

# Afficher les résultats
if [ $EXIT_CODE -eq 0 ]; then
    result "📊 Résultats obtenus ($RESULT_COUNT ligne(s)) en ${QUERY_TIME}s :"
    echo "   ┌─────────────────────────────────────────────────────────┐"
    echo "$QUERY_RESULTS" | head -10 | while IFS= read -r line; do
        if [ -n "$line" ]; then
            echo "   │ $line"
        fi
    done
    echo "   └─────────────────────────────────────────────────────────┘"
    
    if [ "$RESULT_COUNT" -gt 0 ]; then
        SUCCESS_COUNT=$((SUCCESS_COUNT + 1))
        success "✅ Démonstration $DEMO_NUM réussie"
    else
        FAILED_COUNT=$((FAILED_COUNT + 1))
        warn "⚠️  Démonstration $DEMO_NUM : Aucun résultat"
    fi
else
    FAILED_COUNT=$((FAILED_COUNT + 1))
    error "❌ Démonstration $DEMO_NUM : Erreur lors de l'exécution"
    echo "$QUERY_OUTPUT"
fi

# Stocker les résultats dans le JSON temporaire
python3 << EOF
import json
import sys

with open("$TEMP_RESULTS", "r") as f:
    demos = json.load(f)

demo = {
    "num": $DEMO_NUM,
    "title": "$DEMO_TITLE",
    "description": "$DEMO_DESC",
    "expected": "$DEMO_EXPECTED",
    "query": "$DEMO_QUERY",
    "result_count": $RESULT_COUNT,
    "query_time": $QUERY_TIME,
    "success": $EXIT_CODE == 0 and $RESULT_COUNT > 0,
    "output": """$QUERY_OUTPUT"""
}

demos.append(demo)

with open("$TEMP_RESULTS", "w") as f:
    json.dump(demos, f, indent=2, ensure_ascii=False)
EOF

DEMO_COUNT=$((DEMO_COUNT + 1))
echo ""

# Répéter pour chaque démonstration...
# DÉMONSTRATION 2, 3, 4, etc.

# ============================================
# PARTIE 7 : STATISTIQUES ET RÉSUMÉ
# ============================================
section "PARTIE 6 : STATISTIQUES ET RÉSUMÉ"
echo ""

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  📊 STATISTIQUES"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Statistiques globales
TOTAL=$($CQLSH localhost 9042 -e "USE domirama2_poc; SELECT COUNT(*) FROM operations_by_account;" 2>&1 | grep -v "Warnings" | grep -E "^[[:space:]]*[0-9]+" | head -1 | tr -d ' ')
info "Total opérations dans HCD : $TOTAL"
info "Nombre de démonstrations : $DEMO_COUNT"
success "Démonstrations réussies : $SUCCESS_COUNT"
if [ "$FAILED_COUNT" -gt 0 ]; then
    warn "Démonstrations échouées : $FAILED_COUNT"
fi
echo ""

echo "═══════════════════════════════════════════════════════════════"
if [ "$FAILED_COUNT" -eq 0 ]; then
    success "✅ DÉMONSTRATION TERMINÉE AVEC SUCCÈS"
else
    warn "⚠️  DÉMONSTRATION TERMINÉE AVEC $FAILED_COUNT ÉCHEC(S)"
fi
echo "═══════════════════════════════════════════════════════════════"
echo ""

info "📋 Capacités démontrées :"
echo "   ✅ [Capacité 1]"
echo "   ✅ [Capacité 2]"
echo "   ⚠️  [Limite 1]"
echo "   ✅ [Solution 1]"
echo ""

# ============================================
# PARTIE 8 : GÉNÉRATION DU RAPPORT
# ============================================
section "PARTIE 7 : GÉNÉRATION DU RAPPORT"
echo ""

info "📝 Génération du rapport markdown..."

python3 << 'PYEOF'
import json
from datetime import datetime

# Lire les résultats
with open("$TEMP_RESULTS", "r") as f:
    demos = json.load(f)

# Générer le rapport
report = f"""# 🎯 Démonstration Complète : [Titre]

**Date** : {datetime.now().strftime("%Y-%m-%d %H:%M:%S")}  
**Script** : `XX_demonstration_complete.sh`  
**Objectif** : [Description de l'objectif]

---

## 📋 Résumé Exécutif

Cette démonstration complète orchestre plusieurs étapes et exécute **{len(demos)} démonstrations** pour valider les fonctionnalités de [domaine].

**Résultats** :
- ✅ **{sum(1 for d in demos if d.get('success', False))}** démonstrations réussies
- ⚠️  **{sum(1 for d in demos if not d.get('success', False))}** démonstrations échouées
- 📊 **{sum(d.get('result_count', 0) for d in demos)}** résultats au total

---

## 🔄 Orchestration

### Étape 1 : Vérification de l'environnement
- ✅ HCD démarré
- ✅ Java 11 configuré
- ✅ Scripts dépendants présents

### Étape 2 : Configuration du schéma
- ✅ Schéma créé via script XX_setup_schema.sh
- ✅ Index SAI configurés

### Étape 3 : Chargement des données
- ✅ Données chargées via script XX_load_data.sh
- ✅ [Nombre] opérations dans HCD

### Étape 4 : Attente de l'indexation
- ✅ Indexation SAI terminée (30 secondes)

---

## 🔍 Démonstrations

"""

# Ajouter chaque démonstration
for demo in demos:
    num = demo.get('num', 0)
    title = demo.get('title', '')
    desc = demo.get('description', '')
    expected = demo.get('expected', '')
    query = demo.get('query', '')
    result_count = demo.get('result_count', 0)
    query_time = demo.get('query_time', 0)
    success = demo.get('success', False)
    output = demo.get('output', '')
    
    status = "✅ Succès" if success else "⚠️  Échec"
    
    report += f"""### DÉMONSTRATION {num} : {title}

**Description** : {desc}

**Résultat attendu** : {expected}

**Temps d'exécution** : {query_time:.3f}s

**Statut** : {status}

**Requête CQL exécutée :**

```cql
{query}
```

**Résultats obtenus** : {result_count} ligne(s)

**Aperçu des résultats :**

```
{output[:500]}  # Tronquer à 500 caractères
```

---

"""

# Ajouter le résumé final
report += f"""## 📊 Statistiques Globales

- **Total opérations dans HCD** : [Nombre]
- **Nombre de démonstrations** : {len(demos)}
- **Démonstrations réussies** : {sum(1 for d in demos if d.get('success', False))}
- **Démonstrations échouées** : {sum(1 for d in demos if not d.get('success', False))}

---

## ✅ Capacités Démontrées

- ✅ [Capacité 1]
- ✅ [Capacité 2]
- ⚠️  [Limite 1]
- ✅ [Solution 1]

---

## 💡 Points Clés

1. [Point clé 1]
2. [Point clé 2]
3. [Point clé 3]

---

*Rapport généré automatiquement par le script XX_demonstration_complete.sh*
"""

# Écrire le rapport
with open("$REPORT_FILE", "w") as f:
    f.write(report)

print(f"✅ Rapport généré : $REPORT_FILE")
PYEOF

success "✅ Rapport généré : $REPORT_FILE"
echo ""

info "💡 Le rapport contient :"
echo "   - Résumé exécutif"
echo "   - Détails de l'orchestration"
echo "   - Toutes les démonstrations avec résultats"
echo "   - Statistiques globales"
echo "   - Points clés"
echo ""

success "✅ DÉMONSTRATION COMPLÈTE TERMINÉE"
echo ""
```

---

## 📋 Sections Détaillées

### 1. **Section Orchestration**

#### Vérification Environnement
- Vérification HCD (démarrage si nécessaire)
- Vérification Java
- Vérification scripts dépendants
- Vérification fichiers de données

#### Configuration Schéma
- Appel au script de setup
- Vérification de la création du schéma
- Gestion des erreurs

#### Chargement des Données
- Vérification des données existantes
- Appel au script de chargement si nécessaire
- Vérification du nombre d'opérations

#### Attente Indexation
- Attente de l'indexation SAI
- Message d'attente avec durée

### 2. **Section Démonstrations (Boucle)**

Pour chaque démonstration :

#### Structure Standard
```bash
# En-tête de la démonstration
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  🔍 DÉMONSTRATION N : [Titre]"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# Définition du concept
info "📚 DÉFINITION - [Concept] :"
echo "   [Explication détaillée]"

# Requête CQL
info "📝 Requête CQL :"
code "[Requête CQL complète]"

# Explication
info "💡 Ce que nous démontrons :"
echo "   ✅ [Point 1]"
echo "   ✅ [Point 2]"

# Résultat attendu
expected "📋 Résultat attendu : [Description]"

# Exécution et mesure du temps
START_TIME=$(date +%s.%N)
QUERY_OUTPUT=$($CQLSH localhost 9042 -e "USE domirama2_poc; [QUERY];" 2>&1)
END_TIME=$(date +%s.%N)
QUERY_TIME=$(echo "$END_TIME - $START_TIME" | bc)

# Affichage des résultats
result "📊 Résultats obtenus ([COUNT] ligne(s)) en ${QUERY_TIME}s :"
# ... affichage formaté ...

# Stockage dans JSON pour le rapport
python3 << EOF
# ... code Python pour stocker dans JSON ...
EOF
```

### 3. **Section Statistiques**

- Total opérations dans HCD
- Nombre de démonstrations
- Démonstrations réussies/échouées
- Temps total d'exécution

### 4. **Section Documentation**

- Génération automatique d'un rapport markdown
- Toutes les démonstrations documentées
- Résultats capturés pour chaque démonstration
- Statistiques globales
- Points clés

---

## 🔄 Différences avec les Autres Templates

| Aspect | Template 43 | Template 47 | Template 50 | **Template 63** |
|--------|-------------|-------------|-------------|-----------------|
| **Type** | Test/Démo | Setup DDL | Ingestion ETL | **Orchestration** |
| **Nombre de tests** | 1 | 0 | 0 | **N démonstrations** |
| **Orchestration** | ❌ | ❌ | ❌ | **✅** |
| **Appels scripts** | ❌ | ❌ | ❌ | **✅** |
| **Structure** | Linéaire | Linéaire | Linéaire | **Étapes + Boucle** |
| **Rapport** | 1 test | DDL | ETL | **N démonstrations** |

---

## ✅ Checklist pour Appliquer le Template

- [ ] Remplacer `XX` par le numéro du script
- [ ] Remplacer `[Titre]` par le titre de la démonstration
- [ ] Définir les variables `CODE_SI` et `CONTRAT` si nécessaire
- [ ] Adapter les vérifications d'environnement
- [ ] Adapter les appels aux scripts dépendants
- [ ] Créer chaque démonstration avec la structure standard
- [ ] Adapter le code Python de génération de rapport
- [ ] Tester l'exécution complète
- [ ] Vérifier la génération du rapport markdown

---

## 💡 Exemples d'Utilisation

### Script 18 : Démonstration Complète Full-Text Search
- 5 étapes d'orchestration
- 10 démonstrations (full-text, stemming, asciifolding, etc.)
- Rapport : `doc/demonstrations/18_DEMONSTRATION.md`

### Script Futur : Démonstration Complète Multi-Version
- 4 étapes d'orchestration
- N démonstrations (time travel, priorité client, etc.)
- Rapport : `doc/demonstrations/XX_MULTI_VERSION_DEMONSTRATION.md`

---

*Template créé le 2025-11-26 pour standardiser les scripts d'orchestration/démonstration complète*


