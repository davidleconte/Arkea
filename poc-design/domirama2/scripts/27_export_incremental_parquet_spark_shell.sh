#!/bin/bash
# ============================================
# Script 27 (Alternative) : Export Incrémental Parquet avec spark-shell
# ============================================
#
# OBJECTIF :
#   Ce script est une version alternative du script 27 utilisant spark-shell
#   au lieu de spark-submit. Il démontre l'export incrémental de données depuis
#   HCD vers des fichiers Parquet, équivalent aux exports HBase avec FullScan,
#   STARTROW, STOPROW et TIMERANGE.
#   
#   NOTE : La version spark-submit (27_export_incremental_parquet.sh) est
#   recommandée pour la production. Cette version spark-shell est utile pour
#   le développement et le débogage.
#
# PRÉREQUIS :
#   - HCD démarré (./scripts/setup/03_start_hcd.sh)
#   - Schéma configuré (./10_setup_domirama2_poc.sh)
#   - Données chargées (./11_load_domirama2_data_parquet.sh)
#   - Spark 3.5.1 installé et configuré
#   - Spark Cassandra Connector 3.5.0 disponible
#   - Java 11 configuré via jenv
#   - Scala script présent: examples/scala/export_incremental_parquet.scala
#
# UTILISATION :
#   ./27_export_incremental_parquet_spark_shell.sh [start_date] [end_date] [output_path]
#
# PARAMÈTRES :
#   $1 : Date de début (format: YYYY-MM-DD, optionnel, défaut: 2024-01-01)
#   $2 : Date de fin (format: YYYY-MM-DD, optionnel, défaut: 2024-02-01)
#   $3 : Chemin de sortie (optionnel, défaut: /tmp/exports/domirama/incremental)
#
# EXEMPLE :
#   ./27_export_incremental_parquet_spark_shell.sh
#   ./27_export_incremental_parquet_spark_shell.sh "2024-01-01" "2024-02-01" "/tmp/exports"
#
# SORTIE :
#   - Fichiers Parquet créés dans le répertoire de sortie
#   - Statistiques de l'export (nombre d'opérations, dates min/max)
#   - Messages de succès/erreur
#
# PROCHAINES ÉTAPES :
#   - Script 27 (recommandé): Export avec spark-submit (./27_export_incremental_parquet.sh)
#   - Script 28: Démonstration fenêtre glissante (./28_demo_fenetre_glissante_spark_submit.sh)
#
# ============================================

set -euo pipefail

# Couleurs pour output
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

code() {
    echo -e "${BLUE}   $1${NC}"
}

# ============================================
# Configuration
# ============================================

# Configuration - Utiliser setup_paths si disponible
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
if [ -f "$SCRIPT_DIR/../utils/didactique_functions.sh" ]; then
    source "$SCRIPT_DIR/../utils/didactique_functions.sh"
    setup_paths
else
    # Fallback si les fonctions ne sont pas disponibles
    INSTALL_DIR="${ARKEA_HOME:-$(cd "$SCRIPT_DIR/../.." && pwd)}"
    HCD_DIR="${HCD_DIR:-${INSTALL_DIR}/binaire/hcd-1.2.3}"
    SPARK_HOME="${SPARK_HOME:-${INSTALL_DIR}/binaire/spark-3.5.1}"
    HCD_HOST="${HCD_HOST:-localhost}"
    HCD_PORT="${HCD_PORT:-9042}"
fi

# Source environment
if [ -f "$INSTALL_DIR/.poc-profile" ]; then
    source "$INSTALL_DIR/.poc-profile"
fi

# Paramètres (avec valeurs par défaut)
START_DATE="${1:-2024-01-01}"
END_DATE="${2:-2024-02-01}"
OUTPUT_PATH="${3:-/tmp/exports/domirama/incremental/2024-01}"
COMPRESSION="${4:-snappy}"

# Vérifier que HCD est démarré
info "Vérification que HCD est démarré..."
if ! nc -z "$HCD_HOST" "$HCD_PORT" 2>/dev/null; then
    error "HCD n'est pas démarré sur "$HCD_HOST:$HCD_PORT""
    error "Exécutez d'abord: ./scripts/setup/03_start_hcd.sh"
    exit 1
fi
success "HCD est démarré"

# Configurer Java 11 pour Spark
jenv local 11
eval "$(jenv init -)"

# SPARK_HOME devrait être défini par .poc-profile
if [ -z "$SPARK_HOME" ] || [ ! -d "$SPARK_HOME" ]; then
    export SPARK_HOME="${INSTALL_DIR}/binaire/spark-3.5.1"
fi
export PATH=$SPARK_HOME/bin:$PATH

# Vérifier Spark Cassandra Connector
if [ -z "$SPARK_CASSANDRA_CONNECTOR_JAR" ]; then
    SPARK_CASSANDRA_CONNECTOR_JAR="${INSTALL_DIR}/binaire/spark-cassandra-connector_2.12-3.5.0.jar"
fi

if [ ! -f "$SPARK_CASSANDRA_CONNECTOR_JAR" ]; then
    error "Spark Cassandra Connector JAR non trouvé: $SPARK_CASSANDRA_CONNECTOR_JAR"
    exit 1
fi

# Créer le répertoire de sortie si nécessaire
mkdir -p "$(dirname "$OUTPUT_PATH")"

# ============================================
# Export avec spark-shell
# ============================================

info "🚀 Lancement de l'export Spark (spark-shell)..."
warn "⚠️  Note: spark-submit est recommandé pour de meilleures performances"

TEMP_SCRIPT=$(mktemp)
cat > "$TEMP_SCRIPT" <<EOFSCRIPT
import org.apache.spark.sql.SparkSession
import org.apache.spark.sql.functions._

val spark = SparkSession.builder()
  .appName("Export Incremental Parquet from HCD")
  .config("spark.cassandra.connection.host", "$HCD_HOST")
  .config("spark.cassandra.connection.port", "$HCD_PORT")
  .config("spark.sql.extensions", "com.datastax.spark.connector.CassandraSparkExtensions")
  .getOrCreate()

import spark.implicits._

val startDate = "$START_DATE"
val endDate = "$END_DATE"
val outputPath = "$OUTPUT_PATH"
val compression = "$COMPRESSION"

println("=" * 80)
println(s"📥 Export Incrémental Parquet : \$startDate → \$endDate")
println("=" * 80)

// 1. Lecture depuis HCD
println("\n🔍 Lecture depuis HCD (keyspace: domirama2_poc, table: operations_by_account)...")
println(s"   WHERE date_op >= '\$startDate' AND date_op < '\$endDate'")

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
println(s"✅ \$count opérations trouvées dans la fenêtre")

if (count == 0) {
  println("⚠️  Aucune donnée à exporter")
  System.exit(0)
}

// 2. Statistiques
println("\n📊 Statistiques de l'export :")
df.select(
  min("date_op").as("date_min"),
  max("date_op").as("date_max"),
  count("*").as("total"),
  countDistinct("code_si", "contrat").as("comptes_uniques")
).show()

// 3. Export Parquet
println(s"\n💾 Export Parquet vers : \$outputPath")
println(s"   Compression : \$compression")
println(s"   Partitionnement : par date_op")

df.write
  .mode("overwrite")
  .partitionBy("date_op")
  .option("compression", compression)
  .option("parquet.block.size", "134217728")
  .parquet(outputPath)

println(s"✅ Export Parquet terminé : \$count opérations")
println(s"   Fichiers créés dans : \$outputPath")

// 4. Vérification
println("\n🔍 Vérification : lecture du Parquet exporté...")
try {
  val dfRead = spark.read.parquet(outputPath)
  val countRead = dfRead.count()
  println(s"✅ Vérification OK : \$countRead opérations lues depuis Parquet")
  
  if (count != countRead) {
    println(s"⚠️  ATTENTION : Incohérence (\$count exportées vs \$countRead lues)")
  }
} catch {
  case e: Exception => println(s"⚠️  Impossible de vérifier l'export : \${e.getMessage}")
}

println("\n" + "=" * 80)
println("✅ Export Incrémental Parquet - Terminé")
println("=" * 80)
EOFSCRIPT

# Exécuter avec spark-shell (mode non-interactif)
spark-shell \
  --jars "$SPARK_CASSANDRA_CONNECTOR_JAR" \
  --driver-memory 2g \
  --executor-memory 2g \
  -i "$TEMP_SCRIPT" \
  2>&1 | grep -v "^scala>" | grep -v "^     |"

# Nettoyer
rm -f "$TEMP_SCRIPT"

echo ""
success "✅ Export incrémental Parquet terminé"
info "   Fichiers Parquet créés dans : $OUTPUT_PATH"

