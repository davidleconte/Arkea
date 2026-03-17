// ============================================
// Export Incrémental Parquet depuis HCD
// ============================================
//
// Objectif : Démontrer l'export incrémental depuis HCD vers HDFS (format Parquet)
// Équivalent HBase : FullScan + STARTROW + STOPROW + TIMERANGE
//
// Usage :
//   spark-shell --jars $SPARK_CASSANDRA_CONNECTOR_JAR < export_incremental_parquet.scala
//   OU
//   spark-submit --class ExportIncrementalParquet export_incremental_parquet.scala
//
// ============================================

import org.apache.spark.sql.SparkSession
import org.apache.spark.sql.functions._
import java.time.LocalDate
import java.time.format.DateTimeFormatter

// ============================================
// Configuration
// ============================================

val spark = SparkSession.builder()
  .appName("Export Incremental Parquet from HCD")
  .config("spark.cassandra.connection.host", "localhost")
  .config("spark.cassandra.connection.port", "9042")
  .config("spark.sql.extensions", "com.datastax.spark.connector.CassandraSparkExtensions")
  .getOrCreate()

import spark.implicits._

// ============================================
// Fonction : Export Incrémental Parquet
// ============================================
//
// Équivalent HBase :
//   - FullScan + STARTROW + STOPROW + TIMERANGE
//   - Unload incrémental vers HDFS au format ORC
//
// Cette fonction :
//   1. Lit depuis HCD avec WHERE date_op BETWEEN start AND end
//   2. Exporte vers HDFS au format Parquet (partitionné par date)
//   3. Gère la fenêtre glissante pour exports incrémentaux
//
def exportIncrementalParquet(
  startDate: String,      // Format: "2024-01-01"
  endDate: String,        // Format: "2024-02-01" (exclusif)
  outputPath: String,    // HDFS path: "hdfs://.../exports/domirama/incremental/2024-01"
  compression: String = "snappy"  // snappy (rapide) ou gzip (compact)
): Unit = {

  println("=" * 80)
  println(s"📥 Export Incrémental Parquet : $startDate → $endDate")
  println("=" * 80)

  // 1. Lecture depuis HCD avec fenêtre glissante (équivalent TIMERANGE HBase)
  println(s"\n🔍 Lecture depuis HCD (keyspace: domirama2_poc, table: operations_by_account)...")
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
  println(s"✅ ${count} opérations trouvées dans la fenêtre")

  if (count == 0) {
    println("⚠️  Aucune donnée à exporter")
    return
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
    .mode("overwrite")  // Mode overwrite pour idempotence (peut être changé en "append")
    .partitionBy("date_op")  // Partitionnement par date (équivalent STARTROW/STOPROW)
    .option("compression", compression)
    .option("parquet.block.size", "134217728")  // 128MB (optimisation)
    .parquet(outputPath)

  println(s"✅ Export Parquet terminé : $count opérations")
  println(s"   Fichiers créés dans : $outputPath")

  // 4. Vérification : lire le Parquet exporté
  println("\n🔍 Vérification : lecture du Parquet exporté...")
  val dfRead = spark.read.parquet(outputPath)
  val countRead = dfRead.count()
  println(s"✅ Vérification OK : $countRead opérations lues depuis Parquet")

  if (count != countRead) {
    println(s"⚠️  ATTENTION : Incohérence ($count exportées vs $countRead lues)")
  }
}

// ============================================
// Fonction : Export avec STARTROW/STOPROW équivalent
// ============================================
//
// Équivalent HBase :
//   - STARTROW + STOPROW pour cibler précisément les données
//
// Cette fonction permet de cibler précisément une plage avec :
//   - Partition key (code_si, contrat)
//   - Clustering keys (date_op, numero_op)
//
def exportWithStartStopRow(
  codeSi: String,
  contrat: String,
  startDate: String,
  startNumeroOp: Int,
  endDate: String,
  endNumeroOp: Int,
  outputPath: String
): Unit = {

  println("=" * 80)
  println(s"📥 Export avec STARTROW/STOPROW équivalent")
  println(s"   Partition: ($codeSi, $contrat)")
  println(s"   Clustering: ($startDate, $startNumeroOp) → ($endDate, $endNumeroOp)")
  println("=" * 80)

  val df = spark.read
    .format("org.apache.spark.sql.cassandra")
    .options(Map(
      "table" -> "operations_by_account",
      "keyspace" -> "domirama2_poc"
    ))
    .load()
    .filter(
      col("code_si") === codeSi &&
      col("contrat") === contrat &&
      (
        (col("date_op") > startDate) ||
        (col("date_op") === startDate && col("numero_op") >= startNumeroOp)
      ) &&
      (
        (col("date_op") < endDate) ||
        (col("date_op") === endDate && col("numero_op") <= endNumeroOp)
      )
    )

  val count = df.count()
  println(s"✅ ${count} opérations trouvées")

  if (count > 0) {
    df.write
      .mode("overwrite")
      .partitionBy("date_op")
      .option("compression", "snappy")
      .parquet(outputPath)

    println(s"✅ Export terminé : $count opérations")
  }
}

// ============================================
// Exemples d'utilisation
// ============================================

println("\n" + "=" * 80)
println("📋 Export Incrémental Parquet - Exemples")
println("=" * 80)

// Exemple 1 : Export mensuel (fenêtre glissante)
println("\n📅 Exemple 1 : Export mensuel (Janvier 2024)")
exportIncrementalParquet(
  startDate = "2024-01-01",
  endDate = "2024-02-01",
  outputPath = "/tmp/exports/domirama/incremental/2024-01",
  compression = "snappy"
)

// Exemple 2 : Export avec compression Gzip (plus compact)
println("\n📅 Exemple 2 : Export avec compression Gzip (plus compact)")
exportIncrementalParquet(
  startDate = "2024-01-01",
  endDate = "2024-02-01",
  outputPath = "/tmp/exports/domirama/incremental/2024-01-gzip",
  compression = "gzip"
)

// Exemple 3 : Export avec STARTROW/STOPROW équivalent
println("\n📅 Exemple 3 : Export avec STARTROW/STOPROW équivalent")
// Note: Nécessite des données réelles dans HCD
// exportWithStartStopRow(
//   codeSi = "DEMO_MV",
//   contrat = "DEMO_001",
//   startDate = "2024-01-15",
//   startNumeroOp = 1,
//   endDate = "2024-01-20",
//   endNumeroOp = 100,
//   outputPath = "/tmp/exports/domirama/startstop/2024-01-15"
// )

println("\n" + "=" * 80)
println("✅ Export Incrémental Parquet - Terminé")
println("=" * 80)

spark.stop()
