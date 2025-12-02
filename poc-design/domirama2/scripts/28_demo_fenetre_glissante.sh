#!/bin/bash
# ============================================
# Script 28 : Démonstration Fenêtre Glissante (TIMERANGE équivalent)
# ============================================
#
# OBJECTIF :
#   Ce script démontre la fenêtre glissante pour les exports incrémentaux,
#   équivalent au TIMERANGE HBase, permettant d'exporter des données sur une
#   plage de dates spécifique avec un décalage progressif.
#
#   Fonctionnalités :
#   - Export par fenêtre de dates (équivalent TIMERANGE HBase)
#   - Fenêtre glissante avec décalage progressif
#   - Format Parquet optimisé pour l'analytique
#   - Support des exports incrémentaux réguliers
#
# PRÉREQUIS :
#   - HCD démarré (./scripts/setup/03_start_hcd.sh)
#   - Schéma configuré (./10_setup_domirama2_poc.sh)
#   - Données chargées (./11_load_domirama2_data_parquet.sh)
#   - Spark 3.5.1 installé et configuré
#   - Spark Cassandra Connector 3.5.0 disponible
#   - Java 11 configuré via jenv
#
# UTILISATION :
#   ./28_demo_fenetre_glissante.sh [window_days] [shift_days]
#
# PARAMÈTRES :
#   $1 : Taille de la fenêtre en jours (optionnel, défaut: 7)
#   $2 : Décalage de la fenêtre en jours (optionnel, défaut: 1)
#
# EXEMPLE :
#   ./28_demo_fenetre_glissante.sh
#   ./28_demo_fenetre_glissante.sh 30 7
#
# SORTIE :
#   - Fichiers Parquet créés pour chaque fenêtre
#   - Statistiques de chaque export
#   - Messages de succès/erreur
#
# PROCHAINES ÉTAPES :
#   - Script 28 (recommandé): Version spark-submit (./28_demo_fenetre_glissante_spark_submit.sh)
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

# Répertoire de sortie
OUTPUT_BASE="/tmp/exports/domirama/incremental"

# ============================================
# Démonstration
# ============================================

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  📅 Démonstration Fenêtre Glissante (TIMERANGE équivalent)"
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

    TEMP_SCRIPT=$(mktemp)
    cat > "$TEMP_SCRIPT" <<EOFSCRIPT
import org.apache.spark.sql.SparkSession
import org.apache.spark.sql.functions._

val spark = SparkSession.builder()
  .appName("Fenetre Glissante Export")
  .config("spark.cassandra.connection.host", "$HCD_HOST")
  .config("spark.cassandra.connection.port", "$HCD_PORT")
  .config("spark.sql.extensions", "com.datastax.spark.connector.CassandraSparkExtensions")
  .getOrCreate()

import spark.implicits._

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
    col("date_op") >= "$start_date" &&
    col("date_op") < "$end_date"
  )

val count = df.count()
println(s"✅ \${count} opérations dans la fenêtre")

if (count > 0) {
  df.write
    .mode("overwrite")  // Idempotence : rejeux possibles
    .partitionBy("date_op")
    .option("compression", "snappy")
    .parquet("$output_path")

  println(s"✅ Export terminé : \${count} opérations")
} else {
  println("⚠️  Aucune donnée à exporter")
}

spark.stop()
EOFSCRIPT

    spark-shell \
      --packages com.datastax.spark:spark-cassandra-connector_2.12:3.5.0 \
      --conf spark.cassandra.connection.host="$HCD_HOST" \
      --conf spark.cassandra.connection.port="$HCD_PORT" \
      --conf spark.sql.extensions=com.datastax.spark.connector.CassandraSparkExtensions \
      --driver-memory 2g \
      --executor-memory 2g \
      -i "$TEMP_SCRIPT" 2>&1 | grep -v "^scala>" | grep -v "^     |" | grep -v "^Welcome to" | grep -v "WARN NativeCodeLoader" | grep -E "(✅|⚠️|opérations|Export|Terminé|count)" | head -10

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
echo ""
