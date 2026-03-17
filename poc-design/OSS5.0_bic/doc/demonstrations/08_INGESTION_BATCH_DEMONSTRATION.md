# 📥 Démonstration : Chargement Batch des Interactions (Parquet)

**Date** : 2025-12-01
**Script** : `08_load_interactions_batch.sh`
**Use Cases** : BIC-07 (Format JSON), BIC-09 (Écriture batch - bulkLoad équivalent)

---

## 📋 Objectif

Charger les données d'interactions depuis un fichier Parquet dans HCD via Spark,
en démontrant l'équivalence avec le bulkLoad HBase.

---

## 🎯 Use Cases Couverts

### BIC-07 : Format JSON + Colonnes Dynamiques

**Description** : Stockage des données en JSON avec colonnes dynamiques pour flexibilité.

### BIC-09 : Écriture Batch (bulkLoad équivalent HBase)

**Description** : Chargement massif des données via Spark (équivalent MapReduce bulkLoad HBase).

**Composant HBase** : `bic-batch-main.tar.gz` (inputs-clients)

- Traitement batch
- MapReduce en bulkLoad
- Chargement massif des données

---

## 🔄 Équivalences HBase → HCD

### Équivalence BulkLoad HBase → Spark Batch Write

| Aspect | HBase | HCD (Spark) |
|--------|-------|-------------|
| **Format source** | SequenceFile, HFile | Parquet, JSON |
| **Traitement** | MapReduce bulkLoad | Spark batch write |
| **Performance** | Génération HFiles puis chargement | Écriture directe via Spark Cassandra Connector |
| **Complexité** | Nécessite génération HFiles | Écriture directe, plus simple |
| **Scalabilité** | Parallélisation via MapReduce | Parallélisation native Spark |

**Avantages HCD** :

- ✅ Plus simple : Pas besoin de générer HFiles
- ✅ Plus rapide : Écriture directe via connecteur
- ✅ Plus flexible : Support de multiples formats (Parquet, JSON, CSV)

---

## 📝 Code Spark Complet

### Code Spark - Lecture

```scala
val inputPath = "data/parquet/interactions_100.parquet"
val spark = SparkSession.builder()
  .appName("BICLoaderBatchParquet")
  .config("spark.cassandra.connection.host", "localhost")
  .config("spark.cassandra.connection.port", "9042")
  .config("spark.sql.extensions", "com.datastax.spark.connector.CassandraSparkExtensions")
  .getOrCreate()
import spark.implicits._

println("📥 Lecture du Parquet...")
val raw = spark.read.parquet(inputPath)
println(s"✅ ${raw.count()} lignes lues")
println("📋 Schéma Parquet:")
raw.printSchema()
```

**Explication** :

- Lecture Parquet avec schéma préservé
- Types déjà présents (pas de parsing nécessaire)
- Performance optimale (format columnar)

---

### Code Spark - Transformation

```scala
println("🔄 Transformation des données...")
val interactions = raw.select(
  col("code_efs").as("code_efs"),
  col("numero_client").as("numero_client"),
  col("date_interaction").as("date_interaction"),
  col("canal").as("canal"),
  col("type_interaction").as("type_interaction"),
  col("idt_tech").as("idt_tech"),
  col("json_data").as("json_data"),
  col("colonnes_dynamiques").as("colonnes_dynamiques"),
  col("resultat").as("resultat"),
  current_timestamp().as("created_at"),
  current_timestamp().as("updated_at"),
  lit(1).as("version")
)
```

**Explication** :

- Mapping direct colonnes Parquet → HCD
- Colonnes JSON et dynamiques préservées
- Métadonnées ajoutées

---

### Code Spark - Écriture

```scala
println("💾 Écriture dans HCD...")
interactions.write
  .format("org.apache.spark.sql.cassandra")
  .options(Map("keyspace" -> "bic_poc", "table" -> "interactions_by_client"))
  .mode("append")
  .save()

println("✅ Écriture terminée !")

val count = spark.read
  .format("org.apache.spark.sql.cassandra")
  .options(Map("keyspace" -> "bic_poc", "table" -> "interactions_by_client"))
  .load()
  .count()

println(s"📊 Total dans HCD : $count")
spark.stop()
```

**Explication** :

- Écriture directe via Spark Cassandra Connector
- Mode append (ajout des données)
- Équivalent HBase bulkLoad mais plus simple

---

## 🔄 Équivalence HBase → HCD (Détaillée)

### HBase BulkLoad (inputs-clients)

**Processus HBase** :

1. Génération des HFiles via MapReduce
2. Chargement des HFiles dans HBase (bulkLoad)
3. Compaction des HFiles

**Composant** : `bic-batch-main.tar.gz`

- Traitement batch
- MapReduce en bulkLoad
- Chargement massif

### HCD Spark Batch Write

**Processus HCD** :

1. Lecture Parquet via Spark
2. Transformation des données
3. Écriture directe dans HCD via Spark Cassandra Connector

**Avantages** :

- ✅ Plus simple : Pas de génération HFiles
- ✅ Plus rapide : Écriture directe
- ✅ Plus flexible : Support de multiples formats

---

## ✅ Conclusion

**Use Cases Validés** :

- ✅ BIC-07 : Format JSON + colonnes dynamiques
- ✅ BIC-09 : Écriture batch (bulkLoad équivalent)

**Équivalence HBase** : ✅ Documentée et validée

**Performance** : Optimale avec Spark batch write

**Conformité** : ✅ Tous les tests passés

---

**Date** : 2025-12-01
**Script** : `08_load_interactions_batch.sh`
