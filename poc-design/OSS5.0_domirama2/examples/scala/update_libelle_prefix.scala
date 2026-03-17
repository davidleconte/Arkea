import org.apache.spark.sql.SparkSession
import org.apache.spark.sql.functions._

val spark = SparkSession.builder()
  .appName("UpdateLibellePrefix")
  .config("spark.cassandra.connection.host", "localhost")
  .config("spark.cassandra.connection.port", "9042")
  .config("spark.sql.extensions", "com.datastax.spark.connector.CassandraSparkExtensions")
  .getOrCreate()
import spark.implicits._

println("📥 Lecture des données depuis HCD...")
val df = spark.read
  .format("org.apache.spark.sql.cassandra")
  .options(Map("keyspace" -> "domirama2_poc", "table" -> "operations_by_account"))
  .load()

println(s"✅ ${df.count()} lignes lues")

println("🔄 Mise à jour de libelle_prefix...")
val updated = df.withColumn("libelle_prefix", col("libelle"))

println("💾 Écriture des données mises à jour...")
// Utiliser saveMode "overwrite" pour mettre à jour les lignes existantes
// Note: Spark Cassandra Connector met à jour uniquement les lignes avec la même clé primaire
updated.write
  .format("org.apache.spark.sql.cassandra")
  .options(Map("keyspace" -> "domirama2_poc", "table" -> "operations_by_account"))
  .mode("append")
  .save()

println("✅ Mise à jour terminée !")
spark.stop()
