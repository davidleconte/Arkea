// Job Spark Streaming : Kafka → HCD
// Ce script lit depuis Kafka et écrit vers HCD
// Date : 2026-03-12
// Usage : spark-shell -i kafka_to_hcd_streaming.scala

import org.apache.spark.sql.SparkSession
import org.apache.spark.sql.functions._

println("=" * 60)
println("Spark Streaming : Kafka → HCD")
println("=" * 60)

// Configuration depuis variables d'environnement (respecte .poc-config.sh)
val hcdHost = sys.env.getOrElse("HCD_HOST", "localhost")
val hcdPort = sys.env.getOrElse("HCD_PORT", "9042")
val kafkaBootstrapServers = sys.env.getOrElse("KAFKA_BOOTSTRAP_SERVERS", "localhost:9092")
val kafkaTopic = sys.env.getOrElse("KAFKA_TOPIC", "test-topic")

// Créer la session Spark avec les packages nécessaires
val spark = SparkSession.builder()
  .appName("Kafka to HCD Streaming")
  .config("spark.cassandra.connection.host", hcdHost)
  .config("spark.cassandra.connection.port", hcdPort)
  .config("spark.cassandra.connection.localDC", "datacenter1")
  .config("spark.sql.extensions", "com.datastax.spark.connector.CassandraSparkExtensions")
  .getOrCreate()

println("\n✅ Spark Session créée")
println(s"Version Spark: ${spark.version}")
println(s"HCD: $hcdHost:$hcdPort")

// Lire depuis Kafka
println("\n📖 Lecture depuis Kafka...")
val kafkaDF = spark
  .readStream
  .format("kafka")
  .option("kafka.bootstrap.servers", kafkaBootstrapServers)
  .option("subscribe", kafkaTopic)
  .option("startingOffsets", "earliest")
  .load()

println("✅ Connexion Kafka établie")

// Transformer les données
println("\n🔄 Transformation des données...")
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

// Écrire vers HCD
println("\n✍️  Écriture vers HCD...")
println("   Keyspace: poc_hbase_migration")
println("   Table: kafka_events")

// Checkpoint dans un répertoire persistant (respecte ARKEA_HOME)
val arkeaHome = sys.env.getOrElse("ARKEA_HOME", sys.props("user.home") + "/Arkea")
val checkpointLocation = s"$arkeaHome/logs/spark-checkpoints/kafka-to-hcd"

val query = transformed
  .writeStream
  .format("org.apache.spark.sql.cassandra")
  .option("keyspace", "poc_hbase_migration")
  .option("table", "kafka_events")
  .option("checkpointLocation", checkpointLocation)
  .outputMode("append")
  .start()

println("✅ Streaming query démarrée")
println(s"   Checkpoint: $checkpointLocation")
println("\n💡 Le streaming est actif. Les données de Kafka seront écrites dans HCD.")
println("   Tapez Ctrl+C pour arrêter")

// Graceful shutdown hook
sys.addShutdownHook {
  println("\n🛑 Arrêt du streaming demandé...")
  query.stop()
  println("✅ Streaming arrêté proprement")
}

// Attendre la terminaison avec timeout (24h max, permet restart)
query.awaitTermination(24 * 60 * 60 * 1000)
