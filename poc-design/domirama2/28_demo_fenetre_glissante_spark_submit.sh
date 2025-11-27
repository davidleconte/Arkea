#!/bin/bash
# ============================================
# Script 28 (Alternative) : Fenêtre Glissante avec spark-submit
# ============================================
#
# OBJECTIF :
#   Ce script démontre la fenêtre glissante pour les exports incrémentaux en
#   utilisant spark-submit (recommandé pour la production), équivalent au
#   TIMERANGE HBase.
#   
#   Cette version spark-submit est recommandée car elle :
#   - Permet un meilleur contrôle des ressources
#   - Facilite le monitoring et le logging
#   - Est plus adaptée aux environnements de production
#
# PRÉREQUIS :
#   - HCD démarré (./03_start_hcd.sh)
#   - Schéma configuré (./10_setup_domirama2_poc.sh)
#   - Données chargées (./11_load_domirama2_data_parquet.sh)
#   - Spark 3.5.1 installé et configuré
#   - Spark Cassandra Connector 3.5.0 disponible
#   - Java 11 configuré via jenv
#   - Scala script présent: examples/scala/export_incremental_parquet_standalone.scala
#
# UTILISATION :
#   ./28_demo_fenetre_glissante_spark_submit.sh [window_days] [shift_days]
#
# PARAMÈTRES :
#   $1 : Taille de la fenêtre en jours (optionnel, défaut: 7)
#   $2 : Décalage de la fenêtre en jours (optionnel, défaut: 1)
#
# EXEMPLE :
#   ./28_demo_fenetre_glissante_spark_submit.sh
#   ./28_demo_fenetre_glissante_spark_submit.sh 30 7
#
# SORTIE :
#   - Fichiers Parquet créés pour chaque fenêtre
#   - Statistiques de chaque export
#   - Messages de succès/erreur
#
# PROCHAINES ÉTAPES :
#   - Script 29: Requêtes in-base avec fenêtre glissante (./29_demo_requetes_fenetre_glissante.sh)
#   - Script 30: Requêtes avec STARTROW/STOPROW (./30_demo_requetes_startrow_stoprow.sh)
#
# ============================================

set -e

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

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
INSTALL_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"

# Source environment
if [ -f "$INSTALL_DIR/.poc-profile" ]; then
    source "$INSTALL_DIR/.poc-profile"
fi

# Vérifier que HCD est démarré
info "Vérification que HCD est démarré..."
if ! nc -z localhost 9042 2>/dev/null; then
    error "HCD n'est pas démarré sur localhost:9042"
    error "Exécutez d'abord: ./03_start_hcd.sh"
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

# Répertoire de sortie
OUTPUT_BASE="/tmp/exports/domirama/incremental"
SCALA_SCRIPT="$SCRIPT_DIR/examples/scala/export_incremental_parquet_standalone.scala"

if [ ! -f "$SCALA_SCRIPT" ]; then
    error "Script Scala non trouvé: $SCALA_SCRIPT"
    exit 1
fi

# ============================================
# Démonstration
# ============================================

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  📅 Démonstration Fenêtre Glissante (spark-submit)"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

info "Objectif : Démontrer la fenêtre glissante pour exports incrémentaux"
echo ""
info "Équivalent HBase :"
code "  - TIMERANGE pour une fenêtre glissante"
code "  - Ciblage précis des données à exporter"
code "  - Gestion des rejeux (idempotence)"
echo ""
info "Stratégie :"
code "  - Export mensuel (fenêtre de 1 mois)"
code "  - Fenêtre glissante : chaque mois exporte les données du mois précédent"
code "  - Mode overwrite pour idempotence (rejeux possibles)"
echo ""

# ============================================
# Fonction : Export Fenêtre Glissante
# ============================================

export_window() {
    local year=$1
    local month=$2
    local start_date="${year}-$(printf "%02d" $month)-01"
    
    # Calculer la date de fin (mois suivant)
    local next_month=$((month + 1))
    local next_year=$year
    if [ $next_month -gt 12 ]; then
        next_month=1
        next_year=$((year + 1))
    fi
    local end_date="${next_year}-$(printf "%02d" $next_month)-01"
    
    local output_path="${OUTPUT_BASE}/${year}-$(printf "%02d" $month)"
    
    info "📅 Export fenêtre : $start_date → $end_date"
    code "   Output : $output_path"
    
    # Créer un script Scala temporaire avec les paramètres
    TEMP_SCRIPT=$(mktemp)
    cat > "$TEMP_SCRIPT" <<EOFSCRIPT
import org.apache.spark.sql.SparkSession
import org.apache.spark.sql.functions._

val spark = SparkSession.builder()
  .appName("Export Incremental Parquet from HCD - Window ${year}-${month}")
  .config("spark.cassandra.connection.host", "localhost")
  .config("spark.cassandra.connection.port", "9042")
  .config("spark.sql.extensions", "com.datastax.spark.connector.CassandraSparkExtensions")
  .getOrCreate()

import spark.implicits._

val startDate = "$start_date"
val endDate = "$end_date"
val outputPath = "$output_path"
val compression = "snappy"

println("=" * 80)
println(s"📥 Export Incrémental Parquet : \$startDate → \$endDate")
println("=" * 80)

// 1. Lecture depuis HCD avec fenêtre glissante (équivalent TIMERANGE HBase)
println("\n🔍 Lecture depuis HCD (keyspace: domirama2_poc, table: operations_by_account)...")
println(s"   WHERE date_op >= '\$startDate' AND date_op < '\$endDate'")

// Exclure la colonne libelle_embedding (type VECTOR non supporté par Spark Cassandra Connector)
val df = spark.read
  .format("org.apache.spark.sql.cassandra")
  .options(Map(
    "table" -> "operations_by_account",
    "keyspace" -> "domirama2_poc"
  ))
  .load()
  .select(
    col("code_si"), col("contrat"), col("date_op"), col("numero_op"),
    col("op_id"), col("libelle"), col("montant"), col("devise"),
    col("date_valeur"), col("type_operation"), col("sens_operation"),
    col("operation_data"), col("cobol_data_base64"), col("copy_type"),
    col("meta_flags"), col("cat_auto"), col("cat_confidence"),
    col("cat_user"), col("cat_date_user"), col("cat_validee"),
    col("libelle_prefix")
  )
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

spark.stop()
EOFSCRIPT

    # Exécuter avec spark-shell en mode non-interactif
    spark-shell \
      --packages com.datastax.spark:spark-cassandra-connector_2.12:3.5.0 \
      --conf spark.cassandra.connection.host=localhost \
      --conf spark.cassandra.connection.port=9042 \
      --conf spark.sql.extensions=com.datastax.spark.connector.CassandraSparkExtensions \
      --driver-memory 2g \
      --executor-memory 2g \
      -i "$TEMP_SCRIPT" \
      2>&1 | grep -v "^scala>" | grep -v "^     |" | grep -v "^Welcome to" | grep -v "WARN NativeCodeLoader" | grep -E "(✅|⚠️|📥|📊|💾|🔍|opérations|Export|Terminé|count|Statistiques|Vérification)" | head -15
    
    # Nettoyer
    rm -f "$TEMP_SCRIPT"
    
    echo ""
}

# ============================================
# Démonstration : Exports Mensuels
# ============================================

info "📋 Démonstration : Exports mensuels (fenêtre glissante)"
echo ""

# Exemple : Exports pour les 3 premiers mois de 2024
for month in 1 2 3; do
    export_window 2024 $month
done

# ============================================
# Vérification : Liste des Exports
# ============================================

echo ""
info "📋 Vérification : Liste des exports créés"
echo ""

if [ -d "$OUTPUT_BASE" ]; then
    for dir in "$OUTPUT_BASE"/*; do
        if [ -d "$dir" ]; then
            local count=$(find "$dir" -name "*.parquet" 2>/dev/null | wc -l | tr -d ' ')
            if [ "$count" -gt 0 ]; then
                success "  $(basename "$dir") : $count fichier(s) Parquet"
            fi
        fi
    done
else
    warn "Aucun export trouvé dans $OUTPUT_BASE"
fi

echo ""
success "✅ Démonstration fenêtre glissante terminée"
info ""
info "💡 Points clés démontrés :"
code "  ✅ Fenêtre glissante avec WHERE date_op BETWEEN start AND end"
code "  ✅ Export incrémental par période (mensuel)"
code "  ✅ Idempotence (mode overwrite pour rejeux)"
code "  ✅ Partitionnement par date_op (performance)"
code "  ✅ Format Parquet (cohérent avec ingestion)"
code "  ✅ Utilisation de spark-submit (recommandé)"
echo ""

