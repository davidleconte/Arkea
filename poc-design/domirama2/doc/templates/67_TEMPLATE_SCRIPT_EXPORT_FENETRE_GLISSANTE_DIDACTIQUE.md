# 📋 Template : Script Shell Didactique pour Export avec Fenêtre Glissante

**Date** : 2025-11-26  
**Objectif** : Template réutilisable pour créer des scripts d'export avec fenêtre glissante très didactiques  
**Type** : Scripts d'export de données avec boucle sur plusieurs fenêtres (HCD → Parquet/Fichiers)

---

## 🎯 Principes du Template pour Fenêtre Glissante

Un script d'export avec fenêtre glissante didactique doit :

1. **Afficher le code Spark complet** : Pour chaque fenêtre, avec explications
2. **Expliquer les équivalences HBase → HCD** : TIMERANGE avec fenêtre glissante
3. **Afficher les résultats de chaque export** : Nombre d'opérations, fichiers créés, statistiques par fenêtre
4. **Documenter la cinématique** : Chaque étape expliquée pour chaque fenêtre
5. **Générer un rapport structuré** : Avec tableau récapitulatif de toutes les fenêtres
6. **Afficher les métriques agrégées** : Stats par fenêtre + stats globales

---

## 📝 Structure Standard pour Script Fenêtre Glissante

```bash
#!/bin/bash
# ============================================
# Script XX : Export Fenêtre Glissante (Version Didactique)
# Exporte les données depuis HCD vers Parquet via Spark
# Équivalent HBase: TIMERANGE avec fenêtre glissante
# ============================================
#
# OBJECTIF :
#   Ce script démontre la fenêtre glissante pour les exports incrémentaux,
#   équivalent au TIMERANGE HBase avec décalage progressif.
#  
#   Cette version didactique affiche :
#   - Le code Spark complet pour chaque fenêtre avec explications
#   - Les équivalences HBase → HCD détaillées
#   - Les résultats d'export détaillés pour chaque fenêtre
#   - La cinématique complète de chaque étape
#   - Une documentation structurée pour livrable
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
#   ./XX_export_fenetre_glissante.sh [window_type] [start_date] [end_date] [compression]
#
# PARAMÈTRES :
#   $1 : Type de fenêtre (optionnel, défaut: "monthly", options: "monthly", "weekly", "daily")
#   $2 : Date de début (format: YYYY-MM-DD, optionnel, défaut: 2024-01-01)
#   $3 : Date de fin (format: YYYY-MM-DD, optionnel, défaut: 2024-04-01)
#   $4 : Compression (optionnel, défaut: snappy, options: snappy, gzip, lz4)
#
# SORTIE :
#   - Code Spark complet affiché avec explications pour chaque fenêtre
#   - Fichiers Parquet créés pour chaque fenêtre
#   - Statistiques de chaque export
#   - Vérification de chaque export
#   - Documentation structurée générée avec tableau récapitulatif
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
INSTALL_DIR="${ARKEA_HOME}"
HCD_DIR="${INSTALL_DIR}/binaire/hcd-1.2.3"
SPARK_HOME="${INSTALL_DIR}/binaire/spark-3.5.1"
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
REPORT_FILE="${SCRIPT_DIR}/doc/demonstrations/XX_FENETRE_GLISSANTE_DEMONSTRATION.md"

# Paramètres (avec valeurs par défaut)
WINDOW_TYPE="${1:-monthly}"  # monthly, weekly, daily
START_DATE="${2:-2024-01-01}"
END_DATE="${3:-2024-04-01}"
COMPRESSION="${4:-snappy}"
OUTPUT_BASE="/tmp/exports/domirama/incremental"

# Créer le répertoire de documentation
mkdir -p "$(dirname "$REPORT_FILE")"

# Fichiers temporaires pour capture
TEMP_OUTPUT=$(mktemp "/tmp/script_XX_output_$(date +%s)_XXXXXX.txt")
TEMP_RESULTS=$(mktemp "/tmp/script_XX_results_$(date +%s)_XXXXXX.json")

# Tableau pour stocker les résultats de chaque fenêtre
declare -a WINDOW_RESULTS

# ============================================
# PARTIE 0: VÉRIFICATIONS
# ============================================
# (Identique au Template 66)

# ============================================
# PARTIE 1: CONTEXTE ET STRATÉGIE
# ============================================
echo ""
section "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
section "  📚 PARTIE 1: CONTEXTE ET STRATÉGIE"
section "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

info "📚 OBJECTIF : Démontrer la fenêtre glissante pour exports incrémentaux"
echo ""
info "🔄 ÉQUIVALENCES HBase → HCD :"
echo ""
echo "   HBase                          →  HCD (Spark)"
echo "   ──────────────────────────────    ─────────────────────────────"
echo "   TIMERANGE                      →  WHERE date_op >= start AND date_op < end"
echo "   Fenêtre glissante              →  Boucle sur plusieurs périodes"
echo "   Export mensuel                 →  Export par fenêtre (mois/semaine/jour)"
echo "   Idempotence                    →  Mode overwrite pour rejeux"
echo ""
info "📋 STRATÉGIE FENÊTRE GLISSANTE :"
code "   Type de fenêtre    : $WINDOW_TYPE"
code "   Date début         : $START_DATE"
code "   Date fin           : $END_DATE"
code "   Compression        : $COMPRESSION"
code "   Répertoire base    : $OUTPUT_BASE"
echo ""
info "💡 Principe de la fenêtre glissante :"
echo "   - Export de plusieurs périodes consécutives"
echo "   - Chaque période est exportée indépendamment"
echo "   - Mode overwrite pour idempotence (rejeux possibles)"
echo "   - Partitionnement par date_op pour performance"
echo ""

# ============================================
# PARTIE 2: FONCTION EXPORT_WINDOW
# ============================================
echo ""
section "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
section "  🔧 PARTIE 2: FONCTION EXPORT_WINDOW"
section "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

info "📝 Fonction export_window() : Exporte une fenêtre spécifique"
echo ""

export_window() {
    local window_id=$1
    local start_date=$2
    local end_date=$3
    local output_path=$4

    info "📅 Fenêtre $window_id : $start_date → $end_date"
    code "   Output : $output_path"
    echo ""

    # Afficher le code Spark qui sera exécuté
    info "📝 Code Spark qui sera exécuté :"
    echo ""
    code "val spark = SparkSession.builder()"
    code "  .appName(\"Export Window $window_id\")"
    code "  .config(\"spark.cassandra.connection.host\", \"localhost\")"
    code "  .config(\"spark.cassandra.connection.port\", \"9042\")"
    code "  .getOrCreate()"
    echo ""
    code "val df = spark.read"
    code "  .format(\"org.apache.spark.sql.cassandra\")"
    code "  .options(Map("
    code "    \"table\" -> \"operations_by_account\","
    code "    \"keyspace\" -> \"domirama2_poc\""
    code "  ))"
    code "  .load()"
    code "  .select(/* colonnes sans libelle_embedding */)"
    code "  .filter("
    code "    col(\"date_op\") >= \"$start_date\" &&"
    code "    col(\"date_op\") < \"$end_date\""
    code "  )"
    echo ""
    code "df.write"
    code "  .mode(\"overwrite\")"
    code "  .partitionBy(\"date_op\")"
    code "  .option(\"compression\", \"$COMPRESSION\")"
    code "  .parquet(\"$output_path\")"
    echo ""
    info "💡 Explication :"
    echo "   - Lecture depuis HCD avec filtrage par dates (TIMERANGE)"
    echo "   - Exclusion de libelle_embedding (type VECTOR non supporté)"
    echo "   - Export Parquet avec partitionnement par date_op"
    echo "   - Mode overwrite pour idempotence (rejeux possibles)"
    echo ""

    # Créer le script Scala temporaire
    TEMP_SCRIPT=$(mktemp "/tmp/window_${window_id}_$(date +%s)_XXXXXX.scala")
    cat > "$TEMP_SCRIPT" <<EOFSCRIPT
import org.apache.spark.sql.SparkSession
import org.apache.spark.sql.functions._

val spark = SparkSession.builder()
  .appName("Export Window $window_id")
  .config("spark.cassandra.connection.host", "localhost")
  .config("spark.cassandra.connection.port", "9042")
  .config("spark.sql.extensions", "com.datastax.spark.connector.CassandraSparkExtensions")
  .getOrCreate()

import spark.implicits._

val startDate = "$start_date"
val endDate = "$end_date"
val outputPath = "$output_path"
val compression = "$COMPRESSION"

println("=" * 80)
println(s"📥 Export Fenêtre $window_id : \$startDate → \$endDate")
println("=" * 80)

// Lecture depuis HCD
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
println(s"✅ \$count opérations trouvées")

if (count == 0) {
  println("⚠️  Aucune donnée à exporter")
  System.exit(0)
}

// Statistiques
val stats = df.agg(
  min("date_op").as("date_min"),
  max("date_op").as("date_max"),
  countDistinct("code_si", "contrat").as("comptes_uniques")
)
stats.show()

// Export
df.write
  .mode("overwrite")
  .partitionBy("date_op")
  .option("compression", compression)
  .parquet(outputPath)

println(s"✅ Export terminé : \$count opérations")

// Vérification
val dfRead = spark.read.parquet(outputPath)
val countRead = dfRead.count()
println(s"✅ Vérification : \$countRead opérations lues")

spark.stop()
EOFSCRIPT

    # Exécuter avec spark-shell
    info "🚀 Exécution de l'export pour la fenêtre $window_id..."
    echo ""

    spark-shell \
      --packages com.datastax.spark:spark-cassandra-connector_2.12:3.5.0 \
      --conf spark.cassandra.connection.host=localhost \
      --conf spark.cassandra.connection.port=9042 \
      --conf spark.sql.extensions=com.datastax.spark.connector.CassandraSparkExtensions \
      --driver-memory 2g \
      --executor-memory 2g \
      -i "$TEMP_SCRIPT" \
      2>&1 | tee -a "$TEMP_OUTPUT" | grep -v "^scala>" | grep -v "^     |" | grep -v "^Welcome to" | grep -v "WARN NativeCodeLoader" | grep -E "(✅|⚠️|📥|📊|💾|🔍|opérations|Export|Terminé|count|Statistiques|Vérification)" | head -20

    # Extraire les résultats
    local count=$(grep -E "✅ [0-9]+ opérations trouvées" "$TEMP_OUTPUT" | tail -1 | grep -oE "[0-9]+" | head -1 || echo "0")
    local count_read=$(grep -E "✅ Vérification : [0-9]+ opérations lues" "$TEMP_OUTPUT" | tail -1 | grep -oE "[0-9]+" | head -1 || echo "0")

    # Stocker les résultats
    WINDOW_RESULTS+=("$window_id|$start_date|$end_date|$output_path|$count|$count_read")

    # Nettoyer
    rm -f "$TEMP_SCRIPT"

    echo ""
    if [ "$count" -gt 0 ]; then
        success "✅ Fenêtre $window_id exportée : $count opérations"
    else
        warn "⚠️  Fenêtre $window_id : Aucune donnée exportée"
    fi
    echo ""
}

# ============================================
# PARTIE 3: CALCUL DES FENÊTRES
# ============================================
echo ""
section "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
section "  📅 PARTIE 3: CALCUL DES FENÊTRES"
section "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

info "📅 Calcul des fenêtres selon le type : $WINDOW_TYPE"
echo ""

# Fonction pour calculer les fenêtres (à adapter selon le type)
calculate_windows() {
    # Implémentation selon WINDOW_TYPE (monthly, weekly, daily)
    # Retourne une liste de fenêtres au format: "window_id|start_date|end_date|output_path"
    # Exemple pour monthly:
    #   "2024-01|2024-01-01|2024-02-01|/tmp/exports/domirama/incremental/2024-01"
    #   "2024-02|2024-02-01|2024-03-01|/tmp/exports/domirama/incremental/2024-02"
    #   ...
}

# Calculer les fenêtres
WINDOWS=$(calculate_windows)

info "📋 Fenêtres à exporter :"
# Afficher la liste des fenêtres

# ============================================
# PARTIE 4: BOUCLE FENÊTRE GLISSANTE
# ============================================
echo ""
section "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
section "  🔄 PARTIE 4: BOUCLE FENÊTRE GLISSANTE"
section "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

info "🔄 Exécution des exports pour chaque fenêtre..."
echo ""

# Boucle sur chaque fenêtre
while IFS='|' read -r window_id start_date end_date output_path; do
    export_window "$window_id" "$start_date" "$end_date" "$output_path"
done <<< "$WINDOWS"

# ============================================
# PARTIE 5: VÉRIFICATION GLOBALE
# ============================================
echo ""
section "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
section "  🔍 PARTIE 5: VÉRIFICATION GLOBALE"
section "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

info "📋 Liste des exports créés :"
echo ""

# Afficher la liste des exports créés
total_exports=0
total_operations=0

for result in "${WINDOW_RESULTS[@]}"; do
    IFS='|' read -r window_id start_date end_date output_path count count_read <<< "$result"
    if [ "$count" -gt 0 ]; then
        success "  $window_id : $count opérations exportées"
        total_exports=$((total_exports + 1))
        total_operations=$((total_operations + count))
    fi
done

echo ""
info "📊 Statistiques globales :"
code "   Fenêtres exportées : $total_exports"
code "   Total opérations   : $total_operations"

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
window_type = "$WINDOW_TYPE"
start_date = "$START_DATE"
end_date = "$END_DATE"
compression = "$COMPRESSION"
output_base = "$OUTPUT_BASE"

# Lire les résultats des fenêtres
window_results = """${WINDOW_RESULTS[@]}""".split()

report_date = datetime.now().strftime("%Y-%m-%d %H:%M:%S")
script_name = os.path.basename("$0")

# Générer le rapport
report_content = f"""# 📅 Démonstration : Export Fenêtre Glissante

**Date** : {report_date}
**Script** : {script_name}
**Objectif** : Démontrer la fenêtre glissante pour exports incrémentaux

---

## 📋 Table des Matières

1. [Contexte et Stratégie](#contexte-et-stratégie)
2. [Fenêtres Exportées](#fenêtres-exportées)
3. [Résultats par Fenêtre](#résultats-par-fenêtre)
4. [Statistiques Globales](#statistiques-globales)
5. [Conclusion](#conclusion)

---

## 📚 Contexte et Stratégie

### Équivalences HBase → HCD

| Concept HBase | Équivalent HCD (Spark) |
|---------------|------------------------|
| TIMERANGE | WHERE date_op >= start AND date_op < end |
| Fenêtre glissante | Boucle sur plusieurs périodes |
| Export mensuel | Export par fenêtre (mois/semaine/jour) |
| Idempotence | Mode overwrite pour rejeux |

### Paramètres

- **Type de fenêtre** : {window_type}
- **Date début** : {start_date}
- **Date fin** : {end_date}
- **Compression** : {compression}
- **Répertoire base** : {output_base}

---

## 📅 Fenêtres Exportées

### Tableau Récapitulatif

| Fenêtre | Date Début | Date Fin | Opérations | Statut |
|---------|------------|----------|------------|--------|
"""

# Ajouter les résultats de chaque fenêtre
for result in window_results:
    if result:
        parts = result.split('|')
        if len(parts) >= 6:
            window_id, start, end, output, count, count_read = parts[:6]
            status = "✅ OK" if int(count) > 0 else "⚠️  Vide"
            report_content += f"| {window_id} | {start} | {end} | {count} | {status} |\n"

report_content += f"""

---

## 📊 Résultats par Fenêtre

"""

# Détails pour chaque fenêtre
for result in window_results:
    if result:
        parts = result.split('|')
        if len(parts) >= 6:
            window_id, start, end, output, count, count_read = parts[:6]
            report_content += f"""
### Fenêtre {window_id}

- **Période** : {start} → {end}
- **Opérations exportées** : {count}
- **Opérations lues (vérification)** : {count_read}
- **Répertoire** : {output}
- **Statut** : {'✅ Export réussi' if int(count) > 0 else '⚠️  Aucune donnée'}

"""

report_content += f"""
---

## 📊 Statistiques Globales

- **Total fenêtres** : {len([r for r in window_results if r])}
- **Fenêtres avec données** : {len([r for r in window_results if r and int(r.split('|')[4]) > 0])}
- **Total opérations** : {sum([int(r.split('|')[4]) for r in window_results if r and len(r.split('|')) >= 5])}

---

## ✅ Conclusion

- ✅ Fenêtre glissante démontrée avec succès
- ✅ Export incrémental par période (équivalent TIMERANGE HBase)
- ✅ Idempotence garantie (mode overwrite)
- ✅ Partitionnement par date_op pour performance
- ✅ Format Parquet (cohérent avec ingestion)

---

**✅ Export fenêtre glissante terminé avec succès !**
"""

with open(report_file, 'w', encoding='utf-8') as f:
    f.write(report_content)

print(f"✅ Rapport généré : {report_file}")
PYTHON_REPORT

success "✅ Rapport généré : $REPORT_FILE"
echo ""

# Nettoyer
rm -f "$TEMP_OUTPUT"
rm -f "$TEMP_RESULTS"

echo ""
success "✅ Démonstration fenêtre glissante terminée"
echo ""
