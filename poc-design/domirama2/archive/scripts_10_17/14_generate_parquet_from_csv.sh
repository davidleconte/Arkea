#!/bin/bash
# ============================================
# Script 14 : Génération Parquet depuis CSV
# Convertit le CSV en format Parquet optimisé
# ============================================
#
# OBJECTIF :
#   Ce script convertit un fichier CSV d'opérations en format Parquet,
#   qui est optimisé pour les traitements analytiques avec Spark.
#   
#   Avantages du format Parquet :
#   - Performance 3-10x plus rapide que CSV pour les lectures
#   - Schéma typé (moins d'erreurs de conversion)
#   - Compression efficace (Snappy par défaut)
#   - Compatible avec tous les outils Big Data (Spark, Hive, etc.)
#
# PRÉREQUIS :
#   - Spark 3.5.1 installé et configuré
#   - Java 11 configuré via jenv
#   - Fichier CSV source présent (data/operations_10000.csv ou chemin fourni)
#
# UTILISATION :
#   ./14_generate_parquet_from_csv.sh [chemin_csv] [chemin_parquet_sortie]
#
# PARAMÈTRES :
#   $1 : Chemin vers le fichier CSV source (optionnel, défaut: data/operations_10000.csv)
#   $2 : Chemin de sortie pour le Parquet (optionnel, défaut: data/operations_10000.parquet)
#
# EXEMPLE :
#   ./14_generate_parquet_from_csv.sh
#   ./14_generate_parquet_from_csv.sh data/operations_sample.csv data/operations_sample.parquet
#
# SORTIE :
#   - Fichier Parquet créé dans le répertoire de sortie
#   - Statistiques de conversion (nombre de lignes)
#   - Messages de succès/erreur
#
# PROCHAINES ÉTAPES :
#   - Script 11: Chargement des données Parquet dans HCD (./11_load_domirama2_data_parquet.sh)
#
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
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"

# Utiliser le fichier CSV spécifié en argument, ou le fichier par défaut
if [ -n "$1" ]; then
    CSV_FILE="$1"
else
    CSV_FILE="${SCRIPT_DIR}/data/operations_10000.csv"
fi

if [ -n "$2" ]; then
    PARQUET_OUTPUT="$2"
else
    PARQUET_OUTPUT="${SCRIPT_DIR}/data/operations_10000.parquet"
fi

# Si le fichier spécifié n'existe pas, essayer operations_sample.csv
if [ ! -f "$CSV_FILE" ]; then
    warn "Fichier $CSV_FILE non trouvé, utilisation du fichier par défaut"
    CSV_FILE="${SCRIPT_DIR}/data/operations_sample.csv"
    PARQUET_OUTPUT="${SCRIPT_DIR}/data/operations_sample.parquet"
fi

# Charger l'environnement POC
if [ -f "${INSTALL_DIR}/.poc-profile" ]; then
    source "${INSTALL_DIR}/.poc-profile"
fi

# Configurer Java 11 pour Spark
jenv local 11
eval "$(jenv init -)"

# SPARK_HOME devrait être défini par .poc-profile
if [ -z "$SPARK_HOME" ] || [ ! -d "$SPARK_HOME" ]; then
    export SPARK_HOME="${INSTALL_DIR}/binaire/spark-3.5.1"
fi
export PATH=$SPARK_HOME/bin:$PATH

# Vérifier que le fichier CSV existe
if [ ! -f "$CSV_FILE" ]; then
    error "Fichier CSV non trouvé: $CSV_FILE"
    exit 1
fi

info "🔄 Génération Parquet depuis CSV..."
info "   CSV source: $CSV_FILE"
info "   Parquet output: $PARQUET_OUTPUT"

# Supprimer l'ancien Parquet si existe
if [ -d "$PARQUET_OUTPUT" ]; then
    warn "Suppression de l'ancien Parquet..."
    rm -rf "$PARQUET_OUTPUT"
fi

TEMP_SCRIPT=$(mktemp)
cat > "$TEMP_SCRIPT" <<EOFSCRIPT
import org.apache.spark.sql.SparkSession
import org.apache.spark.sql.functions._
import org.apache.spark.sql.types._

val spark = SparkSession.builder()
  .appName("CsvToParquet")
  .getOrCreate()
import spark.implicits._

println("📥 Lecture du CSV...")
val df = spark.read
  .option("header", "true")
  .option("inferSchema", "true")  // Inférer les types automatiquement
  .csv("$CSV_FILE")

println(s"✅ \${df.count()} lignes lues")
println("📋 Schéma inféré:")
df.printSchema()

println("🔄 Conversion date_iso → date_op (Timestamp)...")
val dfWithTimestamp = df.withColumn(
  "date_op",
  to_timestamp(col("date_iso"), "yyyy-MM-dd'T'HH:mm:ss'Z'")
).drop("date_iso")

// Renommer seq → numero_op pour cohérence
val dfRenamed = dfWithTimestamp.withColumnRenamed("seq", "numero_op")

println("💾 Écriture en Parquet...")
dfRenamed.write
  .mode("overwrite")
  .parquet("$PARQUET_OUTPUT")

println("✅ Parquet généré avec succès !")

// Vérification
val parquetDf = spark.read.parquet("$PARQUET_OUTPUT")
println(s"📊 Vérification: \${parquetDf.count()} lignes dans le Parquet")
println("📋 Schéma Parquet:")
parquetDf.printSchema()

spark.stop()
EOFSCRIPT

"$SPARK_HOME/bin/spark-shell" \
  -i "$TEMP_SCRIPT" \
  2>&1 | grep -E "(✅|📊|📥|🔄|💾|📋|ERROR|Exception|lignes|Schéma)" || true

rm -f "$TEMP_SCRIPT"

if [ -d "$PARQUET_OUTPUT" ]; then
    success "✅ Parquet généré: $PARQUET_OUTPUT"
    info "📁 Contenu:"
    ls -lh "$PARQUET_OUTPUT" | head -5
else
    error "❌ Échec de la génération Parquet"
    exit 1
fi

echo ""
success "✅ Génération Parquet terminée !"
info "📝 Prochaine étape: Exécuter ./11_load_domirama2_data.sh (modifié pour Parquet)"

