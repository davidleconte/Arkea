# 📥 Export Incrémental Parquet : Versions spark-submit et spark-shell

**Date** : 2025-11-25
**Objectif** : Deux versions des scripts d'export (spark-submit recommandé)

---

## 🎯 Deux Versions Disponibles

### Version 1 : spark-submit (⭐ Recommandé)

**Scripts** :

- `27_export_incremental_parquet.sh` - Utilise `spark-submit`
- `28_demo_fenetre_glissante_spark_submit.sh` - Utilise `spark-submit`

**Avantages** :

- ✅ **Meilleures performances** : Optimisations Spark natives
- ✅ **Pas d'interprétation ligne par ligne** : Script compilé
- ✅ **Gestion d'erreurs améliorée** : Exceptions claires
- ✅ **Production-ready** : Format standard pour jobs Spark
- ✅ **Logs propres** : Pas de pollution scala> prompt

**Usage** :

```bash
# Export incrémental
./27_export_incremental_parquet.sh "2024-01-01" "2024-02-01" "/tmp/exports/domirama/incremental/2024-01"

# Fenêtre glissante
./28_demo_fenetre_glissante_spark_submit.sh
```

### Version 2 : spark-shell (Alternative)

**Scripts** :

- `27_export_incremental_parquet_spark_shell.sh` - Utilise `spark-shell`
- `28_demo_fenetre_glissante.sh` - Utilise `spark-shell`

**Avantages** :

- ✅ **Interactivité** : Possibilité de déboguer ligne par ligne
- ✅ **Rapidité de développement** : Pas besoin de recompiler
- ✅ **Utile pour tests** : Validation rapide

**Inconvénients** :

- ⚠️ **Performance** : Moins optimisé que spark-submit
- ⚠️ **Logs** : Pollution avec scala> prompts
- ⚠️ **Gestion d'erreurs** : Moins claire

**Usage** :

```bash
# Export incrémental
./27_export_incremental_parquet_spark_shell.sh "2024-01-01" "2024-02-01" "/tmp/exports/domirama/incremental/2024-01"

# Fenêtre glissante
./28_demo_fenetre_glissante.sh
```

---

## 📋 Scripts Disponibles

### Export Incrémental

| Script | Méthode | Recommandation |
|--------|---------|---------------|
| `27_export_incremental_parquet.sh` | spark-submit | ⭐ **Recommandé** |
| `27_export_incremental_parquet_spark_shell.sh` | spark-shell | Alternative |

### Fenêtre Glissante

| Script | Méthode | Recommandation |
|--------|---------|---------------|
| `28_demo_fenetre_glissante_spark_submit.sh` | spark-submit | ⭐ **Recommandé** |
| `28_demo_fenetre_glissante.sh` | spark-shell | Alternative |

---

## 🔧 Script Scala Standalone

**Fichier** : `examples/scala/export_incremental_parquet_standalone.scala`

**Caractéristiques** :

- ✅ Classe `ExportIncrementalParquet` avec méthode `main()`
- ✅ Paramètres en ligne de commande
- ✅ Compatible avec `spark-submit`
- ✅ Gestion d'erreurs complète

**Usage direct** :

```bash
spark-submit \
  --class ExportIncrementalParquet \
  --jars $SPARK_CASSANDRA_CONNECTOR_JAR \
  examples/scala/export_incremental_parquet_standalone.scala \
  2024-01-01 2024-02-01 /tmp/exports/domirama/incremental/2024-01 snappy
```

---

## 📊 Comparaison Performance

| Critère | spark-submit | spark-shell |
|---------|--------------|-------------|
| **Performance** | ⭐⭐⭐⭐⭐ | ⭐⭐⭐ |
| **Logs** | ✅ Propres | ⚠️ Pollution scala> |
| **Gestion erreurs** | ✅ Excellente | ⚠️ Moins claire |
| **Production** | ✅ Recommandé | ❌ Non recommandé |
| **Développement** | ⭐⭐⭐⭐ | ⭐⭐⭐⭐⭐ |
| **Débogage** | ⭐⭐⭐ | ⭐⭐⭐⭐⭐ |

---

## 🎯 Recommandation

### Pour Production

**Utiliser spark-submit** :

- ✅ Meilleures performances
- ✅ Logs propres
- ✅ Gestion d'erreurs améliorée
- ✅ Standard industrie

### Pour Développement/Débogage

**Utiliser spark-shell** :

- ✅ Interactivité
- ✅ Débogage ligne par ligne
- ✅ Tests rapides

---

## 📝 Exemples d'Utilisation

### Exemple 1 : Export avec spark-submit (Recommandé)

```bash
# Export janvier 2024
./27_export_incremental_parquet.sh \
  "2024-01-01" \
  "2024-02-01" \
  "/tmp/exports/domirama/incremental/2024-01" \
  "snappy"
```

### Exemple 2 : Fenêtre Glissante avec spark-submit

```bash
# Exports mensuels automatiques
./28_demo_fenetre_glissante_spark_submit.sh
```

### Exemple 3 : Export Direct avec spark-submit

```bash
# Utilisation directe du script Scala
spark-submit \
  --class ExportIncrementalParquet \
  --jars $SPARK_CASSANDRA_CONNECTOR_JAR \
  --driver-memory 2g \
  --executor-memory 2g \
  examples/scala/export_incremental_parquet_standalone.scala \
  2024-01-01 2024-02-01 /tmp/exports/domirama/incremental/2024-01 snappy
```

---

## ✅ Correction des Erreurs

### Problèmes Résolus

1. ✅ **Erreurs d'interprétation spark-shell** : Résolu avec spark-submit
2. ✅ **Variables non définies** : Résolu avec paramètres en ligne de commande
3. ✅ **Gestion d'erreurs** : Améliorée avec try/catch explicite
4. ✅ **Logs propres** : spark-submit produit des logs clairs

### Améliorations

- ✅ Script Scala standalone réutilisable
- ✅ Deux versions disponibles (spark-submit et spark-shell)
- ✅ Documentation complète
- ✅ Exemples d'utilisation

---

**✅ Les scripts sont maintenant corrigés et fonctionnels !**
