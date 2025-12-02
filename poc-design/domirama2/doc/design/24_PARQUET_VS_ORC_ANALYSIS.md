# 📊 Parquet vs ORC : Analyse pour Exports Incrémentaux

**Date** : 2025-11-25  
**Contexte** : Migration HBase → HCD, exports incrémentaux vers HDFS  
**Question** : Parquet ou ORC pour les exports incrémentaux ?

---

## 🎯 Réponse Directe

**✅ OUI, Parquet est une excellente alternative (voire supérieure) à ORC pour les exports incrémentaux**

**Recommandation** : **Parquet** pour ce POC, car :
1. ✅ Déjà utilisé dans le POC (ingestion Parquet)
2. ✅ Standard de facto dans l'écosystème Spark
3. ✅ Performance équivalente ou supérieure à ORC
4. ✅ Meilleure intégration avec Spark
5. ✅ Simplicité (un seul format dans tout le POC)

---

## 📊 Comparaison Technique : Parquet vs ORC

### Vue d'Ensemble

| Critère | Parquet | ORC | Gagnant |
|---------|---------|-----|---------|
| **Format** | Columnar (Apache) | Columnar (Apache) | Égalité |
| **Compression** | Snappy, Gzip, LZO, Brotli | Zlib, Snappy, LZO, Zstd | Parquet (plus d'options) |
| **Schéma** | Schema evolution supporté | Schema evolution supporté | Égalité |
| **Performance Lecture** | Excellent | Excellent | Égalité (selon cas) |
| **Performance Écriture** | Très bon | Très bon | Égalité |
| **Support Spark** | ⭐⭐⭐⭐⭐ Natif | ⭐⭐⭐⭐ Bon | **Parquet** |
| **Support Hive** | ⭐⭐⭐⭐ Bon | ⭐⭐⭐⭐⭐ Excellent | ORC |
| **Taille Fichier** | Compact | Compact | Égalité |
| **Adoption** | Standard de facto | Principalement Hive | **Parquet** |
| **Type System** | Rich (nested types) | Rich (nested types) | Égalité |

---

## 🔍 Analyse Détaillée

### 1. Performance

#### Compression

**Parquet** :
- Formats : Snappy (rapide), Gzip (compact), Brotli (très compact)
- Ratio compression : 2-5x selon données
- Vitesse : Snappy très rapide, Gzip plus lent mais plus compact

**ORC** :
- Formats : Zlib (par défaut), Snappy, LZO, Zstd
- Ratio compression : 2-5x selon données
- Vitesse : Zlib rapide, Zstd très performant

**Verdict** : **Égalité** - Les deux offrent d'excellentes performances de compression

#### Lecture (Query Performance)

**Parquet** :
- Prédicats pushdown : ✅ Excellent
- Projection columnar : ✅ Excellent
- Index : Row groups avec statistiques
- Performance : Très rapide pour analytics

**ORC** :
- Prédicats pushdown : ✅ Excellent
- Projection columnar : ✅ Excellent
- Index : Stripe-level avec statistiques + bloom filters
- Performance : Très rapide pour analytics

**Verdict** : **ORC légèrement meilleur** pour Hive (bloom filters), **Parquet meilleur** pour Spark natif

#### Écriture

**Parquet** :
- Écriture rapide avec Spark
- Pas de bloom filters (moins d'overhead écriture)
- Row groups configurables

**ORC** :
- Écriture rapide avec Hive
- Bloom filters (overhead écriture mais gain lecture)
- Stripes configurables

**Verdict** : **Parquet** pour Spark (plus rapide), **ORC** pour Hive

---

### 2. Support Écosystème

#### Apache Spark

**Parquet** :
- ✅ **Support natif** depuis Spark 1.0+
- ✅ Format par défaut recommandé
- ✅ Optimisations natives (predicate pushdown, column pruning)
- ✅ Lecture/écriture très performantes
- ✅ Support complet des types complexes (nested, arrays, maps)

**ORC** :
- ✅ Support depuis Spark 2.0+
- ⚠️ Moins optimisé que Parquet
- ⚠️ Nécessite parfois Hive pour meilleures performances
- ✅ Support des types complexes

**Verdict** : **Parquet** est le format natif de Spark

#### Hive

**Parquet** :
- ✅ Support complet
- ⚠️ Moins optimisé que ORC (mais très bon)

**ORC** :
- ✅ **Support natif** (créé par Hive)
- ✅ Optimisations natives (bloom filters, ACID)
- ✅ Format recommandé pour Hive

**Verdict** : **ORC** est le format natif de Hive

#### Autres Outils

**Parquet** :
- ✅ Pandas (Python)
- ✅ Arrow (interopérabilité)
- ✅ Presto/Trino
- ✅ BigQuery
- ✅ S3 (Athena)
- ✅ **Standard de facto** dans l'écosystème data

**ORC** :
- ✅ Hive (excellent)
- ✅ Presto/Trino
- ⚠️ Moins supporté par les outils Python
- ⚠️ Moins standard dans l'écosystème moderne

**Verdict** : **Parquet** a une adoption plus large

---

### 3. Cas d'Usage Spécifique : Exports Incrémentaux HCD → HDFS

#### Contexte

- **Source** : HCD (Cassandra) via Spark
- **Destination** : HDFS
- **Format actuel POC** : Parquet (ingestion)
- **Usage** : Analytics, reporting, data warehouse

#### Analyse

**Parquet** :
- ✅ **Cohérence** : Même format que l'ingestion (simplicité)
- ✅ **Performance Spark** : Optimisations natives
- ✅ **Interopérabilité** : Compatible avec tous les outils analytics
- ✅ **Maintenance** : Un seul format à gérer
- ✅ **Évolution** : Standard en croissance

**ORC** :
- ✅ Performance excellente
- ⚠️ **Incohérence** : Format différent de l'ingestion (Parquet)
- ⚠️ **Moins optimal** pour Spark (vs Parquet)
- ⚠️ **Maintenance** : Deux formats à gérer (Parquet ingestion + ORC export)
- ✅ Meilleur si utilisation Hive intensive

**Verdict** : **Parquet** est la meilleure option pour ce POC

---

## 🎯 Recommandation pour le POC Domirama

### Option 1 : Parquet (Recommandé) ✅

**Avantages** :
1. ✅ **Cohérence** : Même format que l'ingestion (Parquet)
2. ✅ **Simplicité** : Un seul format dans tout le POC
3. ✅ **Performance Spark** : Optimisations natives
4. ✅ **Standard** : Format de facto dans l'écosystème moderne
5. ✅ **Interopérabilité** : Compatible avec tous les outils
6. ✅ **Maintenance** : Plus simple (un seul format)

**Inconvénients** :
- ⚠️ Si Hive est utilisé intensivement, ORC pourrait être légèrement meilleur

**Recommandation** : **Parquet** pour ce POC

### Option 2 : ORC (Alternative)

**Avantages** :
1. ✅ Performance excellente
2. ✅ Bloom filters (gain pour certaines requêtes)
3. ✅ Si Hive est l'outil principal d'analytics

**Inconvénients** :
- ⚠️ Format différent de l'ingestion (Parquet)
- ⚠️ Moins optimal pour Spark (vs Parquet)
- ⚠️ Maintenance de deux formats
- ⚠️ Moins standard dans l'écosystème moderne

**Recommandation** : **ORC** uniquement si Hive est l'outil principal d'analytics

### Option 3 : Les Deux Formats (Non Recommandé)

**Avantages** :
- ✅ Flexibilité maximale

**Inconvénients** :
- ❌ Complexité de maintenance
- ❌ Duplication des exports
- ❌ Pas de valeur ajoutée pour un POC

**Recommandation** : **Non recommandé** pour un POC

---

## 📝 Implémentation : Export Incrémental Parquet

### Architecture

```
HCD (Cassandra)
    ↓ Spark
    ↓ SELECT avec WHERE date_op BETWEEN start AND end
    ↓ DataFrame
    ↓ write.parquet()
HDFS (/data/exports/domirama/incremental/)
    ↓ Parquet files (partitioned by date)
```

### Exemple Spark (Scala)

```scala
import org.apache.spark.sql.SparkSession
import org.apache.spark.sql.functions._

val spark = SparkSession.builder()
  .appName("Export Incremental Parquet")
  .config("spark.cassandra.connection.host", "localhost")
  .getOrCreate()

// 1. Lecture depuis HCD avec fenêtre glissante
val df = spark.read
  .format("org.apache.spark.sql.cassandra")
  .options(Map(
    "table" -> "operations_by_account",
    "keyspace" -> "domirama2_poc"
  ))
  .load()
  .filter(
    col("date_op") >= "2024-01-01" &&
    col("date_op") < "2024-02-01"
  )

// 2. Export Parquet vers HDFS (partitionné par date)
df.write
  .mode("overwrite")  // ou "append" pour incrémental
  .partitionBy("date_op")  // Partitionnement par date
  .option("compression", "snappy")  // Compression rapide
  .parquet("hdfs://namenode:9000/data/exports/domirama/incremental/2024-01")

println(s"✅ Export Parquet terminé : ${df.count()} opérations")
```

### Exemple avec Fenêtre Glissante

```scala
import java.time.LocalDate
import java.time.format.DateTimeFormatter

def exportIncrementalParquet(
  startDate: LocalDate,
  endDate: LocalDate,
  outputPath: String
): Unit = {
  
  val df = spark.read
    .format("org.apache.spark.sql.cassandra")
    .options(Map(
      "table" -> "operations_by_account",
      "keyspace" -> "domirama2_poc"
    ))
    .load()
    .filter(
      col("date_op") >= startDate.toString &&
      col("date_op") < endDate.toString
    )
  
  df.write
    .mode("overwrite")
    .partitionBy("date_op")
    .option("compression", "snappy")
    .parquet(outputPath)
  
  println(s"✅ Export Parquet : ${startDate} → ${endDate} : ${df.count()} opérations")
}

// Export mensuel (fenêtre glissante)
val start = LocalDate.of(2024, 1, 1)
val end = LocalDate.of(2024, 2, 1)
exportIncrementalParquet(start, end, "hdfs://.../incremental/2024-01")
```

### Avantages de Parquet pour Exports Incrémentaux

1. **Partitionnement** : Partitionnement natif par date (performance)
2. **Compression** : Snappy rapide, Gzip compact
3. **Schéma** : Schema evolution supporté
4. **Performance** : Lecture très rapide pour analytics
5. **Interopérabilité** : Compatible avec tous les outils

---

## 🔄 Comparaison : Parquet vs ORC pour Exports

### Performance Écriture (Spark)

| Format | Vitesse | Compression | Taille |
|--------|---------|-------------|--------|
| **Parquet (Snappy)** | ⭐⭐⭐⭐⭐ | 2-3x | Compact |
| **Parquet (Gzip)** | ⭐⭐⭐ | 3-5x | Très compact |
| **ORC (Zlib)** | ⭐⭐⭐⭐ | 2-4x | Compact |
| **ORC (Zstd)** | ⭐⭐⭐⭐ | 3-5x | Très compact |

**Verdict** : **Égalité** - Les deux sont excellents

### Performance Lecture (Analytics)

| Format | Spark | Hive | Presto |
|--------|-------|------|--------|
| **Parquet** | ⭐⭐⭐⭐⭐ | ⭐⭐⭐⭐ | ⭐⭐⭐⭐⭐ |
| **ORC** | ⭐⭐⭐⭐ | ⭐⭐⭐⭐⭐ | ⭐⭐⭐⭐⭐ |

**Verdict** : **Parquet** pour Spark, **ORC** pour Hive

### Maintenance

| Format | Cohérence POC | Simplicité | Standard |
|--------|---------------|------------|----------|
| **Parquet** | ✅ Même format ingestion | ✅ Un seul format | ✅ Standard |
| **ORC** | ⚠️ Format différent | ⚠️ Deux formats | ⚠️ Moins standard |

**Verdict** : **Parquet** pour simplicité et cohérence

---

## 📊 Tableau Récapitulatif

| Critère | Parquet | ORC | Recommandation POC |
|---------|---------|-----|---------------------|
| **Performance Spark** | ⭐⭐⭐⭐⭐ | ⭐⭐⭐⭐ | ✅ **Parquet** |
| **Performance Hive** | ⭐⭐⭐⭐ | ⭐⭐⭐⭐⭐ | ORC si Hive |
| **Cohérence POC** | ✅ Même format | ⚠️ Format différent | ✅ **Parquet** |
| **Simplicité** | ✅ Un format | ⚠️ Deux formats | ✅ **Parquet** |
| **Standard** | ✅ Standard | ⚠️ Moins standard | ✅ **Parquet** |
| **Interopérabilité** | ✅ Excellente | ✅ Bonne | ✅ **Parquet** |
| **Compression** | ✅ Excellente | ✅ Excellente | Égalité |
| **Bloom Filters** | ❌ Non | ✅ Oui | ORC si nécessaire |

---

## 🎯 Conclusion

### Pour le POC Domirama

**Recommandation** : **Parquet** pour les exports incrémentaux

**Raisons** :
1. ✅ **Cohérence** : Même format que l'ingestion (Parquet)
2. ✅ **Simplicité** : Un seul format dans tout le POC
3. ✅ **Performance** : Optimisations natives Spark
4. ✅ **Standard** : Format de facto dans l'écosystème moderne
5. ✅ **Interopérabilité** : Compatible avec tous les outils analytics

### Quand Utiliser ORC ?

**ORC** est recommandé si :
- Hive est l'outil principal d'analytics (pas Spark)
- Besoin de bloom filters pour certaines requêtes
- Écosystème Hive existant à préserver

### Pour la Production

**Recommandation** : **Parquet** sauf si :
- Hive est l'outil principal d'analytics
- Besoin spécifique de bloom filters ORC
- Contraintes d'écosystème existant

---

## 📝 Scripts à Créer

### 1. Export Incrémental Parquet

**`27_export_incremental_parquet.sh`** :
- Export incrémental depuis HCD vers HDFS (Parquet)
- Fenêtre glissante avec WHERE date_op BETWEEN
- Partitionnement par date

**`examples/scala/export_incremental_parquet.scala`** :
- Job Spark pour export Parquet
- Gestion fenêtre glissante
- Compression Snappy

### 2. Comparaison Parquet vs ORC (Optionnel)

**`28_comparaison_parquet_vs_orc.sh`** :
- Export dans les deux formats
- Comparaison performance/taille
- Recommandation finale

---

**Conclusion** : **Parquet est supérieur pour ce POC** (cohérence, simplicité, performance Spark). ORC serait complémentaire uniquement si Hive est l'outil principal d'analytics.

