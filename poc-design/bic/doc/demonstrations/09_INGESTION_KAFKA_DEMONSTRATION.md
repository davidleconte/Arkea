# 📥 Démonstration : Ingestion Temps Réel via Kafka

**Date** : 2025-12-01  
**Script** : `09_load_interactions_realtime.sh`  
**Use Cases** : BIC-02 (Ingestion Kafka temps réel), BIC-07 (Format JSON)

---

## 📋 Objectif

Ingérer les interactions client en temps réel depuis Kafka (topic `bic-event`)
vers HCD via Spark Structured Streaming.

---

## 🏗️ Architecture

```
┌─────────────┐      ┌──────────────┐      ┌─────────────┐
│   Client   │─────▶│  Kafka Topic │─────▶│Spark Stream │
│   API      │      │  (bic-event) │      │  (Consumer) │
└─────────────┘      └──────────────┘      └─────────────┘
                                                      │
                                                      ▼
                                              ┌─────────────┐
                                              │     HCD     │
                                              │(interactions)│
                                              └─────────────┘
```

---

## 📋 Configuration Kafka

### Topic

- **Nom** : `bic-event`
- **Partitions** : 3
- **Replication** : 1 (POC local)

### Format des Messages (JSON)

```json
{
  "id_interaction": "INT-2024-ABC123",
  "code_efs": "EFS001",
  "numero_client": "CLIENT123",
  "date_interaction": "2024-01-20T10:00:00Z",
  "canal": "email",
  "type_interaction": "consultation",
  "resultat": "succès",
  "details": "Le client a consulté son solde",
  "sujet": "Consultation - email",
  "contenu": "Contenu de l'interaction consultation via email.",
  "id_conseiller": "CONS001",
  "nom_conseiller": "Dupont",
  "prenom_conseiller": "Jean",
  "duree_interaction": 180,
  "tags": ["consultation", "email"],
  "categorie": "service_client",
  "metadata": {
    "source": "kafka",
    "topic": "bic-event",
    "partition": 0,
    "offset": 12345,
    "timestamp_kafka": "2024-01-20T10:00:00Z"
  }
}
```

---

## 🔧 Configuration Spark Streaming

### Code Spark Streaming

```scala
import org.apache.spark.sql.SparkSession
import org.apache.spark.sql.functions._
import org.apache.spark.sql.types._
import org.apache.spark.sql.streaming.Trigger

// Configuration Spark
val spark = SparkSession.builder()
  .appName("BICStreamingKafka")
  .config("spark.cassandra.connection.host", "localhost")
  .config("spark.cassandra.connection.port", "9042")
  .config("spark.sql.extensions", "com.datastax.spark.connector.CassandraSparkExtensions")
  .getOrCreate()

import spark.implicits._

// Schéma JSON des événements Kafka
val eventSchema = StructType(Array(
  StructField("id_interaction", StringType),
  StructField("code_efs", StringType),
  StructField("numero_client", StringType),
  StructField("date_interaction", StringType),
  StructField("canal", StringType),
  StructField("type_interaction", StringType),
  StructField("resultat", StringType),
  StructField("details", StringType),
  StructField("sujet", StringType),
  StructField("contenu", StringType),
  StructField("id_conseiller", StringType),
  StructField("nom_conseiller", StringType),
  StructField("prenom_conseiller", StringType),
  StructField("duree_interaction", IntegerType),
  StructField("tags", ArrayType(StringType)),
  StructField("categorie", StringType),
  StructField("metadata", MapType(StringType, StringType))
))

// 1. Lecture depuis Kafka
println("📥 Lecture depuis Kafka (topic: bic-event)...")
val kafkaDF = spark.readStream
  .format("kafka")
  .option("kafka.bootstrap.servers", "localhost:9092")
  .option("subscribe", "bic-event")
  .option("startingOffsets", "latest")
  .load()

// 2. Parsing JSON
println("🔄 Parsing JSON...")
val eventsDF = kafkaDF
  .select(from_json(col("value").cast("string"), eventSchema).as("data"))
  .select("data.*")
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

// 3. Écriture dans HCD (ForeachBatch pour contrôle fin)
println("💾 Écriture dans HCD...")
val query = eventsDF.writeStream
  .foreachBatch { (batchDF: DataFrame, batchId: Long) =>
    val count = batchDF.count()
    if (count > 0) {
      batchDF.write
        .format("org.apache.spark.sql.cassandra")
        .options(Map(
          "keyspace" -> "bic_poc",
          "table" -> "interactions_by_client"
        ))
        .mode("append")
        .save()

      println(s"✅ Batch $batchId : $count événement(s) écrit(s)")
    }
  }
  .option("checkpointLocation", "${ARKEA_HOME}/poc-design/bic/data/checkpoints/kafka_streaming")
  .outputMode("append")
  .trigger(Trigger.ProcessingTime("10 seconds"))
  .start()

println("🚀 Streaming démarré. Appuyez sur Ctrl+C pour arrêter.")
query.awaitTermination()
```

**Explication** :

- Lecture depuis Kafka avec `readStream.format("kafka")`
- Parsing JSON avec schéma défini
- Transformation vers format HCD
- Écriture par micro-batch avec `foreachBatch`
- Checkpointing pour reprise après crash

---

## ✅ Validation

**Pertinence** : ✅ Conforme BIC-02 (Ingestion Kafka temps réel)  
**Cohérence** : ✅ Format Kafka → HCD correct  
**Intégrité** : ✅ Tous les événements traités  
**Consistance** : ✅ Pas de perte de données  
**Conformité** : ✅ Conforme aux exigences clients/IBM

---

**Date** : 2025-12-01  
**Script** : `09_load_interactions_realtime.sh`
