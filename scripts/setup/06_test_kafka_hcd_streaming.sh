#!/bin/bash

# Script de test complet du pipeline Kafka → HCD

set -e

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

echo "=========================================="
echo "Test Complet : Kafka → HCD Streaming"
echo "=========================================="
echo ""

cd /Users/david.leconte/Documents/Arkea

# 1. Vérifier que Kafka est démarré
info "🔍 Vérification de Kafka..."
if lsof -Pi :9092 -sTCP:LISTEN -t >/dev/null 2>&1 ; then
    info "✅ Kafka est démarré"
else
    error "❌ Kafka n'est pas démarré. Démarrez avec: ./start_kafka.sh"
    exit 1
fi

# 2. Vérifier que HCD est démarré
info "🔍 Vérification de HCD..."
if lsof -Pi :9042 -sTCP:LISTEN -t >/dev/null 2>&1 ; then
    info "✅ HCD est démarré"
else
    error "❌ HCD n'est pas démarré. Démarrez avec: ./start_hcd.sh"
    exit 1
fi

# 3. Vérifier que le topic existe
info "🔍 Vérification du topic Kafka..."
KAFKA_BOOTSTRAP="${KAFKA_BOOTSTRAP_SERVERS:-localhost:9092}"
if ./kafka-helper.sh kafka-topics.sh --list --bootstrap-server "$KAFKA_BOOTSTRAP" 2>&1 | grep -q "test-topic"; then
    info "✅ Topic test-topic existe"
else
    warn "⚠️  Création du topic test-topic..."
    ./kafka-helper.sh kafka-topics.sh --create --bootstrap-server "$KAFKA_BOOTSTRAP" --topic test-topic --partitions 1 --replication-factor 1 2>&1 | grep -v "Error" || true
    sleep 2
fi

# 4. Nettoyer les données précédentes dans HCD (optionnel)
info "🧹 Nettoyage des données précédentes dans HCD..."
cd binaire/hcd-1.2.3
jenv local 11
eval "$(jenv init -)"
./bin/cqlsh localhost 9042 -e "USE poc_hbase_migration; TRUNCATE kafka_events;" 2>&1 | grep -v "Warnings" || true
cd ..
info "✅ Données nettoyées"

# 5. Produire des messages de test dans Kafka
info "📤 Production de messages de test dans Kafka..."
KAFKA_BOOTSTRAP="${KAFKA_BOOTSTRAP_SERVERS:-localhost:9092}"
echo "Message test 1" | ./kafka-helper.sh kafka-console-producer.sh --bootstrap-server "$KAFKA_BOOTSTRAP" --topic test-topic 2>&1 | grep -v "Warnings" || true
sleep 1
echo "Message test 2" | ./kafka-helper.sh kafka-console-producer.sh --bootstrap-server "$KAFKA_BOOTSTRAP" --topic test-topic 2>&1 | grep -v "Warnings" || true
sleep 1
echo '{"user": "alice", "action": "login", "timestamp": "2025-11-25T13:00:00Z"}' | ./kafka-helper.sh kafka-console-producer.sh --bootstrap-server "$KAFKA_BOOTSTRAP" --topic test-topic 2>&1 | grep -v "Warnings" || true
sleep 1
echo '{"user": "bob", "action": "logout", "timestamp": "2025-11-25T13:01:00Z"}' | ./kafka-helper.sh kafka-console-producer.sh --bootstrap-server "$KAFKA_BOOTSTRAP" --topic test-topic 2>&1 | grep -v "Warnings" || true
info "✅ 4 messages produits dans Kafka"

# 6. Lancer le job Spark Streaming en arrière-plan
info "🚀 Lancement du job Spark Streaming..."
export SPARK_HOME=$(pwd)/binaire/spark-3.5.1
export PATH=$SPARK_HOME/bin:$PATH
jenv local 11
eval "$(jenv init -)"

# Créer une version de test qui lit un batch limité
cat > /tmp/test_kafka_hcd_batch.scala <<'EOF'
import org.apache.spark.sql.SparkSession
import org.apache.spark.sql.functions._

val spark = SparkSession.builder()
  .appName("Kafka to HCD Test")
  .config("spark.cassandra.connection.host", "localhost")
  .config("spark.cassandra.connection.port", "9042")
  .config("spark.sql.extensions", "com.datastax.spark.connector.CassandraSparkExtensions")
  .getOrCreate()

println("✅ Spark Session créée")

// Lire depuis Kafka (batch, pas streaming pour le test)
val kafkaDF = spark
  .read
  .format("kafka")
  .option("kafka.bootstrap.servers", "${KAFKA_BOOTSTRAP_SERVERS:-localhost:9092}")
  .option("subscribe", "test-topic")
  .option("startingOffsets", "earliest")
  .option("endingOffsets", "latest")
  .load()

println(s"✅ ${kafkaDF.count()} messages lus depuis Kafka")

// Transformer
val transformed = kafkaDF
  .select(
    col("key").cast("string").as("kafka_key"),
    col("value").cast("string").as("kafka_value"),
    col("topic"),
    col("partition"),
    col("offset"),
    col("timestamp").as("kafka_timestamp")
  )
  .withColumn("id", expr("uuid()"))
  .withColumn("processed_at", current_timestamp())
  .select(
    col("id"),
    col("kafka_timestamp").as("timestamp"),
    col("topic"),
    col("partition"),
    col("offset"),
    col("kafka_key").as("key"),
    col("kafka_value").as("value"),
    col("processed_at")
  )

println("✅ Données transformées")
transformed.show(false)

// Écrire vers HCD
transformed.write
  .format("org.apache.spark.sql.cassandra")
  .option("keyspace", "poc_hbase_migration")
  .option("table", "kafka_events")
  .mode("append")
  .save()

println("✅ Données écrites dans HCD")
spark.stop()
EOF

# Lancer le job
$SPARK_HOME/bin/spark-shell \
  --packages org.apache.spark:spark-sql-kafka-0-10_2.12:3.5.1,com.datastax.spark:spark-cassandra-connector_2.12:3.5.0 \
  --conf spark.cassandra.connection.host=localhost \
  --conf spark.cassandra.connection.port=9042 \
  --conf spark.sql.extensions=com.datastax.spark.connector.CassandraSparkExtensions \
  -i /tmp/test_kafka_hcd_batch.scala 2>&1 | tee /tmp/spark_test_output.log

# Attendre un peu pour que l'écriture se termine
sleep 3

# 7. Vérifier les données dans HCD
info "🔍 Vérification des données dans HCD..."
cd binaire/hcd-1.2.3
jenv local 11
eval "$(jenv init -)"

echo ""
echo "=========================================="
echo "Données dans HCD (poc_hbase_migration.kafka_events):"
echo "=========================================="
./bin/cqlsh localhost 9042 -e "USE poc_hbase_migration; SELECT COUNT(*) FROM kafka_events;" 2>&1 | grep -v "Warnings" | grep -E "count|^[0-9]" || true

echo ""
echo "Aperçu des données:"
./bin/cqlsh localhost 9042 -e "USE poc_hbase_migration; SELECT topic, partition, offset, key, value FROM kafka_events LIMIT 5;" 2>&1 | grep -v "Warnings" | tail -10

cd ..

echo ""
echo "=========================================="
info "✅ Test terminé !"
echo "=========================================="

