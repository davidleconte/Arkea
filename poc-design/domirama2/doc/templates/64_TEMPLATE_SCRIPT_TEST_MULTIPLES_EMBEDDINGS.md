# 📋 Template : Script Shell Didactique pour Tests Multiples avec Embeddings

**Date** : 2025-11-26
**Objectif** : Template réutilisable pour créer des scripts de test avec embeddings et tests multiples très didactiques
**Type** : Scripts qui testent des fonctionnalités utilisant des embeddings (ByteT5, etc.) avec N tests

---

## 🎯 Principes du Template pour Tests Multiples avec Embeddings

Un script de test avec embeddings didactique doit :

1. **Afficher le DDL complet** : Schéma avec colonne VECTOR et index vectoriel
2. **Vérifier les dépendances Python** : transformers, torch, cassandra-driver
3. **Démontrer la génération d'embeddings** : Exemple concret avec affichage du vecteur
4. **Définir le concept** : Explication détaillée avec comparaison des approches
5. **Exécuter N tests** : Chaque test avec description, attendu, stratégie, requête, résultats
6. **Contrôler la cohérence** : Vérification présence données, couverture embeddings, pertinence résultats
7. **Générer un rapport** : Documentation structurée pour livrable avec tous les tests

---

## 📝 Structure Standard pour Script de Test avec Embeddings

```bash
#!/bin/bash
# ============================================
# Script XX : Test [Nom] avec Embeddings (Version Didactique)
# Démonstration détaillée avec embeddings et tests multiples
# ============================================
#
# OBJECTIF :
#   Ce script démontre de manière très didactique [fonctionnalité]
#   qui utilise des embeddings [modèle] pour [objectif].
#
#   Cette version améliorée affiche :
#   - Le DDL complet (schéma avec embeddings)
#   - Vérification des dépendances Python
#   - Démonstration de génération d'embeddings
#   - Définition et principe avec comparaison détaillée
#   - N tests avec résultats détaillés
#   - Contrôles de cohérence
#   - Documentation structurée
#
# PRÉREQUIS :
#   - HCD démarré (./scripts/setup/03_start_hcd.sh)
#   - Schéma configuré (./10_setup_domirama2_poc.sh)
#   - Données chargées (./11_load_domirama2_data_parquet.sh)
#   - Python 3.8+ avec transformers, torch, cassandra-driver installés
#   - Clé API Hugging Face configurée (HF_API_KEY dans .poc-profile)
#
# UTILISATION :
#   ./XX_test.sh
#
# SORTIE :
#   - DDL complet affiché
#   - Dépendances vérifiées
#   - Embeddings démontrés
#   - N tests avec résultats
#   - Contrôles de cohérence
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
INSTALL_DIR="${ARKEA_HOME}"
HCD_DIR="${INSTALL_DIR}/binaire/hcd-1.2.3"
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
REPORT_FILE="${SCRIPT_DIR}/doc/demonstrations/XX_DEMONSTRATION.md"

# Créer le répertoire de documentation
mkdir -p "$(dirname "$REPORT_FILE")"

# Variables de test
CODE_SI="1"
CONTRAT="5913101072"
MODEL_NAME="google/byt5-small"
VECTOR_DIMENSION=1472

# Vérifier que HCD est démarré
if ! pgrep -f "cassandra" > /dev/null; then
    error "HCD n'est pas démarré. Exécutez d'abord: ./scripts/setup/03_start_hcd.sh"
    exit 1
fi

cd "$HCD_DIR"
jenv local 11
eval "$(jenv init -)"

# Charger la clé API Hugging Face
if [ -f "$INSTALL_DIR/.poc-profile" ]; then
    source "$INSTALL_DIR/.poc-profile" 2>/dev/null || true
fi

if [ -z "$HF_API_KEY" ]; then
    export HF_API_KEY="${HF_API_KEY:-}"
    warn "⚠️  HF_API_KEY non définie dans .poc-profile, utilisation de la clé par défaut."
fi

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  🔍 DÉMONSTRATION DIDACTIQUE COMPLÈTE : [Titre]"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
info "📚 Cette démonstration affiche :"
echo "   ✅ DDL complet (schéma avec embeddings)"
echo "   ✅ Vérification des dépendances Python"
echo "   ✅ Démonstration de génération d'embeddings"
echo "   ✅ Définition et principe avec comparaison détaillée"
echo "   ✅ N tests avec résultats détaillés"
echo "   ✅ Contrôles de cohérence"
echo "   ✅ Documentation structurée générée automatiquement"
echo ""

# ============================================
# PARTIE 1: DDL - Schéma avec Embeddings
# ============================================
echo ""
section "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
section "  📋 PARTIE 1: DDL - SCHÉMA AVEC EMBEDDINGS"
section "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

info "📚 CONTEXTE - [Fonctionnalité] dans HCD :"
echo ""
echo "   HBase :"
echo "      ❌ [Limitation HBase]"
echo ""
echo "   HCD :"
echo "      ✅ [Avantage HCD 1]"
echo "      ✅ [Avantage HCD 2]"
echo "      ✅ [Avantage HCD 3]"
echo ""

info "📝 DDL - Index Full-Text (SAI) :"
echo ""
code "CREATE CUSTOM INDEX idx_libelle_fulltext"
code "ON operations_by_account(libelle)"
code "USING 'StorageAttachedIndex'"
code "WITH OPTIONS = {"
code "  'index_analyzer': '{"
code "    \"tokenizer\": {\"name\": \"standard\"},"
code "    \"filters\": ["
code "      {\"name\": \"lowercase\"},"
code "      {\"name\": \"frenchLightStem\"},"
code "      {\"name\": \"asciiFolding\"}"
code "    ]"
code "  }'"
code "};"
echo ""

info "📝 DDL - Colonne VECTOR :"
echo ""
code "ALTER TABLE operations_by_account"
code "ADD libelle_embedding VECTOR<FLOAT, 1472>;"
echo ""

info "📝 DDL - Index Vectoriel (SAI) :"
echo ""
code "CREATE CUSTOM INDEX idx_libelle_embedding_vector"
code "ON operations_by_account(libelle_embedding)"
code "USING 'StorageAttachedIndex';"
echo ""

# Vérification
info "🔍 Vérification du schéma..."
# [Code de vérification]
success "✅ Schéma vérifié"
echo ""

# ============================================
# PARTIE 2: Vérification des Dépendances
# ============================================
echo ""
section "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
section "  🔧 PARTIE 2: VÉRIFICATION DES DÉPENDANCES PYTHON"
section "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

info "📋 Vérification des dépendances Python..."
echo ""

# Vérifier Python
if ! command -v python3 &> /dev/null; then
    error "Python3 n'est pas installé"
    exit 1
fi
success "✅ Python3 installé : $(python3 --version)"
echo ""

# Vérifier transformers
if ! python3 -c "import transformers" 2>/dev/null; then
    warn "⚠️  transformers n'est pas installé"
    info "📦 Installation des dépendances..."
    pip3 install transformers torch cassandra-driver --quiet
    success "✅ Dépendances installées"
else
    success "✅ transformers installé"
fi

# Vérifier torch
if ! python3 -c "import torch" 2>/dev/null; then
    warn "⚠️  torch n'est pas installé"
    info "📦 Installation de torch..."
    pip3 install torch --quiet
    success "✅ torch installé"
else
    success "✅ torch installé"
fi

# Vérifier cassandra-driver
if ! python3 -c "import cassandra" 2>/dev/null; then
    warn "⚠️  cassandra-driver n'est pas installé"
    info "📦 Installation de cassandra-driver..."
    pip3 install cassandra-driver --quiet
    success "✅ cassandra-driver installé"
else
    success "✅ cassandra-driver installé"
fi

echo ""
info "📋 Configuration Hugging Face :"
echo "   Clé API : $([ -n \"$HF_API_KEY\" ] && echo '[CONFIGURÉE]' || echo '[NON CONFIGURÉE]')"
success "✅ Configuration OK"
echo ""

# ============================================
# PARTIE 3: Démonstration de Génération d'Embeddings
# ============================================
echo ""
section "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
section "  🔄 PARTIE 3: DÉMONSTRATION DE GÉNÉRATION D'EMBEDDINGS"
section "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

info "📚 DÉFINITION - Génération d'Embeddings :"
echo ""
echo "   Les embeddings sont des représentations vectorielles des textes qui"
echo "   capturent leur signification sémantique. [MODÈLE] génère des vecteurs"
echo "   de [DIMENSION] dimensions pour chaque texte."
echo ""
echo "   Processus :"
echo "   1. Le texte est tokenisé (découpé en tokens)"
echo "   2. Le modèle [MODÈLE] encode le texte en vecteur"
echo "   3. Le vecteur est normalisé (moyenne des tokens)"
echo "   4. Le vecteur est stocké dans la colonne [COLONNE_EMBEDDING]"
echo ""

expected "📋 Test de génération d'embedding :"
echo "   Texte : '[TEXTE_EXEMPLE]'"
echo "   Résultat attendu : Vecteur de [DIMENSION] dimensions généré"
echo ""

info "🚀 Génération de l'embedding de démonstration..."
echo ""

# [Code Python pour générer un embedding de démonstration]
# [Afficher le vecteur généré]

echo ""

# ============================================
# PARTIE 4: Définition et Principe avec Comparaison
# ============================================
echo ""
section "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
section "  📚 PARTIE 4: DÉFINITION ET PRINCIPE - [CONCEPT]"
section "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

info "📚 DÉFINITION - [Concept] :"
echo ""
echo "   [Explication détaillée du concept]"
echo ""

info "💡 Comparaison des Approches :"
echo ""
echo "   | Aspect | Full-Text (SAI) | Vector (ByteT5) | Hybrid (Full-Text + Vector) |"
echo "   |--------|-----------------|-----------------|----------------------------|"
echo "   | **Précision** | ✅ Excellente | ⚠️  Variable | ✅ Excellente |"
echo "   | **Tolérance typos** | ❌ Aucune | ✅ Excellente | ✅ Excellente |"
echo "   | **Latence** | ✅ Faible | ⚠️  Moyenne | ⚠️  Moyenne |"
echo "   | **Stockage** | ✅ Faible | ⚠️  Élevé | ⚠️  Élevé |"
echo "   | **Cas d'usage** | Requêtes exactes | Recherche sémantique | Recherche générale |"
echo ""

info "🎯 Recommandations :"
echo ""
echo "   ✅ Utiliser Full-Text seul pour :"
echo "      - Requêtes exactes sans risque de typos"
echo "      - Performance maximale"
echo ""
echo "   ✅ Utiliser Vector seul pour :"
echo "      - Recherche sémantique (comprend le sens)"
echo "      - Typos sévères"
echo ""
echo "   ✅ Utiliser Hybrid pour :"
echo "      - Recherche générale (précision + tolérance typos)"
echo "      - Meilleure pertinence globale"
echo ""

# ============================================
# PARTIE 5: Tests Multiples (Boucle Python)
# ============================================
echo ""
section "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
section "  🧪 PARTIE 5: TESTS DE [FONCTIONNALITÉ]"
section "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

info "📋 Configuration des tests :"
echo "   - Partition : code_si = '$CODE_SI', contrat = '$CONTRAT'"
echo "   - Modèle : $MODEL_NAME ($VECTOR_DIMENSION dimensions)"
echo "   - Clé API Hugging Face : $([ -n \"$HF_API_KEY\" ] && echo '[CONFIGURÉE]' || echo '[NON CONFIGURÉE]')"
echo ""

# Créer un script Python pour les tests
TEMP_SCRIPT=$(mktemp)
TEMP_RESULTS="${TEMP_SCRIPT}.results.json"
cat > "$TEMP_SCRIPT" << 'PYTHON_SCRIPT'
import os
import sys
import torch
from transformers import AutoTokenizer, AutoModel
from cassandra.cluster import Cluster
from cassandra.query import SimpleStatement
import json
import time
from decimal import Decimal

# Configuration
MODEL_NAME = "google/byt5-small"
VECTOR_DIMENSION = 1472
HF_API_KEY = os.getenv("HF_API_KEY")
CODE_SI = "CODE_SI_PLACEHOLDER"
CONTRAT = "CONTRAT_PLACEHOLDER"

# Tests à exécuter
test_cases = [
    {
        "query": "[REQUÊTE_1]",
        "description": "[Description test 1]",
        "expected": "[Résultat attendu test 1]",
        "strategy": "[Stratégie test 1]",
        "explanation": "[Explication détaillée de ce qui est démontré]"
    },
    # ... autres tests ...
]

# [Code Python pour exécuter les tests]
# [Stockage des résultats dans JSON]

PYTHON_SCRIPT

# Remplacer les placeholders
sed -i '' "s/CODE_SI_PLACEHOLDER/$CODE_SI/g" "$TEMP_SCRIPT"
sed -i '' "s/CONTRAT_PLACEHOLDER/$CONTRAT/g" "$TEMP_SCRIPT"
sed -i '' "s|RESULTS_FILE_PLACEHOLDER|$TEMP_RESULTS|g" "$TEMP_SCRIPT"

info "🚀 Exécution des tests..."
HF_API_KEY="$HF_API_KEY" python3 "$TEMP_SCRIPT"

# Vérifier que le fichier de résultats existe
if [ ! -f "$TEMP_RESULTS" ]; then
    warn "⚠️  Fichier de résultats non trouvé"
    echo "[]" > "$TEMP_RESULTS"
fi

rm -f "$TEMP_SCRIPT"

# ============================================
# PARTIE 6: Contrôles de Cohérence
# ============================================
echo ""
section "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
section "  🔍 PARTIE 6: CONTRÔLES DE COHÉRENCE"
section "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

info "📊 Vérification de la cohérence des résultats..."
echo ""

# [Code Python pour contrôles de cohérence]
# - Vérification présence données
# - Vérification couverture embeddings
# - Vérification pertinence résultats
# - Métriques de performance

echo ""

# ============================================
# PARTIE 7: Résumé et Conclusion
# ============================================
echo ""
section "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
section "  📊 PARTIE 7: RÉSUMÉ ET CONCLUSION"
section "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

info "📊 Résumé de la démonstration complète :"
echo ""
echo "   ✅ PARTIE 1 : DDL - Schéma avec embeddings"
echo "   ✅ PARTIE 2 : Dépendances Python vérifiées/installées"
echo "   ✅ PARTIE 3 : Génération d'embeddings démontrée"
echo "   ✅ PARTIE 4 : Définition et principe avec comparaison"
echo "   ✅ PARTIE 5 : Tests avec résultats détaillés"
echo "   ✅ PARTIE 6 : Contrôles de cohérence"
echo "   ✅ Documentation structurée générée automatiquement"
echo ""

# Générer le rapport markdown
info "📝 Génération du rapport de démonstration..."
# [Code Python pour générer le rapport markdown complet]

success "✅ Démonstration terminée !"
success "📝 Documentation générée : $REPORT_FILE"
```

---

## 📋 Sections Détaillées

### 1. **PARTIE 1 : DDL - Schéma avec Embeddings**

- Affiche le DDL complet (table, colonne VECTOR, index vectoriel)
- Contexte HBase → HCD
- Explications détaillées

### 2. **PARTIE 2 : Vérification des Dépendances Python**

- Vérifie Python, transformers, torch, cassandra-driver
- Installation automatique si nécessaire
- Configuration Hugging Face

### 3. **PARTIE 3 : Démonstration de Génération d'Embeddings**

- Définition des embeddings
- Génération d'un embedding de démonstration
- Affichage du vecteur généré

### 4. **PARTIE 4 : Définition et Principe avec Comparaison**

- Définition du concept
- **Tableau comparatif détaillé** (Full-Text vs Vector vs Hybrid)
- Recommandations par cas d'usage

### 5. **PARTIE 5 : Tests Multiples (Boucle Python)**

- Structure de test_cases avec :
  - query
  - description
  - expected
  - strategy
  - **explanation** (nouveau : explication détaillée)
- Pour chaque test :
  - Description
  - Résultat attendu
  - Stratégie
  - **Explication détaillée** (nouveau)
  - Génération embedding
  - Requête CQL affichée (formatée)
  - Exécution avec fallback si nécessaire
  - Résultats affichés (formatés)
  - Stockage dans JSON

### 6. **PARTIE 6 : Contrôles de Cohérence** (Nouveau)

- Vérification présence données
- Vérification couverture embeddings
- Vérification pertinence résultats
- Métriques de performance

### 7. **PARTIE 7 : Résumé et Conclusion**

- Résumé de la démonstration
- Comparaison détaillée des approches (tableau)
- Avantages et limitations
- Recommandations

---

## 🔄 Différences avec les Autres Templates

| Aspect | Template 43 | Template 63 | **Template 64** |
|--------|-------------|-------------|-----------------|
| **Type** | Test/Démo | Orchestration | **Test Multiples + Embeddings** |
| **Nombre de tests** | 1 | N (boucle shell) | **N (boucle Python)** |
| **Vérification dépendances** | ❌ | ⚠️ (optionnel) | **✅ (Python)** |
| **Démonstration embeddings** | ❌ | ❌ | **✅** |
| **DDL** | ⚠️ (optionnel) | ⚠️ (via scripts) | **✅ (complet)** |
| **Contrôles cohérence** | ❌ | ❌ | **✅** |
| **Comparaison approches** | ❌ | ❌ | **✅ (tableau)** |
| **Explications détaillées** | ⚠️ | ⚠️ | **✅ (par test)** |
| **Boucle** | ❌ | Shell | **Python** |

---

## ✅ Checklist pour Appliquer le Template 64

- [ ] Remplacer `XX` par le numéro du script
- [ ] Remplacer `[Nom]` par le nom de la fonctionnalité
- [ ] Adapter le DDL (PARTIE 1)
- [ ] Adapter la vérification dépendances (PARTIE 2)
- [ ] Adapter la démonstration embeddings (PARTIE 3)
- [ ] Adapter la définition et principe (PARTIE 4)
- [ ] Créer les test_cases avec `explanation` (PARTIE 5)
- [ ] Adapter le code Python de tests
- [ ] Ajouter les contrôles de cohérence (PARTIE 6)
- [ ] Adapter le résumé et conclusion (PARTIE 7)
- [ ] Tester l'exécution complète
- [ ] Vérifier la génération du rapport markdown

---

*Template créé le 2025-11-26 pour standardiser les scripts de test avec embeddings*
