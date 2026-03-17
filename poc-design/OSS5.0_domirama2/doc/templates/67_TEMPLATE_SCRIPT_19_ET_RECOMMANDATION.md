# 📋 Recommandation Template pour Script 19 : `19_setup_typo_tolerance.sh`

**Date** : 2025-11-26
**Script analysé** : `19_setup_typo_tolerance.sh`
**Objectif** : Déterminer quel template utiliser ou créer pour enrichir le script 19

---

## 📊 Analyse du Script 19

### Type de Script

Le script 19 est un **script de setup partiel** qui :
- ✅ Ajoute une colonne (`libelle_prefix`) à une table existante
- ✅ Crée un index SAI (`idx_libelle_prefix_ngram`)
- ✅ Vérifie l'existence avant d'agir (idempotent)
- ✅ Ne crée pas de keyspace ou table (contrairement au script 10)

### Comparaison avec Autres Scripts

| Script | Type | Portée | Template Utilisé |
|--------|------|--------|------------------|
| **Script 10** | Setup complet | Keyspace + Table + Index | Template 47 (Setup Didactique) |
| **Script 11** | Ingestion | Chargement de données | Template 50 (Ingestion Didactique) |
| **Script 12** | Test | Recherches | Template 43 (Didactique général) |
| **Script 18** | Orchestration | Multi-démonstrations | Template 63 (Orchestration Didactique) |
| **Script 19** | Setup partiel | Colonne + Index | ❓ À déterminer |

---

## 🎯 Recommandation : Utiliser le Template 47 (Adapté)

### Pourquoi le Template 47 ?

Le **Template 47** (`47_TEMPLATE_SCRIPT_SETUP_DIDACTIQUE.md`) est conçu pour les scripts de setup/schéma, ce qui correspond au script 19.

**Points communs** :
- ✅ Configuration de schéma (DDL)
- ✅ Création d'index SAI
- ✅ Vérifications post-création
- ✅ Explications des équivalences HBase → HCD
- ✅ Génération de rapport markdown

**Différences à adapter** :
- ⚠️ Script 10 : Crée keyspace + table + index (setup complet)
- ⚠️ Script 19 : Ajoute colonne + index (setup partiel)

### Adaptations Nécessaires

Le Template 47 doit être **adapté** pour un setup partiel :

#### 1. **PARTIE 1: Contexte** (Conserver)
- ✅ Équivalences HBase → HCD
- ✅ Explications sur la tolérance aux typos
- ✅ Comparaison avec Elasticsearch N-Gram

#### 2. **PARTIE 2: DDL - Colonne** (Adapter)
- ❌ Supprimer : Création keyspace (déjà existant)
- ❌ Supprimer : Création table (déjà existante)
- ✅ Ajouter : ALTER TABLE ADD COLUMN avec explications
- ✅ Ajouter : Vérification de l'existence de la colonne

#### 3. **PARTIE 3: DDL - Index** (Conserver)
- ✅ Création index SAI avec analyzers
- ✅ Explications des analyzers (lowercase, asciifolding)
- ✅ Vérification de la création de l'index

#### 4. **PARTIE 4: Vérifications** (Adapter)
- ❌ Supprimer : Vérification keyspace (déjà vérifié)
- ❌ Supprimer : Vérification table (déjà vérifiée)
- ✅ Ajouter : Vérification colonne ajoutée
- ✅ Ajouter : Vérification index créé
- ✅ Ajouter : Vérification données existantes (libelle_prefix NULL vs rempli)

#### 5. **PARTIE 5: Résumé** (Adapter)
- ✅ Résumer : Colonne ajoutée, index créé
- ✅ Expliquer : Impact sur les recherches partielles
- ✅ Documenter : Mise à jour des données existantes (optionnel)

---

## 📝 Structure Recommandée pour Script 19 Didactique

```bash
#!/bin/bash
# ============================================
# Script 19 : Configuration Tolérance aux Typos (Version Didactique)
# Ajout d'une colonne dérivée avec index pour recherche partielle
# ============================================

# PARTIE 1: CONTEXTE - Tolérance aux Typos
#   - Problème : Recherches avec typos ne fonctionnent pas
#   - Solution : Colonne libelle_prefix + index N-Gram
#   - Équivalence HBase : Elasticsearch N-Gram

# PARTIE 2: DDL - Ajout de la Colonne
#   - ALTER TABLE ADD libelle_prefix TEXT
#   - Vérification existence avant ajout
#   - Explication : Colonne dérivée pour recherche partielle

# PARTIE 3: DDL - Création de l'Index
#   - CREATE INDEX idx_libelle_prefix_ngram
#   - Analyzers : lowercase, asciifolding
#   - Explication : Index N-Gram pour recherche partielle

# PARTIE 4: Vérifications
#   - Colonne ajoutée ?
#   - Index créé ?
#   - Données existantes (libelle_prefix NULL vs rempli) ?

# PARTIE 5: Résumé et Documentation
#   - Colonne ajoutée
#   - Index créé
#   - Impact sur les recherches
#   - Mise à jour des données existantes (optionnel)
```

---

## 🔄 Alternative : Créer un Nouveau Template

### Option 1 : Template "Setup Partiel" (Recommandé)

Créer un nouveau template `68_TEMPLATE_SCRIPT_SETUP_PARTIEL_DIDACTIQUE.md` spécifiquement pour :
- Ajout de colonnes
- Ajout d'index
- Modification de schéma (ALTER TABLE)
- Migration de données

**Avantages** :
- ✅ Plus spécifique que Template 47
- ✅ Réutilisable pour d'autres scripts similaires (21, 22, etc.)
- ✅ Structure optimisée pour setup partiel

**Inconvénients** :
- ⚠️ Création d'un nouveau template (maintenance supplémentaire)

### Option 2 : Adapter le Template 47 (Plus Simple)

Adapter directement le Template 47 pour le script 19.

**Avantages** :
- ✅ Réutilisation d'un template existant
- ✅ Pas de nouveau template à maintenir
- ✅ Cohérence avec script 10

**Inconvénients** :
- ⚠️ Template 47 orienté setup complet (keyspace + table)
- ⚠️ Adaptations nécessaires à chaque utilisation

---

## ✅ Recommandation Finale

### **Utiliser le Template 47 avec Adaptations**

**Justification** :
1. ✅ Le Template 47 est déjà conçu pour les scripts de setup
2. ✅ Les adaptations sont mineures (supprimer keyspace/table, ajouter colonne)
3. ✅ Cohérence avec le script 10 (même famille de scripts)
4. ✅ Pas besoin de créer un nouveau template

### Structure Adaptée

```bash
# PARTIE 1: CONTEXTE (Conserver)
#   - Équivalences HBase → HCD
#   - Problème : Typos dans les recherches
#   - Solution : libelle_prefix + index N-Gram

# PARTIE 2: DDL - COLONNE (Adapter)
#   - ALTER TABLE ADD libelle_prefix TEXT
#   - Vérification existence
#   - Explications

# PARTIE 3: DDL - INDEX (Conserver)
#   - CREATE INDEX idx_libelle_prefix_ngram
#   - Analyzers
#   - Explications

# PARTIE 4: VÉRIFICATIONS (Adapter)
#   - Colonne ajoutée
#   - Index créé
#   - Données existantes

# PARTIE 5: RÉSUMÉ (Adapter)
#   - Colonne + index créés
#   - Impact sur recherches
#   - Mise à jour données (optionnel)
```

---

## 📋 Checklist pour Enrichir le Script 19

### Structure
- [ ] Utiliser Template 47 comme base
- [ ] Adapter PARTIE 2 (colonne au lieu de keyspace/table)
- [ ] Adapter PARTIE 4 (vérifications colonne/index)
- [ ] Adapter PARTIE 5 (résumé setup partiel)

### Contenu
- [ ] **PARTIE 1: Contexte**
  - [ ] Expliquer le problème des typos
  - [ ] Expliquer la solution (libelle_prefix + N-Gram)
  - [ ] Comparer avec Elasticsearch N-Gram (HBase)

- [ ] **PARTIE 2: DDL - Colonne**
  - [ ] Afficher ALTER TABLE ADD avec explications
  - [ ] Vérifier existence avant ajout
  - [ ] Expliquer colonne dérivée

- [ ] **PARTIE 3: DDL - Index**
  - [ ] Afficher CREATE INDEX avec analyzers
  - [ ] Expliquer analyzers (lowercase, asciifolding)
  - [ ] Expliquer index N-Gram

- [ ] **PARTIE 4: Vérifications**
  - [ ] Vérifier colonne ajoutée
  - [ ] Vérifier index créé
  - [ ] Vérifier données existantes (libelle_prefix NULL)

- [ ] **PARTIE 5: Résumé**
  - [ ] Résumer colonne + index créés
  - [ ] Expliquer impact sur recherches
  - [ ] Documenter mise à jour données (optionnel)

### Formatage
- [ ] Utiliser fonctions de couleur (info, success, warn, error, code, section, result, expected)
- [ ] Utiliser séparateurs visuels
- [ ] Formater DDL dans des boîtes
- [ ] Générer rapport markdown

---

## 🎯 Conclusion

**Recommandation** : **Utiliser le Template 47 avec adaptations** pour le script 19.

**Actions** :
1. ✅ Utiliser `47_TEMPLATE_SCRIPT_SETUP_DIDACTIQUE.md` comme base
2. ✅ Adapter PARTIE 2 (colonne au lieu de keyspace/table)
3. ✅ Adapter PARTIE 4 (vérifications colonne/index)
4. ✅ Adapter PARTIE 5 (résumé setup partiel)
5. ✅ Créer `19_setup_typo_tolerance_v2_didactique.sh`

**Priorité** : ⚠️ **Moyenne** - Le script fonctionne mais l'enrichissement didactique améliorerait la compréhension.

---

**✅ Template recommandé : Template 47 (avec adaptations)**
