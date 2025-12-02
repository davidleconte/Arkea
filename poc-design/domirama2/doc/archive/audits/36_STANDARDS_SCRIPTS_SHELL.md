# 📋 Standards et Bonnes Pratiques : Scripts Shell

**Date** : 2025-11-25  
**Objectif** : Définir les standards de documentation et bonnes pratiques pour tous les scripts shell du POC Domirama2

---

## 🎯 Objectifs

1. **Conformité aux bonnes pratiques** : Scripts robustes, maintenables, sécurisés
2. **Compréhensibilité** : Un développeur externe doit pouvoir comprendre et utiliser les scripts sans connaissance préalable du POC

---

## ✅ Bonnes Pratiques Obligatoires

### 1. En-tête du Script

**Format standard** :

```bash
#!/bin/bash
# ============================================
# Script XX : Nom du Script
# Description courte et claire (1-2 lignes)
# ============================================
#
# OBJECTIF :
#   Description détaillée de ce que fait le script (3-5 lignes)
#
# PRÉREQUIS :
#   - Liste des prérequis (HCD démarré, données chargées, etc.)
#   - Scripts à exécuter avant celui-ci
#
# UTILISATION :
#   ./XX_nom_script.sh [paramètres optionnels]
#
# EXEMPLE :
#   ./XX_nom_script.sh param1 param2
#
# SORTIE :
#   - Ce que le script produit (fichiers, données, etc.)
#   - Messages de succès/erreur
#
# ============================================
```

**Exemple complet** :

```bash
#!/bin/bash
# ============================================
# Script 10 : Configuration du POC Domirama2
# Crée le schéma HCD avec toutes les colonnes nécessaires
# ============================================
#
# OBJECTIF :
#   Ce script initialise le keyspace 'domirama2_poc' et la table
#   'operations_by_account' avec toutes les colonnes de catégorisation
#   (cat_auto, cat_confidence, cat_user, cat_date_user, cat_validee).
#   Il crée également les index SAI pour la recherche full-text.
#
# PRÉREQUIS :
#   - HCD 1.2.3 doit être démarré (./03_start_hcd.sh)
#   - Java 11 configuré via jenv
#   - Fichier schéma : schemas/01_create_domirama2_schema.cql
#
# UTILISATION :
#   ./10_setup_domirama10_setup_domirama2_poc.sh
#
# EXEMPLE :
#   ./10_setup_domirama10_setup_domirama2_poc.sh
#
# SORTIE :
#   - Keyspace 'domirama2_poc' créé
#   - Table 'operations_by_account' créée avec toutes les colonnes
#   - Index SAI créés
#   - Messages de validation affichés
#
# ============================================
```

---

### 2. Gestion des Erreurs

**Obligatoire** :

```bash
set -e  # Arrêter en cas d'erreur
set -u  # Erreur si variable non définie (optionnel mais recommandé)
set -o pipefail  # Erreur si une commande dans un pipe échoue (optionnel)
```

**Gestion explicite** :

```bash
# Vérifier les prérequis
if ! command -v python3 &> /dev/null; then
    error "Python3 n'est pas installé"
    error "Installez Python3 : brew install python3"
    exit 1
fi
```

---

### 3. Variables et Configuration

**Définir toutes les variables en haut** :

```bash
# Configuration
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
INSTALL_DIR="/Users/david.leconte/Documents/Arkea"
HCD_DIR="${INSTALL_DIR}/binaire/hcd-1.2.3"
SCHEMA_FILE="${SCRIPT_DIR}/schemas/01_create_domirama2_schema.cql"
```

**Commenter les variables importantes** :

```bash
# Chemin vers le fichier schéma CQL (doit exister)
SCHEMA_FILE="${SCRIPT_DIR}/schemas/01_create_domirama2_schema.cql"

# Port CQL par défaut pour HCD
CQL_PORT=9042
```

---

### 4. Fonctions Utilitaires

**Définir les fonctions de logging** :

```bash
# Couleurs pour les messages
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Fonctions de logging
info() { echo -e "${BLUE}ℹ️  $1${NC}"; }
success() { echo -e "${GREEN}✅ $1${NC}"; }
warn() { echo -e "${YELLOW}⚠️  $1${NC}"; }
error() { echo -e "${RED}❌ $1${NC}"; }
```

---

### 5. Vérifications Préalables

**Toujours vérifier les prérequis** :

```bash
# Vérifier que HCD est démarré
if ! pgrep -f "cassandra" > /dev/null; then
    error "HCD n'est pas démarré"
    error "Exécutez d'abord: ./03_start_hcd.sh"
    exit 1
fi

# Vérifier que le fichier existe
if [ ! -f "$SCHEMA_FILE" ]; then
    error "Fichier schéma non trouvé: $SCHEMA_FILE"
    error "Vérifiez que le fichier existe dans schemas/"
    exit 1
fi
```

---

### 6. Messages Informatifs

**Expliquer chaque étape** :

```bash
info "🔍 Vérification que HCD est prêt..."
# ... vérification ...

info "📋 Configuration du schéma Domirama2..."
info "   Keyspace: domirama2_poc"
info "   Table: operations_by_account"
# ... exécution ...

success "✅ Configuration terminée !"
```

---

### 7. Documentation des Paramètres

**Si le script accepte des paramètres** :

```bash
# ============================================
# PARAMÈTRES :
#   $1 : Date de début (format: YYYY-MM-DD)
#   $2 : Date de fin (format: YYYY-MM-DD)
#   $3 : Chemin de sortie (optionnel, défaut: /tmp/exports)
#
# EXEMPLE :
#   ./27_export_incremental_parquet.sh "2024-01-01" "2024-02-01" "/tmp/exports"
# ============================================

# Validation des paramètres
if [ $# -lt 2 ]; then
    error "Usage: $0 <start_date> <end_date> [output_path]"
    error "Exemple: $0 '2024-01-01' '2024-02-01' '/tmp/exports'"
    exit 1
fi

START_DATE="$1"
END_DATE="$2"
OUTPUT_PATH="${3:-/tmp/exports}"
```

---

## 📋 Checklist de Documentation

Pour chaque script, vérifier :

- [ ] **En-tête complet** : OBJECTIF, PRÉREQUIS, UTILISATION, EXEMPLE, SORTIE
- [ ] **Shebang** : `#!/bin/bash`
- [ ] **Gestion d'erreurs** : `set -e` (au minimum)
- [ ] **Variables documentées** : Toutes les variables importantes commentées
- [ ] **Vérifications préalables** : Prérequis vérifiés avec messages clairs
- [ ] **Messages informatifs** : Chaque étape expliquée
- [ ] **Gestion des erreurs** : Messages d'erreur explicites avec solutions
- [ ] **Exemples d'utilisation** : Si le script accepte des paramètres
- [ ] **Prochaines étapes** : Indiquer ce qu'il faut faire après

---

## 🎯 Niveau de Documentation Requis

### Pour un Développeur Externe

Un développeur externe doit pouvoir :

1. **Comprendre l'objectif** : Lire l'en-tête et savoir ce que fait le script
2. **Vérifier les prérequis** : Savoir ce qui doit être installé/configuré avant
3. **Exécuter le script** : Comprendre comment l'utiliser (paramètres, exemples)
4. **Interpréter les résultats** : Comprendre les messages de succès/erreur
5. **Trouver de l'aide** : Savoir quoi faire en cas d'erreur

---

## 📝 Exemple de Script Bien Documenté

```bash
#!/bin/bash
# ============================================
# Script 25 : Test de Recherche Hybride
# Démonstration de la recherche combinant Full-Text et Vector Search
# ============================================
#
# OBJECTIF :
#   Ce script démontre la recherche hybride qui combine :
#   1. Full-Text Search (SAI) : Filtre initial pour la précision
#   2. Vector Search (ByteT5) : Tri par similarité pour tolérer les typos
#  
#   La recherche hybride offre une meilleure pertinence que chaque
#   approche seule, en combinant précision et tolérance aux erreurs.
#
# PRÉREQUIS :
#   - HCD démarré (./03_start_hcd.sh)
#   - Schéma configuré (./10_setup_domirama10_setup_domirama2_poc.sh)
#   - Données chargées (./11_load_domirama11_load_domirama2_data_parquet.sh)
#   - Fuzzy search configuré (./21_setup_fuzzy_search.sh)
#   - Embeddings générés (./22_generate_embeddings.sh)
#   - Python 3 avec transformers et torch installés
#
# UTILISATION :
#   ./25_test_hybrid_search.sh
#
# EXEMPLE :
#   ./25_test_hybrid_search.sh
#
# SORTIE :
#   - Résultats de recherche pour plusieurs requêtes de test
#   - Comparaison Full-Text vs Vector vs Hybride
#   - Messages de succès/erreur
#
# ============================================

set -e

# Couleurs pour les messages
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Fonctions de logging
info() { echo -e "${BLUE}ℹ️  $1${NC}"; }
success() { echo -e "${GREEN}✅ $1${NC}"; }
warn() { echo -e "${YELLOW}⚠️  $1${NC}"; }
error() { echo -e "${RED}❌ $1${NC}"; }

# Configuration
INSTALL_DIR="/Users/david.leconte/Documents/Arkea"
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
PYTHON_SCRIPT="${SCRIPT_DIR}/examples/python/search/hybrid_search.py"

# Vérifications préalables
if ! pgrep -f "cassandra" > /dev/null; then
    error "HCD n'est pas démarré"
    error "Exécutez d'abord: ./03_start_hcd.sh"
    exit 1
fi

if [ ! -f "$PYTHON_SCRIPT" ]; then
    error "Script Python non trouvé: $PYTHON_SCRIPT"
    error "Vérifiez que le fichier existe dans examples/python/search/"
    exit 1
fi

# ... reste du script ...
```

---

## ✅ Conformité Actuelle

### Scripts Bien Documentés

- ✅ `10_setup_domirama10_setup_domirama2_poc.sh` : Bon en-tête, vérifications
- ✅ `11_load_domirama11_load_domirama2_data_parquet.sh` : Documentation complète
- ✅ `25_test_hybrid_search.sh` : Bonne structure

### Scripts à Améliorer

- ⚠️ Certains scripts manquent de détails dans l'en-tête
- ⚠️ Certains scripts n'ont pas d'exemples d'utilisation
- ⚠️ Certains scripts n'expliquent pas les prérequis en détail

---

## 🎯 Plan d'Action

1. **Auditer tous les scripts** : Identifier ceux qui manquent de documentation
2. **Créer un template** : Template standard pour tous les scripts
3. **Améliorer les scripts** : Ajouter la documentation manquante
4. **Valider** : Vérifier qu'un développeur externe peut comprendre

---

**✅ Standards définis pour une documentation complète et compréhensible !**
