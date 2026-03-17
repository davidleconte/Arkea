# 📥 Démonstration : Chargement des Données Domirama2

**Date** : 2025-11-26 12:26:29
**Script** : 11_load_domirama2_data_fixed_v2_didactique.sh
**Objectif** : Démontrer le chargement de données dans HCD via Spark

---

## 📋 Table des Matières

1. [Contexte et Stratégie](#contexte-et-stratégie)
2. [Code Spark - Lecture](#code-spark---lecture)
3. [Code Spark - Transformation](#code-spark---transformation)
4. [Code Spark - Écriture](#code-spark---écriture)
5. [Vérifications](#vérifications)
6. [Conclusion](#conclusion)

---

## 📚 Contexte et Stratégie

### Stratégie Multi-Version (Conforme IBM)

**Principe** :

- Le BATCH écrit UNIQUEMENT `cat_auto` et `cat_confidence`
- Le CLIENT écrit dans `cat_user`, `cat_date_user`, `cat_validee`
- L'APPLICATION priorise `cat_user` si non nul, sinon `cat_auto`
- Cette séparation garantit qu'aucune correction client ne sera perdue

**Colonnes écrites par le BATCH** :

- ✅ `cat_auto` : Catégorie automatique (batch)
- ✅ `cat_confidence` : Score de confiance (0.0 à 1.0)
- ❌ `cat_user` : NULL (batch ne touche jamais)
- ❌ `cat_date_user` : NULL (batch ne touche jamais)
- ❌ `cat_validee` : false (batch ne touche jamais)

### Format de Données Source

- **Format** : CSV
- **Fichier** : `${ARKEA_HOME}/poc-design/domirama2/data/operations_sample
csv`

- **Colonnes** : code_si, contrat, date_iso, seq, libelle, montant, etc.

---

## 📥 Code Spark - Lecture

### Code Exécuté

```scala
val inputPath = "${ARKEA_HOME}/poc-design/domirama2/data/operations_sample.csv"
val spark = SparkSession.builder()
  .appName("Domirama2LoaderBatch")
  .config("spark.cassandra.connection.host", "localhost")
  .config("spark.cassandra.connection.port", "9042")
  .config("spark.sql.extensions", "com.datastax.spark.connector.CassandraSparkExtensions")
  .getOrCreate()
import spark.implicits._

println("📥 Lecture du CSV...")
val raw = spark.read
  .option("header", "true")
  .option("inferSchema", "false")
  .csv(inputPath)
println(s"✅ ${raw.count()} lignes lues")
```

### Explication

- **SparkSession** : Session Spark avec connexion HCD configurée
- **spark.read** : Lecture des données depuis le fichier CSV
- **option("header", "true")** : Première ligne = en-têtes
- **option("inferSchema", "false")** : Pas d'inférence automatique de types
- **.csv()** : Format de lecture CSV

---

## 🔄 Code Spark - Transformation

### Code Exécuté

```scala
println("🔄 Transformation...")
val ops = raw.select(
  col("code_si").cast("string").as("code_si"),
  col("contrat").cast("string").as("contrat"),
  to_timestamp(col("date_iso"), "yyyy-MM-dd'T'HH:mm:ss'Z'").as("date_op"),
  col("seq").cast("int").as("numero_op"),
  lit(UUID.randomUUID().toString).as("op_id"),
  col("libelle").cast("string").as("libelle"),
  col("montant").cast("decimal(10,2)").as("montant"),
  coalesce(col("devise").cast("string"), lit("EUR")).as("devise"),
  coalesce(col("type_operation").cast("string"), lit("AUTRE")).as("type_operation"),
  coalesce(col("sens_operation").cast("string"), lit("DEBIT")).as("sens_operation"),
  lit("BASE64_COBOL_DATA".getBytes("UTF-8")).as("operation_data"),
  lit("").cast("string").as("cobol_data_base64"),
  lit(null).cast("string").as("copy_type"),
  lit(null).cast("timestamp").as("date_valeur"),
  lit(null).cast("map<string,string>").as("meta_flags"),
  coalesce(col("categorie_auto").cast("string"), lit("")).as("cat_auto"),
  coalesce(col("cat_confidence").cast("decimal(3,2)"), lit(BigDecimal.ZERO)).as("cat_confidence"),
  lit(null).cast("string").as("cat_user"),
  lit(null).cast("timestamp").as("cat_date_user"),
  lit(false).cast("boolean").as("cat_validee")
)

val countBefore = ops.count()
println(s"✅ $countBefore opérations transformées")
```

### Explication des Transformations

**Clés de Partition et Clustering** :

- `code_si` : Cast en string (partition key)
- `contrat` : Cast en string (partition key)
- `date_op` : Conversion timestamp depuis date_iso (clustering key DESC)
- `numero_op` : Cast en int depuis seq (clustering key ASC)

**Colonnes Principales** :

- `op_id` : UUID généré pour chaque opération
- `libelle` : Libellé de l'opération (recherche full-text)
- `montant` : Montant en decimal(10,2)
- `devise` : Devise (EUR par défaut si null)

**Colonnes de Catégorisation (Stratégie Batch)** :

- `cat_auto` : Catégorie automatique depuis categorie_auto (batch écrit)
- `cat_confidence` : Score de confiance depuis cat_confidence (batch écrit)
- `cat_user` : NULL (batch ne touche jamais)
- `cat_date_user` : NULL (batch ne touche jamais)
- `cat_validee` : false (batch ne touche jamais)

---

## 💾 Code Spark - Écriture

### Code Exécuté

```scala
println("💾 Écriture dans HCD...")
ops.write
  .format("org.apache.spark.sql.cassandra")
  .options(Map("keyspace" -> "domirama2_poc", "table" -> "operations_by_account"))
  .mode("append")
  .save()

println("✅ Écriture terminée !")

val count = spark.read
  .format("org.apache.spark.sql.cassandra")
  .options(Map("keyspace" -> "domirama2_poc", "table" -> "operations_by_account"))
  .load()
  .count()

println(s"📊 Total dans HCD : $count")
spark.stop()
```

### Explication

- **format("org.apache.spark.sql.cassandra")** : Utilise Spark Cassandra Connector
- **options()** : Configuration keyspace et table
- **mode("append")** : Ajoute les données (pas de remplacement)
- **Vérification** : Lecture depuis HCD pour compter le total

---

## 🔍 Vérifications

### Résumé des Vérifications

| Vérification | Attendu | Obtenu | Statut |
|--------------|---------|--------|--------|
| Opérations chargées | > 0 | 10010 | ✅ |
| Stratégie batch (cat_user null) | null | null | ✅ |

---

## ✅ Conclusion

Le chargement des données a été effectué avec succès :

✅ **Fichier source** : ${ARKEA_HOME}/poc-design/domirama2/data/operations_sample.csv
✅ **Opérations chargées** : 10010
✅ **Stratégie batch validée** : cat_user est null
✅ **Stratégie multi-version** : Conforme IBM

### Prochaines Étapes

- Script 12: Tests de recherche
- Script 13: Tests de correction client (API)

---

**✅ Chargement terminé avec succès !**
