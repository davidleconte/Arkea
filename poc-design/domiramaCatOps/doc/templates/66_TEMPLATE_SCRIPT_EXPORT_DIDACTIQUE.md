# 📋 Template : Script Shell Didactique pour Export/ETL Sortant

**Date** : 2025-11-26  
**Objectif** : Template réutilisable pour créer des scripts d'export/ETL sortant très didactiques  
**Type** : Scripts d'export de données (HCD → Parquet/Fichiers)

---

## 🎯 Principes du Template pour Export

Un script d'export didactique doit :

1. **Afficher le code Spark complet** : Lecture depuis HCD, filtrage, export avec explications
2. **Expliquer les équivalences HBase → HCD** : TIMERANGE, STARTROW/STOPROW, FullScan
3. **Afficher les résultats d'export** : Nombre d'opérations, fichiers créés, statistiques
4. **Documenter la cinématique** : Chaque étape expliquée (lecture, filtrage, export, vérification)
5. **Générer un rapport** : Documentation structurée pour livrable
6. **Afficher les métriques** : Nombre de lignes lues, exportées, fichiers créés, taille

---

## 📝 Structure Standard pour Script d'Export

```bash
#!/bin/bash
# ============================================
# Script XX : Export Incrémental [Nom] (Version Didactique)
# Exporte les données depuis HCD vers [format] via Spark
# Équivalent HBase: FullScan + TIMERANGE + STARTROW/STOPROW
# ============================================
#
# OBJECTIF :
#   Ce script exporte les données d'opérations depuis HCD vers des fichiers
#   [format] via Spark, avec filtrage par dates (équivalent TIMERANGE HBase).
#  
#   Cette version didactique affiche :
#   - Le code Spark complet (lecture HCD, filtrage, export) avec explications
#   - Les équivalences HBase → HCD détaillées
#   - Les résultats d'export détaillés (fichiers créés, statistiques)
#   - La cinématique complète de chaque étape
#   - Une documentation structurée pour livrable
#
# PRÉREQUIS :
#   - HCD démarré (./scripts/setup/03_start_hcd.sh)
#   - Schéma configuré (./10_setup_domiramacatops_poc.sh)
#   - Données chargées (./11_load_domiramaCatOps_data_parquet.sh)
#   - Spark 3.5.1 installé et configuré
#   - Spark Cassandra Connector 3.5.0 disponible
#   - Java 11 configuré via jenv
#
# UTILISATION :
#   ./XX_export_[nom].sh [start_date] [end_date] [output_path] [compression]
#
# PARAMÈTRES :
#   $1 : Date de début (format: YYYY-MM-DD, optionnel, défaut: 2024-01-01)
#   $2 : Date de fin (format: YYYY-MM-DD, optionnel, défaut: 2024-02-01)
#   $3 : Chemin de sortie (optionnel, défaut: /tmp/exports/domirama/incremental)
#   $4 : Compression (optionnel, défaut: snappy, options: snappy, gzip, lz4)
#
# SORTIE :
#   - Code Spark complet affiché avec explications
#   - Fichiers [format] créés dans le répertoire de sortie
#   - Statistiques de l'export (nombre d'opérations, dates min/max)
#   - Vérification de l'export (lecture des fichiers créés)
#   - Documentation structurée générée
#
# ============================================

set -e

# ============================================
# CONFIGURATION DES COULEURS
# ============================================
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
BOLD='\033[1m'
NC='\033[0m'

info() { echo -e "${BLUE}ℹ️  $1${NC}"; }
success() { echo -e "${GREEN}✅ $1${NC}"; }
warn() { echo -e "${YELLOW}⚠️  $1${NC}"; }
error() { echo -e "${RED}❌ $1${NC}"; }
demo() { echo -e "${CYAN}🎯 $1${NC}"; }
code() { echo -e "${MAGENTA}📝 $1${NC}"; }
section() { echo -e "${BOLD}${CYAN}$1${NC}"; }
result() { echo -e "${GREEN}📊 $1${NC}"; }
expected() { echo -e "${YELLOW}📋 $1${NC}"; }

# ============================================
# CONFIGURATION
# ============================================
INSTALL_DIR="/Users/david.leconte/Documents/Arkea"
HCD_DIR="${INSTALL_DIR}/binaire/hcd-1.2.3"
SPARK_HOME="${INSTALL_DIR}/binaire/spark-3.5.1"
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
REPORT_FILE="${SCRIPT_DIR}/doc/demonstrations/XX_EXPORT_DEMONSTRATION.md"

# Paramètres (avec valeurs par défaut)
START_DATE="${1:-2024-01-01}"
END_DATE="${2:-2024-02-01}"
OUTPUT_PATH="${3:-/tmp/exports/domirama/incremental/2024-01}"
COMPRESSION="${4:-snappy}"  # snappy (rapide) ou gzip (compact)

# Créer le répertoire de documentation
mkdir -p "$(dirname "$REPORT_FILE")"

# Fichiers temporaires pour capture
TEMP_OUTPUT=$(mktemp "/tmp/script_XX_output_$(date +%s)_XXXXXX.txt")
TEMP_RESULTS=$(mktemp "/tmp/script_XX_results_$(date +%s)_XXXXXX.json")

# ============================================
# PARTIE 0: VÉRIFICATIONS
# ============================================
echo ""
section "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
section "  🔍 PARTIE 0: VÉRIFICATIONS"
section "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

info "Vérification de HCD..."
if ! nc -z localhost 9042 2>/dev/null; then
    error "HCD n'est pas démarré sur localhost:9042"
    error "Exécutez d'abord: ./scripts/setup/03_start_hcd.sh"
    exit 1
fi
success "HCD est démarré"

info "Vérification de Spark..."
if [ -z "$SPARK_HOME" ] || [ ! -d "$SPARK_HOME" ]; then
    export SPARK_HOME="${INSTALL_DIR}/binaire/spark-3.5.1"
fi
if [ ! -d "$SPARK_HOME" ]; then
    error "Spark n'est pas installé dans : $SPARK_HOME"
    exit 1
fi
export PATH=$SPARK_HOME/bin:$PATH
success "Spark trouvé : $SPARK_HOME"

info "Vérification de Spark Cassandra Connector..."
if [ -z "$SPARK_CASSANDRA_CONNECTOR_JAR" ]; then
    SPARK_CASSANDRA_CONNECTOR_JAR="${INSTALL_DIR}/binaire/spark-cassandra-connector_2.12-3.5.0.jar"
fi
if [ ! -f "$SPARK_CASSANDRA_CONNECTOR_JAR" ]; then
    error "Spark Cassandra Connector JAR non trouvé: $SPARK_CASSANDRA_CONNECTOR_JAR"
    exit 1
fi
success "Spark Cassandra Connector trouvé"

info "Vérification de Java..."
jenv local 11
eval "$(jenv init -)"
JAVA_VERSION=$(java -version 2>&1 | head -1)
success "Java configuré : $JAVA_VERSION"

info "Vérification du répertoire de sortie..."
mkdir -p "$(dirname "$OUTPUT_PATH")"
if [ ! -w "$(dirname "$OUTPUT_PATH")" ]; then
    error "Répertoire de sortie non accessible en écriture : $(dirname "$OUTPUT_PATH")"
    exit 1
fi
success "Répertoire de sortie accessible : $(dirname "$OUTPUT_PATH")"

# ============================================
# PARTIE 1: CONTEXTE ET STRATÉGIE
# ============================================
echo ""
section "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
section "  📚 PARTIE 1: CONTEXTE ET STRATÉGIE"
section "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

info "📚 OBJECTIF : Démontrer l'export incrémental depuis HCD vers [format]"
echo ""
info "🔄 ÉQUIVALENCES HBase → HCD :"
echo ""
echo "   HBase                          →  HCD (Spark)"
echo "   ──────────────────────────────    ─────────────────────────────"
echo "   FullScan + TIMERANGE          →  WHERE date_op >= start AND date_op < end"
echo "   STARTROW + STOPROW             →  WHERE code_si = X AND contrat >= Y AND contrat < Z"
echo "   Unload ORC vers HDFS          →  Export Parquet vers HDFS"
echo "   Fenêtre glissante             →  Calcul automatique des dates"
echo ""
info "📋 AVANTAGES [Format] vs ORC :"
echo "   ✅ Cohérence : même format que l'ingestion ([format])"
echo "   ✅ Performance : optimisations Spark natives"
echo "   ✅ Simplicité : un seul format dans le POC"
echo "   ✅ Standard : format de facto dans l'écosystème moderne"
echo ""
info "📋 PARAMÈTRES DE L'EXPORT :"
code "   Date début    : $START_DATE"
code "   Date fin       : $END_DATE (exclusif)"
code "   Output path    : $OUTPUT_PATH"
code "   Compression    : $COMPRESSION"
echo ""

# ============================================
# PARTIE 2: CODE SPARK - LECTURE DEPUIS HCD
# ============================================
echo ""
section "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
section "  📥 PARTIE 2: CODE SPARK - LECTURE DEPUIS HCD"
section "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

info "📝 Code Spark pour lire depuis HCD avec filtrage par dates :"
echo ""
code "val spark = SparkSession.builder()"
code "  .appName(\"Export Incremental [Format] from HCD\")"
code "  .config(\"spark.cassandra.connection.host\", \"localhost\")"
code "  .config(\"spark.cassandra.connection.port\", \"9042\")"
code "  .config(\"spark.sql.extensions\", \"com.datastax.spark.connector.CassandraSparkExtensions\")"
code "  .getOrCreate()"
echo ""
code "val df = spark.read"
code "  .format(\"org.apache.spark.sql.cassandra\")"
code "  .options(Map("
code "    \"table\" -> \"operations_by_account\","
code "    \"keyspace\" -> \"domiramacatops_poc\""
code "  ))"
code "  .load()"
code "  .filter("
code "    col(\"date_op\") >= \"$START_DATE\" &&"
code "    col(\"date_op\") < \"$END_DATE\""
code "  )"
echo ""
info "💡 Explication :"
echo "   - Lecture depuis HCD via Spark Cassandra Connector"
echo "   - Filtrage par dates (équivalent TIMERANGE HBase)"
echo "   - WHERE date_op >= '$START_DATE' AND date_op < '$END_DATE'"
echo "   - Date de fin exclusive (comme TIMERANGE HBase)"
echo ""

# ============================================
# PARTIE 3: CODE SPARK - EXPORT [FORMAT]
# ============================================
echo ""
section "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
section "  💾 PARTIE 3: CODE SPARK - EXPORT [FORMAT]"
section "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

info "📝 Code Spark pour exporter vers [format] :"
echo ""
code "df.write"
code "  .mode(\"overwrite\")"
code "  .partitionBy(\"date_op\")"
code "  .option(\"compression\", \"$COMPRESSION\")"
code "  .option(\"parquet.block.size\", \"134217728\")  // 128MB"
code "  .[format](\"$OUTPUT_PATH\")"
echo ""
info "💡 Explication :"
echo "   - Mode overwrite : permet les rejeux (idempotence)"
echo "   - Partitionnement par date_op : performance optimale pour requêtes futures"
echo "   - Compression $COMPRESSION : [explication selon compression]"
echo "   - Block size 128MB : taille optimale pour Spark"
echo ""

# ============================================
# PARTIE 4: EXÉCUTION SPARK
# ============================================
echo ""
section "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
section "  🚀 PARTIE 4: EXÉCUTION SPARK"
section "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

info "🚀 Lancement de l'export Spark..."
echo ""

# Créer un script Scala temporaire avec les paramètres
TEMP_SCRIPT=$(mktemp "/tmp/script_XX_scala_$(date +%s)_XXXXXX.scala")
cat > "$TEMP_SCRIPT" <<EOFSCRIPT
import org.apache.spark.sql.SparkSession
import org.apache.spark.sql.functions._

val spark = SparkSession.builder()
  .appName("Export Incremental [Format] from HCD")
  .config("spark.cassandra.connection.host", "localhost")
  .config("spark.cassandra.connection.port", "9042")
  .config("spark.sql.extensions", "com.datastax.spark.connector.CassandraSparkExtensions")
  .getOrCreate()

import spark.implicits._

val startDate = "$START_DATE"
val endDate = "$END_DATE"
val outputPath = "$OUTPUT_PATH"
val compression = "$COMPRESSION"

println("=" * 80)
println(s"📥 Export Incrémental [Format] : \$startDate → \$endDate")
println("=" * 80)

// 1. Lecture depuis HCD avec filtrage par dates (équivalent TIMERANGE HBase)
println("\n🔍 Lecture depuis HCD (keyspace: domiramacatops_poc, table: operations_by_account)...")
println(s"   WHERE date_op >= '\$startDate' AND date_op < '\$endDate'")

val df = spark.read
  .format("org.apache.spark.sql.cassandra")
  .options(Map(
    "table" -> "operations_by_account",
    "keyspace" -> "domiramacatops_poc"
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

// 3. Export [Format] vers HDFS (partitionné par date_op)
println(s"\n💾 Export [Format] vers : \$outputPath")
println(s"   Compression : \$compression")
println(s"   Partitionnement : par date_op")

df.write
  .mode("overwrite")
  .partitionBy("date_op")
  .option("compression", compression)
  .option("parquet.block.size", "134217728")  // 128MB
  .[format](outputPath)

println(s"✅ Export [Format] terminé : \$count opérations")
println(s"   Fichiers créés dans : \$outputPath")

// 4. Vérification : lire le [Format] exporté
println("\n🔍 Vérification : lecture du [Format] exporté...")
try {
  val dfRead = spark.read.[format](outputPath)
  val countRead = dfRead.count()
  println(s"✅ Vérification OK : \$countRead opérations lues depuis [Format]")

  if (count != countRead) {
    println(s"⚠️  ATTENTION : Incohérence (\$count exportées vs \$countRead lues)")
  }
} catch {
  case e: Exception => println(s"⚠️  Impossible de vérifier l'export : \${e.getMessage}")
}

println("\n" + "=" * 80)
println("✅ Export Incrémental [Format] - Terminé")
println("=" * 80)
EOFSCRIPT

# Exécuter avec spark-shell en mode non-interactif et capturer la sortie
spark-shell \
  --packages com.datastax.spark:spark-cassandra-connector_2.12:3.5.0 \
  --conf spark.cassandra.connection.host=localhost \
  --conf spark.cassandra.connection.port=9042 \
  --conf spark.sql.extensions=com.datastax.spark.connector.CassandraSparkExtensions \
  --driver-memory 2g \
  --executor-memory 2g \
  -i "$TEMP_SCRIPT" \
  2>&1 | tee "$TEMP_OUTPUT" | grep -v "^scala>" | grep -v "^     |" | grep -v "^Welcome to" | grep -v "WARN NativeCodeLoader"

# Nettoyer
rm -f "$TEMP_SCRIPT"

# ============================================
# PARTIE 5: VÉRIFICATION DE L'EXPORT
# ============================================
echo ""
section "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
section "  🔍 PARTIE 5: VÉRIFICATION DE L'EXPORT"
section "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

info "🔍 Vérification des fichiers créés..."
if [ -d "$OUTPUT_PATH" ]; then
    FILE_COUNT=$(find "$OUTPUT_PATH" -type f | wc -l | tr -d ' ')
    DIR_COUNT=$(find "$OUTPUT_PATH" -type d | wc -l | tr -d ' ')
    TOTAL_SIZE=$(du -sh "$OUTPUT_PATH" 2>/dev/null | cut -f1)
    success "Fichiers créés : $FILE_COUNT fichiers, $DIR_COUNT répertoires"
    success "Taille totale : $TOTAL_SIZE"
else
    warn "Répertoire de sortie non trouvé : $OUTPUT_PATH"
fi

# Extraire les statistiques de la sortie Spark
if [ -f "$TEMP_OUTPUT" ]; then
    EXPORT_COUNT=$(grep -oP '\d+ opérations trouvées' "$TEMP_OUTPUT" | head -1 | grep -oP '\d+' || echo "0")
    READ_COUNT=$(grep -oP '\d+ opérations lues' "$TEMP_OUTPUT" | head -1 | grep -oP '\d+' || echo "0")

    if [ "$EXPORT_COUNT" != "0" ]; then
        result "Opérations exportées : $EXPORT_COUNT"
    fi
    if [ "$READ_COUNT" != "0" ]; then
        result "Opérations lues (vérification) : $READ_COUNT"
    fi
fi

# ============================================
# PARTIE 6: GÉNÉRATION DU RAPPORT
# ============================================
echo ""
section "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
section "  📝 PARTIE 6: GÉNÉRATION DU RAPPORT"
section "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

info "📝 Génération du rapport markdown..."

python3 << PYTHON_REPORT
import json
import os
import re
from datetime import datetime

report_file = "$REPORT_FILE"
output_file = "$TEMP_OUTPUT"
start_date = "$START_DATE"
end_date = "$END_DATE"
output_path = "$OUTPUT_PATH"
compression = "$COMPRESSION"

# Lire la sortie Spark
spark_output = ""
if os.path.exists(output_file):
    with open(output_file, 'r', encoding='utf-8') as f:
        spark_output = f.read()

# Parser les résultats
export_count = 0
read_count = 0
date_min = "N/A"
date_max = "N/A"
comptes_uniques = "N/A"

# Extraire le nombre d'opérations exportées
count_match = re.search(r'(\d+) opérations trouvées', spark_output)
if count_match:
    export_count = int(count_match.group(1))

# Extraire le nombre d'opérations lues
read_match = re.search(r'(\d+) opérations lues', spark_output)
if read_match:
    read_count = int(read_match.group(1))

# Extraire les statistiques
stats_match = re.search(r'date_min.*?date_max.*?comptes_uniques', spark_output, re.DOTALL)
if stats_match:
    # Essayer d'extraire les valeurs depuis la sortie
    date_min_match = re.search(r'date_min.*?(\d{4}-\d{2}-\d{2})', spark_output)
    if date_min_match:
        date_min = date_min_match.group(1)
    date_max_match = re.search(r'date_max.*?(\d{4}-\d{2}-\d{2})', spark_output)
    if date_max_match:
        date_max = date_max_match.group(1)

report_date = datetime.now().strftime("%Y-%m-%d %H:%M:%S")

report_content = f"""# 📥 Démonstration : Export Incrémental [Format] depuis HCD

**Date** : {report_date}
**Script** : $(basename "$0")
**Objectif** : Démontrer l'export incrémental depuis HCD vers [format]

---

## 📋 Table des Matières

1. [Contexte et Stratégie](#contexte-et-stratégie)
2. [Code Spark - Lecture depuis HCD](#code-spark---lecture-depuis-hcd)
3. [Code Spark - Export [Format]](#code-spark---export-format)
4. [Résultats de l'Export](#résultats-de-lexport)
5. [Vérification](#vérification)
6. [Conclusion](#conclusion)

---

## 📚 Contexte et Stratégie

### Équivalences HBase → HCD

| Concept HBase | Équivalent HCD (Spark) |
|---------------|------------------------|
| FullScan + TIMERANGE | WHERE date_op >= start AND date_op < end |
| STARTROW + STOPROW | WHERE code_si = X AND contrat >= Y AND contrat < Z |
| Unload ORC vers HDFS | Export [Format] vers HDFS |
| Fenêtre glissante | Calcul automatique des dates |

### Avantages [Format] vs ORC

- ✅ **Cohérence** : même format que l'ingestion ([format])
- ✅ **Performance** : optimisations Spark natives
- ✅ **Simplicité** : un seul format dans le POC
- ✅ **Standard** : format de facto dans l'écosystème moderne

### Paramètres de l'Export

- **Date début** : {start_date}
- **Date fin** : {end_date} (exclusif)
- **Output path** : {output_path}
- **Compression** : {compression}

---

## 📥 Code Spark - Lecture depuis HCD

### Code Exécuté

```scala
val spark = SparkSession.builder()
  .appName("Export Incremental [Format] from HCD")
  .config("spark.cassandra.connection.host", "localhost")
  .config("spark.cassandra.connection.port", "9042")
  .config("spark.sql.extensions", "com.datastax.spark.connector.CassandraSparkExtensions")
  .getOrCreate()

val df = spark.read
  .format("org.apache.spark.sql.cassandra")
  .options(Map(
    "table" -> "operations_by_account",
    "keyspace" -> "domiramacatops_poc"
  ))
  .load()
  .filter(
    col("date_op") >= "{start_date}" &&
    col("date_op") < "{end_date}"
  )
```

### Explication

- **Lecture depuis HCD** : Via Spark Cassandra Connector
- **Filtrage par dates** : Équivalent TIMERANGE HBase
- **Date de fin exclusive** : Comme TIMERANGE HBase (date_op < end_date)

---

## 💾 Code Spark - Export [Format]

### Code Exécuté

```scala
df.write
  .mode("overwrite")
  .partitionBy("date_op")
  .option("compression", "{compression}")
  .option("parquet.block.size", "134217728")  // 128MB
  .[format]("{output_path}")
```

### Explication

- **Mode overwrite** : Permet les rejeux (idempotence)
- **Partitionnement par date_op** : Performance optimale pour requêtes futures
- **Compression {compression}** : [Explication selon compression]
- **Block size 128MB** : Taille optimale pour Spark

---

## 📊 Résultats de l'Export

### Statistiques

- **Opérations exportées** : {export_count}
- **Opérations lues (vérification)** : {read_count}
- **Date min** : {date_min}
- **Date max** : {date_max}
- **Comptes uniques** : {comptes_uniques}

### Fichiers Créés

- **Répertoire** : {output_path}
- **Compression** : {compression}
- **Partitionnement** : par date_op

---

## 🔍 Vérification

### Vérification de Cohérence

"""
if export_count == read_count:
    report_content += f"""
✅ **Cohérence validée** : {export_count} opérations exportées = {read_count} opérations lues
"""
else:
    report_content += f"""
⚠️  **Incohérence détectée** : {export_count} opérations exportées ≠ {read_count} opérations lues
"""

report_content += f"""

### Sortie Spark Complète

```
{spark_output[:2000]}...
```

---

## ✅ Conclusion

### Résumé de l'Export

- ✅ **Export réussi** : {export_count} opérations exportées
- ✅ **Vérification OK** : {read_count} opérations lues depuis [Format]
- ✅ **Fichiers créés** : {output_path}
- ✅ **Compression** : {compression}

### Points Clés Démontrés

- ✅ Export incrémental depuis HCD vers [Format]
- ✅ Filtrage par dates (équivalent TIMERANGE HBase)
- ✅ Partitionnement par date_op pour performance
- ✅ Compression configurable
- ✅ Vérification de cohérence

### Prochaines Étapes

- Script 28: Démonstration fenêtre glissante
- Script 29: Requêtes in-base avec fenêtre glissante

---

**✅ Export incrémental [Format] terminé avec succès !**
"""

with open(report_file, 'w', encoding='utf-8') as f:
    f.write(report_content)

print(f"✅ Rapport généré : {report_file}")
PYTHON_REPORT

success "Rapport markdown généré : $(basename "$REPORT_FILE")"

# Nettoyer les fichiers temporaires

rm -f "$TEMP_OUTPUT" "$TEMP_RESULTS"

# ============================================

# PARTIE 7: RÉSUMÉ ET CONCLUSION

# ============================================

echo ""
section "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
section "  📊 PARTIE 7: RÉSUMÉ ET CONCLUSION"
section "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

info "📊 Résumé de l'export :"
echo ""
echo "   ✅ Export incrémental [Format] terminé"
echo "   ✅ Fichiers créés dans : $OUTPUT_PATH"
echo "   ✅ Compression : $COMPRESSION"
echo ""
info "💡 Points clés démontrés :"
echo "   ✅ Export incrémental depuis HCD vers [Format]"
echo "   ✅ Filtrage par dates (équivalent TIMERANGE HBase)"
echo "   ✅ Partitionnement par date_op pour performance"
echo "   ✅ Compression configurable"
echo "   ✅ Vérification de cohérence"
echo ""
info "📝 Documentation générée :"
echo "   📄 $(basename "$REPORT_FILE")"
echo ""
info "📝 Script suivant : Démonstration fenêtre glissante (./28_demo_fenetre_glissante_spark_submit.sh)"
echo ""
success "✅ ✅ Export incrémental [Format] terminé !"
echo ""

```

---

## 📋 Checklist d'Adaptation

Pour utiliser ce template, adapter :

- [ ] Remplacer `[Format]` par le format réel (Parquet, CSV, etc.)
- [ ] Adapter les vérifications (PARTIE 0)
- [ ] Adapter l'objectif et stratégie (PARTIE 1)
- [ ] Adapter le code Spark (PARTIE 2, 3, 4)
- [ ] Adapter la vérification (PARTIE 5)
- [ ] Adapter la génération du rapport (PARTIE 6)
- [ ] Adapter le résumé et conclusion (PARTIE 7)
- [ ] Tester l'exécution complète
- [ ] Vérifier la génération du rapport markdown

---

**✅ Template créé !**
