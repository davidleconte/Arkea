// ============================================
// POC Domirama - Loader CSV → Spark → HCD
// Remplace: PIG → MapReduce → HBase
// ============================================

import org.apache.spark.sql.{SparkSession, Dataset}
import org.apache.spark.sql.functions._
import java.sql.Timestamp
import java.time.Instant
import java.util.UUID
import java.math.BigDecimal

case class Operation(
    code_si: String,        // Partition key
    contrat: String,        // Partition key
    op_date: Timestamp,     // Clustering key
    op_seq: Int,            // Clustering key
    op_id: String,          // UUID stocké comme String
    libelle: String,
    montant: BigDecimal,
    devise: String,
    type_operation: String,
    sens_operation: String,
    cat_auto: String,       // Optionnel
    cat_user: String        // Optionnel
)

object DomiramaLoaderCsv {
  
  def main(args: Array[String]): Unit = {
    val defaultPath = if (new java.io.File("data/operations_sample.csv").exists()) {
      "data/operations_sample.csv"
    } else {
      "poc-design/domirama/data/operations_sample.csv"
    }
    val inputPath = if (args.nonEmpty) args(0) else defaultPath
    val cassandraHost = sys.env.getOrElse("CASSANDRA_HOST", "127.0.0.1")

    val spark = SparkSession.builder()
      .appName("DomiramaLoaderCsv")
      .master("local[*]")
      .config("spark.cassandra.connection.host", cassandraHost)
      .config("spark.cassandra.connection.port", "9042")
      .config("spark.sql.extensions", "com.datastax.spark.connector.CassandraSparkExtensions")
      .getOrCreate()

    import spark.implicits._

    println("📥 Lecture du fichier CSV...")
    val raw = spark.read
      .option("header", "true")
      .option("inferSchema", "false")
      .csv(inputPath)

    println("🔄 Transformation des données...")
    val ops: Dataset[Operation] = raw.map { row =>
      val codeSi  = row.getAs[String]("code_si")
      val contrat = row.getAs[String]("contrat")
      val dateIso = row.getAs[String]("date_iso")
      val seq     = row.getAs[String]("seq").toInt
      val libelle = row.getAs[String]("libelle")
      val montant = new BigDecimal(row.getAs[String]("montant"))
      val devise  = row.getAs[String]("devise")
      val typeOp  = Option(row.getAs[String]("type_operation")).getOrElse("AUTRE")
      val sensOp  = Option(row.getAs[String]("sens_operation")).getOrElse("DEBIT")
      val catAuto = Option(row.getAs[String]("categorie_auto")).getOrElse("")
      val catUser = Option(row.getAs[String]("categorie_client")).getOrElse("")

      val ts = Timestamp.from(Instant.parse(dateIso))
      val opId = UUID.randomUUID().toString

      Operation(
        code_si        = codeSi,
        contrat        = contrat,
        op_date        = ts,
        op_seq         = seq,
        op_id          = opId,
        libelle        = libelle,
        montant        = montant,
        devise         = devise,
        type_operation = typeOp,
        sens_operation = sensOp,
        cat_auto       = catAuto,
        cat_user       = catUser
      )
    }

    println(s"✅ ${ops.count()} opérations transformées")

    println("💾 Écriture dans HCD...")
    ops.write
      .format("org.apache.spark.sql.cassandra")
      .options(Map(
        "keyspace" -> "domirama_poc",
        "table"    -> "operations_by_account"
      ))
      .mode("append")
      .save()

    println("✅ Écriture terminée avec succès !")

    // Vérification
    val count = spark.read
      .format("org.apache.spark.sql.cassandra")
      .options(Map(
        "keyspace" -> "domirama_poc",
        "table"    -> "operations_by_account"
      ))
      .load()
      .count()

    println(s"📊 Total d'opérations dans HCD : $count")

    spark.stop()
  }
}

