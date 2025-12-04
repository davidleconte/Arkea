# 🔍 Analyse et Amélioration de la Racine ARKEA

**Date** : 2025-12-01  
**Objectif** : Analyser la structure de la racine ARKEA et proposer des améliorations  
**Périmètre** : Répertoire racine `${ARKEA_HOME}`

---

## 📊 État Actuel de la Racine

### Structure Actuelle

```
Arkea/
├── [Scripts numérotés à la racine]
│   ├── 01_install_hcd.sh
│   ├── 02_install_spark_kafka.sh
│   ├── 03_start_hcd.sh
│   ├── 04_start_kafka.sh
│   ├── 05_setup_kafka_hcd_streaming.sh
│   ├── 06_test_kafka_hcd_streaming.sh
│   ├── 70_kafka-helper.sh
│   ├── 80_verify_all.sh
│   └── 90_list_scripts.sh
│
├── [Fichiers Scala à la racine]
│   ├── test_spark_hcd_connection.scala
│   ├── test_spark_hcd.scala
│   └── test_spark_simple.scala
│
├── [Fichiers CQL à la racine]
│   └── create_kafka_schema.cql
│
├── [Fichiers de configuration]
│   ├── .poc-profile
│   ├── .poc-config.sh
│   └── date_requête (fichier sans extension)
│
├── [Répertoires principaux]
│   ├── binaire/              ✅ Bien organisé
│   ├── software/             ✅ Bien organisé
│   ├── docs/                 ✅ Bien organisé
│   ├── inputs-clients/       ✅ Bien organisé
│   ├── inputs-ibm/           ✅ Bien organisé
│   ├── poc-design/           ✅ Bien organisé
│   ├── scripts/              ⚠️  Contient seulement migrate_hardcoded_paths.sh
│   ├── data/                 ⚠️  Vide ou peu utilisé
│   ├── logs/                 ⚠️  Beaucoup de répertoires UNLOAD_*
│   ├── hcd-data/             ✅ Bien organisé
│   ├── hcd-1.2.3/            ⚠️  Dupliqué avec binaire/hcd-1.2.3 ?
│   └── ehB /                 ❌ Répertoire vide ou inutile
│
└── README.md                 ✅ Présent
```

---

## 🔴 Problèmes Identifiés

### 1. Scripts Dispersés à la Racine

**Problème** :

- 9 scripts shell à la racine (01-06, 70, 80, 90)
- Pas de répertoire `scripts/` dédié pour les scripts racine
- Mélange avec les scripts des sous-projets (`poc-design/*/scripts/`)

**Impact** :

- ❌ Navigation difficile
- ❌ Structure incohérente
- ❌ Difficile de distinguer scripts racine vs sous-projets

**Recommandation** : Créer `scripts/root/` ou `scripts/setup/` pour les scripts d'installation/setup

---

### 2. Fichiers Scala à la Racine

**Problème** :

- 3 fichiers `.scala` à la racine (`test_spark_*.scala`)
- Pas de répertoire dédié pour les scripts/test Scala

**Impact** :

- ❌ Pollution de la racine
- ❌ Difficile de trouver les tests Scala

**Recommandation** : Créer `scripts/scala/` ou `tests/scala/` ou `examples/scala/`

---

### 3. Fichiers CQL à la Racine

**Problème** :

- 1 fichier `.cql` à la racine (`create_kafka_schema.cql`)
- Pas de répertoire `schemas/` à la racine (existe dans `poc-design/*/schemas/`)

**Impact** :

- ❌ Incohérence avec la structure des sous-projets
- ❌ Difficile de trouver les schémas

**Recommandation** : Créer `schemas/` à la racine ou déplacer dans `poc-design/`

---

### 4. Répertoire `hcd-1.2.3/` à la Racine

**Problème** :

- Répertoire `hcd-1.2.3/` à la racine
- Dupliqué avec `binaire/hcd-1.2.3/` ?

**Impact** :

- ❌ Confusion sur quel répertoire utiliser
- ❌ Duplication potentielle

**Recommandation** : Vérifier et supprimer le doublon, utiliser uniquement `binaire/hcd-1.2.3/`

---

### 5. Répertoire `ehB /` (Vide ou Inutile)

**Problème** :

- Répertoire `ehB /` avec espace dans le nom
- Probablement vide ou inutile

**Impact** :

- ❌ Pollution de la structure
- ❌ Nom avec espace (problématique)

**Recommandation** : Supprimer si inutile, ou renommer si nécessaire

---

### 6. Fichier `date_requête` (Sans Extension)

**Problème** :

- Fichier `date_requête` sans extension
- Nature du fichier inconnue

**Impact** :

- ❌ Confusion sur le type de fichier
- ❌ Difficile de savoir à quoi il sert

**Recommandation** : Identifier le type et renommer avec extension appropriée, ou supprimer si inutile

---

### 7. Répertoire `logs/` Non Organisé

**Problème** :

- Beaucoup de répertoires `UNLOAD_*` dans `logs/`
- Pas d'organisation par date/projet

**Impact** :

- ❌ Difficile de trouver les logs pertinents
- ❌ Accumulation de logs anciens

**Recommandation** : Organiser par date ou projet, archiver les anciens logs

---

### 8. Répertoire `data/` Vide ou Peu Utilisé

**Problème** :

- Répertoire `data/` à la racine
- Probablement vide ou peu utilisé

**Impact** :

- ❌ Confusion sur son usage
- ❌ Structure non claire

**Recommandation** : Clarifier l'usage ou supprimer si inutile

---

### 9. Absence de `.gitignore`

**Problème** :

- Pas de `.gitignore` visible à la racine
- Risque de commiter des fichiers temporaires/logs

**Impact** :

- ❌ Fichiers temporaires dans le repo
- ❌ Logs et données dans le repo

**Recommandation** : Créer `.gitignore` pour exclure logs, données, binaires, etc.

---

### 10. Structure des Scripts Incohérente

**Problème** :

- Scripts numérotés (01-06, 70-90) à la racine
- Scripts nommés dans `poc-design/*/scripts/`
- Pas de convention claire

**Impact** :

- ❌ Difficile de comprendre l'ordre d'exécution
- ❌ Pas de standardisation

**Recommandation** : Standardiser la numérotation ou utiliser des noms descriptifs

---

## ✅ Recommandations d'Amélioration

### Priorité 1 : Organisation Immédiate (Critique)

#### 1.1 Créer Structure de Scripts Racine

**Action** : Créer `scripts/setup/` pour les scripts d'installation/setup

```
scripts/
├── setup/                    # Scripts d'installation/setup
│   ├── 01_install_hcd.sh
│   ├── 02_install_spark_kafka.sh
│   ├── 03_start_hcd.sh
│   ├── 04_start_kafka.sh
│   ├── 05_setup_kafka_hcd_streaming.sh
│   └── 06_test_kafka_hcd_streaming.sh
│
├── utils/                    # Scripts utilitaires
│   ├── 70_kafka-helper.sh
│   ├── 80_verify_all.sh
│   └── 90_list_scripts.sh
│
├── scala/                    # Scripts/test Scala
│   ├── test_spark_hcd_connection.scala
│   ├── test_spark_hcd.scala
│   └── test_spark_simple.scala
│
└── migrate_hardcoded_paths.sh  # Script de migration (existant)
```

**Avantages** :

- ✅ Structure claire et organisée
- ✅ Séparation setup vs utils
- ✅ Facilite la navigation

---

#### 1.2 Créer Répertoire `schemas/` à la Racine

**Action** : Créer `schemas/` et déplacer `create_kafka_schema.cql`

```
schemas/
└── kafka/
    └── create_kafka_schema.cql
```

**Avantages** :

- ✅ Cohérence avec `poc-design/*/schemas/`
- ✅ Centralisation des schémas

---

#### 1.3 Nettoyer les Répertoires Inutiles

**Actions** :

1. Vérifier et supprimer `hcd-1.2.3/` si doublon de `binaire/hcd-1.2.3/`
2. Supprimer `ehB /` si inutile
3. Identifier et renommer/supprimer `date_requête`

---

### Priorité 2 : Organisation des Logs (Important)

#### 2.1 Organiser le Répertoire `logs/`

**Action** : Créer structure organisée par date/projet

```
logs/
├── archive/                  # Logs archivés (anciens)
│   └── 2025-11/
│       └── UNLOAD_*/
│
├── current/                  # Logs actuels
│   └── 2025-12/
│       └── UNLOAD_*/
│
└── README.md                 # Documentation de l'organisation
```

**Avantages** :

- ✅ Logs organisés par date
- ✅ Facilite le nettoyage
- ✅ Archive des anciens logs

---

### Priorité 3 : Documentation et Configuration (Important)

#### 3.1 Créer `.gitignore`

**Action** : Créer `.gitignore` pour exclure :

```gitignore
# Logs
logs/
*.log

# Données
data/
hcd-data/

# Binaires
binaire/
software/

# Fichiers temporaires
*.tmp
*.bak
*.swp

# OS
.DS_Store
Thumbs.db

# IDE
.idea/
.vscode/
*.iml
```

---

#### 3.2 Mettre à Jour README.md

**Action** : Mettre à jour README.md avec :

- Structure complète et à jour
- Référence à `.poc-config.sh` (nouveau)
- Guide de démarrage amélioré
- Liens vers documentation

---

#### 3.3 Créer Guide de Structure

**Action** : Créer `docs/GUIDE_STRUCTURE.md` expliquant :

- Organisation complète du projet
- Rôle de chaque répertoire
- Conventions de nommage
- Où trouver quoi

---

### Priorité 4 : Améliorations Optionnelles (Nice to Have)

#### 4.1 Créer Scripts d'Aide

**Actions** :

1. Créer `scripts/utils/list_all_scripts.sh` - Liste tous les scripts du projet
2. Créer `scripts/utils/clean_logs.sh` - Nettoie les anciens logs
3. Créer `scripts/utils/verify_structure.sh` - Vérifie la structure du projet

---

#### 4.2 Standardiser les Noms de Scripts

**Action** : Créer convention de nommage :

- `setup_*.sh` - Scripts d'installation/setup
- `start_*.sh` - Scripts de démarrage
- `test_*.sh` - Scripts de test
- `utils_*.sh` - Scripts utilitaires

---

## 📋 Plan d'Action Détaillé

### Phase 1 : Nettoyage Immédiat (30 min)

1. ✅ Créer `scripts/setup/` et déplacer scripts 01-06
2. ✅ Créer `scripts/utils/` et déplacer scripts 70-90
3. ✅ Créer `scripts/scala/` et déplacer fichiers `.scala`
4. ✅ Créer `schemas/kafka/` et déplacer `create_kafka_schema.cql`
5. ✅ Vérifier et supprimer doublons (`hcd-1.2.3/`, `ehB /`)
6. ✅ Identifier et traiter `date_requête`

### Phase 2 : Organisation Logs (15 min)

7. ✅ Créer structure `logs/archive/` et `logs/current/`
8. ✅ Déplacer anciens logs dans `archive/`
9. ✅ Créer `logs/README.md`

### Phase 3 : Documentation (30 min)

10. ✅ Créer `.gitignore`
11. ✅ Mettre à jour `README.md`
12. ✅ Créer `docs/GUIDE_STRUCTURE.md`

### Phase 4 : Scripts d'Aide (30 min)

13. ✅ Créer `scripts/utils/list_all_scripts.sh`
14. ✅ Créer `scripts/utils/clean_logs.sh`
15. ✅ Créer `scripts/utils/verify_structure.sh`

---

## 🎯 Structure Cible Recommandée

```
Arkea/
├── README.md                 # Documentation principale (mis à jour)
├── .poc-profile              # Configuration (existant)
├── .poc-config.sh            # Configuration centralisée (existant)
├── .gitignore                # Exclusions Git (nouveau)
│
├── scripts/                  # Tous les scripts organisés
│   ├── setup/                # Scripts d'installation/setup
│   ├── utils/                # Scripts utilitaires
│   ├── scala/                # Scripts/test Scala
│   └── migrate_hardcoded_paths.sh
│
├── schemas/                  # Schémas CQL
│   └── kafka/
│
├── binaire/                  # Logiciels installés (inchangé)
├── software/                 # Archives (inchangé)
├── docs/                     # Documentation (inchangé)
├── inputs-clients/           # Inputs clients (inchangé)
├── inputs-ibm/               # Inputs IBM (inchangé)
├── poc-design/               # POCs (inchangé)
│
├── data/                     # Données (clarifier usage)
├── hcd-data/                 # Données HCD (inchangé)
│
└── logs/                     # Logs organisés
    ├── archive/              # Logs archivés
    ├── current/               # Logs actuels
    └── README.md              # Documentation logs
```

---

## ✅ Bénéfices Attendus

### Organisation

- ✅ Structure claire et intuitive
- ✅ Navigation facilitée
- ✅ Séparation des préoccupations

### Maintenabilité

- ✅ Facilite l'ajout de nouveaux scripts
- ✅ Réduit la confusion
- ✅ Standardisation

### Portabilité

- ✅ Structure cohérente
- ✅ Facilite le partage
- ✅ Documentation à jour

---

## 📊 Métriques de Succès

| Métrique | Avant | Cible | Statut |
|----------|-------|-------|--------|
| Scripts à la racine | 9 | 0 | ⏳ |
| Fichiers Scala à la racine | 3 | 0 | ⏳ |
| Fichiers CQL à la racine | 1 | 0 | ⏳ |
| Répertoires inutiles | 2-3 | 0 | ⏳ |
| Documentation structure | Partielle | Complète | ⏳ |
| .gitignore | Absent | Présent | ⏳ |

---

## 🚀 Prochaines Étapes

1. **Valider le plan** avec l'équipe
2. **Exécuter Phase 1** (nettoyage immédiat)
3. **Exécuter Phase 2** (organisation logs)
4. **Exécuter Phase 3** (documentation)
5. **Exécuter Phase 4** (scripts d'aide)
6. **Tester** la nouvelle structure
7. **Mettre à jour** la documentation

---

**Date** : 2025-12-01  
**Version** : 1.0  
**Statut** : ✅ **Plan d'amélioration complet**
