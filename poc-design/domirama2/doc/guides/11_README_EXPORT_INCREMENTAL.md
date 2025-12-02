# 📥 Export Incrémental Parquet depuis HCD

**Date** : 2025-11-25  
**Objectif** : Démontrer l'export incrémental depuis HCD vers HDFS (format Parquet)  
**Équivalent HBase** : FullScan + STARTROW + STOPROW + TIMERANGE

---

## 🎯 Objectif

Démontrer la capacité d'**export incrémental** depuis HCD vers HDFS au format **Parquet**, équivalent aux fonctionnalités HBase :

- ✅ **FullScan incrémental** : Export par plages de dates
- ✅ **STARTROW/STOPROW équivalent** : Ciblage précis avec WHERE sur clustering keys
- ✅ **TIMERANGE équivalent** : Fenêtre glissante pour exports périodiques
- ✅ **Format Parquet** : Cohérent avec l'ingestion (vs ORC HBase)

---

## 📋 Fonctionnalités Démontrées

### 1. Export Incrémental Parquet

**Script** : `27_export_incremental_parquet.sh` ⭐ Recommandé (spark-submit)

**Alternative** : `27_export_incremental_parquet_spark_shell.sh` (spark-shell)

**Fonctionnalités** :

- Export depuis HCD vers HDFS (format Parquet)
- Fenêtre glissante avec `WHERE date_op BETWEEN start AND end`
- Partitionnement par `date_op` (performance)
- Compression Snappy (rapide) ou Gzip (compact)
- Vérification post-export

**Usage** :

```bash
# Export par défaut (Janvier 2024)
./27_export_incremental_parquet.sh

# Export personnalisé
./27_export_incremental_parquet.sh "2024-01-01" "2024-02-01" "/tmp/exports/domirama/incremental/2024-01" "snappy"
```

**Équivalent HBase** :

```java
// HBase
Scan scan = new Scan();
scan.setTimeRange(startTimestamp, endTimestamp);
scan.setStartRow(startRow);
scan.setStopRow(stopRow);
// Export ORC vers HDFS
```

**HCD/Spark** :

```scala
val df = spark.read
  .format("org.apache.spark.sql.cassandra")
  .options(Map("table" -> "operations_by_account", "keyspace" -> "domirama2_poc"))
  .load()
  .filter(
    col("date_op") >= "2024-01-01" &&
    col("date_op") < "2024-02-01"
  )

df.write
  .mode("overwrite")
  .partitionBy("date_op")
  .option("compression", "snappy")
  .parquet("/tmp/exports/domirama/incremental/2024-01")
```

### 2. Fenêtre Glissante (TIMERANGE équivalent)

**Script** : `28_demo_fenetre_glissante_spark_submit.sh` ⭐ Recommandé (spark-submit)

**Alternative** : `28_demo_fenetre_glissante.sh` (spark-shell)

**Fonctionnalités** :

- Export mensuel automatique (fenêtre glissante)
- Idempotence (mode overwrite pour rejeux)
- Gestion des périodes (janvier, février, mars, etc.)
- Vérification des exports créés

**Usage** :

```bash
./28_demo_fenetre_glissante.sh
```

**Équivalent HBase** :

```java
// HBase : TIMERANGE pour fenêtre glissante
for (int month = 1; month <= 12; month++) {
    long startTime = getStartTimestamp(2024, month);
    long endTime = getEndTimestamp(2024, month);
    scan.setTimeRange(startTime, endTime);
    // Export ORC
}
```

**HCD/Spark** :

```scala
// Fenêtre glissante mensuelle
for (month <- 1 to 12) {
  val startDate = s"2024-${month:02d}-01"
  val endDate = s"2024-${(month + 1):02d}-01"

  val df = spark.read
    .format("org.apache.spark.sql.cassandra")
    .load()
    .filter(
      col("date_op") >= startDate &&
      col("date_op") < endDate
    )

  df.write
    .mode("overwrite")  // Idempotence
    .partitionBy("date_op")
    .parquet(s"/tmp/exports/domirama/incremental/2024-${month:02d}")
}
```

### 3. STARTROW/STOPROW Équivalent

**Fonctionnalité** : Ciblage précis avec WHERE sur clustering keys

**Exemple CQL** :

```cql
-- Équivalent STARTROW/STOPROW HBase
SELECT * FROM operations_by_account
WHERE code_si = '01' AND contrat = '1234567890'
  AND date_op >= '2024-01-15 10:00:00'
  AND date_op <= '2024-01-20 18:00:00'
  AND numero_op >= 1
  AND numero_op <= 100;
```

**Exemple Spark** :

```scala
val df = spark.read
  .format("org.apache.spark.sql.cassandra")
  .load()
  .filter(
    col("code_si") === "01" &&
    col("contrat") === "1234567890" &&
    col("date_op") >= "2024-01-15" &&
    col("date_op") <= "2024-01-20" &&
    col("numero_op") >= 1 &&
    col("numero_op") <= 100
  )
```

---

## 📊 Comparaison HBase vs HCD

| Fonctionnalité HBase | Équivalent HCD | Statut |
|----------------------|----------------|--------|
| **FullScan incrémental** | SELECT avec WHERE date_op BETWEEN | ✅ Démontré |
| **STARTROW/STOPROW** | WHERE sur clustering keys (date_op, numero_op) | ✅ Démontré |
| **TIMERANGE** | WHERE date_op BETWEEN start AND end | ✅ Démontré |
| **Unload ORC** | Export Parquet | ✅ Démontré (Parquet recommandé) |
| **Fenêtre glissante** | Boucle avec dates calculées | ✅ Démontré |
| **Idempotence** | Mode overwrite | ✅ Démontré |

---

## 🎯 Avantages Parquet vs ORC

### Pourquoi Parquet ?

1. ✅ **Cohérence** : Même format que l'ingestion (Parquet)
2. ✅ **Performance Spark** : Optimisations natives (⭐⭐⭐⭐⭐)
3. ✅ **Simplicité** : Un seul format dans tout le POC
4. ✅ **Standard** : Format de facto dans l'écosystème moderne
5. ✅ **Interopérabilité** : Compatible avec tous les outils analytics

### Comparaison Performance

| Format | Spark | Hive | Compression | Standard |
|-------|-------|------|-------------|----------|
| **Parquet** | ⭐⭐⭐⭐⭐ | ⭐⭐⭐⭐ | 2-5x | ✅ Standard |
| **ORC** | ⭐⭐⭐⭐ | ⭐⭐⭐⭐⭐ | 2-5x | ⚠️ Principalement Hive |

**Verdict** : **Parquet** est supérieur pour ce POC (Spark + cohérence)

---

## 📝 Exemples d'Utilisation

### Exemple 1 : Export Mensuel

```bash
# Export janvier 2024
./27_export_incremental_parquet.sh "2024-01-01" "2024-02-01" "/tmp/exports/domirama/incremental/2024-01"
```

**Résultat** :

- Fichiers Parquet créés dans `/tmp/exports/domirama/incremental/2024-01/`
- Partitionnés par `date_op`
- Compression Snappy

### Exemple 2 : Fenêtre Glissante Automatique

```bash
# Exports mensuels automatiques
./28_demo_fenetre_glissante.sh
```

**Résultat** :

- Exports créés pour chaque mois (2024-01, 2024-02, 2024-03, etc.)
- Chaque export est idempotent (rejeux possibles)

### Exemple 3 : Lecture des Exports Parquet

```scala
// Dans spark-shell
val df = spark.read.parquet("/tmp/exports/domirama/incremental/2024-01")
df.show()
df.count()  // Nombre d'opérations exportées
```

---

## 🔍 Vérification

### Vérifier les Exports Créés

```bash
# Lister les répertoires d'export
ls -lh /tmp/exports/domirama/incremental/

# Compter les fichiers Parquet
find /tmp/exports/domirama/incremental/2024-01 -name "*.parquet" | wc -l
```

### Vérifier le Contenu

```scala
// Dans spark-shell
val df = spark.read.parquet("/tmp/exports/domirama/incremental/2024-01")
df.printSchema()
df.select(
  min("date_op").as("date_min"),
  max("date_op").as("date_max"),
  count("*").as("total")
).show()
```

---

## 📊 Statistiques et Performance

### Métriques d'Export

- **Vitesse** : ~10-50 MB/s selon données et compression
- **Compression** : 2-5x selon format (Snappy rapide, Gzip compact)
- **Partitionnement** : Par `date_op` (optimisation lecture)

### Comparaison avec HBase

| Métrique | HBase (ORC) | HCD (Parquet) | Amélioration |
|----------|------------|--------------|--------------|
| **Format** | ORC | Parquet | ✅ Cohérence |
| **Performance Spark** | Bonne | Excellente | ✅ Optimisations natives |
| **Compression** | 2-5x | 2-5x | Égalité |
| **Partitionnement** | Par date | Par date | Égalité |

---

## ✅ Points Validés

1. ✅ **Export incrémental** : Fonctionnel avec WHERE date_op BETWEEN
2. ✅ **Fenêtre glissante** : Automatisée avec boucles mensuelles
3. ✅ **STARTROW/STOPROW** : Équivalent avec WHERE sur clustering keys
4. ✅ **Format Parquet** : Cohérent avec ingestion, performance optimale
5. ✅ **Idempotence** : Mode overwrite pour rejeux
6. ✅ **Vérification** : Lecture post-export pour validation

---

## 📚 Références

- **Analyse Parquet vs ORC** : `PARQUET_VS_ORC_ANALYSIS.md`
- **Gaps Analysis** : `GAPS_ANALYSIS.md`
- **Script Scala** : `examples/scala/export_incremental_parquet.scala`
- **Script Shell 27** : `27_export_incremental_parquet.sh`
- **Script Shell 28** : `28_demo_fenetre_glissante.sh`

---

**✅ Export incrémental Parquet démontré et validé !**
