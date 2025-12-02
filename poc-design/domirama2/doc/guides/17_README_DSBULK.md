# 📦 DSBulk : DataStax Bulk Loader

**Date** : 2025-11-25  
**Objectif** : Documenter DSBulk et son utilisation avec Parquet

---

## 📋 Qu'est-ce que DSBulk ?

**DSBulk** (DataStax Bulk Loader) est un outil d'import/export massif vers/depuis Cassandra/HCD.

### Formats Supportés

| Format | Support | Usage |
|--------|---------|-------|
| **CSV** | ✅ Supporté | Import/Export tabulaire |
| **JSON** | ✅ Supporté | Import/Export structuré |
| **CQL** | ✅ Supporté | Requêtes CQL |
| **Parquet** | ❌ Non supporté | Format columnar binaire |

---

## 🎯 DSBulk et Parquet

### Support Parquet

**DSBulk ne supporte PAS directement Parquet** car :

- Parquet est un format columnar binaire
- DSBulk est optimisé pour formats textuels (CSV, JSON)
- Parquet nécessite des bibliothèques spécifiques (Parquet-MR, etc.)

### Solutions pour Parquet

#### Solution 1 : Spark Direct (Recommandé) ⭐

**Utiliser Spark directement** (déjà démontré dans le POC) :

```scala
// Lire Parquet et écrire directement dans HCD
spark.read.parquet("/data/operations.parquet")
  .write
  .format("org.apache.spark.sql.cassandra")
  .options(Map(
    "keyspace" -> "domirama2_poc",
    "table" -> "operations_by_account"
  ))
  .save()
```

**Avantages** :

- ✅ Pas de conversion intermédiaire
- ✅ Performance optimale
- ✅ Format natif Parquet
- ✅ Intégration Spark-Cassandra-Connector

#### Solution 2 : Parquet → CSV → DSBulk

**Workflow** :

1. **Spark** : Convertir Parquet → CSV
2. **DSBulk** : Importer CSV → HCD

```scala
// Étape 1 : Conversion Parquet → CSV
spark.read.parquet("/data/operations.parquet")
  .write
  .option("header", "true")
  .csv("/tmp/operations.csv")
```

```bash
# Étape 2 : Import CSV → HCD avec DSBulk
dsbulk load \
  -h localhost \
  -k domirama2_poc \
  -t operations_by_account \
  -url /tmp/operations.csv \
  -header true \
  -batchSize 100
```

**Avantages** :

- ✅ Utilise DSBulk pour import optimisé
- ✅ Gestion erreurs automatique

**Inconvénients** :

- ⚠️ Conversion intermédiaire nécessaire
- ⚠️ Performance réduite (conversion + import)

---

## 📊 Comparaison : DSBulk vs Spark

| Critère | DSBulk | Spark | Gagnant |
|---------|--------|-------|---------|
| **Formats** | CSV, JSON, CQL | Parquet, CSV, JSON, ORC, etc. | ✅ **Spark** |
| **Parquet** | ❌ Non supporté | ✅ Support natif | ✅ **Spark** |
| **Performance CSV** | ✅ Excellente | ✅ Excellente | ⚖️ **Égal** |
| **Performance Parquet** | ❌ Nécessite conversion | ✅ Excellente | ✅ **Spark** |
| **Bulk Load** | ✅ Optimisé | ✅ Optimisé | ⚖️ **Égal** |
| **ETL** | ❌ Limité | ✅ Complet | ✅ **Spark** |

**Conclusion** :

- ✅ **Pour Parquet** : Utiliser Spark directement (recommandé)
- ✅ **Pour CSV/JSON** : DSBulk ou Spark (selon besoins)
- ✅ **Pour ETL** : Spark (transformation, analytics)

---

## 🚀 Utilisation DSBulk

### Installation

```bash
# Télécharger DSBulk
wget https://downloads.datastax.com/dsbulk/dsbulk-1.11.0.tar.gz
tar -xzf dsbulk-1.11.0.tar.gz
cd dsbulk-1.11.0/bin
```

### Export depuis HCD vers CSV

```bash
dsbulk unload \
  -h localhost \
  -k domirama2_poc \
  -t operations_by_account \
  -url /tmp/export_dsbulk \
  -header true \
  -query "SELECT * FROM operations_by_account WHERE code_si = 'DEMO_MV' LIMIT 1000"
```

### Import depuis CSV vers HCD

```bash
dsbulk load \
  -h localhost \
  -k domirama2_poc \
  -t operations_by_account \
  -url /tmp/import_dsbulk/data.csv \
  -header true \
  -batchSize 100 \
  -maxConcurrentQueries 4
```

### Options Importantes

- `-header true` : Inclure les en-têtes CSV
- `-batchSize 100` : Taille des batches
- `-maxConcurrentQueries 4` : Nombre de requêtes concurrentes
- `-query "SELECT ..."` : Requête CQL pour export filtré

---

## 🎯 Cas d'Usage

### Cas 1 : Migration depuis CSV

**DSBulk recommandé** :

```bash
dsbulk load -h localhost -k domirama2_poc -t operations_by_account \
  -url /data/operations.csv -header true
```

### Cas 2 : Migration depuis Parquet

**Spark recommandé** (déjà démontré dans POC) :

```scala
spark.read.parquet("/data/operations.parquet")
  .write.format("org.apache.spark.sql.cassandra")
  .options(Map("keyspace" -> "domirama2_poc", "table" -> "operations_by_account"))
  .save()
```

### Cas 3 : Export vers CSV

**DSBulk recommandé** :

```bash
dsbulk unload -h localhost -k domirama2_poc -t operations_by_account \
  -url /tmp/export -header true
```

### Cas 4 : Export vers Parquet

**Spark recommandé** :

```scala
spark.read.format("org.apache.spark.sql.cassandra")
  .options(Map("keyspace" -> "domirama2_poc", "table" -> "operations_by_account"))
  .load()
  .write.parquet("/tmp/export_parquet")
```

---

## 🎯 Recommandations

### Pour Parquet

**✅ Utiliser Spark directement** :

- Support natif Parquet
- Performance optimale
- Pas de conversion intermédiaire
- Intégration Spark-Cassandra-Connector

**Déjà démontré dans le POC** :

- `examples/scala/export_incremental_parquet.scala` : Export Parquet
- `11_load_domirama2_data_parquet.sh` : Import Parquet

### Pour CSV/JSON

**✅ Utiliser DSBulk** :

- Performance optimale pour bulk load
- Gestion erreurs automatique
- Monitoring intégré
- Optimisé pour CSV/JSON

### Pour ETL Complexe

**✅ Utiliser Spark** :

- Transformation de données
- Analytics
- Agrégations
- Support multi-formats

---

## 📋 Conclusion

### DSBulk

**Formats supportés** :

- ✅ CSV, JSON, CQL
- ❌ Parquet (non supporté directement)

**Cas d'usage** :

- ✅ Bulk load depuis CSV/JSON
- ✅ Export vers CSV/JSON
- ✅ Migration de données

### Parquet

**Recommandation** :

- ✅ **Spark direct** (déjà démontré dans POC)
- ⚠️ DSBulk nécessite conversion intermédiaire (non recommandé)

**POC actuel** :

- ✅ Spark utilisé pour Parquet (déjà démontré)
- ✅ Performance optimale
- ✅ Pas de conversion nécessaire

---

## 🚀 Démonstrations Disponibles

### Script 35 : Démonstration Standard

**Fichier** : `35_demo_dsbulk_v2.sh`

**Contenu** :

- Explication DSBulk et formats supportés
- Analyse Parquet vs DSBulk
- Comparaison DSBulk vs Spark
- Recommandations

### Script 35 v2 : Démonstration Améliorée ⭐

**Fichier** : `35_demo_dsbulk_v2.sh`

**Améliorations** :

- ✅ Installation DSBulk (si nécessaire)
- ✅ Démonstrations pratiques avec CSV (import/export)
- ✅ Workflow complet Parquet → CSV → DSBulk
- ✅ Comparaison performance DSBulk vs Spark
- ✅ Cas d'usage avancés
- ✅ Mesures de performance (simulation)

**Usage** :

```bash
./35_demo_dsbulk_v2.sh
```

---

**✅ DSBulk documenté, Spark recommandé pour Parquet (déjà démontré) !**
