#!/bin/bash
# ============================================
# Script 08 : Chargement des données Domirama
# Charge les données CSV dans HCD via Spark
# ============================================

set -e

# Couleurs pour les messages
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

info() {
    echo -e "${BLUE}ℹ️  $1${NC}"
}

success() {
    echo -e "${GREEN}✅ $1${NC}"
}

warn() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

error() {
    echo -e "${RED}❌ $1${NC}"
}

# Variables
INSTALL_DIR="/Users/david.leconte/Documents/Arkea"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SPARK_HOME="${INSTALL_DIR}/binaire/spark-3.5.1"
CSV_FILE="${SCRIPT_DIR}/data/operations_sample.csv"
SCALA_FILE="${SCRIPT_DIR}/domirama_loader_csv.scala"

# Charger l'environnement POC
if [ -f "${INSTALL_DIR}/.poc-profile" ]; then
    source "${INSTALL_DIR}/.poc-profile"
fi

# Vérifier que Spark est installé
if [ ! -d "$SPARK_HOME" ]; then
    error "Spark non installé. Exécutez d'abord: ./02_install_spark_kafka.sh"
    exit 1
fi

# Vérifier que HCD est démarré
if ! pgrep -f "cassandra" > /dev/null; then
    error "HCD n'est pas démarré. Exécutez d'abord: ./03_start_hcd.sh"
    exit 1
fi

# Vérifier que le fichier CSV existe
if [ ! -f "$CSV_FILE" ]; then
    error "Fichier CSV non trouvé: $CSV_FILE"
    exit 1
fi

# Vérifier que le fichier Scala existe
if [ ! -f "$SCALA_FILE" ]; then
    error "Fichier Scala non trouvé: $SCALA_FILE"
    exit 1
fi

# Configurer Java 11 pour Spark
jenv local 11
eval "$(jenv init -)"

export SPARK_HOME
export PATH=$SPARK_HOME/bin:$PATH

info "📥 Chargement des données Domirama dans HCD..."
info "   Fichier CSV: $CSV_FILE"
info "   Keyspace: domirama_poc"
info "   Table: operations_by_account"

# Compiler le code Scala (si nécessaire)
# Pour l'instant, on utilise spark-shell avec le code inline
# ou on peut créer un JAR avec sbt

info "🚀 Lancement du job Spark..."

# Créer un script temporaire qui exécute le code avec les arguments
TEMP_SCRIPT=$(mktemp)
cat > "$TEMP_SCRIPT" <<EOF
import org.apache.spark.sql.SparkSession
import java.sql.Timestamp
import java.time.Instant
import java.util.UUID
import java.math.BigDecimal

case class Operation(
    code_si: String,
    contrat: String,
    op_date: Timestamp,
    op_seq: Int,
    op_id: String,
    libelle: String,
    montant: BigDecimal,
    devise: String,
    type_operation: String,
    sens_operation: String,
    cat_auto: String,
    cat_user: String
)

val inputPath = "$CSV_FILE"
val spark = SparkSession.builder()
  .appName("DomiramaLoaderCsv")
  .config("spark.cassandra.connection.host", "localhost")
  .config("spark.cassandra.connection.port", "9042")
  .config("spark.sql.extensions", "com.datastax.spark.connector.CassandraSparkExtensions")
  .getOrCreate()
import spark.implicits._

val raw = spark.read.option("header", "true").option("inferSchema", "false").csv(inputPath)

val ops = raw.map { row =>
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

  Operation(codeSi, contrat, ts, seq, opId, libelle, montant, devise, typeOp, sensOp, catAuto, catUser)
}

val countBefore = ops.count()
println(s"✅ \$countBefore opérations transformées")

ops.write
  .format("org.apache.spark.sql.cassandra")
  .options(Map("keyspace" -> "domirama_poc", "table" -> "operations_by_account"))
  .mode("append")
  .save()

println("✅ Écriture terminée avec succès !")

val count = spark.read
  .format("org.apache.spark.sql.cassandra")
  .options(Map("keyspace" -> "domirama_poc", "table" -> "operations_by_account"))
  .load()
  .count()

println(s"📊 Total d'opérations dans HCD : \$count")
spark.stop()
EOF

# Exécuter avec spark-shell
CSV_PATH="$CSV_FILE" CASSANDRA_HOST="localhost" spark-shell \
  --packages com.datastax.spark:spark-cassandra-connector_2.12:3.5.0 \
  --conf spark.cassandra.connection.host=localhost \
  --conf spark.cassandra.connection.port=9042 \
  --conf spark.sql.extensions=com.datastax.spark.connector.CassandraSparkExtensions \
  -i "$TEMP_SCRIPT" \
  2>&1 | grep -E "(📥|🔄|✅|💾|📊|ERROR|Exception|opérations)" || true

rm -f "$TEMP_SCRIPT"

# Vérification
info "🔍 Vérification des données chargées..."
cd "${INSTALL_DIR}/binaire/hcd-1.2.3"
jenv local 11
eval "$(jenv init -)"

sleep 2  # Attendre que les écritures soient complètes

COUNT_OUTPUT=$(./bin/cqlsh localhost 9042 -e "USE domirama_poc; SELECT COUNT(*) as count FROM operations_by_account;" 2>&1 | grep -v "Warnings" | grep -E "^[[:space:]]*[0-9]+" | head -1 | tr -d ' ')

if [ -n "$COUNT_OUTPUT" ] && [ "$COUNT_OUTPUT" -gt 0 ] 2>/dev/null; then
    success "$COUNT_OUTPUT opération(s) chargée(s) dans HCD"
else
    # Essayer une autre méthode de parsing
    COUNT=$(./bin/cqlsh localhost 9042 -e "USE domirama_poc; SELECT COUNT(*) FROM operations_by_account;" 2>&1 | grep -E "^[[:space:]]*[0-9]+" | head -1 | awk '{print $1}' | tr -d ' ')
    if [ -n "$COUNT" ] && [ "$COUNT" -gt 0 ] 2>/dev/null; then
        success "$COUNT opération(s) chargée(s) dans HCD"
    else
        warn "Vérifiez manuellement: cqlsh -e \"USE domirama_poc; SELECT COUNT(*) FROM operations_by_account;\""
    fi
fi

echo ""
success "✅ Chargement des données terminé !"

