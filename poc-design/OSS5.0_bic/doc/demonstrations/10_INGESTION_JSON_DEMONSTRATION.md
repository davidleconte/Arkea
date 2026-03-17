# 📥 Démonstration : Ingestion depuis Fichiers JSON

**Date** : 2025-12-01
**Script** : `10_load_interactions_json.sh`
**Use Cases** : BIC-07 (Format JSON), Ingestion fichiers JSON individuels

---

## 📋 Objectif

Ingérer les interactions depuis un fichier JSON (format JSONL) dans HCD via Spark.

---

## 🏗️ Architecture

```
┌─────────────┐      ┌──────────────┐      ┌─────────────┐
│  Fichier   │─────▶│    Spark     │─────▶│     HCD     │
│   JSON     │      │  (Lecture +  │      │(interactions)│
│  (JSONL)   │      │ Transformation)│      │             │
└─────────────┘      └──────────────┘      └─────────────┘
```

---

## 📋 Format des Données

### Format JSONL (JSON Lines)

Un événement par ligne, format JSON :

```json
{"id_interaction": "INT-2024-ABC123", "code_efs": "EFS001", ...}
{"id_interaction": "INT-2024-DEF456", "code_efs": "EFS002", ...}
```

---

## 🔧 Code Spark

### Code Spark - Lecture

```scala
// Lecture du fichier JSON (format JSONL)
val jsonDF = spark.read
  .option("multiline", "false")
  .option("mode", "PERMISSIVE")
  .json("${ARKEA_HOME}/poc-design/bic/data/json/interactions_1000.json")
```

**Explication** :

- Lecture JSON avec `read.json()`
- Format JSONL (une ligne JSON par événement)
- Mode PERMISSIVE pour gérer les erreurs

---

### Code Spark - Transformation

```scala
// Transformation vers format HCD
val interactions = jsonDF
  .withColumn("date_interaction", to_timestamp(col("date_interaction"), "yyyy-MM-dd'T'HH:mm:ss'Z'"))
  .withColumn("json_data", to_json(struct("*")))
  .withColumn("colonnes_dynamiques", map(
    lit("categorie"), col("categorie"),
    lit("duree_secondes"), col("duree_interaction").cast("string")
  ))
  .withColumn("idt_tech", col("id_interaction"))
  .withColumn("created_at", current_timestamp())
  .withColumn("updated_at", current_timestamp())
  .withColumn("version", lit(1))
  .select(
    col("code_efs"),
    col("numero_client"),
    col("date_interaction"),
    col("canal"),
    col("type_interaction"),
    col("idt_tech"),
    col("resultat"),
    col("json_data"),
    col("colonnes_dynamiques"),
    col("created_at"),
    col("updated_at"),
    col("version")
  )
  .filter(col("code_efs").isNotNull)
```

**Explication** :

- Transformation vers format HCD
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
- Vérification du total

---

## ✅ Validation

**Pertinence** : ✅ Conforme BIC-07 (Format JSON)
**Cohérence** : ✅ Format JSON → HCD correct
**Intégrité** : ✅ Toutes les données chargées
**Consistance** : ✅ Format uniforme
**Conformité** : ✅ Conforme aux exigences

---

**Date** : 2025-12-01
**Script** : `10_load_interactions_json.sh`
