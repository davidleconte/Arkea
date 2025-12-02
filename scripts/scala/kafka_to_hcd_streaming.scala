// Job Spark Streaming : Kafka → HCD
// Ce script lit depuis Kafka et écrit vers HCD

import org.apache.spark.sql.SparkSession
import org.apache.spark.sql.functions._

println("=" * 60)
println("Spark Streaming : Kafka → HCD")
println("=" * 60)

// Créer la session Spark avec les packages nécessaires
val spark = SparkSession.builder()
  .appName("Kafka to HCD Streaming")
  .config("spark.cassandra.connection.host", "localhost")
  .config("spark.cassandra.connection.port", "9042")
  .config("spark.sql.extensions", "com.datastax.spark.connector.CassandraSparkExtensions")
  .getOrCreate()

println("\n✅ Spark Session créée")
println(s"Version Spark: ${spark.version}")

// Configuration Kafka
// Utiliser la variable d'environnement ou localhost par défaut
val kafkaBootstrapServers = sys.env.getOrElse("KAFKA_BOOTSTRAP_SERVERS", "localhost:9092")
val kafkaTopic = "test-topic"

println(s"\n📥 Configuration Kafka:")
println(s"   Bootstrap servers: $kafkaBootstrapServers")
println(s"   Topic: $kafkaTopic")

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

val checkpointLocation = "/tmp/spark-checkpoints/kafka-to-hcd"

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

// Attendre la terminaison
query.awaitTermination()





