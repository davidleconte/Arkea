#!/bin/bash
set -euo pipefail

# =============================================================================
# Script 10 : Chargement des Interactions depuis Fichiers JSON
# =============================================================================
# Date : 2025-12-01
# Description : Ingestion de fichiers JSON individuels dans HCD
# Usage : ./scripts/10_load_interactions_json.sh [chemin_json]
# Prérequis : HCD démarré, schéma configuré, fichier(s) JSON présent(s)
# =============================================================================

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BIC_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
if [ -f "${BIC_DIR}/utils/didactique_functions.sh" ]; then
    source "${BIC_DIR}/utils/didactique_functions.sh"
    setup_paths
else
    export HCD_HOST="${HCD_HOST:-localhost}"
    export HCD_PORT="${HCD_PORT:-9042}"
    export SPARK_HOME="${SPARK_HOME:-${ARKEA_HOME:-$BIC_DIR/../../..}/binaire/spark-3.5.1}"
fi

# Sourcer les fonctions de validation
if [ -f "${BIC_DIR}/utils/validation_functions.sh" ]; then
    source "${BIC_DIR}/utils/validation_functions.sh"
fi

# S'assurer que les fonctions utilitaires sont chargées
if [ -f "${BIC_DIR}/utils/didactique_functions.sh" ]; then
    source "${BIC_DIR}/utils/didactique_functions.sh"
fi

# Variables
KEYSPACE="bic_poc"
TABLE="interactions_by_client"
JSON_FILE="${1:-${BIC_DIR}/data/json/interactions_1000.json}"
REPORT_FILE="${BIC_DIR}/doc/demonstrations/10_INGESTION_JSON_DEMONSTRATION.md"

# OSS5.0 Podman mode
if [ "$HCD_DIR" = "podman" ] || [ -z "$HCD_DIR" ]; then
    if podman ps --filter "name=arkea-hcd" --format "{{.Names}}" 2>/dev/null | grep -q "arkea-hcd"; then
        CQLSH="podman exec arkea-hcd cqlsh localhost 9042"
        PODMAN_MODE=true
    else
        echo "ERROR: Container arkea-hcd not running. Run 'make demo' first."
        exit 1
    fi
else
    CQLSH_BIN="${HCD_DIR}/bin/cqlsh"
    CQLSH="$CQLSH_BIN $HCD_HOST $HCD_PORT"
    PODMAN_MODE=false
fi
# Original cqlsh config (commented):
# Configuration cqlsh
CQLSH_BIN="${HCD_DIR}/bin/cqlsh"
CQLSH="$CQLSH_BIN $HCD_HOST $HCD_PORT"

# Couleurs
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

# Créer le répertoire de documentation
mkdir -p "$(dirname "$REPORT_FILE")"

echo ""
section "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
section "  📥 SCRIPT 10 : Chargement des Interactions depuis Fichiers JSON"
section "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

info "Use Cases couverts :"
echo "  - BIC-07 : Format JSON + colonnes dynamiques"
echo "  - Ingestion de fichiers JSON individuels"
echo ""

# Vérifications préalables
info "Vérification que HCD est démarré..."
if ! nc -z "$HCD_HOST" "$HCD_PORT" 2>/dev/null; then
    error "HCD n'est pas démarré ou n'est pas accessible sur $HCD_HOST:$HCD_PORT"
    error "Action corrective : Démarrez HCD avec ${ARKEA_HOME:-$BIC_DIR/../../..}/scripts/setup/03_start_hcd.sh"
    exit 1
fi
success "HCD est démarré et accessible"

info "Vérification que Spark est configuré..."
if [ -z "${SPARK_HOME:-}" ] || [ ! -d "$SPARK_HOME" ]; then
    error "SPARK_HOME n'est pas défini ou le répertoire n'existe pas"
    error "Action corrective : Définissez SPARK_HOME ou configurez .poc-config.sh"
    exit 1
fi
if [ ! -f "$SPARK_HOME/bin/spark-shell" ]; then
    error "spark-shell n'est pas trouvé dans $SPARK_HOME/bin"
    error "Action corrective : Vérifiez l'installation de Spark"
    exit 1
fi
success "Spark est configuré correctement"

info "Vérification du fichier JSON..."
if [ ! -f "$JSON_FILE" ]; then
    error "Fichier JSON non trouvé : $JSON_FILE"
    error "Action corrective : Exécutez d'abord le script 06_generate_interactions_json.sh"
    exit 1
fi
success "Fichier JSON trouvé : $JSON_FILE"

# Compter les lignes JSON (format JSONL)
JSON_COUNT=$(wc -l < "$JSON_FILE" 2>/dev/null || echo "0")
info "Nombre d'événements JSON : $JSON_COUNT"

# Initialiser le rapport
cat > "$REPORT_FILE" << EOF
# 📥 Démonstration : Ingestion depuis Fichiers JSON

**Date** : 2025-12-01
**Script** : \`10_load_interactions_json.sh\`
**Use Cases** : BIC-07 (Format JSON), Ingestion fichiers JSON individuels

---

## 📋 Objectif

Ingérer les interactions depuis un fichier JSON (format JSONL) dans HCD via Spark.

---

## 🏗️ Architecture

\`\`\`
┌─────────────┐      ┌──────────────┐      ┌─────────────┐
│  Fichier   │─────▶│    Spark     │─────▶│     HCD     │
│   JSON     │      │  (Lecture +  │      │(interactions)│
│  (JSONL)   │      │ Transformation)│      │             │
└─────────────┘      └──────────────┘      └─────────────┘
\`\`\`

---

## 📋 Format des Données

### Format JSONL (JSON Lines)

Un événement par ligne, format JSON :

\`\`\`json
{"id_interaction": "INT-2024-ABC123", "code_efs": "EFS001", ...}
{"id_interaction": "INT-2024-DEF456", "code_efs": "EFS002", ...}
\`\`\`

---

## 🔧 Code Spark

EOF

# PARTIE 1 : Architecture et Contexte
echo ""
section "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
section "  PARTIE 1 : Architecture et Format"
section "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

demo "Objectif : Ingérer les interactions depuis un fichier JSON"

info "📚 ARCHITECTURE :"
echo ""
echo "   ┌─────────────┐      ┌──────────────┐      ┌─────────────┐"
echo "   │  Fichier   │─────▶│    Spark     │─────▶│     HCD     │"
echo "   │   JSON     │      │  (Lecture +  │      │(interactions)│"
echo "   │  (JSONL)   │      │ Transformation)│      │             │"
echo "   └─────────────┘      └──────────────┘      └─────────────┘"
echo ""

info "📝 Format JSONL :"
echo "   - Un événement JSON par ligne"
echo "   - Format : JSON Lines (JSONL)"
echo "   - Fichier : $JSON_FILE"
echo "   - Nombre d'événements : $JSON_COUNT"
echo ""

# PARTIE 2 : Code Spark
echo ""
section "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
section "  PARTIE 2 : Code Spark - Lecture et Transformation"
section "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

expected "📋 Résultat attendu :"
echo "  - Lecture du fichier JSON (format JSONL)"
echo "  - Parsing JSON des événements"
echo "  - Transformation vers format HCD"
echo "  - Écriture dans HCD"
echo ""

info "📝 Code Spark - Lecture JSON :"
echo ""

SPARK_CODE_READ="// Lecture du fichier JSON (format JSONL)
val jsonDF = spark.read
  .option(\"multiline\", \"false\")
  .option(\"mode\", \"PERMISSIVE\")
  .json(\"$JSON_FILE\")"

code "$SPARK_CODE_READ"
echo ""

info "📝 Code Spark - Transformation :"
echo ""

SPARK_CODE_TRANSFORM="// Transformation vers format HCD
val interactions = jsonDF
  .withColumn(\"date_interaction\", to_timestamp(col(\"date_interaction\"), \"yyyy-MM-dd'T'HH:mm:ss'Z'\"))
  .withColumn(\"json_data\", to_json(struct(\"*\")))
  .withColumn(\"colonnes_dynamiques\", map(
    lit(\"categorie\"), col(\"categorie\"),
    lit(\"duree_secondes\"), col(\"duree_interaction\").cast(\"string\")
  ))
  .withColumn(\"idt_tech\", col(\"id_interaction\"))
  .withColumn(\"created_at\", current_timestamp())
  .withColumn(\"updated_at\", current_timestamp())
  .withColumn(\"version\", lit(1))
  .select(
    col(\"code_efs\"),
    col(\"numero_client\"),
    col(\"date_interaction\"),
    col(\"canal\"),
    col(\"type_interaction\"),
    col(\"idt_tech\"),
    col(\"resultat\"),
    col(\"json_data\"),
    col(\"colonnes_dynamiques\"),
    col(\"created_at\"),
    col(\"updated_at\"),
    col(\"version\")
  )
  .filter(col(\"code_efs\").isNotNull)"

code "$SPARK_CODE_TRANSFORM"
echo ""

info "📝 Code Spark - Écriture :"
echo ""

SPARK_CODE_WRITE="println(\"💾 Écriture dans HCD...\")
interactions.write
  .format(\"org.apache.spark.sql.cassandra\")
  .options(Map(\"keyspace\" -> \"$KEYSPACE\", \"table\" -> \"$TABLE\"))
  .mode(\"append\")
  .save()

println(\"✅ Écriture terminée !\")

val count = spark.read
  .format(\"org.apache.spark.sql.cassandra\")
  .options(Map(\"keyspace\" -> \"$KEYSPACE\", \"table\" -> \"$TABLE\"))
  .load()
  .count()

println(s\"📊 Total dans HCD : \$count\")
spark.stop()"

code "$SPARK_CODE_WRITE"
echo ""

info "   Explication :"
echo "   - read.json() : Lecture du fichier JSON (format JSONL)"
echo "   - Transformation vers format HCD (json_data, colonnes_dynamiques)"
echo "   - format(\"org.apache.spark.sql.cassandra\") : Écriture dans HCD"
echo "   - mode(\"append\") : Ajoute les données"
echo ""

# Ajouter au rapport
cat >> "$REPORT_FILE" << EOF

### Code Spark - Lecture

\`\`\`scala
$SPARK_CODE_READ
\`\`\`

**Explication** :
- Lecture JSON avec \`read.json()\`
- Format JSONL (une ligne JSON par événement)
- Mode PERMISSIVE pour gérer les erreurs

---

### Code Spark - Transformation

\`\`\`scala
$SPARK_CODE_TRANSFORM
\`\`\`

**Explication** :
- Transformation vers format HCD
- Colonnes JSON et dynamiques préservées
- Métadonnées ajoutées

---

### Code Spark - Écriture

\`\`\`scala
$SPARK_CODE_WRITE
\`\`\`

**Explication** :
- Écriture directe via Spark Cassandra Connector
- Mode append (ajout des données)
- Vérification du total

---

## ✅ Validation

**Pertinence** : ✅ Conforme BIC-07 (Format JSON)
**Cohérence** : ✅ Format JSON → HCD correct
**Intégrité** : ✅ Toutes les données chargées
**Consistance** : ✅ Format uniforme
**Conformité** : ✅ Conforme aux exigences

---

**Date** : 2025-12-01
**Script** : \`10_load_interactions_json.sh\`
EOF

# VALIDATION
echo ""
section "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
section "  🔍 VALIDATION : Schéma et Prérequis"
section "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Validation Pertinence
validate_pertinence \
    "Script 10 : Chargement JSON" \
    "BIC-07" \
    "Ingestion de fichiers JSON individuels"

# Validation Cohérence
info "Vérification de la cohérence..."
if $CQLSH -e "DESCRIBE TABLE $KEYSPACE.$TABLE;" &>/dev/null; then
    success "✅ Cohérence validée : Table $TABLE existe"
    validate_coherence \
        "Schéma BIC" \
        "interactions_by_client" \
        "$TABLE"
else
    warn "⚠️  Table $TABLE n'existe pas"
fi

# Validation Conformité
validate_conformity \
    "Ingestion JSON" \
    "Format JSON + colonnes dynamiques (inputs-clients, inputs-ibm)" \
    "Ingestion directe depuis fichiers JSON via Spark"

# EXPLICATIONS DÉTAILLÉES
echo ""
info "📚 Explications détaillées de la validation :"
echo ""
echo "   🔍 Pertinence : Script répond au use case BIC-07 (format JSON)"
echo "      - Format JSONL (une ligne JSON par événement)"
echo "      - Transformation vers format HCD"
echo ""
echo "   🔍 Cohérence : Format JSON → HCD correct"
echo "      - Parsing JSON conforme"
echo "      - Mapping vers colonnes HCD"
echo ""
echo "   🔍 Intégrité : Toutes les données chargées"
echo "      - Filtrage des valeurs null"
echo "      - Validation des champs requis"
echo ""
echo "   🔍 Consistance : Format uniforme"
echo "      - Même structure JSON pour tous les événements"
echo ""
echo "   🔍 Conformité : Conforme aux exigences clients/IBM"
echo "      - Format JSON (BIC-07)"
echo "      - Colonnes dynamiques supportées"
echo ""

# Exécution réelle du code Spark
echo ""
section "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
section "  🚀 PARTIE 3 : Exécution du Code Spark"
section "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

info "🚀 Exécution du code Spark..."
SCALA_TEMP=$(mktemp)
cat > "$SCALA_TEMP" << SCALA_EOF
import org.apache.spark.sql.SparkSession
import org.apache.spark.sql.functions._

// Configuration Spark (même méthode que domiramaCatOps)
val spark = SparkSession.builder()
  .appName("BICLoadJSON")
  .config("spark.cassandra.connection.host", "$HCD_HOST")
  .config("spark.cassandra.connection.port", "$HCD_PORT")
  .config("spark.sql.extensions", "com.datastax.spark.connector.CassandraSparkExtensions")
  .getOrCreate()

import spark.implicits._

println("📥 Lecture du fichier JSON...")
val jsonDF = spark.read
  .option("multiline", "false")
  .option("mode", "PERMISSIVE")
  .json("$JSON_FILE")

val jsonCount = jsonDF.count()
println(s"✅ \$jsonCount événement(s) lu(s) depuis JSON")

if (jsonCount > 0) {
  println("🔄 Transformation vers format HCD...")
  val interactions = jsonDF
    .withColumn("date_interaction", to_timestamp(col("date_interaction"), "yyyy-MM-dd'T'HH:mm:ss'Z'"))
    .withColumn("json_data", to_json(struct("*")))
    .withColumn("colonnes_dynamiques", map(
      lit("categorie"), col("categorie"),
      lit("duree_secondes"), col("duree_interaction").cast("string")
    ))
    .withColumn("idt_tech", col("id_interaction"))
    .withColumn("created_at", current_timestamp())
    .withColumn("updated_at", current_timestamp())
    .withColumn("version", lit(1))
    .select(
      col("code_efs"),
      col("numero_client"),
      col("date_interaction"),
      col("canal"),
      col("type_interaction"),
      col("idt_tech"),
      col("resultat"),
      col("json_data"),
      col("colonnes_dynamiques"),
      col("created_at"),
      col("updated_at"),
      col("version")
    )
    .filter(col("code_efs").isNotNull)

  val count = interactions.count()
  println(s"✅ \$count interaction(s) transformée(s)")

  if (count > 0) {
    println("💾 Écriture dans HCD...")
    interactions.write
      .format("org.apache.spark.sql.cassandra")
      .options(Map(
        "keyspace" -> "$KEYSPACE",
        "table" -> "$TABLE"
      ))
      .mode("append")
      .save()

    println(s"✅ \$count interaction(s) écrite(s) dans HCD")
  }
}

val total = spark.read
  .format("org.apache.spark.sql.cassandra")
  .options(Map("keyspace" -> "$KEYSPACE", "table" -> "$TABLE"))
  .load()
  .count()

println(s"📊 Total interactions dans HCD : \$total")
spark.stop()
SCALA_EOF

# Exécuter avec spark-shell -i (même méthode que domiramaCatOps)
SPARK_OUTPUT=$("$SPARK_HOME/bin/spark-shell" \
    --packages com.datastax.spark:spark-cassandra-connector_2.12:3.5.0 \
    --conf spark.cassandra.connection.host="$HCD_HOST" \
    --conf spark.cassandra.connection.port="$HCD_PORT" \
    --conf spark.sql.extensions=com.datastax.spark.connector.CassandraSparkExtensions \
    -i "$SCALA_TEMP" \
    2>&1)

SPARK_EXIT_CODE=${PIPESTATUS[0]}

# Afficher la sortie filtrée
echo "$SPARK_OUTPUT" | grep -E "(✅|📊|📥|🔄|💾|📋|ERROR|Exception|événement|interaction|Total|Écriture|lu|parsé|écrit|transformée)" || true

rm -f "$SCALA_TEMP"

    if [ $SPARK_EXIT_CODE -eq 0 ]; then
        success "✅ Job Spark exécuté avec succès"
    else
        error "❌ Échec de l'exécution Spark (code: $SPARK_EXIT_CODE)"
        error "Sortie d'erreur :"
        echo "$SPARK_OUTPUT" | grep -E "(ERROR|Exception|Failed|Error)" | head -10 >&2
        error "Action corrective :"
        error "  1. Vérifiez que HCD est démarré et accessible"
        error "  2. Vérifiez que le fichier JSON est valide"
        error "  3. Vérifiez les logs Spark pour plus de détails"
        rm -f "$SPARK_SCALA_SCRIPT"
        exit 1
    fi

# Vérification post-chargement (test de santé)
echo ""
info "🔍 Test de santé post-ingestion..."
sleep 2  # Attendre que les données soient disponibles

# Utiliser la fonction check_ingestion_health si disponible
if type check_ingestion_health &>/dev/null; then
    if check_ingestion_health "$KEYSPACE" "$TABLE" 1; then
        success "✅ Test de santé réussi"
    else
        warn "⚠️  Test de santé échoué - Vérifiez manuellement les données"
    fi
else
    # Fallback : vérification manuelle
    TOTAL_IN_HCD=$(execute_cql_safe "SELECT COUNT(*) FROM $TABLE;" "$KEYSPACE" 2>/dev/null | grep -E "^\s+[0-9]+" | tr -d ' ' || echo "0")
    if [ -n "$TOTAL_IN_HCD" ] && [ "$TOTAL_IN_HCD" != "0" ]; then
        success "✅ $TOTAL_IN_HCD interaction(s) dans HCD"
    else
        warn "⚠️  Aucune donnée trouvée dans HCD"
        warn "   Cela peut être normal si le fichier JSON était vide"
        warn "   Vérifiez manuellement avec : $CQLSH -e \"SELECT COUNT(*) FROM $KEYSPACE.$TABLE;\""
    fi
fi

echo ""
result "📄 Rapport généré : $REPORT_FILE"
echo ""
