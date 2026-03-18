# ARKEA POC - Service Endpoints & API Reference

**Version:** 1.0.0
**Last Updated:** 2026-03-16
**Cassandra Version:** 5.0.6

---

## 🚀 Quick Access

| Service | Endpoint | Status |
|---------|----------|--------|
| **Cassandra CQL** | `localhost:9102` | ✅ Operational |
| **Kafka Broker** | `localhost:9192` | ✅ Operational |
| **Kafka UI** | <http://localhost:9190> | ✅ Operational |
| **Spark Master UI** | <http://localhost:9280> | ✅ Operational |
| **Spark Worker UI** | <http://localhost:9281> | ✅ Operational |

---

## 📦 Cassandra (HCD)

### Connection

```bash
# CQL Shell (container internal check)
podman exec -it arkea-hcd cqlsh localhost 9042

# CQL Shell (host-side mapped port)
cqlsh localhost 9102

# Python Driver (host-side mapped port)
from cassandra.cluster import Cluster
cluster = Cluster(['localhost'], port=9102)
session = cluster.connect()
```

### Key Operations

```sql
-- List keyspaces
DESCRIBE KEYSPACES;

-- Create keyspace
CREATE KEYSPACE my_keyspace
WITH replication = {'class': 'SimpleStrategy', 'replication_factor': 1};

-- Use keyspace
USE my_keyspace;

-- Create table
CREATE TABLE operations (
    id UUID PRIMARY KEY,
    data text,
    created_at timestamp
);

-- Insert data
INSERT INTO operations (id, data, created_at)
VALUES (uuid(), 'test', toTimestamp(now()));
```

### Health Check

```bash
podman exec arkea-hcd cqlsh -e "SELECT cluster_name, release_version FROM system.local;"
```

---

## 📨 Kafka

### Kafka Connection

```bash
# Bootstrap server
localhost:9192

# Environment variable
KAFKA_BOOTSTRAP_SERVERS=localhost:9192
```

### Topic Operations

```bash
# Create topic
podman exec arkea-kafka /opt/kafka/bin/kafka-topics.sh \
  --bootstrap-server localhost:9192 \
  --create --topic my-topic \
  --partitions 3 --replication-factor 1

# List topics
podman exec arkea-kafka /opt/kafka/bin/kafka-topics.sh \
  --bootstrap-server localhost:9192 --list

# Describe topic
podman exec arkea-kafka /opt/kafka/bin/kafka-topics.sh \
  --bootstrap-server localhost:9192 \
  --describe --topic my-topic
```

### Produce/Consume

```bash
# Produce messages
podman exec -it arkea-kafka /opt/kafka/bin/kafka-console-producer.sh \
  --bootstrap-server localhost:9192 --topic my-topic

# Consume messages
podman exec -it arkea-kafka /opt/kafka/bin/kafka-console-consumer.sh \
  --bootstrap-server localhost:9192 --topic my-topic --from-beginning
```

### Kafka UI

Access the web interface at: <http://localhost:9190>

Features:

- Topic management
- Message viewing
- Consumer group monitoring
- Cluster metrics

---

## ⚡ Apache Spark

### Master UI

Access at: <http://localhost:9280>

Shows:

- Running applications
- Worker status
- Application history
- Cluster resources

### Worker UI

Access at: <http://localhost:9281>

Shows:

- Executor status
- Memory usage
- Running tasks

### Submit Jobs

```bash
# Submit Spark job
podman exec arkea-spark-master /opt/spark/bin/spark-submit \
  --master spark://arkea-spark-master:7077 \
  --conf spark.cassandra.connection.host=arkea-hcd \
  /path/to/script.py
```

### Spark Shell

```bash
# PySpark shell
podman exec -it arkea-spark-master /opt/spark/bin/pyspark \
  --master spark://arkea-spark-master:7077

# Scala shell
podman exec -it arkea-spark-master /opt/spark/bin/spark-shell \
  --master spark://arkea-spark-master:7077
```

---

## 🔗 Integration Examples

### Spark → Cassandra

```python
from pyspark.sql import SparkSession

spark = SparkSession.builder \
    .appName("CassandraIntegration") \
    .config("spark.cassandra.connection.host", "arkea-hcd") \
    .config("spark.cassandra.connection.port", "9042") \
    .getOrCreate()

# Read from Cassandra
df = spark.read \
    .format("org.apache.spark.sql.cassandra") \
    .options(table="my_table", keyspace="my_keyspace") \
    .load()

# Write to Cassandra
df.write \
    .format("org.apache.spark.sql.cassandra") \
    .options(table="target_table", keyspace="my_keyspace") \
    .mode("append") \
    .save()
```

### Kafka → Spark Streaming

```python
from pyspark.sql import SparkSession

spark = SparkSession.builder \
    .appName("KafkaStream") \
    .config("spark.jars.packages", "org.apache.spark:spark-sql-kafka-0-10_2.12:3.5.1") \
    .getOrCreate()

# Read from Kafka
df = spark.readStream \
    .format("kafka") \
    .option("kafka.bootstrap.servers", "arkea-kafka:9092") \
    .option("subscribe", "my-topic") \
    .load()
```

---

## 🛠️ Troubleshooting

### Container Not Starting

```bash
# Check logs
podman logs arkea-hcd --tail 50

# Check container status
podman ps -a --filter name=arkea

# Restart container
podman restart arkea-hcd
```

### Connection Refused

1. Verify container is running: `podman ps`
2. Check port mapping: `podman port arkea-hcd`
3. Verify network: `podman network inspect arkea-network`

### Performance Issues

```bash
# Check container resources
podman stats --no-stream

# Increase memory limit
podman update --memory 8G arkea-hcd
```

---

## 📚 References

- [Cassandra 5.0 Documentation](https://cassandra.apache.org/doc/latest/)
- [Apache Kafka Documentation](https://kafka.apache.org/documentation/)
- [Apache Spark Documentation](https://spark.apache.org/docs/latest/)
- [Spark Cassandra Connector](https://github.com/datastax/spark-cassandra-connector)
