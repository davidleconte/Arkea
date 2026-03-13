// Job Spark Streaming : Kafka → HCD (Simple RDD approach)
// Ce script lit depuis Kafka et écrit vers HCD via RDD API
// Date : 2026-03-12
// Usage : spark-shell -i kafka_to_hcd_simple.scala

import org.apache.spark.sql.SparkSession
import org.apache.spark.sql.functions._
import com.datastax.spark.connector._
import org.apache.spark.sql.cassandra._

println("=" * 60)
println("Spark Streaming : Kafka → HCD (RDD Mode)")
println("=" * 60)

// Configuration depuis variables d'environnement
val hcdHost = sys.env.getOrElse("HCD_HOST", "localhost")
val hcdPort = sys.env.getOrElse("HCD_PORT", "9042")
val kafkaBootstrapServers = sys.env.getOrElse("KAFKA_BOOTSTRAP_SERVERS", "localhost:9092")
val kafkaTopic = sys.env.getOrElse("KAFKA_TOPIC", "test-topic")

// Créer la session Spark
val spark = SparkSession.builder()
  .appName("Kafka to HCD Simple")
  .config("spark.cassandra.connection.host", hcdHost)
  .config("spark.cassandra.connection.port", hcdPort)
  .config("spark.cassandra.connection.localDC", "datacenter1")
  .config("spark.sql.extensions", "com.datastax.spark.connector.CassandraSparkExtensions")
  .getOrCreate()

import spark.implicits._

println("\n✅ Spark Session créée")
println(s"Version Spark: ${spark.version}")
println(s"HCD: $hcdHost:$hcdPort")

// Lire depuis Kafka en batch mode (pas streaming pour ce test)
println("\n📖 Lecture depuis Kafka...")
val kafkaDF = spark
  .read
  .format("kafka")
  .option("kafka.bootstrap.servers", kafkaBootstrapServers)
  .option("subscribe", kafkaTopic)
  .option("startingOffsets", "earliest")
  .option("endingOffsets", "latest")
  .load()

val count = kafkaDF.count()
println(s"✅ $count messages lus depuis Kafka")

if (count > 0) {
  // Transformer les données
  println("\n🔄 Transformation des données...")
  val events = kafkaDF
    .select(
      expr("uuid()").as("id"),
      col("timestamp").as("timestamp"),
      col("topic"),
      col("partition"),
      col("offset"),
      col("key").cast("string").as("key"),
      col("value").cast("string").as("value"),
      current_timestamp().as("processed_at")
    )

  // Afficher les données
  println("\n📊 Données à écrire:")
  events.show(5, truncate = false)

  // Écrire vers HCD via RDD API (bypass schema metadata)
  println("\n✍️  Écriture vers HCD...")
  val eventRDD = events.rdd.map { row =>
    (row.getAs[java.util.UUID]("id"),
     new java.util.Date(row.getAs[java.lang.Long]("timestamp")),
     row.getAs[String]("topic"),
     row.getAs[Int]("partition"),
     row.getAs[Long]("offset"),
     row.getAs[String]("key"),
     row.getAs[String]("value"),
     new java.util.Date())
  }

  eventRDD.saveToCassandra("poc_hbase_migration", "kafka_events",
    SomeColumns("id", "timestamp", "topic", "partition", "offset", "key", "value", "processed_at"))

  println("✅ Données écrites dans HCD!")

  // Vérifier les données
  println("\n🔍 Vérification des données dans HCD...")
  val readBack = spark.read
    .format("org.apache.spark.sql.cassandra")
    .options(Map("keyspace" -> "poc_hbase_migration", "table" -> "kafka_events"))
    .load()

  println(s"Total enregistrements dans kafka_events: ${readBack.count()}")
  readBack.show(5, truncate = false)
} else {
  println("⚠️ Aucun message à traiter")
}

println("\n✅ Test terminé avec succès!")

// Arrêter Spark
spark.stop()
