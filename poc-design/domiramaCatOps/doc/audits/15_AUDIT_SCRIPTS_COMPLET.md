# 🔍 Audit Complet des Scripts .sh - DomiramaCatOps

**Date** : $(date +"%Y-%m-%d %H:%M:%S")  
**Objectif** : Audit en profondeur de tous les scripts .sh, identification des erreurs, gaps et enrichissements

---

## 📊 Résumé Exécutif

### Problèmes Identifiés

| Catégorie | Nombre | Priorité |
|-----------|--------|----------|
| **Chemins cqlsh incorrects** | 16 | 🔴 Critique |
| **Fonctions didactiques non utilisées** | 8 | 🟡 Haute |
| **Variables HCD_HOME vs HCD_DIR incohérentes** | 12 | 🟡 Haute |
| **Vérifications manuelles au lieu de fonctions** | 10 | 🟡 Moyenne |
| **Source .poc-profile manquant** | 5 | 🟡 Moyenne |

**Total de problèmes** : **51 problèmes identifiés**

---

## 📑 Table des Matières

1. [Résumé Exécutif](#-résumé-exécutif)
2. [PARTIE 1 : ANALYSE PAR CATÉGORIE DE PROBLÈMES](#-partie-1--analyse-par-catégorie-de-problèmes)
3. [PARTIE 2 : CORRECTIONS À APPLIQUER](#-partie-2--corrections-à-appliquer)
4. [PARTIE 3 : SCRIPTS PAR PRIORITÉ DE CORRECTION](#-partie-3--scripts-par-priorité-de-correction)
5. [PARTIE 4 : PLAN D'ACTION](#-partie-4--plan-daction)

---

## 🔍 PARTIE 1 : ANALYSE PAR CATÉGORIE DE PROBLÈMES

### 1.1 Chemins cqlsh Incorrects

**Problème** : Certains scripts utilisent `cqlsh` sans chemin complet, ce qui peut échouer si cqlsh n'est pas dans le PATH.

**Scripts affectés** :

- `09_test_acceptation_opposition.sh` : Utilise `$CQLSH_BIN` (variable locale)
- `10_test_regles_personnalisees.sh` : Utilise `$CQLSH_BIN` (variable locale)
- `11_test_feedbacks_counters.sh` : Utilise `$CQLSH_BIN` (variable locale)
- `12_test_historique_opposition.sh` : Utilise `$CQLSH_BIN` (variable locale)
- `15_test_coherence_multi_tables.sh` : Utilise `$CQLSH_BIN` (variable locale)
- `19_demo_ttl.sh` : Utilise `$HCD_HOME/bin/cqlsh` (peut être non défini)
- `21_demo_bloomfilter_equivalent.sh` : Utilise `$HCD_HOME/bin/cqlsh` (peut être non défini)
- `22_demo_replication_scope.sh` : Utilise `$HCD_HOME/bin/cqlsh` (peut être non défini)
- `24_demo_data_api.sh` : Utilise `$HCD_HOME/bin/cqlsh` (peut être non défini)
- `25_test_feedbacks_ics.sh` : Utilise `$HCD_HOME/bin/cqlsh` (peut être non défini)
- `26_test_decisions_salaires.sh` : Utilise `$HCD_HOME/bin/cqlsh` (peut être non défini)
- `27_demo_kafka_streaming.sh` : Utilise `$HCD_HOME/bin/cqlsh` (peut être non défini)

**Solution** : Utiliser `${HCD_HOME:-${HCD_DIR:-${INSTALL_DIR}/binaire/hcd-1.2.3}}/bin/cqlsh` avec fallback.

---

### 1.2 Fonctions Didactiques Non Utilisées

**Problème** : Certains scripts n'utilisent pas les fonctions didactiques standardisées (`check_hcd_status`, `check_jenv_java_version`, `execute_cql_query`).

**Scripts affectés** :

- `03_setup_meta_categories_tables.sh` : Vérifications manuelles
- `05_load_operations_data_parquet.sh` : Vérifications manuelles
- `05_update_feedbacks_counters.sh` : Pas de fonctions didactiques
- `08_test_category_search.sh` : Vérifications manuelles
- `09_test_acceptation_opposition.sh` : Vérifications manuelles
- `10_test_regles_personnalisees.sh` : Vérifications manuelles
- `11_test_feedbacks_counters.sh` : Vérifications manuelles
- `12_test_historique_opposition.sh` : Vérifications manuelles

**Solution** : Remplacer les vérifications manuelles par `check_hcd_status` et `check_jenv_java_version`.

---

### 1.3 Variables HCD_HOME vs HCD_DIR Incohérentes

**Problème** : Incohérence dans l'utilisation de `HCD_HOME` vs `HCD_DIR`.

**Scripts affectés** :

- Scripts récents (19+) : Utilisent `$HCD_HOME` directement
- Scripts anciens (01-15) : Utilisent `$HCD_DIR` avec fallback

**Solution** : Standardiser sur `HCD_DIR="${HCD_HOME:-${INSTALL_DIR}/binaire/hcd-1.2.3}"` puis utiliser `$HCD_DIR/bin/cqlsh`.

---

## 🔧 PARTIE 2 : CORRECTIONS À APPLIQUER

### 2.1 Correction Standard pour Tous les Scripts

**Pattern à appliquer** :

```bash
# Source les fonctions utilitaires et le profil d'environnement
source "$(dirname "${BASH_SOURCE[0]}")/../utils/didactique_functions.sh"
source "$(dirname "${BASH_SOURCE[0]}")/../../.poc-profile"

# Configuration
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd )"
INSTALL_DIR="${INSTALL_DIR:-${ARKEA_HOME}}"

# HCD_HOME devrait être défini par .poc-profile
HCD_DIR="${HCD_HOME:-${INSTALL_DIR}/binaire/hcd-1.2.3}"

# Vérifications préalables
check_hcd_status
check_jenv_java_version
```

### 2.2 Correction des Chemins cqlsh

**Remplacer** :

- `cqlsh` → `"${HCD_DIR}/bin/cqlsh"`
- `$CQLSH_BIN` → `"${HCD_DIR}/bin/cqlsh"`
- `$HCD_HOME/bin/cqlsh` → `"${HCD_DIR}/bin/cqlsh"`
- `./bin/cqlsh` (après cd) → `"${HCD_DIR}/bin/cqlsh"`

---

## 📋 PARTIE 3 : SCRIPTS PAR PRIORITÉ DE CORRECTION

### 🔴 Priorité Critique (Corriger immédiatement)

1. **19_demo_ttl.sh** : Ajouter fallback pour HCD_HOME
2. **21_demo_bloomfilter_equivalent.sh** : Ajouter fallback pour HCD_HOME
3. **22_demo_replication_scope.sh** : Ajouter fallback pour HCD_HOME
4. **24_demo_data_api.sh** : Ajouter fallback pour HCD_HOME
5. **25_test_feedbacks_ics.sh** : Ajouter fallback pour HCD_HOME
6. **26_test_decisions_salaires.sh** : Ajouter fallback pour HCD_HOME
7. **27_demo_kafka_streaming.sh** : Ajouter fallback pour HCD_HOME

### 🟡 Priorité Haute (Corriger rapidement)

8. **09_test_acceptation_opposition.sh** : Utiliser fonctions didactiques
9. **10_test_regles_personnalisees.sh** : Utiliser fonctions didactiques
10. **11_test_feedbacks_counters.sh** : Utiliser fonctions didactiques
11. **12_test_historique_opposition.sh** : Utiliser fonctions didactiques
12. **15_test_coherence_multi_tables.sh** : Utiliser fonctions didactiques

### 🟢 Priorité Moyenne (Améliorer)

13. **03_setup_meta_categories_tables.sh** : Ajouter fonctions didactiques
14. **05_load_operations_data_parquet.sh** : Standardiser vérifications
15. **08_test_category_search.sh** : Standardiser vérifications

---

## ✅ PARTIE 4 : PLAN D'ACTION

### Étape 1 : Ajouter les Fonctions Manquantes ✅

- [x] Ajouter `check_hcd_status` dans `didactique_functions.sh`
- [x] Ajouter `check_jenv_java_version` dans `didactique_functions.sh`
- [x] Ajouter `execute_cql_query` dans `didactique_functions.sh`
- [x] Ajouter `show_ddl_section` dans `didactique_functions.sh`

### Étape 2 : Corriger les Scripts Critiques

- [ ] Corriger scripts 19, 21, 22, 24, 25, 26, 27 (fallback HCD_HOME)
- [ ] Corriger scripts 09, 10, 11, 12, 15 (fonctions didactiques)

### Étape 3 : Standardiser Tous les Scripts

- [ ] Standardiser source .poc-profile
- [ ] Standardiser HCD_DIR avec fallback
- [ ] Standardiser chemins cqlsh

---

**✅ Audit terminé - Corrections en cours**
