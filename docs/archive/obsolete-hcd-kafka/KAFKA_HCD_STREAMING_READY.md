# ✅ Kafka → HCD Streaming : Configuration Terminée

**Date** : 2025-11-25
**Statut** : ✅ Prêt pour le streaming

---

## ✅ Ce qui a été Configuré

### 1. Infrastructure ✅

| Composant | Statut | Détails |
|-----------|--------|---------|
| **Kafka** | ✅ Opérationnel | Port 9092, démarré |
| **HCD** | ✅ Opérationnel | Port 9042, démarré |
| **Spark** | ✅ Installé | 3.5.1 |
| **spark-cassandra-connector** | ✅ Installé | 3.5.0 |

### 2. Schéma HCD ✅

- **Keyspace** : `poc_hbase_migration` ✅ Créé
- **Table** : `kafka_events` ✅ Créée

**Structure de la table** :

```cql
CREATE TABLE poc_hbase_migration.kafka_events (
    id UUID PRIMARY KEY,
    timestamp timestamp,
    topic text,
    partition int,
    offset bigint,
    key text,
    value text,
    processed_at timestamp
);
```

### 3. Kafka Topic ✅

- **Topic** : `test-topic` ✅ Créé
- **Partitions** : 1
- **Replication** : 1

### 4. Checkpoint Location ✅

- **Répertoire** : `/tmp/spark-checkpoints/kafka-to-hcd` ✅ Créé

### 5. Fichiers Créés ✅

- ✅ `kafka_to_hcd_streaming.scala` - Job Spark Streaming
- ✅ `setup_kafka_hcd_streaming.sh` - Script de configuration
- ✅ `create_kafka_schema.cql` - Schéma HCD
- ✅ `CE_QUI_MANQUE_KAFKA_HCD.md` - Documentation

---

## 🚀 Comment Utiliser

### Étape 1: Produire des Messages dans Kafka

Dans un terminal :

```bash
cd ${ARKEA_HOME}
./kafka-helper.sh kafka-console-producer.sh \
  --bootstrap-server localhost:9092 \
  --topic test-topic
```

Puis tapez des messages (un par ligne) :

```
Message 1
Message 2
{"user": "alice", "action": "login"}
```

Appuyez sur `Ctrl+C` pour quitter.

### Étape 2: Lancer le Job Spark Streaming

Dans un autre terminal :

```bash
cd ${ARKEA_HOME}
export SPARK_HOME=$(pwd)/spark-3.5.1
export PATH=$SPARK_HOME/bin:$PATH
jenv local 11
eval "$(jenv init -)"

$SPARK_HOME/bin/spark-shell \
  --packages org.apache.spark:spark-sql-kafka-0-10_2.12:3.5.1,com.datastax.spark:spark-cassandra-connector_2.12:3.5.0 \
  --conf spark.cassandra.connection.host=localhost \
  --conf spark.cassandra.connection.port=9042 \
  --conf spark.sql.extensions=com.datastax.spark.connector.CassandraSparkExtensions \
  -i kafka_to_hcd_streaming.scala
```

Le job va :

1. Se connecter à Kafka
2. Lire les messages du topic `test-topic`
3. Les transformer
4. Les écrire dans HCD

### Étape 3: Vérifier les Données dans HCD

Dans un troisième terminal :

```bash
cd ${ARKEA_HOME}/hcd-1.2.3
jenv local 11
eval "$(jenv init -)"
./bin/cqlsh localhost 9042
```

Puis dans cqlsh :

```cql
USE poc_hbase_migration;
SELECT * FROM kafka_events;
```

---

## 📊 Architecture du Pipeline

```
Kafka (test-topic)
    ↓
Spark Structured Streaming
    ↓ (transformation)
HCD (poc_hbase_migration.kafka_events)
```

---

## 🔍 Vérifications

### Vérifier que Kafka est démarré

```bash
lsof -Pi :9092 -sTCP:LISTEN
```

### Vérifier que HCD est démarré

```bash
lsof -Pi :9042 -sTCP:LISTEN
```

### Lister les topics Kafka

```bash
./kafka-helper.sh kafka-topics.sh --list --bootstrap-server localhost:9092
```

### Vérifier le schéma HCD

```bash
cd hcd-1.2.3
jenv local 11
eval "$(jenv init -)"
./bin/cqlsh localhost 9042 -e "DESCRIBE KEYSPACE poc_hbase_migration;"
```

---

## ⚠️ Points d'Attention

### 1. Format des Messages

Par défaut, les messages Kafka sont traités comme des **strings**. Pour des données structurées (JSON), il faudra ajouter un parsing dans le job Spark.

### 2. Checkpoint Location

Le répertoire `/tmp/spark-checkpoints/kafka-to-hcd` stocke l'état du streaming. **Ne pas le supprimer** entre les exécutions si vous voulez reprendre là où vous vous êtes arrêté.

### 3. Packages Spark

Les packages `spark-sql-kafka` et `spark-cassandra-connector` seront téléchargés automatiquement lors du premier lancement. Cela peut prendre quelques minutes.

### 4. Java Version

Assurez-vous d'utiliser **Java 11** (via jenv) pour Spark et HCD.

---

## 🎯 Prochaines Étapes

1. ✅ **Configuration terminée** - Tout est prêt
2. 🔄 **Tester le pipeline** - Produire des messages et vérifier dans HCD
3. 📊 **Créer les schémas Domirama/BIC** - Pour le POC complet
4. 🔧 **Adapter le format des données** - Selon les besoins métier

---

## 📝 Résumé

**Tout est maintenant en place pour streamer Kafka → HCD !**

- ✅ Infrastructure opérationnelle
- ✅ Schémas créés
- ✅ Job Spark Streaming prêt
- ✅ Configuration complète

**Il ne reste plus qu'à tester le pipeline complet !** 🚀
