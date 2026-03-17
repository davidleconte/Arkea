# 📊 Analyse : Script 11_load_domirama2_data.sh

**Date** : 2025-11-26
**Script analysé** : `11_load_domirama2_data.sh`
**Objectif** : Analyser le script original et déterminer quel template utiliser ou créer pour l'améliorer de manière didactique

---

## 📋 Table des Matières

1. [Analyse du Script Original](#analyse-du-script-original)
2. [Comparaison avec Versions Existantes](#comparaison-avec-versions-existantes)
3. [État Actuel des Scripts 11](#état-actuel-des-scripts-11)
4. [Recommandations](#recommandations)
5. [Conclusion](#conclusion)

---

## 🔍 Analyse du Script Original

### Contenu du Script

Le script `11_load_domirama2_data.sh` est **identique** à `11_load_domirama2_data_fixed.sh`.

**Caractéristiques** :

- ✅ Script d'ingestion/ETL (CSV → HCD via Spark)
- ✅ Format source : CSV
- ✅ Stratégie multi-version implémentée
- ✅ Vérifications basiques (HCD, keyspace, fichier)
- ✅ Exécution Spark avec script temporaire
- ✅ Vérifications post-chargement (comptage, stratégie batch)

**Limitations** :

- ❌ Pas d'affichage du code Spark avant exécution
- ❌ Pas d'explications détaillées
- ❌ Vérifications basiques (pas d'échantillon de données)
- ❌ Pas de documentation générée automatiquement
- ❌ Pas de structure didactique

### Problème Identifié

**SPARK_HOME incorrect** :

```bash
SPARK_HOME="${INSTALL_DIR}/binaire/spark-3.5.1-bin-hadoop3"
```

**Correction nécessaire** :

```bash
SPARK_HOME="${INSTALL_DIR}/binaire/spark-3.5.1"
```

Le chemin contient `-bin-hadoop3` qui n'est pas le chemin correct dans l'environnement POC.

---

## 📊 Comparaison avec Versions Existantes

### État Actuel des Scripts 11

| Script | Format | Version | Statut | Description |
|--------|--------|---------|--------|-------------|
| `11_load_domirama2_data.sh` | CSV | Original | ⚠️ **OBSOLÈTE** | Identique à `_fixed.sh`, SPARK_HOME incorrect |
| `11_load_domirama2_data_fixed.sh` | CSV | Corrigé | ✅ **FONCTIONNEL** | Version corrigée (SPARK_HOME correct) |
| `11_load_domirama2_data_fixed_v2_didactique.sh` | CSV | Didactique | ✅ **RECOMMANDÉ** | Version didactique complète avec documentation |
| `11_load_domirama2_data_parquet.sh` | Parquet | Standard | ✅ **FONCTIONNEL** | Version Parquet standard |
| `11_load_domirama2_data_parquet_v2_didactique.sh` | Parquet | Didactique | ✅ **RECOMMANDÉ** | Version didactique Parquet complète |

### Comparaison Détaillée

#### Script Original vs Script Fixed

| Aspect | `11_load_domirama2_data.sh` | `11_load_domirama2_data_fixed.sh` |
|--------|----------------------------|----------------------------------|
| **SPARK_HOME** | `spark-3.5.1-bin-hadoop3` ❌ | `spark-3.5.1` ✅ |
| **Contenu** | Identique | Identique |
| **Statut** | ⚠️ OBSOLÈTE | ✅ FONCTIONNEL |

**Conclusion** : Le script original est **obsolète** et doit être remplacé ou supprimé.

#### Script Fixed vs Script Didactique CSV

| Aspect | `11_load_domirama2_data_fixed.sh` | `11_load_domirama2_data_fixed_v2_didactique.sh` |
|--------|----------------------------------|------------------------------------------------|
| **Structure** | Basique | 7 parties didactiques |
| **Code Spark affiché** | Non | Oui (complet avec explications) |
| **Explications** | Basiques | Détaillées |
| **Vérifications** | Basiques | Complètes (échantillon de données) |
| **Documentation** | Non générée | Générée automatiquement (markdown) |
| **Statut** | ✅ FONCTIONNEL | ✅ **RECOMMANDÉ** |

**Conclusion** : La version didactique est **supérieure** et doit être utilisée.

#### Script Parquet vs Script Didactique Parquet

| Aspect | `11_load_domirama2_data_parquet.sh` | `11_load_domirama2_data_parquet_v2_didactique.sh` |
|--------|-------------------------------------|---------------------------------------------------|
| **Structure** | Basique | 7 parties didactiques |
| **Code Spark affiché** | Non | Oui (complet avec explications) |
| **Avantages Parquet** | Mentionnés | Démontrés et expliqués |
| **Schéma Parquet** | Affiché dans Spark | Affiché et expliqué |
| **Documentation** | Non générée | Générée automatiquement (markdown) |
| **Statut** | ✅ FONCTIONNEL | ✅ **RECOMMANDÉ** |

**Conclusion** : La version didactique Parquet est **supérieure** et doit être utilisée.

---

## 📊 État Actuel des Scripts 11

### Scripts Disponibles

```
poc-design/domirama2/
├── 11_load_domirama2_data.sh                    ⚠️  OBSOLÈTE (SPARK_HOME incorrect)
├── 11_load_domirama2_data_fixed.sh              ✅  FONCTIONNEL (version corrigée)
├── 11_load_domirama2_data_fixed_v2_didactique.sh ✅  RECOMMANDÉ (version didactique CSV)
├── 11_load_domirama2_data_parquet.sh            ✅  FONCTIONNEL (version Parquet)
└── 11_load_domirama2_data_parquet_v2_didactique.sh ✅  RECOMMANDÉ (version didactique Parquet)
```

### Recommandations d'Utilisation

| Format Source | Script Recommandé | Raison |
|--------------|------------------|--------|
| **CSV** | `11_load_domirama2_data_fixed_v2_didactique.sh` | Version didactique complète avec documentation |
| **Parquet** | `11_load_domirama2_data_parquet_v2_didactique.sh` | Version didactique complète avec documentation et avantages Parquet |

---

## 💡 Recommandations

### Option 1 : Supprimer le Script Obsolète (Recommandé) ⭐

**Action** : Supprimer `11_load_domirama2_data.sh`

**Justification** :

- ✅ Identique à `_fixed.sh` mais avec SPARK_HOME incorrect
- ✅ Risque de confusion pour les utilisateurs
- ✅ Les versions didactiques sont supérieures

**Avantages** :

- ✅ Évite la confusion
- ✅ Nettoie le répertoire
- ✅ Force l'utilisation des versions recommandées

### Option 2 : Corriger le Script Original

**Action** : Corriger `SPARK_HOME` dans `11_load_domirama2_data.sh`

**Justification** :

- ⚠️ Permet de conserver le script original
- ⚠️ Mais toujours inférieur aux versions didactiques

**Inconvénients** :

- ❌ Duplication avec `_fixed.sh`
- ❌ Pas de valeur ajoutée
- ❌ Risque de confusion

### Option 3 : Créer une Version Didactique du Script Original

**Action** : Créer `11_load_domirama2_data_v2_didactique.sh`

**Justification** :

- ⚠️ Cohérence avec les autres versions didactiques
- ⚠️ Mais le script original est obsolète

**Inconvénients** :

- ❌ Duplication inutile (déjà 2 versions didactiques)
- ❌ Le script original a un SPARK_HOME incorrect
- ❌ Pas de valeur ajoutée

---

## ✅ Conclusion

### Recommandation Finale

**Supprimer `11_load_domirama2_data.sh`** et utiliser les versions didactiques existantes.

### Justification

1. **Script obsolète** :
   - SPARK_HOME incorrect (`spark-3.5.1-bin-hadoop3`)
   - Identique à `_fixed.sh` mais avec erreur

2. **Versions supérieures disponibles** :
   - `11_load_domirama2_data_fixed_v2_didactique.sh` (CSV didactique)
   - `11_load_domirama2_data_parquet_v2_didactique.sh` (Parquet didactique)

3. **Pas de valeur ajoutée** :
   - Le script original n'apporte rien de plus
   - Les versions didactiques sont complètes et documentées

### Actions Recommandées

1. ✅ **Supprimer** `11_load_domirama2_data.sh` (obsolète) - **TERMINÉ** ✅
2. ✅ **Conserver** `11_load_domirama2_data_fixed.sh` (référence fonctionnelle)
3. ✅ **Utiliser** `11_load_domirama2_data_fixed_v2_didactique.sh` (CSV didactique)
4. ✅ **Utiliser** `11_load_domirama2_data_parquet_v2_didactique.sh` (Parquet didactique)

### Action Effectuée

**Date** : 2025-11-26
**Action** : Suppression de `11_load_domirama2_data.sh`
**Raison** : Script obsolète avec SPARK_HOME incorrect, identique à `_fixed.sh`
**Statut** : ✅ **SUPPRIMÉ**

### Template à Utiliser

**Aucun template à créer** : Les versions didactiques existantes utilisent déjà le template d'ingestion (`50_TEMPLATE_SCRIPT_INGESTION_DIDACTIQUE.md`) avec les adaptations nécessaires.

---

## 📊 Tableau Récapitulatif

| Script | Format | Version | SPARK_HOME | Structure | Documentation | Statut | Action |
|--------|--------|---------|------------|-----------|---------------|--------|--------|
| `11_load_domirama2_data.sh` | CSV | Original | ❌ Incorrect | Basique | Non | ❌ **SUPPRIMÉ** | ✅ **SUPPRIMÉ** |
| `11_load_domirama2_data_fixed.sh` | CSV | Corrigé | ✅ Correct | Basique | Non | ✅ FONCTIONNEL | Conserver |
| `11_load_domirama2_data_fixed_v2_didactique.sh` | CSV | Didactique | ✅ Correct | 7 parties | ✅ Auto | ✅ **RECOMMANDÉ** | **UTILISER** |
| `11_load_domirama2_data_parquet.sh` | Parquet | Standard | ✅ Correct | Basique | Non | ✅ FONCTIONNEL | Conserver |
| `11_load_domirama2_data_parquet_v2_didactique.sh` | Parquet | Didactique | ✅ Correct | 7 parties | ✅ Auto | ✅ **RECOMMANDÉ** | **UTILISER** |

---

**✅ Conclusion : Le script `11_load_domirama2_data.sh` est obsolète et doit être supprimé. Les versions didactiques existantes sont recommandées.**
