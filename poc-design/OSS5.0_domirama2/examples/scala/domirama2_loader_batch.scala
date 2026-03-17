// ============================================
// POC Domirama2 - Loader Batch (conforme IBM)
// Remplace: PIG → MapReduce → HBase
// Stratégie: Batch écrit UNIQUEMENT cat_auto (ne touche JAMAIS cat_user)
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
    date_op: Timestamp,     // Clustering key (aligné IBM)
    numero_op: Int,         // Clustering key (aligné IBM)
    op_id: String,          // UUID stocké comme String
    libelle: String,
    montant: BigDecimal,
    devise: String,
    type_operation: String,
    sens_operation: String,
    operation_data: Array[Byte],  // BLOB pour données COBOL
    cat_auto: String,       // Catégorie automatique (batch écrit ici)
    cat_confidence: BigDecimal, // Score du moteur
    cat_user: String,       // Catégorie client (batch NE TOUCHE JAMAIS)
    cat_date_user: Timestamp, // Date modification client (batch NE TOUCHE JAMAIS)
    cat_validee: Boolean    // Acceptation client (batch NE TOUCHE JAMAIS)
)

object Domirama2LoaderBatch {

  def main(args: Array[String]): Unit = {
    val defaultPath = if (new java.io.File("data/operations_sample.csv").exists()) {
      "data/operations_sample.csv"
    } else {
      "poc-design/domirama2/data/operations_sample.csv"
    }
    val inputPath = if (args.nonEmpty) args(0) else defaultPath
    val cassandraHost = sys.env.getOrElse("CASSANDRA_HOST", "127.0.0.1")

    val spark = SparkSession.builder()
      .appName("Domirama2LoaderBatch")
      .master("local[*]")
      .config("spark.cassandra.connection.host", cassandraHost)
      .config("spark.cassandra.connection.port", "9042")
      .config("spark.sql.extensions", "com.datastax.spark.connector.CassandraSparkExtensions")
      .getOrCreate()

    import spark.implicits._

    println("📥 [BATCH] Lecture du fichier CSV...")
    val raw = spark.read
      .option("header", "true")
      .option("inferSchema", "false")
      .csv(inputPath)

    println("🔄 [BATCH] Transformation des données...")
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
      val catConf = Option(row.getAs[String]("cat_confidence"))
        .map(s => new BigDecimal(s))
        .getOrElse(BigDecimal.ZERO)

      val ts = Timestamp.from(Instant.parse(dateIso))
      val opId = UUID.randomUUID().toString

      // Simulation données COBOL (en production: décodage via OperationDecoder)
      val cobolDataBase64 = s"BASE64_ENCODED_COBOL_DATA_${opId}"
      val operationData = cobolDataBase64.getBytes("UTF-8") // En production: vrai décodage

      // ============================================
      // STRATÉGIE BATCH (conforme IBM):
      // - Écrit UNIQUEMENT cat_auto
      // - Écrit cat_confidence
      // - NE TOUCHE JAMAIS cat_user, cat_date_user, cat_validée
      // ============================================
      Operation(
        code_si        = codeSi,
        contrat        = contrat,
        date_op        = ts,
        numero_op      = seq,
        op_id          = opId,
        libelle        = libelle,
        montant        = montant,
        devise         = devise,
        type_operation = typeOp,
        sens_operation = sensOp,
        operation_data = operationData,
        cat_auto       = catAuto,        // ✅ Batch écrit ici
        cat_confidence = catConf,        // ✅ Batch écrit ici
        cat_user       = null,           // ❌ Batch NE TOUCHE JAMAIS
        cat_date_user  = null,          // ❌ Batch NE TOUCHE JAMAIS
        cat_validee    = false           // ❌ Batch NE TOUCHE JAMAIS (défaut)
      )
    }

    println(s"✅ [BATCH] ${ops.count()} opérations transformées")

    println("💾 [BATCH] Écriture dans HCD...")
    println("   ⚠️  Stratégie: Batch écrit UNIQUEMENT cat_auto et cat_confidence")
    println("   ⚠️  Batch NE TOUCHE JAMAIS cat_user, cat_date_user, cat_validée")

    ops.write
      .format("org.apache.spark.sql.cassandra")
      .options(Map(
        "keyspace" -> "domirama2_poc",
        "table"    -> "operations_by_account"
      ))
      .mode("append")
      .save()

    println("✅ [BATCH] Écriture terminée avec succès !")

    // Vérification
    val count = spark.read
      .format("org.apache.spark.sql.cassandra")
      .options(Map(
        "keyspace" -> "domirama2_poc",
        "table"    -> "operations_by_account"
      ))
      .load()
      .count()

    println(s"📊 [BATCH] Total d'opérations dans HCD : $count")

    spark.stop()
  }
}
