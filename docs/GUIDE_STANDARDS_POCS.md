# 📐 Guide de Standards POCs - ARKEA

**Date** : 2026-03-13
**Version** : 1.0.0
**Objectif** : Standards communs pour tous les POCs du projet ARKEA

---

## 📋 Table des Matières

1. [Vue d'Ensemble](#vue-densemble)
2. [Structure Standardisée](#structure-standardisée)
3. [Standards de Documentation](#standards-de-documentation)
4. [Standards de Scripts](#standards-de-scripts)
5. [Conventions de Nommage](#conventions-de-nommage)
6. [Bonnes Pratiques](#bonnes-pratiques)

---

## 🎯 Vue d'Ensemble

Ce guide définit les **standards communs** pour tous les POCs du projet ARKEA afin d'assurer :

- ✅ **Cohérence** entre les POCs
- ✅ **Maintenabilité** facilitée
- ✅ **Navigabilité** améliorée
- ✅ **Qualité** uniforme

### POCs Concernés

- `poc-design/bic/` - POC BIC (Base d'Interaction Client)
- `poc-design/domirama2/` - POC Domirama2 (Opérations bancaires)
- `poc-design/domiramaCatOps/` - POC DomiramaCatOps (Catégorisation)

---

## 🏗️ Structure Standardisée

### Structure Recommandée

```
poc-design/<nom_poc>/
├── README.md                    # README principal (obligatoire)
├── scripts/                     # Scripts d'automatisation
│   ├── 01_setup_*.sh           # Scripts de setup (01-04)
│   ├── 05_generate_*.sh        # Génération de données (05-07)
│   ├── 08_load_*.sh            # Chargement de données (08-10)
│   ├── 11_test_*.sh            # Tests fonctionnels (11-15)
│   └── ...
├── schemas/                     # Schémas CQL
│   ├── 01_create_*_keyspace.cql
│   ├── 02_create_*_tables.cql
│   └── 03_create_*_indexes.cql
├── doc/                         # Documentation
│   ├── 00_ORGANISATION_DOC.md   # Organisation de la documentation
│   ├── design/                  # Design et architecture
│   ├── guides/                  # Guides d'utilisation
│   ├── implementation/         # Documents d'implémentation
│   ├── results/                 # Résultats de tests
│   ├── audits/                  # Audits et analyses
│   ├── demonstrations/         # Rapports de démonstrations
│   └── templates/               # Templates réutilisables
├── examples/                    # Exemples de code (optionnel)
│   ├── python/
│   ├── scala/
│   └── java/
├── utils/                       # Utilitaires
│   └── didactique_functions.sh  # Fonctions didactiques communes
└── data/                        # Données (gitignored)
```

---

## 📚 Standards de Documentation

### README.md Principal

**Structure standardisée** :

```markdown
# 🏦 POC [Nom] - Migration HBase → HCD

**Date** : YYYY-MM-DD
**Version** : X.Y.Z
**Objectif** : Description courte
**Conformité** : XX% avec les exigences

---

## 📋 Vue d'Ensemble
[Description du POC]

## 🏗️ Structure du Projet
[Structure détaillée]

## 🚀 Démarrage Rapide
[Instructions de démarrage]

## 📚 Documentation
[Liens vers documentation]

## 🧪 Tests
[Instructions pour tests]

## 📊 Résultats
[Résultats et métriques]
```

### Organisation Documentation

**Fichier obligatoire** : `doc/00_ORGANISATION_DOC.md`

**Structure recommandée** :

- `design/` : Design et architecture
- `guides/` : Guides d'utilisation
- `implementation/` : Documents d'implémentation
- `results/` : Résultats de tests
- `audits/` : Audits et analyses
- `demonstrations/` : Rapports de démonstrations
- `templates/` : Templates réutilisables

---

## 🔧 Standards de Scripts

### En-tête Standardisé

```bash
#!/bin/bash
set -euo pipefail

# =============================================================================
# Script : [Nom du Script]
# =============================================================================
# Date : YYYY-MM-DD
# Description : Description détaillée
# Usage : ./scripts/[nom_script].sh [options]
# Prérequis : [Prérequis]
# =============================================================================
```

### Numérotation Recommandée

- **01-04** : Setup (keyspace, tables, indexes)
- **05-07** : Génération de données
- **08-10** : Chargement de données
- **11-15** : Tests fonctionnels
- **16-20** : Tests avancés
- **21-25** : Démonstrations
- **26+** : Scripts spécialisés

### Utilisation de `setup_paths()`

**Obligatoire** : Tous les scripts doivent utiliser `setup_paths()`

```bash
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
if [ -f "${SCRIPT_DIR}/../utils/didactique_functions.sh" ]; then
    source "${SCRIPT_DIR}/../utils/didactique_functions.sh"
    setup_paths
fi
```

---

## 📝 Conventions de Nommage

### Scripts

- **Format** : `NN_description.sh` (NN = numéro à 2 chiffres)
- **Exemples** :
  - `01_setup_keyspace.sh`
  - `05_generate_data.sh`
  - `11_test_search.sh`

### Schémas CQL

- **Format** : `NN_create_*_*.cql`
- **Exemples** :
  - `01_create_bic_keyspace.cql`
  - `02_create_bic_tables.cql`
  - `03_create_bic_indexes.cql`

### Documentation

- **Format** : `NN_DESCRIPTION.md` ou `NN_DESCRIPTION_TYPE.md`
- **Exemples** :
  - `00_ORGANISATION_DOC.md`
  - `01_GUIDE_SETUP.md`
  - `02_AUDIT_COMPLET.md`

---

## ✅ Bonnes Pratiques

### Scripts

- ✅ **`set -euo pipefail`** : Obligatoire dans tous les scripts
- ✅ **`setup_paths()`** : Utiliser pour configuration portable
- ✅ **Gestion d'erreurs** : Messages d'erreur clairs
- ✅ **Documentation** : En-têtes complets avec description

### Documentation

- ✅ **README.md** : Présent et à jour
- ✅ **Organisation** : Structure claire et logique
- ✅ **Liens** : Liens croisés entre documents
- ✅ **Exemples** : Exemples de code avec sortie attendue

### Code

- ✅ **Portabilité** : Pas de chemins hardcodés
- ✅ **Variables d'environnement** : Utiliser pour configuration
- ✅ **Commentaires** : Commentaires didactiques pour scripts complexes

---

## 📊 Checklist de Conformité

### Structure

- [ ] README.md principal présent
- [ ] Structure `scripts/` organisée
- [ ] Structure `schemas/` organisée
- [ ] Structure `doc/` organisée
- [ ] Fichier `doc/00_ORGANISATION_DOC.md` présent

### Scripts

- [ ] Tous les scripts ont `set -euo pipefail`
- [ ] Tous les scripts utilisent `setup_paths()`
- [ ] En-têtes standardisés
- [ ] Numérotation cohérente

### Documentation

- [ ] README.md complet
- [ ] Documentation organisée
- [ ] Guides présents
- [ ] Exemples documentés

---

## 🔄 Harmonisation Progressive

### État Actuel

| POC | Structure | Scripts | Documentation | Conformité |
|-----|-----------|---------|---------------|------------|
| **BIC** | ✅ Excellente | ✅ Bonne | ✅ Excellente | ~95% |
| **domirama2** | ✅ Excellente | ✅ Bonne | ✅ Excellente | ~95% |
| **domiramaCatOps** | ✅ Excellente | ✅ Bonne | ✅ Excellente | ~95% |

### Objectif

- **Conformité cible** : 100%
- **Harmonisation** : Progressive selon besoins

---

## 📚 Références

- `docs/GUIDE_CHOIX_POC.md` - Guide pour choisir un POC
- `docs/GUIDE_COMPARAISON_POCS.md` - Comparaison des POCs
- `docs/GUIDE_CONTRIBUTION_POCS.md` - Standards de contribution

---

**Date** : 2026-03-13
**Version** : 1.0.0
**Statut** : ✅ **Guide complet**
