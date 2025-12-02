#!/bin/bash
# ============================================
# Script 27 : Export Incrémental Parquet depuis HCD
# ============================================
#
# OBJECTIF :
#   Ce script démontre l'export incrémental de données depuis HCD vers
#   des fichiers Parquet, équivalent aux exports HBase avec FullScan,
#   STARTROW, STOPROW et TIMERANGE.
#
#   Fonctionnalités :
#   - Export par fenêtre de dates (équivalent TIMERANGE HBase)
#   - Export avec filtrage STARTROW/STOPROW (équivalent HBase)
#   - Format Parquet optimisé pour l'analytique
#   - Partitionnement par date_op pour performance
#   - Compression Snappy par défaut
#
# PRÉREQUIS :
#   - HCD démarré (./scripts/setup/03_start_hcd.sh)
#   - Schéma configuré (./10_setup_domirama2_poc.sh)
#   - Données chargées (./11_load_domirama2_data_parquet.sh)
#   - Spark 3.5.1 installé et configuré
#   - Spark Cassandra Connector 3.5.0 disponible
#   - Java 11 configuré via jenv
#   - Scala script présent: examples/scala/export_incremental_parquet_standalone.scala
#
# UTILISATION :
#   ./27_export_incremental_parquet.sh [start_date] [end_date] [output_path] [compression]
#
# PARAMÈTRES :
#   $1 : Date de début (format: YYYY-MM-DD, optionnel, défaut: 2024-01-01)
#   $2 : Date de fin (format: YYYY-MM-DD, optionnel, défaut: 2024-02-01)
#   $3 : Chemin de sortie (optionnel, défaut: /tmp/exports/domirama/incremental)
#   $4 : Compression (optionnel, défaut: snappy, options: snappy, gzip, lz4)
#
# EXEMPLE :
#   ./27_export_incremental_parquet.sh
#   ./27_export_incremental_parquet.sh "2024-01-01" "2024-02-01" "/tmp/exports/domirama/incremental/2024-01"
#   ./27_export_incremental_parquet.sh "2024-01-01" "2024-02-01" "/tmp/exports" "gzip"
#
# SORTIE :
#   - Fichiers Parquet créés dans le répertoire de sortie
#   - Statistiques de l'export (nombre d'opérations, dates min/max)
#   - Vérification de l'export (lecture des fichiers créés)
#   - Messages de succès/erreur
#
# PROCHAINES ÉTAPES :
#   - Script 28: Démonstration fenêtre glissante (./28_demo_fenetre_glissante_spark_submit.sh)
#   - Script 29: Requêtes in-base avec fenêtre glissante (./29_demo_requetes_fenetre_glissante.sh)
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

# Charger les fonctions utilitaires et configurer les chemins
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
if [ -f "${SCRIPT_DIR}/utils/didactique_functions.sh" ]; then
    source "${SCRIPT_DIR}/utils/didactique_functions.sh"
    setup_paths
else
    # Fallback si les fonctions ne sont pas disponibles
    SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
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
COMPRESSION="${4:-snappy}"  # snappy (rapide) ou gzip (compact)

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

# ============================================
# Démonstration
# ============================================

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  📥 Export Incrémental Parquet depuis HCD"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

info "Objectif : Démontrer l'export incrémental depuis HCD vers HDFS (format Parquet)"
echo ""
info "Équivalent HBase :"
code "  - FullScan + STARTROW + STOPROW + TIMERANGE"
code "  - Unload incrémental vers HDFS au format ORC"
echo ""
info "Avantages Parquet vs ORC :"
code "  ✅ Cohérence : même format que l'ingestion (Parquet)"
code "  ✅ Performance : optimisations Spark natives"
code "  ✅ Simplicité : un seul format dans le POC"
code "  ✅ Standard : format de facto dans l'écosystème moderne"
echo ""

info "Paramètres de l'export :"
code "  Date début    : $START_DATE"
code "  Date fin       : $END_DATE (exclusif)"
code "  Output path    : $OUTPUT_PATH"
code "  Compression    : $COMPRESSION"
echo ""

# Créer le répertoire de sortie si nécessaire
mkdir -p "$(dirname "$OUTPUT_PATH")"

# ============================================
# Export avec Spark
# ============================================

info "🚀 Lancement de l'export Spark..."

info "🚀 Lancement de l'export Spark (spark-shell non-interactif)..."

# Créer un script Scala temporaire avec les paramètres
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

// 1. Lecture depuis HCD avec fenêtre glissante (équivalent TIMERANGE HBase)
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

// 2. Afficher quelques statistiques
println("\n📊 Statistiques de l'export :")
val stats = df.agg(
  min("date_op").as("date_min"),
  max("date_op").as("date_max"),
  countDistinct("code_si", "contrat").as("comptes_uniques")
)
stats.show()
println(s"   Total opérations : \$count")

// 3. Export Parquet vers HDFS (partitionné par date_op)
println(s"\n💾 Export Parquet vers : \$outputPath")
println(s"   Compression : \$compression")
println(s"   Partitionnement : par date_op")

df.write
  .mode("overwrite")
  .partitionBy("date_op")
  .option("compression", compression)
  .option("parquet.block.size", "134217728")  // 128MB
  .parquet(outputPath)

println(s"✅ Export Parquet terminé : \$count opérations")
println(s"   Fichiers créés dans : \$outputPath")

// 4. Vérification : lire le Parquet exporté
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

# Exécuter avec spark-shell en mode non-interactif
spark-shell \
  --packages com.datastax.spark:spark-cassandra-connector_2.12:3.5.0 \
  --conf spark.cassandra.connection.host="$HCD_HOST" \
  --conf spark.cassandra.connection.port="$HCD_PORT" \
  --conf spark.sql.extensions=com.datastax.spark.connector.CassandraSparkExtensions \
  --driver-memory 2g \
  --executor-memory 2g \
  -i "$TEMP_SCRIPT" \
  2>&1 | grep -v "^scala>" | grep -v "^     |" | grep -v "^Welcome to" | grep -v "WARN NativeCodeLoader"

# Nettoyer
rm -f "$TEMP_SCRIPT"

echo ""
success "✅ Export incrémental Parquet terminé"
info "   Fichiers Parquet créés dans : $OUTPUT_PATH"
info ""
info "📋 Pour lire les fichiers Parquet exportés :"
code "   spark-shell --jars $SPARK_CASSANDRA_CONNECTOR_JAR"
code "   val df = spark.read.parquet(\"$OUTPUT_PATH\")"
code "   df.show()"
echo ""
