# 🔍 Analyse en Profondeur : Spark Local et Kafka Local dans DomiramaCatOps POC

**Date** : 2025-01-XX
**Dernière mise à jour** : 2025-01-XX
**Version** : 2.0
**Objectif** : Analyser l'utilisation de Spark local et Kafka local dans le POC domiramaCatOps et leurs impacts sur le data model
**Format** : Analyse MECE complète avec impacts techniques détaillés

---

## 📑 Table des Matières

1. [PARTIE 1 : CONTEXTE ET BESOINS](#-partie-1--contexte-et-besoins)
2. [PARTIE 2 : ANALYSE SPARK LOCAL](#-partie-2--analyse-spark-local)
3. [PARTIE 3 : ANALYSE KAFKA LOCAL](#-partie-3--analyse-kafka-local)
4. [PARTIE 4 : IMPACTS SUR LE DATA MODEL](#-partie-4--impacts-sur-le-data-model)
5. [PARTIE 5 : RECOMMANDATIONS](#-partie-5--recommandations)

---

## 🎯 PARTIE 1 : CONTEXTE ET BESOINS

### 1.1 Cas d'Usage Spark et Kafka dans DomiramaCatOps

#### 1.1.1 Spark Local - Cas d'Usage

**1. Ingestion Batch (Remplacement MapReduce bulkLoad)**
- **Source** : Fichiers Parquet (format unique spécifié)
- **Cible** : Tables HCD (8 tables)
- **Fréquence** : Quotidienne (batch de fin de journée)
- **Volume** : Gros volumes (millions d'opérations)
- **Pattern** : Spark Batch Job (non-streaming)

**2. Export Incrémental (Remplacement FullScan + STARTROW/STOPROW + TIMERANGE)**
- **Source** : Tables HCD
- **Cible** : Fichiers Parquet (remplacement ORC)
- **Fréquence** : Quotidienne ou hebdomadaire
- **Pattern** : Spark Batch Job avec fenêtre glissante

**3. Transformation et Enrichissement**
- **Application des règles personnalisées** : Lecture `regles_personnalisees` → Application sur `operations_by_account`
- **Mise à jour des feedbacks** : Incrément des compteurs dans `feedback_par_libelle` et `feedback_par_ics`
- **Génération d'embeddings** : Génération `libelle_embedding` pour recherche vectorielle

**4. Migration HBase → HCD**
- **Source** : HBase (extraction)
- **Cible** : Tables HCD
- **Pattern** : Spark Batch Job avec mapping HBase → HCD

---

#### 1.1.2 Kafka Local - Cas d'Usage

**1. Ingestion Temps Réel - Corrections Client**
- **Source** : API Client (corrections de catégorisation)
- **Topic Kafka** : `domirama-catops-corrections`
- **Consumer** : Spark Structured Streaming ou Consumer Java
- **Cible** : Table `operations_by_account` (mise à jour `cat_user`, `cat_date_user`, `cat_validee`)
- **Pattern** : Event-driven, faible latence

**2. Ingestion Temps Réel - Événements Catégorisation**
- **Source** : Moteur de catégorisation (batch ou temps réel)
- **Topic Kafka** : `domirama-catops-categories`
- **Consumer** : Spark Structured Streaming
- **Cible** : Table `operations_by_account` (mise à jour `cat_auto`, `cat_confidence`)
- **Pattern** : Event-driven, traitement en streaming

**3. Ingestion Temps Réel - Feedbacks**
- **Source** : API Client (feedbacks sur catégorisation)
- **Topic Kafka** : `domirama-catops-feedbacks`
- **Consumer** : Spark Structured Streaming ou Consumer Java
- **Cible** : Tables `feedback_par_libelle` et `feedback_par_ics` (incrément compteurs)
- **Pattern** : Event-driven, compteurs atomiques

**4. Ingestion Temps Réel - Règles Personnalisées**
- **Source** : API Client (création/modification règles)
- **Topic Kafka** : `domirama-catops-rules`
- **Consumer** : Spark Structured Streaming ou Consumer Java
- **Cible** : Table `regles_personnalisees`
- **Pattern** : Event-driven, faible latence

**5. Ingestion Temps Réel - Acceptation/Opposition**
- **Source** : API Client (acceptation/opposition catégorisation)
- **Topic Kafka** : `domirama-catops-acceptance`
- **Consumer** : Spark Structured Streaming ou Consumer Java
- **Cible** : Tables `acceptation_client`, `opposition_categorisation`, `historique_opposition`
- **Pattern** : Event-driven, historique complet

---

### 1.2 Besoins de Checkpointing

#### 1.2.1 Spark Structured Streaming

**Checkpoint Location** : Système de fichiers local ou HDFS
- **État des traitements** : Suivi des micro-batches traités
- **Offset Kafka** : Suivi des offsets Kafka consommés
- **État des agrégations** : Si agrégations (ex: compteurs)
- **Watermarks** : Pour traitement événements tardifs

**Exigences** :
- ✅ **Fault Tolerance** : Reprise après crash sans perte de données
- ✅ **Exactly-Once Semantics** : Garantie de traitement unique
- ✅ **Idempotence** : Écritures idempotentes dans HCD

---

#### 1.2.2 Kafka Consumers (Java/Python)

**Checkpoint Location** : Table HCD dédiée ou Kafka Consumer Groups
- **Offset Management** : Suivi des offsets par partition
- **État des traitements** : Suivi des messages traités
- **Retry Logic** : Gestion des échecs et retry

**Exigences** :
- ✅ **At-Least-Once Semantics** : Garantie de traitement (avec possible duplication)
- ✅ **Idempotence** : Écritures idempotentes dans HCD
- ✅ **Monitoring** : Suivi des lag consumers

---

## 📊 PARTIE 2 : IMPACTS SUR LE DATA MODEL

### 2.1 Tables de Checkpoint et Métadonnées

#### 2.1.1 Table : `spark_checkpoints`

**Objectif** : Stocker les checkpoints Spark Structured Streaming

**Schéma CQL** :
```cql
CREATE TABLE domiramacatops_poc.spark_checkpoints (
    checkpoint_id        TEXT,           -- Identifiant unique du checkpoint (ex: "spark-streaming-operations")
    checkpoint_type     TEXT,           -- Type : "streaming", "batch", "export"
    source_type         TEXT,           -- Source : "kafka", "parquet", "hbase"
    source_path         TEXT,           -- Chemin source (topic Kafka ou chemin fichier)
    target_table        TEXT,           -- Table HCD cible
    last_processed_batch TIMESTAMP,     -- Dernier micro-batch traité
    last_processed_offset TEXT,         -- Dernier offset Kafka traité (JSON)
    last_processed_path  TEXT,          -- Dernier fichier Parquet traité
    watermark_timestamp  TIMESTAMP,     -- Watermark pour événements tardifs
    state_snapshot       TEXT,          -- Snapshot de l'état (JSON, optionnel)
    created_at           TIMESTAMP,      -- Date de création
    updated_at           TIMESTAMP,      -- Date de dernière mise à jour

    PRIMARY KEY (checkpoint_id)
) WITH default_time_to_live = 2592000;  -- TTL 30 jours (nettoyage automatique)
```

**Index SAI** :
```cql
CREATE CUSTOM INDEX idx_checkpoints_type ON domiramacatops_poc.spark_checkpoints (checkpoint_type);
CREATE CUSTOM INDEX idx_checkpoints_table ON domiramacatops_poc.spark_checkpoints (target_table);
```

**Usage** :
- Spark Structured Streaming lit/écrit cette table pour checkpointing
- Permet reprise après crash sans perte de données
- Suivi des offsets Kafka et fichiers Parquet traités

---

#### 2.1.2 Table : `kafka_consumer_offsets`

**Objectif** : Stocker les offsets Kafka pour consumers Java/Python (alternative à Kafka Consumer Groups)

**Schéma CQL** :
```cql
CREATE TABLE domiramacatops_poc.kafka_consumer_offsets (
    consumer_group       TEXT,           -- Consumer group ID
    topic                TEXT,           -- Topic Kafka
    partition            INT,            -- Partition Kafka
    offset               BIGINT,         -- Dernier offset traité
    offset_metadata      TEXT,           -- Métadonnées optionnelles
    last_processed_at    TIMESTAMP,      -- Date de dernière mise à jour
    last_message_id      TEXT,           -- ID du dernier message traité (pour idempotence)

    PRIMARY KEY ((consumer_group, topic), partition)
) WITH default_time_to_live = 2592000;  -- TTL 30 jours
```

**Index SAI** :
```cql
CREATE CUSTOM INDEX idx_offsets_group ON domiramacatops_poc.kafka_consumer_offsets (consumer_group);
CREATE CUSTOM INDEX idx_offsets_topic ON domiramacatops_poc.kafka_consumer_offsets (topic);
```

**Usage** :
- Consumers Java/Python lisent/écrivent cette table pour gérer offsets
- Alternative à Kafka Consumer Groups (plus de contrôle)
- Permet reprise après crash avec exactement le bon offset

---

#### 2.1.3 Table : `ingestion_metadata`

**Objectif** : Métadonnées sur les ingestions (batch et streaming)

**Schéma CQL** :
```cql
CREATE TABLE domiramacatops_poc.ingestion_metadata (
    ingestion_id         TEXT,           -- Identifiant unique de l'ingestion
    ingestion_type       TEXT,           -- Type : "batch", "streaming", "export"
    source_type          TEXT,           -- Source : "parquet", "kafka", "hbase"
    source_path          TEXT,           -- Chemin source
    target_table         TEXT,           -- Table HCD cible
    status               TEXT,           -- Status : "running", "completed", "failed", "paused"
    records_processed    BIGINT,         -- Nombre d'enregistrements traités
    records_failed       BIGINT,         -- Nombre d'enregistrements en échec
    start_time           TIMESTAMP,      -- Date de début
    end_time             TIMESTAMP,      -- Date de fin (NULL si en cours)
    error_message        TEXT,           -- Message d'erreur (si échec)
    config_snapshot      TEXT,           -- Configuration utilisée (JSON)
    created_at           TIMESTAMP,      -- Date de création
    updated_at           TIMESTAMP,      -- Date de dernière mise à jour

    PRIMARY KEY (ingestion_id)
) WITH CLUSTERING ORDER BY (start_time DESC);
```

**Index SAI** :
```cql
CREATE CUSTOM INDEX idx_ingestion_type ON domiramacatops_poc.ingestion_metadata (ingestion_type);
CREATE CUSTOM INDEX idx_ingestion_status ON domiramacatops_poc.ingestion_metadata (status);
CREATE CUSTOM INDEX idx_ingestion_table ON domiramacatops_poc.ingestion_metadata (target_table);
```

**Usage** :
- Suivi des ingestions batch et streaming
- Monitoring et alerting
- Historique des ingestions
- Debugging en cas d'échec

---

### 2.2 Colonnes Supplémentaires dans Tables Existantes

#### 2.2.1 Table `operations_by_account` - Colonnes de Métadonnées Ingestion

**Colonnes à Ajouter** :
```cql
-- Métadonnées d'ingestion
ingestion_batch_id      TEXT,           -- ID du batch d'ingestion (pour traçabilité)
ingestion_timestamp     TIMESTAMP,      -- Timestamp d'ingestion (pour déduplication)
ingestion_source        TEXT,           -- Source : "batch_parquet", "kafka_corrections", "kafka_categories"
ingestion_version       INT,            -- Version de l'ingestion (pour idempotence)
```

**Justification** :
- **Traçabilité** : Savoir d'où vient chaque opération
- **Déduplication** : Éviter les doublons en cas de rejeu
- **Debugging** : Identifier les problèmes d'ingestion
- **Audit** : Traçabilité complète

**Impact** : ⚠️ **Modification du schéma existant** (ALTER TABLE)

---

#### 2.2.2 Table `feedback_par_libelle` - Colonnes de Métadonnées

**Colonnes à Ajouter** :
```cql
-- Métadonnées d'ingestion
last_updated_at         TIMESTAMP,      -- Date de dernière mise à jour
updated_by              TEXT,           -- Source : "batch", "kafka_feedback", "api"
```

**Justification** :
- **Traçabilité** : Savoir quand et comment les compteurs ont été mis à jour
- **Audit** : Traçabilité des modifications

**Impact** : ⚠️ **Modification du schéma existant** (ALTER TABLE)

---

#### 2.2.3 Table `feedback_par_ics` - Colonnes de Métadonnées

**Colonnes à Ajouter** :
```cql
-- Métadonnées d'ingestion
last_updated_at         TIMESTAMP,      -- Date de dernière mise à jour
updated_by              TEXT,           -- Source : "batch", "kafka_feedback", "api"
```

**Impact** : ⚠️ **Modification du schéma existant** (ALTER TABLE)

---

#### 2.2.4 Table `regles_personnalisees` - Colonnes de Métadonnées

**Colonnes à Ajouter** :
```cql
-- Métadonnées d'ingestion
created_at              TIMESTAMP,      -- Date de création
updated_at              TIMESTAMP,      -- Date de dernière mise à jour
created_by              TEXT,           -- Source : "batch", "kafka_rules", "api"
version                 INT,            -- Version de la règle (pour historique)
```

**Impact** : ⚠️ **Modification du schéma existant** (ALTER TABLE)

---

#### 2.2.5 Table `acceptation_client` - Colonnes de Métadonnées

**Colonnes à Ajouter** :
```cql
-- Métadonnées d'ingestion
updated_at              TIMESTAMP,      -- Date de dernière mise à jour
updated_by              TEXT,           -- Source : "kafka_acceptance", "api"
```

**Impact** : ⚠️ **Modification du schéma existant** (ALTER TABLE)

---

#### 2.2.6 Table `opposition_categorisation` - Colonnes de Métadonnées

**Colonnes à Ajouter** :
```cql
-- Métadonnées d'ingestion
updated_at              TIMESTAMP,      -- Date de dernière mise à jour
updated_by              TEXT,           -- Source : "kafka_acceptance", "api"
```

**Impact** : ⚠️ **Modification du schéma existant** (ALTER TABLE)

---

## 📊 PARTIE 3 : PATTERNS D'INGESTION SPARK

### 3.1 Pattern 1 : Ingestion Batch Parquet → HCD

**Workflow** :
```
1. Spark lit fichiers Parquet (répertoire ou fichiers individuels)
2. Transformation des données (mapping colonnes, application règles)
3. Écriture dans HCD via Spark Cassandra Connector
4. Mise à jour des métadonnées d'ingestion
5. Checkpointing (si nécessaire pour reprise)
```

**Code Scala Exemple** :
```scala
val spark = SparkSession.builder()
  .appName("DomiramaCatOpsBatchIngestion")
  .config("spark.cassandra.connection.host", "localhost")
  .config("spark.cassandra.connection.port", "9042")
  .config("spark.sql.extensions", "com.datastax.spark.connector.CassandraSparkExtensions")
  .getOrCreate()

// 1. Lecture Parquet
val operationsDF = spark.read.parquet("/data/domiramaCatOps/operations/*.parquet")

// 2. Transformation
val enrichedDF = operationsDF
  .withColumn("ingestion_batch_id", lit(batchId))
  .withColumn("ingestion_timestamp", current_timestamp())
  .withColumn("ingestion_source", lit("batch_parquet"))
  .withColumn("ingestion_version", lit(1))

// 3. Application des règles personnalisées (join avec regles_personnalisees)
val rulesDF = spark.read
  .format("org.apache.spark.sql.cassandra")
  .options(Map("keyspace" -> "domiramacatops_poc", "table" -> "regles_personnalisees"))
  .load()

val withRulesDF = enrichedDF.join(
  broadcast(rulesDF),
  enrichedDF("code_si") === rulesDF("code_efs") &&
  enrichedDF("libelle") === rulesDF("libelle_simplifie") &&
  rulesDF("actif") === true,
  "left"
).withColumn("cat_auto",
  when(col("categorie_cible").isNotNull, col("categorie_cible"))
  .otherwise(col("cat_auto"))
)

// 4. Écriture dans HCD
withRulesDF.write
  .format("org.apache.spark.sql.cassandra")
  .options(Map(
    "keyspace" -> "domiramacatops_poc",
    "table" -> "operations_by_account"
  ))
  .mode("append")
  .save()

// 5. Mise à jour des feedbacks (compteurs)
// Note: Les compteurs nécessitent des UPDATE séparés (pas d'écriture directe)
```

**Checkpointing** :
- **Location** : `/checkpoints/spark/batch/operations/`
- **Contenu** : Liste des fichiers Parquet traités, nombre de lignes, timestamp
- **Usage** : Reprise après crash, évite retraitement des fichiers déjà traités

---

### 3.2 Pattern 2 : Spark Structured Streaming - Kafka → HCD

**Workflow** :
```
1. Spark Structured Streaming lit depuis Kafka
2. Transformation des données (parsing JSON, validation)
3. Écriture dans HCD via Spark Cassandra Connector
4. Checkpointing automatique (offsets Kafka + état)
5. Mise à jour des métadonnées d'ingestion
```

**Code Scala Exemple** :
```scala
val spark = SparkSession.builder()
  .appName("DomiramaCatOpsStreamingCorrections")
  .config("spark.cassandra.connection.host", "localhost")
  .config("spark.cassandra.connection.port", "9042")
  .config("spark.sql.extensions", "com.datastax.spark.connector.CassandraSparkExtensions")
  .getOrCreate()

// 1. Lecture depuis Kafka
val kafkaDF = spark.readStream
  .format("kafka")
  .option("kafka.bootstrap.servers", "localhost:9092")
  .option("subscribe", "domirama-catops-corrections")
  .option("startingOffsets", "latest")
  .load()

// 2. Parsing JSON
val correctionsDF = kafkaDF
  .select(from_json(col("value").cast("string"), correctionSchema).as("data"))
  .select("data.*")
  .withColumn("ingestion_timestamp", current_timestamp())
  .withColumn("ingestion_source", lit("kafka_corrections"))

// 3. Vérification acceptation/opposition (join avec acceptation_client et opposition_categorisation)
val acceptationDF = spark.read
  .format("org.apache.spark.sql.cassandra")
  .options(Map("keyspace" -> "domiramacatops_poc", "table" -> "acceptation_client"))
  .load()

val oppositionDF = spark.read
  .format("org.apache.spark.sql.cassandra")
  .options(Map("keyspace" -> "domiramacatops_poc", "table" -> "opposition_categorisation"))
  .load()

val validatedDF = correctionsDF
  .join(broadcast(acceptationDF),
    correctionsDF("code_si") === acceptationDF("code_efs") &&
    correctionsDF("contrat") === acceptationDF("no_contrat"),
    "left"
  )
  .join(broadcast(oppositionDF),
    correctionsDF("code_si") === oppositionDF("code_efs"),
    "left"
  )
  .filter(col("accepted") === true && col("opposed") === false)

// 4. Écriture dans HCD (ForeachBatch pour contrôle fin)
val query = validatedDF.writeStream
  .foreachBatch { (batchDF: DataFrame, batchId: Long) =>
    batchDF.write
      .format("org.apache.spark.sql.cassandra")
      .options(Map(
        "keyspace" -> "domiramacatops_poc",
        "table" -> "operations_by_account"
      ))
      .mode("append")
      .save()

    // Mise à jour checkpoint
    updateCheckpoint("spark-streaming-corrections", batchId, batchDF.count())
  }
  .option("checkpointLocation", "/checkpoints/spark/streaming/corrections/")
  .outputMode("append")
  .start()

query.awaitTermination()
```

**Checkpointing** :
- **Location** : `/checkpoints/spark/streaming/corrections/`
- **Contenu** : Offsets Kafka, état des micro-batches, watermarks
- **Usage** : Reprise après crash, exactly-once semantics

---

### 3.3 Pattern 3 : Export Incrémental HCD → Parquet

**Workflow** :
```
1. Spark lit depuis HCD avec filtre temporel (fenêtre glissante)
2. Transformation des données (exclusion colonnes vectorielles si nécessaire)
3. Écriture en Parquet (partitionné par date)
4. Checkpointing (dernière date exportée)
```

**Code Scala Exemple** :
```scala
val spark = SparkSession.builder()
  .appName("DomiramaCatOpsExportIncremental")
  .config("spark.cassandra.connection.host", "localhost")
  .config("spark.cassandra.connection.port", "9042")
  .getOrCreate()

// 1. Lecture depuis HCD avec filtre temporel
val lastExportDate = getLastExportDate("operations_export") // Depuis checkpoint

val operationsDF = spark.read
  .format("org.apache.spark.sql.cassandra")
  .options(Map(
    "keyspace" -> "domiramacatops_poc",
    "table" -> "operations_by_account"
  ))
  .load()
  .filter(col("date_op") >= lit(lastExportDate))
  .drop("libelle_embedding") // Exclusion colonne vectorielle (si nécessaire)

// 2. Écriture en Parquet (partitionné par date)
operationsDF.write
  .partitionBy("date_op")
  .mode("append")
  .parquet("/data/exports/domiramaCatOps/operations/")

// 3. Mise à jour checkpoint
updateCheckpoint("operations_export", currentDate, operationsDF.count())
```

**Checkpointing** :
- **Location** : `/checkpoints/spark/export/operations/`
- **Contenu** : Dernière date exportée, nombre de lignes, chemin fichiers
- **Usage** : Fenêtre glissante, évite réexport des données déjà exportées

---

## 📊 PARTIE 4 : PATTERNS D'INGESTION KAFKA (CONSUMERS JAVA/PYTHON)

### 4.1 Pattern 1 : Consumer Java - Corrections Client

**Workflow** :
```
1. Consumer Kafka lit depuis topic
2. Parsing et validation des messages
3. Vérification acceptation/opposition (lecture HCD)
4. UPDATE dans HCD (cat_user, cat_date_user, cat_validee)
5. Mise à jour des offsets Kafka
6. Mise à jour des feedbacks (compteurs)
```

**Code Java Exemple** :
```java
// 1. Configuration Kafka Consumer
Properties props = new Properties();
props.put("bootstrap.servers", "localhost:9092");
props.put("group.id", "domirama-catops-corrections");
props.put("key.deserializer", "org.apache.kafka.common.serialization.StringDeserializer");
props.put("value.deserializer", "org.apache.kafka.common.serialization.StringDeserializer");
props.put("enable.auto.commit", "false"); // Commit manuel pour contrôle

KafkaConsumer<String, String> consumer = new KafkaConsumer<>(props);
consumer.subscribe(Arrays.asList("domirama-catops-corrections"));

// 2. Configuration Cassandra
Cluster cluster = Cluster.builder()
    .addContactPoint("localhost")
    .withPort(9042)
    .build();
Session session = cluster.connect("domiramacatops_poc");

// 3. Préparation des requêtes
PreparedStatement updateOperation = session.prepare(
    "UPDATE operations_by_account SET cat_user = ?, cat_date_user = ?, cat_validee = ? " +
    "WHERE code_si = ? AND contrat = ? AND date_op = ? AND numero_op = ?"
);

PreparedStatement updateOffset = session.prepare(
    "UPDATE kafka_consumer_offsets SET offset = ?, last_processed_at = ? " +
    "WHERE consumer_group = ? AND topic = ? AND partition = ?"
);

// 4. Boucle de consommation
while (true) {
    ConsumerRecords<String, String> records = consumer.poll(Duration.ofMillis(100));

    for (ConsumerRecord<String, String> record : records) {
        try {
            // Parsing JSON
            CorrectionMessage msg = parseJSON(record.value());

            // Vérification acceptation/opposition
            if (!isAccepted(msg.getCodeEfs(), msg.getNoContrat(), session) ||
                isOpposed(msg.getCodeEfs(), session)) {
                continue; // Skip si non accepté ou opposé
            }

            // UPDATE dans HCD
            session.execute(updateOperation.bind(
                msg.getCatUser(),
                new Date(),
                true,
                msg.getCodeSi(),
                msg.getContrat(),
                msg.getDateOp(),
                msg.getNumeroOp()
            ));

            // Mise à jour des feedbacks (compteurs)
            updateFeedbackCounters(msg, session);

            // Mise à jour offset
            session.execute(updateOffset.bind(
                record.offset(),
                new Date(),
                "domirama-catops-corrections",
                "domirama-catops-corrections",
                record.partition()
            ));

            // Commit Kafka (après écriture HCD réussie)
            consumer.commitSync();

        } catch (Exception e) {
            // Log erreur, mais continue (pas de rollback Kafka)
            log.error("Error processing message", e);
        }
    }
}
```

**Checkpointing** :
- **Table** : `kafka_consumer_offsets`
- **Usage** : Suivi des offsets par partition, reprise après crash

---

### 4.2 Pattern 2 : Consumer Python - Feedbacks

**Workflow** :
```
1. Consumer Kafka lit depuis topic
2. Parsing et validation des messages
3. UPDATE compteurs dans HCD (COUNTER type)
4. Mise à jour des offsets Kafka
```

**Code Python Exemple** :
```python
from kafka import KafkaConsumer
from cassandra.cluster import Cluster
from cassandra.query import SimpleStatement
import json

# 1. Configuration Kafka Consumer
consumer = KafkaConsumer(
    'domirama-catops-feedbacks',
    bootstrap_servers=['localhost:9092'],
    group_id='domirama-catops-feedbacks',
    enable_auto_commit=False
)

# 2. Configuration Cassandra
cluster = Cluster(['localhost'])
session = cluster.connect('domiramacatops_poc')

# 3. Préparation des requêtes
update_feedback_stmt = session.prepare(
    "UPDATE feedback_par_libelle SET count_client = count_client + 1 "
    "WHERE type_operation = ? AND sens_operation = ? AND libelle_simplifie = ? AND categorie = ?"
)

update_offset_stmt = session.prepare(
    "UPDATE kafka_consumer_offsets SET offset = ?, last_processed_at = ? "
    "WHERE consumer_group = ? AND topic = ? AND partition = ?"
)

# 4. Boucle de consommation
for message in consumer:
    try:
        # Parsing JSON
        msg = json.loads(message.value.decode('utf-8'))

        # UPDATE compteur
        session.execute(update_feedback_stmt, [
            msg['type_operation'],
            msg['sens_operation'],
            msg['libelle_simplifie'],
            msg['categorie']
        ])

        # Mise à jour offset
        session.execute(update_offset_stmt, [
            message.offset,
            datetime.now(),
            'domirama-catops-feedbacks',
            'domirama-catops-feedbacks',
            message.partition
        ])

        # Commit Kafka
        consumer.commit()

    except Exception as e:
        log.error(f"Error processing message: {e}")
```

**Checkpointing** :
- **Table** : `kafka_consumer_offsets`
- **Usage** : Suivi des offsets par partition

---

## 📊 PARTIE 5 : STRATÉGIES DE CHECKPOINTING

### 5.1 Spark Structured Streaming

#### 5.1.1 Checkpoint Location (Fichiers)

**Structure** :
```
/checkpoints/spark/streaming/
├── corrections/
│   ├── sources/
│   │   └── 0/  (offsets Kafka)
│   ├── state/
│   │   └── 0/  (état des agrégations)
│   └── commits/
│       └── 0/  (commits des micro-batches)
├── categories/
│   └── ...
└── feedbacks/
    └── ...
```

**Contenu** :
- **sources/** : Offsets Kafka (JSON)
- **state/** : État des agrégations (si windowing)
- **commits/** : Commits des micro-batches

**Avantages** :
- ✅ Exactly-once semantics
- ✅ Reprise automatique après crash
- ✅ Pas de perte de données

**Inconvénients** :
- ⚠️ Nécessite système de fichiers partagé (HDFS, S3, NFS)
- ⚠️ Gestion manuelle du nettoyage (TTL)

---

#### 5.1.2 Checkpoint Location (HCD Table)

**Alternative** : Utiliser table `spark_checkpoints` au lieu de fichiers

**Avantages** :
- ✅ Pas besoin de système de fichiers partagé
- ✅ Intégration avec HCD
- ✅ TTL automatique
- ✅ Monitoring facile

**Inconvénients** :
- ⚠️ Nécessite développement custom (pas supporté nativement)
- ⚠️ Performance potentiellement moindre

**Recommandation** : ⚠️ **Utiliser fichiers pour POC local, HCD table pour production**

---

### 5.2 Kafka Consumers (Java/Python)

#### 5.2.1 Kafka Consumer Groups (Natif)

**Configuration** :
```properties
enable.auto.commit=false
auto.commit.interval.ms=5000
```

**Avantages** :
- ✅ Gestion automatique par Kafka
- ✅ Pas de code supplémentaire
- ✅ Performance optimale

**Inconvénients** :
- ⚠️ Moins de contrôle
- ⚠️ At-least-once semantics (possible duplication)

---

#### 5.2.2 Table HCD `kafka_consumer_offsets` (Custom)

**Avantages** :
- ✅ Contrôle total sur les offsets
- ✅ Idempotence possible (avec `last_message_id`)
- ✅ Monitoring facile
- ✅ Reprise fine après crash

**Inconvénients** :
- ⚠️ Code supplémentaire à maintenir
- ⚠️ Performance potentiellement moindre

**Recommandation** : ✅ **Utiliser table HCD pour POC (plus de contrôle)**

---

### 5.3 Idempotence et Déduplication

#### 5.3.1 Stratégie : `ingestion_version` + `ingestion_timestamp`

**Principe** :
- Chaque ingestion a un `ingestion_version` unique
- `ingestion_timestamp` pour ordre chronologique
- Si `ingestion_version` existe déjà → skip (idempotence)

**Code Exemple** :
```scala
// Avant écriture, vérifier si déjà traité
val existingDF = spark.read
  .format("org.apache.spark.sql.cassandra")
  .options(Map(
    "keyspace" -> "domiramacatops_poc",
    "table" -> "operations_by_account"
  ))
  .load()
  .filter(col("ingestion_batch_id") === batchId)

if (existingDF.count() > 0) {
  log.warn(s"Batch $batchId already processed, skipping")
} else {
  // Écriture normale
  operationsDF.write...
}
```

---

#### 5.3.2 Stratégie : `last_message_id` dans `kafka_consumer_offsets`

**Principe** :
- Stocker `last_message_id` (UUID ou hash du message)
- Avant traitement, vérifier si `message_id` déjà traité
- Si oui → skip (idempotence)

**Code Exemple** :
```java
// Vérification avant traitement
String lastMessageId = getLastMessageId(partition);
if (record.key().equals(lastMessageId)) {
    continue; // Déjà traité
}

// Traitement...
// Mise à jour last_message_id
updateLastMessageId(partition, record.key());
```

---

## 📊 PARTIE 6 : IMPACTS SUR LES SCRIPTS DE DÉMONSTRATION

### 6.1 Scripts à Créer/Modifier

#### 6.1.1 Scripts de Setup (Nouveaux)

**`05_create_checkpoint_tables.sh`**
- Création des tables `spark_checkpoints`, `kafka_consumer_offsets`, `ingestion_metadata`
- Création des index SAI
- Documentation

---

#### 6.1.2 Scripts d'Ingestion (Modifiés)

**`05_load_operations_data_parquet.sh`** (Modifié)
- Ajout colonnes métadonnées (`ingestion_batch_id`, `ingestion_timestamp`, etc.)
- Mise à jour table `ingestion_metadata`
- Checkpointing (fichiers ou HCD)

**`06_load_meta_categories_data_parquet.sh`** (Modifié)
- Ajout colonnes métadonnées
- Mise à jour table `ingestion_metadata`

**`07_load_category_data_realtime.sh`** (Modifié)
- Intégration Kafka (optionnel pour POC)
- Mise à jour table `kafka_consumer_offsets`
- Mise à jour table `ingestion_metadata`

---

#### 6.1.3 Scripts de Démonstration (Nouveaux)

**`22_demo_spark_streaming.sh`**
- Démonstration Spark Structured Streaming depuis Kafka
- Checkpointing
- Exactly-once semantics

**`23_demo_kafka_consumer.sh`**
- Démonstration Consumer Kafka (Java ou Python)
- Gestion offsets via table HCD
- Idempotence

**`24_demo_checkpointing.sh`**
- Démonstration reprise après crash
- Vérification checkpointing
- Tests de fault tolerance

---

## 📊 PARTIE 7 : RÉSUMÉ DES IMPACTS

### 7.1 Nouvelles Tables

| Table | Colonnes | Usage | Priorité |
|-------|----------|-------|----------|
| **spark_checkpoints** | 12 colonnes | Checkpointing Spark Streaming | 🔴 **Haute** |
| **kafka_consumer_offsets** | 7 colonnes | Gestion offsets Kafka | 🔴 **Haute** |
| **ingestion_metadata** | 13 colonnes | Métadonnées ingestions | 🟡 **Moyenne** |

**Total** : **3 nouvelles tables** (en plus des 8 existantes)

---

### 7.2 Colonnes Supplémentaires

| Table | Colonnes Ajoutées | Impact | Priorité |
|-------|-------------------|--------|----------|
| **operations_by_account** | 4 colonnes | ⚠️ ALTER TABLE | 🔴 **Haute** |
| **feedback_par_libelle** | 2 colonnes | ⚠️ ALTER TABLE | 🟡 **Moyenne** |
| **feedback_par_ics** | 2 colonnes | ⚠️ ALTER TABLE | 🟡 **Moyenne** |
| **regles_personnalisees** | 4 colonnes | ⚠️ ALTER TABLE | 🟡 **Moyenne** |
| **acceptation_client** | 2 colonnes | ⚠️ ALTER TABLE | 🟡 **Moyenne** |
| **opposition_categorisation** | 2 colonnes | ⚠️ ALTER TABLE | 🟡 **Moyenne** |

**Total** : **16 colonnes supplémentaires** (réparties sur 6 tables)

---

### 7.3 Scripts Supplémentaires

| Script | Type | Priorité |
|--------|------|----------|
| **05_create_checkpoint_tables.sh** | Setup | 🔴 **Haute** |
| **22_demo_spark_streaming.sh** | Démonstration | 🟡 **Moyenne** |
| **23_demo_kafka_consumer.sh** | Démonstration | 🟡 **Moyenne** |
| **24_demo_checkpointing.sh** | Démonstration | 🟡 **Moyenne** |

**Total** : **4 scripts supplémentaires** (en plus des 24 existants)

---

## 📊 PARTIE 8 : RECOMMANDATIONS

### 8.1 Pour le POC Local

**Spark** :
- ✅ **Mode Local** : `local[*]` ou `local[4]` (4 cores)
- ✅ **Checkpoint Location** : Répertoire local (`/tmp/checkpoints/`)
- ✅ **Format Source** : Parquet uniquement (spécification)
- ✅ **Batch Jobs** : Priorité sur streaming (plus simple)

**Kafka** :
- ✅ **Mode Local** : Single broker (suffisant pour POC)
- ✅ **Topics** : 5 topics (corrections, categories, feedbacks, rules, acceptance)
- ✅ **Consumers** : Java ou Python (selon préférence)
- ✅ **Checkpointing** : Table HCD `kafka_consumer_offsets` (plus de contrôle)

---

### 8.2 Pour la Production

**Spark** :
- ✅ **Mode Cluster** : YARN, Kubernetes, ou Standalone
- ✅ **Checkpoint Location** : HDFS ou S3 (système de fichiers partagé)
- ✅ **Structured Streaming** : Exactly-once semantics
- ✅ **Monitoring** : Spark UI + métriques custom

**Kafka** :
- ✅ **Mode Cluster** : Multi-broker (haute disponibilité)
- ✅ **Replication** : Replication factor 3
- ✅ **Consumers** : Consumer groups natifs (performance)
- ✅ **Monitoring** : Kafka Manager, Prometheus

---

## 🎯 CONCLUSION

**Impacts sur le Data Model** :
- ✅ **3 nouvelles tables** : `spark_checkpoints`, `kafka_consumer_offsets`, `ingestion_metadata`
- ✅ **16 colonnes supplémentaires** : Réparties sur 6 tables existantes
- ✅ **4 scripts supplémentaires** : Setup et démonstrations

**Checkpointing** :
- ✅ **Spark Structured Streaming** : Fichiers locaux (POC) ou HDFS/S3 (production)
- ✅ **Kafka Consumers** : Table HCD `kafka_consumer_offsets` (POC et production)

**Prochaines Étapes** :
1. 🔴 Créer les 3 nouvelles tables de checkpoint
2. 🔴 Modifier les schémas existants (ALTER TABLE)
3. 🟡 Créer les scripts de démonstration Spark/Kafka
4. 🟡 Tester les patterns d'ingestion et checkpointing

---

**Date** : 2025-01-XX
**Dernière mise à jour** : 2025-01-XX
**Version** : 2.0
**Version** : 1.0
