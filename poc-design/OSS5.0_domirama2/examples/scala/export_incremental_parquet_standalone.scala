// ============================================
// Export Incrémental Parquet depuis HCD (Standalone)
// ============================================
//
// Usage avec spark-submit :
//   spark-submit --jars $SPARK_CASSANDRA_CONNECTOR_JAR \
//     --class ExportIncrementalParquet \
//     export_incremental_parquet_standalone.scala \
//     <start_date> <end_date> <output_path> [compression]
//
// Exemple :
//   spark-submit --jars spark-cassandra-connector.jar \
//     export_incremental_parquet_standalone.scala \
//     2024-01-01 2024-02-01 /tmp/exports/domirama/incremental/2024-01 snappy
//
// ============================================

import org.apache.spark.sql.SparkSession
import org.apache.spark.sql.functions._
import org.apache.spark.sql.functions.lit

object ExportIncrementalParquet {
  def main(args: Array[String]): Unit = {
    // Paramètres
    val startDate = if (args.length > 0) args(0) else "2024-01-01"
    val endDate = if (args.length > 1) args(1) else "2024-02-01"
    val outputPath = if (args.length > 2) args(2) else "/tmp/exports/domirama/incremental/2024-01"
    val compression = if (args.length > 3) args(3) else "snappy"

    // Configuration Spark
    val spark = SparkSession.builder()
      .appName("Export Incremental Parquet from HCD")
      .config("spark.cassandra.connection.host", "localhost")
      .config("spark.cassandra.connection.port", "9042")
      .config("spark.sql.extensions", "com.datastax.spark.connector.CassandraSparkExtensions")
      .getOrCreate()

    import spark.implicits._

    println("=" * 80)
    println(s"📥 Export Incrémental Parquet : $startDate → $endDate")
    println("=" * 80)

    // 1. Lecture depuis HCD avec fenêtre glissante (équivalent TIMERANGE HBase)
    println("\n🔍 Lecture depuis HCD (keyspace: domirama2_poc, table: operations_by_account)...")
    println(s"   WHERE date_op >= '$startDate' AND date_op < '$endDate'")

    val df = spark.read
      .format("org.apache.spark.sql.cassandra")
      .options(Map(
        "table" -> "operations_by_account",
        "keyspace" -> "domirama2_poc"
      ))
      .load()
      .filter(
        col("date_op") >= startDate &&
        col("date_op") < endDate
      )

    val count = df.count()
    println(s"✅ $count opérations trouvées dans la fenêtre")

    if (count == 0) {
      println("⚠️  Aucune donnée à exporter")
      spark.stop()
      System.exit(0)
    }

    // 2. Afficher quelques statistiques
    println("\n📊 Statistiques de l'export :")
    df.select(
      min("date_op").as("date_min"),
      max("date_op").as("date_max"),
      count(lit(1)).as("total"),
      countDistinct("code_si", "contrat").as("comptes_uniques")
    ).show()

    // 3. Export Parquet vers HDFS (partitionné par date_op)
    println(s"\n💾 Export Parquet vers : $outputPath")
    println(s"   Compression : $compression")
    println(s"   Partitionnement : par date_op")

    df.write
      .mode("overwrite")
      .partitionBy("date_op")
      .option("compression", compression)
      .option("parquet.block.size", "134217728")  // 128MB
      .parquet(outputPath)

    println(s"✅ Export Parquet terminé : $count opérations")
    println(s"   Fichiers créés dans : $outputPath")

    // 4. Vérification : lire le Parquet exporté
    println("\n🔍 Vérification : lecture du Parquet exporté...")
    try {
      val dfRead = spark.read.parquet(outputPath)
      val countRead = dfRead.count()
      println(s"✅ Vérification OK : $countRead opérations lues depuis Parquet")

      if (count != countRead) {
        println(s"⚠️  ATTENTION : Incohérence ($count exportées vs $countRead lues)")
      }
    } catch {
      case e: Exception => println(s"⚠️  Impossible de vérifier l'export : ${e.getMessage}")
    }

    println("\n" + "=" * 80)
    println("✅ Export Incrémental Parquet - Terminé")
    println("=" * 80)

    spark.stop()
  }
}
