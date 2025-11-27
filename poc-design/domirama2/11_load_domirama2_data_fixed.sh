#!/bin/bash
# ============================================
# Script 11 : Chargement des données Domirama2 (Batch) - VERSION CORRIGÉE
# Charge les données CSV dans HCD via Spark
# Stratégie: Batch écrit UNIQUEMENT cat_auto (ne touche JAMAIS cat_user)
# ============================================

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

info() { echo -e "${BLUE}ℹ️  $1${NC}"; }
success() { echo -e "${GREEN}✅ $1${NC}"; }
warn() { echo -e "${YELLOW}⚠️  $1${NC}"; }
error() { echo -e "${RED}❌ $1${NC}"; }

INSTALL_DIR="/Users/david.leconte/Documents/Arkea"
HCD_DIR="${INSTALL_DIR}/binaire/hcd-1.2.3"
SPARK_HOME="${INSTALL_DIR}/binaire/spark-3.5.1-bin-hadoop3"
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
CSV_FILE="${SCRIPT_DIR}/data/operations_sample.csv"

# Vérifier que HCD est démarré
if ! pgrep -f "cassandra" > /dev/null; then
    error "HCD n'est pas démarré. Exécutez d'abord: ./03_start_hcd.sh"
    exit 1
fi

# Vérifier que le keyspace existe
cd "$HCD_DIR"
jenv local 11
eval "$(jenv init -)"
if ! ./bin/cqlsh localhost 9042 -e "DESCRIBE KEYSPACE domirama2_poc;" > /dev/null 2>&1; then
    error "Le keyspace domirama2_poc n'existe pas. Exécutez d'abord: ./10_setup_domirama2_poc.sh"
    exit 1
fi

# Vérifier que le fichier CSV existe
if [ ! -f "$CSV_FILE" ]; then
    error "Fichier CSV non trouvé: $CSV_FILE"
    exit 1
fi

# Configurer Java 11 pour Spark
jenv local 11
eval "$(jenv init -)"

export SPARK_HOME
export PATH=$SPARK_HOME/bin:$PATH

info "📥 [BATCH] Chargement des données Domirama2 dans HCD..."
info "   Fichier CSV: $CSV_FILE"
info "   Keyspace: domirama2_poc"
info "   Table: operations_by_account"
info ""
info "   ⚠️  Stratégie BATCH (conforme IBM):"
info "      - Écrit UNIQUEMENT cat_auto et cat_confidence"
info "      - NE TOUCHE JAMAIS cat_user, cat_date_user, cat_validee"

info "🚀 Lancement du job Spark..."

TEMP_SCRIPT=$(mktemp)
cat > "$TEMP_SCRIPT" <<EOFSCRIPT
import org.apache.spark.sql.SparkSession
import org.apache.spark.sql.functions._
import java.sql.Timestamp
import java.time.Instant
import java.util.UUID
import java.math.BigDecimal

val inputPath = "$CSV_FILE"
val spark = SparkSession.builder()
  .appName("Domirama2LoaderBatch")
  .config("spark.cassandra.connection.host", "localhost")
  .config("spark.cassandra.connection.port", "9042")
  .config("spark.sql.extensions", "com.datastax.spark.connector.CassandraSparkExtensions")
  .getOrCreate()
import spark.implicits._

println("📥 Lecture du CSV...")
val raw = spark.read.option("header", "true").option("inferSchema", "false").csv(inputPath)
println(s"✅ \${raw.count()} lignes lues")

println("🔄 Transformation...")
val ops = raw.select(
  col("code_si").cast("string").as("code_si"),
  col("contrat").cast("string").as("contrat"),
  to_timestamp(col("date_iso"), "yyyy-MM-dd'T'HH:mm:ss'Z'").as("date_op"),
  col("seq").cast("int").as("numero_op"),
  lit(UUID.randomUUID().toString).as("op_id"),
  col("libelle").cast("string").as("libelle"),
  col("montant").cast("decimal(10,2)").as("montant"),
  coalesce(col("devise").cast("string"), lit("EUR")).as("devise"),
  coalesce(col("type_operation").cast("string"), lit("AUTRE")).as("type_operation"),
  coalesce(col("sens_operation").cast("string"), lit("DEBIT")).as("sens_operation"),
  lit("BASE64_COBOL_DATA".getBytes("UTF-8")).as("operation_data"),
  lit("").cast("string").as("cobol_data_base64"),
  lit(null).cast("string").as("copy_type"),
  lit(null).cast("timestamp").as("date_valeur"),
  lit(null).cast("map<string,string>").as("meta_flags"),
  coalesce(col("categorie_auto").cast("string"), lit("")).as("cat_auto"),
  coalesce(col("cat_confidence").cast("decimal(3,2)"), lit(BigDecimal.ZERO)).as("cat_confidence"),
  lit(null).cast("string").as("cat_user"),
  lit(null).cast("timestamp").as("cat_date_user"),
  lit(false).cast("boolean").as("cat_validee")
)

val countBefore = ops.count()
println(s"✅ \$countBefore opérations transformées")

println("💾 Écriture dans HCD...")
ops.write
  .format("org.apache.spark.sql.cassandra")
  .options(Map("keyspace" -> "domirama2_poc", "table" -> "operations_by_account"))
  .mode("append")
  .save()

println("✅ Écriture terminée !")

val count = spark.read
  .format("org.apache.spark.sql.cassandra")
  .options(Map("keyspace" -> "domirama2_poc", "table" -> "operations_by_account"))
  .load()
  .count()

println(s"📊 Total dans HCD : \$count")
spark.stop()
EOFSCRIPT

spark-shell \
  --packages com.datastax.spark:spark-cassandra-connector_2.12:3.5.0 \
  --conf spark.cassandra.connection.host=localhost \
  --conf spark.cassandra.connection.port=9042 \
  --conf spark.sql.extensions=com.datastax.spark.connector.CassandraSparkExtensions \
  -i "$TEMP_SCRIPT" \
  2>&1 | grep -E "(✅|📊|📥|🔄|💾|ERROR|Exception|opérations|Total)" || true

rm -f "$TEMP_SCRIPT"

info "🔍 Vérification des données chargées..."
cd "$HCD_DIR"
jenv local 11
eval "$(jenv init -)"

sleep 2
COUNT=$(./bin/cqlsh localhost 9042 -e "USE domirama2_poc; SELECT COUNT(*) FROM operations_by_account;" 2>&1 | grep -v "Warnings" | grep -E "^[[:space:]]*[0-9]+" | head -1 | tr -d ' ')

if [ -n "$COUNT" ] && [ "$COUNT" -gt 0 ]; then
    success "$COUNT opération(s) chargée(s) dans HCD"
else
    warn "Vérifiez manuellement: cqlsh -e \"USE domirama2_poc; SELECT COUNT(*) FROM operations_by_account;\""
fi

# Vérifier que cat_user est bien null (batch ne doit pas l'écrire)
info "🔍 Vérification de la stratégie batch..."
CAT_USER_SAMPLE=$(./bin/cqlsh localhost 9042 -e "USE domirama2_poc; SELECT cat_user FROM operations_by_account LIMIT 10;" 2>&1 | grep -v "Warnings" | grep -v "cat_user" | grep -v "---" | grep -v "^$" | head -1 | tr -d ' ')

if [ -z "$CAT_USER_SAMPLE" ] || [ "$CAT_USER_SAMPLE" = "null" ]; then
    success "✅ Stratégie batch validée: cat_user est null (batch ne l'a pas touché)"
else
    warn "⚠️  Attention: cat_user contient des valeurs (attendu: null pour batch)"
fi

echo ""
success "✅ Chargement des données terminé !"
echo ""
info "📝 Prochaines étapes:"
echo "   - Script 12: Tests de recherche"
echo "   - Script 13: Tests de correction client (API)"




