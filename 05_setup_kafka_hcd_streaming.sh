#!/bin/bash

# Script de configuration pour Kafka → HCD Streaming

set -e

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

echo "=========================================="
echo "Configuration Kafka → HCD Streaming"
echo "=========================================="
echo ""

# 1. Créer le répertoire de checkpoint
info "📁 Création du répertoire de checkpoint..."
mkdir -p /tmp/spark-checkpoints/kafka-to-hcd
info "✅ Répertoire créé: /tmp/spark-checkpoints/kafka-to-hcd"

# 2. Créer le keyspace et la table dans HCD
info "📊 Création du schéma HCD..."

cd /Users/david.leconte/Documents/Arkea/binaire/hcd-1.2.3
jenv local 11
eval "$(jenv init -)"

# Créer le keyspace et la table via fichier CQL
if [ -f "../create_kafka_schema.cql" ]; then
    ./bin/cqlsh localhost 9042 -f ../create_kafka_schema.cql 2>&1 | grep -v "Warnings" || true
    info "✅ Keyspace poc_hbase_migration et table kafka_events créés"
else
    warn "⚠️  Fichier create_kafka_schema.cql non trouvé, création manuelle..."
    ./bin/cqlsh localhost 9042 <<EOF 2>&1 | grep -v "Warnings" || true
CREATE KEYSPACE IF NOT EXISTS poc_hbase_migration WITH REPLICATION = {'class': 'SimpleStrategy', 'replication_factor': 1};
USE poc_hbase_migration;
CREATE TABLE IF NOT EXISTS kafka_events (id UUID PRIMARY KEY, timestamp timestamp, topic text, partition int, offset bigint, key text, value text, processed_at timestamp);
EOF
    info "✅ Keyspace poc_hbase_migration et table kafka_events créés"
fi

# 3. Vérifier que Kafka est démarré
info "🔍 Vérification de Kafka..."
if lsof -Pi :9092 -sTCP:LISTEN -t >/dev/null 2>&1 ; then
    info "✅ Kafka est démarré (port 9092)"
else
    warn "⚠️  Kafka n'est pas démarré. Démarrez avec: ./start_kafka.sh"
fi

# 4. Vérifier que HCD est démarré
info "🔍 Vérification de HCD..."
if lsof -Pi :9042 -sTCP:LISTEN -t >/dev/null 2>&1 ; then
    info "✅ HCD est démarré (port 9042)"
else
    warn "⚠️  HCD n'est pas démarré. Démarrez avec: ./start_hcd.sh"
fi

echo ""
echo "=========================================="
info "✅ Configuration terminée !"
echo "=========================================="
echo ""
echo "Prochaines étapes :"
echo ""
echo "1. Produire des messages dans Kafka :"
echo "   ./kafka-helper.sh kafka-console-producer.sh \\"
echo "     --bootstrap-server localhost:9092 \\"
echo "     --topic test-topic"
echo ""
echo "2. Lancer le job Spark Streaming :"
echo "   cd /Users/david.leconte/Documents/Arkea"
echo "   export SPARK_HOME=\$(pwd)/binaire/spark-3.5.1"
echo "   export PATH=\$SPARK_HOME/bin:\$PATH"
echo "   jenv local 11"
echo "   eval \"\$(jenv init -)\""
echo "   \$SPARK_HOME/bin/spark-shell \\"
echo "     --packages org.apache.spark:spark-sql-kafka-0-10_2.12:3.5.1,com.datastax.spark:spark-cassandra-connector_2.12:3.5.0 \\"
echo "     --conf spark.cassandra.connection.host=localhost \\"
echo "     --conf spark.cassandra.connection.port=9042 \\"
echo "     --conf spark.sql.extensions=com.datastax.spark.connector.CassandraSparkExtensions \\"
echo "     -i kafka_to_hcd_streaming.scala"
echo ""
echo "3. Vérifier les données dans HCD :"
echo "   cd binaire/hcd-1.2.3"
echo "   ./bin/cqlsh localhost 9042"
echo "   USE poc_hbase_migration;"
echo "   SELECT * FROM kafka_events;"

