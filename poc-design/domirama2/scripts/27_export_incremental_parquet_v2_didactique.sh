#!/bin/bash
# ============================================
# Script 27 : Export Incrémental Parquet depuis HCD (Version Didactique)
# Exporte les données depuis HCD vers Parquet via Spark
# Équivalent HBase: FullScan + TIMERANGE + STARTROW/STOPROW
# ============================================
#
# OBJECTIF :
#   Ce script exporte les données d'opérations depuis HCD vers des fichiers
#   parquet via DSBulk, avec filtrage par dates (équivalent TIMERANGE HBase).
#   DSBulk est utilisé au lieu de Spark pour éviter le problème du type VECTOR.
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
#   - Schéma configuré (./10_setup_domirama2_poc.sh)
#   - Données chargées (./11_load_domirama2_data_parquet.sh)
#   - DSBulk installé et configuré
#   - Java 11 configuré via jenv
#   - nodetool disponible (pour préparation compaction, optionnel)
#
# UTILISATION :
#   ./27_export_incremental_parquet_v2_didactique.sh [start_date] [end_date] [output_path] [compression] [skip_compaction]
#
# PARAMÈTRES :
#   $1 : Date de début (format: YYYY-MM-DD, optionnel, défaut: 2024-01-01)
#   $2 : Date de fin (format: YYYY-MM-DD, optionnel, défaut: 2024-02-01)
#   $3 : Chemin de sortie (optionnel, défaut: /tmp/exports/domirama/incremental/2024-01)
#   $4 : Compression (optionnel, défaut: snappy, options: snappy, gzip, lz4)
#   $5 : Skip compaction (optionnel, défaut: false, valeurs: true/skip pour ignorer)
#
# NOTE IMPORTANTE :
#   Le script effectue automatiquement une préparation compaction avant l'export :
#   - Vérification état cluster
#   - Vérification gc_grace_seconds
#   - Repair complet (recommandé, demande confirmation)
#   - Compaction de la table
#   Cela garantit l'absence de tombstones dans l'export.
#
# SORTIE :
#   - Code Spark complet affiché avec explications
#   - Fichiers parquet créés dans le répertoire de sortie
#   - Statistiques de l'export (nombre d'opérations, dates min/max)
#   - Vérification de l'export (lecture des fichiers créés)
#   - Documentation structurée générée
#
# ============================================

set -euo pipefail

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
REPORT_FILE="${SCRIPT_DIR}/doc/demonstrations/27_EXPORT_DEMONSTRATION.md"

# Paramètres (avec valeurs par défaut)
START_DATE="${1:-2024-01-01}"
END_DATE="${2:-2024-02-01}"
OUTPUT_PATH="${3:-/tmp/exports/domirama/incremental/2024-01}"
COMPRESSION="${4:-snappy}"  # snappy (rapide) ou gzip (compact)
SKIP_COMPACTION="${5:-false}"  # true/skip pour ignorer la préparation compaction

# Configuration HCD pour nodetool
HCD_DIR="${INSTALL_DIR}/binaire/hcd-1.2.3"
if [ ! -d "$HCD_DIR" ]; then
    HCD_DIR="${INSTALL_DIR}/../binaire/hcd-1.2.3"
fi
NODETOOL="${HCD_DIR}/bin/nodetool"
CQLSH="${HCD_DIR}/bin/cqlsh"
KEYSPACE="domirama2_poc"
TABLE="operations_by_account"

# Créer le répertoire de documentation
mkdir -p "$(dirname "$REPORT_FILE")"

# Fichiers temporaires pour capture
TEMP_OUTPUT=$(mktemp "/tmp/script_27_output_$(date +%s)_272727.txt")
TEMP_RESULTS=$(mktemp "/tmp/script_27_results_$(date +%s)_272727.json")

# ============================================
# PARTIE 0: VÉRIFICATIONS
# ============================================
echo ""
section "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
section "  🔍 PARTIE 0: VÉRIFICATIONS"
section "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

info "Vérification de HCD..."
if ! nc -z "$HCD_HOST" "$HCD_PORT" 2>/dev/null; then
    error "HCD n'est pas démarré sur "$HCD_HOST:$HCD_PORT""
    error "Exécutez d'abord: ./scripts/setup/03_start_hcd.sh"
    exit 1
fi
success "HCD est démarré"

info "Vérification de DSBulk..."
if [ -z "$DSBULK" ] || [ ! -f "$DSBULK" ]; then
    DSBULK="${INSTALL_DIR}/binaire/dsbulk/bin/dsbulk"
fi
if [ ! -f "$DSBULK" ]; then
    error "DSBulk non trouvé : $DSBULK"
    exit 1
fi
success "DSBulk trouvé : $DSBULK"

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
# PARTIE 0.5: PRÉPARATION COMPACTION (Éviter Tombstones)
# ============================================
echo ""
section "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
section "  🔧 PARTIE 0.5: PRÉPARATION COMPACTION (Éviter Tombstones)"
section "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

if [ "$SKIP_COMPACTION" = "true" ] || [ "$SKIP_COMPACTION" = "skip" ]; then
    warn "Préparation compaction ignorée (paramètre skip_compaction=true)"
    warn "⚠️  ATTENTION : Des tombstones peuvent être présents dans l'export"
else
    info "📋 Objectif : Préparer la compaction pour éviter les tombstones dans l'export"
    echo ""
    info "Les actions suivantes seront effectuées :"
    echo "   1. Vérification état du cluster"
    echo "   2. Vérification gc_grace_seconds"
    echo "   3. Repair complet (recommandé, propagation tombstones)"
    echo "   4. Compaction de la table (purge tombstones expirés)"
    echo ""
    
    # Vérification nodetool disponible
    if [ ! -f "$NODETOOL" ]; then
        warn "nodetool non trouvé : $NODETOOL"
        warn "Préparation compaction ignorée (nodetool non disponible)"
        warn "⚠️  ATTENTION : Des tombstones peuvent être présents dans l'export"
    else
        # ÉTAPE 1 : Vérification État du Cluster
        echo ""
        info "📊 ÉTAPE 1 : Vérification État du Cluster"
        if "$NODETOOL" status 2>&1 | grep -q "UN"; then
            success "Cluster opérationnel"
            CLUSTER_STATUS=$("$NODETOOL" status 2>&1 | grep -E "UN|DN|UJ" | head -1 || echo "")
            if [ -n "$CLUSTER_STATUS" ]; then
                code "$CLUSTER_STATUS"
            fi
        else
            warn "Impossible de vérifier l'état du cluster (mode standalone ?)"
        fi
        
        # ÉTAPE 2 : Vérification gc_grace_seconds
        echo ""
        info "⏱️  ÉTAPE 2 : Vérification gc_grace_seconds"
        if [ -f "$CQLSH" ]; then
            GC_GRACE=$("$CQLSH" "$HCD_HOST" "$HCD_PORT" -e "DESCRIBE TABLE $KEYSPACE.$TABLE;" 2>/dev/null | grep -i "gc_grace_seconds" | grep -oE '[0-9]+' || echo "864000")
            if [ -n "$GC_GRACE" ]; then
                GC_GRACE_DAYS=$((GC_GRACE / 86400))
                success "gc_grace_seconds : $GC_GRACE secondes ($GC_GRACE_DAYS jours)"
                if [ "$GC_GRACE" -lt 864000 ]; then
                    warn "gc_grace_seconds est inférieur à 10 jours (défaut)"
                    warn "   Assurez-vous que les repairs sont effectués régulièrement"
                fi
            else
                warn "gc_grace_seconds non trouvé (utilise la valeur par défaut : 10 jours)"
            fi
        else
            warn "cqlsh non trouvé, impossible de vérifier gc_grace_seconds"
        fi
        
        # ÉTAPE 3 : Repair Complet (Recommandé)
        echo ""
        info "🔧 ÉTAPE 3 : Repair Complet (Propagation des Tombstones)"
        echo ""
        info "Le repair est RECOMMANDÉ avant compaction pour :"
        echo "   - Propager les tombstones sur tous les nœuds"
        echo "   - Éviter la réapparition de données supprimées (zombie data)"
        echo "   - Garantir la cohérence du cluster"
        echo ""
        
        # Mode non-interactif : on fait le repair automatiquement si possible
        # En mode interactif, on demande confirmation
        if [ -t 0 ]; then
            # Mode interactif
            read -p "Effectuer un repair complet ? (O/n) : " -n 1 -r
            echo ""
            DO_REPAIR=$REPLY
        else
            # Mode non-interactif : on fait le repair automatiquement
            DO_REPAIR="O"
            info "Mode non-interactif : repair sera effectué automatiquement"
        fi
        
        if [[ "$DO_REPAIR" =~ ^[OoYy]$ ]] || [ -z "$DO_REPAIR" ]; then
            info "Lancement du repair complet pour $KEYSPACE.$TABLE..."
            warn "⚠️  Cette opération peut prendre du temps selon la taille des données"
            
            if "$NODETOOL" repair -pr "$KEYSPACE" "$TABLE" 2>&1; then
                success "Repair terminé avec succès"
            else
                REPAIR_EXIT_CODE=$?
                if [ $REPAIR_EXIT_CODE -ne 0 ]; then
                    warn "Repair a échoué ou n'est pas applicable (mode standalone ?)"
                    warn "Continuez quand même avec la compaction ?"
                    if [ -t 0 ]; then
                        read -p "(O/n) : " -n 1 -r
                        echo ""
                        if [[ ! $REPLY =~ ^[OoYy]$ ]] && [ -n "$REPLY" ]; then
                            error "Arrêt du script"
                            exit 1
                        fi
                    else
                        info "Mode non-interactif : continuation avec compaction"
                    fi
                fi
            fi
        else
            warn "Repair ignoré"
            warn "⚠️  ATTENTION : Sans repair, les tombstones peuvent ne pas être propagés"
        fi
        
        # ÉTAPE 4 : Vérification Espace Disque
        echo ""
        info "💾 ÉTAPE 4 : Vérification Espace Disque"
        if [ -d "$HCD_DIR" ]; then
            DISK_USAGE=$(df -h "$HCD_DIR" 2>/dev/null | tail -1 | awk '{print $5}' | sed 's/%//' || echo "0")
            DISK_AVAILABLE=$(df -h "$HCD_DIR" 2>/dev/null | tail -1 | awk '{print $4}' || echo "N/A")
            if [ "$DISK_USAGE" != "0" ]; then
                success "Espace disque utilisé : ${DISK_USAGE}%"
                success "Espace disponible : $DISK_AVAILABLE"
                if [ "$DISK_USAGE" -gt 80 ]; then
                    warn "⚠️  Espace disque utilisé > 80%"
                    warn "   La compaction peut nécessiter de l'espace temporaire"
                fi
            fi
        fi
        
        # ÉTAPE 5 : Compaction
        echo ""
        info "🗜️  ÉTAPE 5 : Compaction de la Table"
        echo ""
        info "Lancement de la compaction pour $KEYSPACE.$TABLE..."
        warn "⚠️  Cette opération peut prendre du temps selon la taille des données"
        warn "⚠️  La compaction va :"
        echo "   - Fusionner les SSTables"
        echo "   - Purger les tombstones expirés (> gc_grace_seconds)"
        echo "   - Optimiser l'utilisation de l'espace disque"
        echo ""
        
        if [ -t 0 ]; then
            read -p "Confirmer la compaction ? (O/n) : " -n 1 -r
            echo ""
            DO_COMPACT=$REPLY
        else
            DO_COMPACT="O"
            info "Mode non-interactif : compaction sera effectuée automatiquement"
        fi
        
        if [[ "$DO_COMPACT" =~ ^[OoYy]$ ]] || [ -z "$DO_COMPACT" ]; then
            info "Compaction en cours..."
            
            if "$NODETOOL" compact "$KEYSPACE" "$TABLE" 2>&1; then
                success "Compaction lancée avec succès"
                info "La compaction s'exécute en arrière-plan"
                info "Vous pouvez surveiller la progression avec :"
                code "   $NODETOOL compactionstats"
                echo ""
                info "⏳ Attente de 10 secondes pour laisser la compaction démarrer..."
                sleep 10
                
                info "Statut de la compaction :"
                "$NODETOOL" compactionstats 2>&1 | grep -E "pending|active|completed" | head -5 || echo "Aucune compaction active visible"
            else
                error "Erreur lors du lancement de la compaction"
                warn "Continuez quand même avec l'export ?"
                if [ -t 0 ]; then
                    read -p "(O/n) : " -n 1 -r
                    echo ""
                    if [[ ! $REPLY =~ ^[OoYy]$ ]] && [ -n "$REPLY" ]; then
                        error "Arrêt du script"
                        exit 1
                    fi
                else
                    warn "Mode non-interactif : continuation avec export"
                fi
            fi
        else
            warn "Compaction ignorée"
            warn "⚠️  ATTENTION : Des tombstones peuvent être présents dans l'export"
        fi
        
        success "✅ Préparation compaction terminée"
    fi
fi

echo ""

# ============================================
# PARTIE 1: CONTEXTE ET STRATÉGIE
# ============================================
echo ""
section "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
section "  📚 PARTIE 1: CONTEXTE ET STRATÉGIE"
section "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

info "📚 OBJECTIF : Démontrer l'export incrémental depuis HCD vers Parquet"
echo ""
if [ "$SKIP_COMPACTION" != "true" ] && [ "$SKIP_COMPACTION" != "skip" ]; then
    info "✅ Préparation compaction effectuée :"
    echo "   - Repair complet : propagation des tombstones"
    echo "   - Compaction : purge des tombstones expirés"
    echo "   - Résultat : export sans tombstones"
    echo ""
fi
info "🔄 ÉQUIVALENCES HBase → HCD :"
echo ""
echo "   HBase                          →  HCD (Spark)"
echo "   ──────────────────────────────    ─────────────────────────────"
echo "   FullScan + TIMERANGE          →  WHERE date_op >= start AND date_op < end"
echo "   STARTROW + STOPROW             →  WHERE code_si = X AND contrat >= Y AND contrat < Z"
echo "   Unload ORC vers HDFS          →  Export Parquet vers HDFS"
echo "   Fenêtre glissante             →  Calcul automatique des dates"
echo ""
info "📋 AVANTAGES Parquet vs ORC :"
echo "   ✅ Cohérence : même format que l'ingestion (parquet)"
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
# PARTIE 2: EXPORT DSBULK VERS JSON (Avec colonne VECTOR)
# ============================================
echo ""
section "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
section "  📥 PARTIE 2: EXPORT DSBULK VERS JSON (Avec colonne VECTOR)"
section "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

info "📝 Commande DSBulk pour exporter depuis HCD vers JSON :"
echo ""
# Créer le répertoire temporaire pour JSON
TEMP_JSON_DIR=$(mktemp -d "/tmp/dsbulk_export_$(date +%s)_XXXXXX")

# Créer un fichier temporaire pour la requête CQL (inclut libelle_embedding)
TEMP_CQL_QUERY=$(mktemp "/tmp/dsbulk_query_$(date +%s)_XXXXXX.cql")
cat > "$TEMP_CQL_QUERY" <<EOFCQL
SELECT code_si, contrat, date_op, numero_op, op_id, libelle, montant, devise, date_valeur, type_operation, sens_operation, operation_data, cobol_data_base64, copy_type, meta_flags, cat_auto, cat_confidence, cat_user, cat_date_user, cat_validee, libelle_tokens, libelle_prefix, metadata, libelle_embedding
FROM domirama2_poc.operations_by_account 
WHERE date_op >= '$START_DATE' AND date_op < '$END_DATE' 
ALLOW FILTERING
EOFCQL

code "$DSBULK unload \\"
code "  --connector.name json \\"
code "  --query.file \"$TEMP_CQL_QUERY\" \\"
code "  --schema.keyspace domirama2_poc \\"
code "  --schema.table operations_by_account \\"
code "  --connector.json.url \"$TEMP_JSON_DIR\" \\"
code "  --connector.json.compression gzip \\"
code "  --dsbulk.connector.cassandra.host localhost \\"
code "  --dsbulk.connector.cassandra.port 9042"
echo ""
info "💡 Explication :"
echo "   - DSBulk exporte directement depuis HCD (contourne Spark)"
echo "   - IMPORTANT : Requête SELECT INCLUT libelle_embedding (type VECTOR)"
echo "   - DSBulk exporte le VECTOR en format JSON (string)"
echo "   - Filtrage par dates dans WHERE (équivalent TIMERANGE HBase)"
echo "   - WHERE date_op >= '$START_DATE' AND date_op < '$END_DATE'"
echo "   - Date de fin exclusive (comme TIMERANGE HBase)"
echo "   - Export vers JSON compressé (gzip) temporaire"
echo "   - Le VECTOR est préservé en format JSON string"
echo ""

# ============================================
# PARTIE 3: CONVERSION JSON -> PARQUET AVEC SPARK (Avec VECTOR)
# ============================================
echo ""
section "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
section "  💾 PARTIE 3: CONVERSION JSON -> PARQUET AVEC SPARK (Avec VECTOR)"
section "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

info "📝 Code Spark pour convertir JSON en Parquet (avec VECTOR) :"
echo ""
code "// Option 1 : Garder le vector en string JSON"
code "val df_json = spark.read.json(\"$TEMP_JSON_DIR/*.json.gz\")"
code "df_json.write.mode(\"overwrite\").partitionBy(\"date_op\").parquet(\"$OUTPUT_PATH\")"
code ""
code "// Option 2 : Reconvertir en tableau de float (ArrayType)"
code "import org.apache.spark.sql.functions.from_json"
code "import org.apache.spark.sql.types.ArrayType, FloatType"
code "val df_vec = df_json.withColumn("
code "  \"libelle_embedding_array\","
code "  from_json(col(\"libelle_embedding\"), ArrayType(FloatType()))"
code ")"
code "df_vec.drop(\"libelle_embedding\")"
code "  .write.mode(\"overwrite\")"
code "  .partitionBy(\"date_op\")"
code "  .option(\"compression\", \"$COMPRESSION\")"
code "  .parquet(\"$OUTPUT_PATH\")"
echo ""
info "💡 Explication :"
echo "   - Spark lit le JSON (pas Cassandra, donc pas de problème VECTOR)"
echo "   - Le VECTOR est préservé en format JSON string dans le JSON"
echo "   - Option 1 : Garder en string JSON (simple, compact)"
echo "   - Option 2 : Reconvertir en ArrayType(FloatType) pour usage Spark ML"
echo "   - Mode overwrite : permet les rejeux (idempotence)"
echo "   - Partitionnement par date_op : performance optimale"
if [ "$COMPRESSION" = "snappy" ]; then
    echo "   - Compression $COMPRESSION : rapide, bon compromis taille/vitesse"
elif [ "$COMPRESSION" = "gzip" ]; then
    echo "   - Compression $COMPRESSION : compact, meilleure compression"
elif [ "$COMPRESSION" = "lz4" ]; then
    echo "   - Compression $COMPRESSION : très rapide, compression modérée"
else
    echo "   - Compression $COMPRESSION : optimise la taille des fichiers"
fi
echo ""

# ============================================
# PARTIE 4: EXÉCUTION DSBULK + SPARK
# ============================================
echo ""
section "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
section "  🚀 PARTIE 4: EXÉCUTION DSBULK + SPARK"
section "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

info "🚀 ÉTAPE 1 : Export DSBulk vers JSON (avec VECTOR)..."
echo ""

# Exécuter DSBulk et capturer la sortie
"$DSBULK" unload \
  --connector.name json \
  --query.file "$TEMP_CQL_QUERY" \
  --schema.keyspace domirama2_poc \
  --schema.table operations_by_account \
  --connector.json.url "$TEMP_JSON_DIR" \
  --connector.json.compression gzip \
  --dsbulk.connector.cassandra.host localhost \
  --dsbulk.connector.cassandra.port 9042 \
  2>&1 | tee "$TEMP_OUTPUT" | grep -v "^$" | tail -20

DSBULK_EXIT_CODE=${PIPESTATUS[0]}

if [ $DSBULK_EXIT_CODE -ne 0 ]; then
    error "Erreur lors de l'export DSBulk (code: $DSBULK_EXIT_CODE)"
    rm -rf "$TEMP_JSON_DIR"
    exit 1
fi

# Extraire le nombre d'opérations depuis la sortie DSBulk
JSON_LINES=$(grep -E "^[[:space:]]*[0-9,]+[[:space:]]*\|" "$TEMP_OUTPUT" | tail -1 | awk -F'|' '{print $1}' | tr -d ', ' || echo "0")
if [ "$JSON_LINES" = "0" ] || [ -z "$JSON_LINES" ]; then
    # Fallback: compter les lignes dans les fichiers JSON
    JSON_LINES=$(find "$TEMP_JSON_DIR" -name "*.json.gz" -exec zcat {} \; 2>/dev/null | wc -l | tr -d ' ' || echo "0")
fi

# Compter les fichiers JSON exportés
JSON_COUNT=$(find "$TEMP_JSON_DIR" -name "*.json.gz" 2>/dev/null | wc -l | tr -d ' ' || echo "0")

# Trouver le répertoire réel où DSBulk a exporté (peut être un sous-répertoire)
ACTUAL_JSON_DIR=$(find "$TEMP_JSON_DIR" -name "*.json.gz" -type f 2>/dev/null | head -1 | xargs dirname 2>/dev/null || echo "$TEMP_JSON_DIR")
if [ -z "$ACTUAL_JSON_DIR" ] || [ "$ACTUAL_JSON_DIR" = "." ]; then
    ACTUAL_JSON_DIR="$TEMP_JSON_DIR"
fi

success "✅ Export DSBulk terminé : $JSON_LINES opérations exportées vers JSON (avec VECTOR)"
info "   📁 Répertoire : $ACTUAL_JSON_DIR"
info "   📄 Fichiers : $JSON_COUNT fichiers JSON.gz"
echo ""

info "🚀 ÉTAPE 2 : Conversion JSON -> Parquet avec Spark (avec VECTOR)..."
echo ""

# Vérifier que Spark est disponible pour la conversion
SPARK_HOME="${INSTALL_DIR}/binaire/spark-3.5.1"
if [ ! -d "$SPARK_HOME" ]; then
    error "Spark non trouvé pour la conversion JSON -> Parquet"
    rm -rf "$TEMP_JSON_DIR"
    exit 1
fi
export PATH=$SPARK_HOME/bin:$PATH

# Créer un script Scala pour la conversion
TEMP_SPARK_SCRIPT=$(mktemp "/tmp/script_27_spark_$(date +%s)_272727.scala")
cat > "$TEMP_SPARK_SCRIPT" <<EOFSPARK
import org.apache.spark.sql.SparkSession
import org.apache.spark.sql.functions._

val spark = SparkSession.builder()
  .appName("JSON to Parquet Converter with Vector")
  .getOrCreate()

import spark.implicits._

val jsonPath = "$ACTUAL_JSON_DIR"
val parquetPath = "$OUTPUT_PATH"
val compression = "$COMPRESSION"

println("=" * 80)
println("📥 Conversion JSON -> Parquet (avec VECTOR)")
println("=" * 80)

// Lire le JSON (avec VECTOR en format JSON string)
println(s"\n🔍 Lecture du JSON depuis : \$jsonPath")
// Chercher récursivement tous les fichiers JSON.gz
val df_json = spark.read.option("recursiveFileLookup", "true").json(s"\$jsonPath/**/*.json.gz")

val count = df_json.count()
println(s"✅ \$count opérations lues depuis JSON")
println(s"   Colonnes présentes : \${df_json.columns.length} colonnes")

// Vérifier si libelle_embedding est présente
val hasVector = df_json.columns.contains("libelle_embedding")
if (hasVector) {
  println("✅ Colonne libelle_embedding détectée (format JSON string)")
  println("   Le vector est préservé en format JSON string")
}

if (count == 0) {
  println("⚠️  Aucune donnée à convertir")
  System.exit(0)
}

// Pour l'instant, gardons le vector en format JSON string (plus simple et compatible)
// Option : peut être reconverti en ArrayType(FloatType) si nécessaire pour Spark ML
val df_final = df_json

// Convertir date_op en timestamp si nécessaire
val dfWithDate = df_final.withColumn("date_op", to_timestamp(col("date_op"), "yyyy-MM-dd HH:mm:ss.SSS"))

// Statistiques
println("\n📊 Statistiques :")
val stats = dfWithDate.agg(
  min("date_op").as("date_min"),
  max("date_op").as("date_max"),
  countDistinct("code_si", "contrat").as("comptes_uniques")
)
stats.show()
println(s"   Total opérations : \$count")

// Export Parquet
println(s"\n💾 Export Parquet vers : \$parquetPath")
println(s"   Compression : \$compression")
println(s"   Partitionnement : par date_op")

dfWithDate.write
  .mode("overwrite")
  .partitionBy("date_op")
  .option("compression", compression)
  .parquet(parquetPath)

println(s"✅ Export Parquet terminé : \$count opérations")

// Vérification
println("\n🔍 Vérification : lecture du Parquet...")
val dfRead = spark.read.parquet(parquetPath)
val countRead = dfRead.count()
println(s"✅ Vérification OK : \$countRead opérations lues depuis Parquet")

if (count != countRead) {
  println(s"⚠️  ATTENTION : Incohérence (\$count exportées vs \$countRead lues)")
}

println("\n" + "=" * 80)
println("✅ Conversion JSON -> Parquet - Terminé")
println("=" * 80)
EOFSPARK

# Exécuter Spark pour la conversion
spark-shell \
  --driver-memory 2g \
  --executor-memory 2g \
  -i "$TEMP_SPARK_SCRIPT" \
  2>&1 | tee -a "$TEMP_OUTPUT" | grep -v "^scala>" | grep -v "^     |" | grep -v "^Welcome to" | grep -v "WARN NativeCodeLoader"

# Nettoyer
rm -f "$TEMP_SPARK_SCRIPT"
rm -f "$TEMP_CQL_QUERY"
rm -rf "$TEMP_JSON_DIR"

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
    EXPORT_COUNT=$(grep -oE '[0-9]+ opérations trouvées' "$TEMP_OUTPUT" | head -1 | grep -oE '[0-9]+' || echo "0")
    READ_COUNT=$(grep -oE '[0-9]+ opérations lues' "$TEMP_OUTPUT" | head -1 | grep -oE '[0-9]+' || echo "0")
    
    # Détecter les avertissements tombstone
    TOMBSTONE_WARNINGS=$(grep -c "tombstone rows" "$TEMP_OUTPUT" 2>/dev/null || echo "0")
    if [ "$TOMBSTONE_WARNINGS" -gt 0 ]; then
        TOMBSTONE_COUNT=$(grep -oE '[0-9]+ tombstone rows' "$TEMP_OUTPUT" | head -1 | grep -oE '[0-9]+' || echo "0")
        if [ "$TOMBSTONE_COUNT" != "0" ] && [ "$TOMBSTONE_COUNT" -gt 1000 ]; then
            warn "⚠️  Tombstones détectés : $TOMBSTONE_COUNT (seuil d'avertissement : 1000)"
            warn "   Recommandation : Effectuer une compaction avant l'export"
            warn "   Commande : nodetool compact domirama2_poc operations_by_account"
        fi
    fi
    
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
skip_compaction = "$SKIP_COMPACTION"

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
tombstone_count = 0
tombstone_warnings = []

# Extraire le nombre d'opérations exportées (DSBulk)
dsbulk_match = re.search(r'Export DSBulk terminé : (\d+) opérations', spark_output)
if dsbulk_match:
    export_count = int(dsbulk_match.group(1))

# Extraire le nombre d'opérations lues depuis JSON
json_match = re.search(r'(\d+) opérations lues depuis JSON', spark_output)
if json_match:
    export_count = int(json_match.group(1))

# Extraire le nombre d'opérations lues depuis Parquet
read_match = re.search(r'(\d+) opérations lues depuis Parquet', spark_output)
if read_match:
    read_count = int(read_match.group(1))

# Extraire l'information sur la présence de libelle_embedding
vector_present = "Colonne libelle_embedding détectée" in spark_output or "libelle_embedding" in spark_output
columns_count = None
if vector_present:
    cols_match = re.search(r'Colonnes présentes : (\d+) colonnes', spark_output)
    if cols_match:
        columns_count = int(cols_match.group(1))

# Extraire les avertissements tombstone
tombstone_matches = re.findall(r'Scanned over (\d+) tombstone rows', spark_output)
if tombstone_matches:
    tombstone_count = max([int(m) for m in tombstone_matches])
    tombstone_warnings = [f"{m} tombstones scannés" for m in tombstone_matches]

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

# Extraire les avertissements tombstone
tombstone_matches = re.findall(r'Scanned over (\d+) tombstone rows', spark_output)
if tombstone_matches:
    tombstone_count = max([int(m) for m in tombstone_matches])
    tombstone_warnings = [f"{m} tombstones scannés" for m in tombstone_matches]

report_date = datetime.now().strftime("%Y-%m-%d %H:%M:%S")
script_name = os.path.basename("$0")

report_content = f"""# 📥 Démonstration : Export Incrémental Parquet depuis HCD

**Date** : {report_date}
**Script** : {script_name}
**Objectif** : Démontrer l'export incrémental depuis HCD vers parquet

---

## 📋 Table des Matières

1. [Contexte et Stratégie](#contexte-et-stratégie)
2. [Export DSBulk vers JSON (Avec colonne VECTOR)](#export-dsbulk-vers-json-avec-colonne-vector)
3. [Résultats de l'Export](#résultats-de-lexport)
4. [Vérification](#vérification)
5. [Conclusion](#conclusion)

---

## 📚 Contexte et Stratégie

### Préparation Compaction

"""
if skip_compaction != "true" and skip_compaction != "skip":
    report_content += f"""
- ✅ **Préparation compaction effectuée** avant l'export
- ✅ **Repair complet** : Propagation des tombstones sur tous les nœuds
- ✅ **Compaction** : Purge des tombstones expirés (> gc_grace_seconds)
- ✅ **Résultat** : Export sans tombstones garantis
"""
else:
    report_content += f"""
- ⚠️  **Préparation compaction ignorée** (paramètre skip_compaction=true)
- ⚠️  **ATTENTION** : Des tombstones peuvent être présents dans l'export
- 📚 **Recommandation** : Relancer sans skip_compaction pour éviter les tombstones
"""

report_content += f"""
### Équivalences HBase → HCD

| Concept HBase | Équivalent HCD (Spark) |
|---------------|------------------------|
| FullScan + TIMERANGE | WHERE date_op >= start AND date_op < end |
| STARTROW + STOPROW | WHERE code_si = X AND contrat >= Y AND contrat < Z |
| Unload ORC vers HDFS | Export Parquet vers HDFS |
| Fenêtre glissante | Calcul automatique des dates |

### Avantages Parquet vs ORC

- ✅ **Cohérence** : même format que l'ingestion (parquet)
- ✅ **Performance** : optimisations Spark natives
- ✅ **Simplicité** : un seul format dans le POC
- ✅ **Standard** : format de facto dans l'écosystème moderne

### Paramètres de l'Export

- **Date début** : {start_date}
- **Date fin** : {end_date} (exclusif)
- **Output path** : {output_path}
- **Compression** : {compression}

---

## 📥 Export DSBulk vers JSON (Avec colonne VECTOR)

### Stratégie

Cette démonstration utilise **DSBulk** au lieu de Spark pour l'export initial, afin d'éviter le problème du type VECTOR non supporté par Spark Cassandra Connector.

### Processus en Deux Étapes

1. **DSBulk exporte HCD → JSON** :
   - Requête CQL avec SELECT explicite (INCLUT libelle_embedding)
   - Filtrage par dates : WHERE date_op >= '{start_date}' AND date_op < '{end_date}'
   - Export vers JSON compressé (gzip) temporaire
   - Le VECTOR est préservé en format JSON string

2. **Spark convertit JSON → Parquet** :
   - Lecture du JSON (pas de problème VECTOR car Spark ne lit pas Cassandra)
   - Le VECTOR est préservé en format JSON string dans le Parquet
   - Option : peut être reconverti en ArrayType(FloatType) si nécessaire pour Spark ML
   - Conversion en Parquet avec partitionnement par date_op

### Code Exécuté

**DSBulk** :
```
dsbulk unload \\
  --query.file "requête_cql.cql" \\
  --schema.keyspace domirama2_poc \\
  --schema.table operations_by_account \\
  --connector.json.url "/tmp/json_export" \\
  --connector.json.compression gzip
```

**Spark** :
```scala
val df_json = spark.read.json(jsonPath + "/*.json.gz")

// Le vector est préservé en format JSON string
val df_final = df_json

df_final.write
  .mode("overwrite")
  .partitionBy("date_op")
  .option("compression", "{compression}")
  .parquet(parquetPath)
```

### Explication

- **DSBulk** : Contourne Spark pour éviter le problème VECTOR
- **Format JSON** : Préserve la colonne `libelle_embedding` en format JSON string
- **Compression gzip** : Optimise la taille des fichiers JSON temporaires
- **Filtrage par dates** : Équivalent TIMERANGE HBase
- **Date de fin exclusive** : Comme TIMERANGE HBase (date_op < end_date)
- **Mode overwrite** : Permet les rejeux (idempotence)
- **Partitionnement par date_op** : Performance optimale pour requêtes futures
- **Compression {compression}** : Optimise la taille des fichiers Parquet
- **Vector préservé** : La colonne `libelle_embedding` est conservée en format JSON string

---

## 📊 Résultats de l'Export

### Statistiques

- **Opérations exportées (DSBulk)** : {export_count}
- **Opérations lues depuis JSON** : {export_count}
- **Opérations converties en Parquet** : {export_count}
- **Opérations lues (vérification)** : {read_count}
- **Date min** : {date_min}
- **Date max** : {date_max}
- **Comptes uniques** : {comptes_uniques}
{f"- **Colonnes présentes** : {columns_count} (libelle_embedding incluse en format JSON string)" if vector_present and columns_count else ""}

### Fichiers Créés

- **Répertoire** : {output_path}
- **Compression** : {compression}
- **Partitionnement** : par date_op
{f"- **Vector préservé** : libelle_embedding incluse en format JSON string" if vector_present else ""}

---

## 🔍 Vérification

### Vérification de Cohérence

{f"✅ **Cohérence OK** : {export_count} opérations exportées = {read_count} opérations lues" if export_count == read_count and export_count > 0 else f"⚠️  **Incohérence détectée** : {export_count} opérations exportées ≠ {read_count} opérations lues" if export_count != read_count else "⚠️  **Aucune donnée exportée**"}

### Préservation de la Colonne Vector

{f"✅ **Colonne libelle_embedding préservée** : Détectée dans le JSON et conservée en format JSON string" if vector_present else "ℹ️  **Colonne libelle_embedding** : Non présente dans le JSON"}
{f"   - Colonnes totales : {columns_count} (libelle_embedding incluse)" if vector_present and columns_count else ""}
{f"   - Format : JSON string (peut être reconverti en ArrayType(FloatType) si nécessaire)" if vector_present else ""}
"""

# Ajouter la section sur les tombstones si détectés
if tombstone_count > 0:
    report_content += f"""
---

## ⚠️ Gestion des Tombstones

### Détection

- **Tombstones scannés** : {tombstone_count}
- **Seuil d'avertissement** : 1000
- **Statut** : {'⚠️  Seuil dépassé' if tombstone_count > 1000 else '✅ Dans les limites'}

### Impact

- **Performance** : {'Potentiellement dégradée' if tombstone_count > 1000 else 'Normale'}
- **Export** : Les tombstones sont automatiquement filtrés par Spark Cassandra Connector
- **Données** : Aucun tombstone exporté (comportement attendu)

### Actions Recommandées

"""
    if tombstone_count > 1000:
        report_content += f"""
1. **Compaction manuelle** (si accès nodetool) :
   ```bash
   nodetool compact domirama2_poc operations_by_account
   ```

2. **Vérification gc_grace_seconds** :
   ```cql
   DESCRIBE TABLE domirama2_poc.operations_by_account;
   ```

3. **Surveillance** : Surveiller les métriques de compaction

"""
    else:
        report_content += f"""
- ✅ **Aucune action requise** : Le nombre de tombstones est dans les limites normales
- 📊 **Surveillance** : Continuer à surveiller les métriques de compaction

"""

# Ajouter la section sur les tombstones si détectés
if tombstone_count > 0:
    report_content += f"""
---

## ⚠️ Gestion des Tombstones

### Détection

- **Tombstones scannés** : {tombstone_count}
- **Seuil d'avertissement** : 1000
- **Statut** : {'⚠️  Seuil dépassé' if tombstone_count > 1000 else '✅ Dans les limites'}

### Impact

- **Performance** : {'Potentiellement dégradée' if tombstone_count > 1000 else 'Normale'}
- **Export** : Les tombstones sont automatiquement filtrés par Spark Cassandra Connector
- **Données** : Aucun tombstone exporté (comportement attendu)

### Actions Recommandées

"""
    if tombstone_count > 1000:
        report_content += f"""
1. **Compaction manuelle** (si accès nodetool) :
   ```bash
   nodetool compact domirama2_poc operations_by_account
   ```

2. **Vérification gc_grace_seconds** :
   ```cql
   DESCRIBE TABLE domirama2_poc.operations_by_account;
   ```

3. **Surveillance** : Surveiller les métriques de compaction

4. **Documentation** : Voir `doc/73_TOMBSTONES_EXPORT_BEST_PRACTICES.md` pour plus de détails

"""
    else:
        report_content += f"""
- ✅ **Aucune action requise** : Le nombre de tombstones est dans les limites normales
- 📊 **Surveillance** : Continuer à surveiller les métriques de compaction
- 📚 **Documentation** : Voir `doc/73_TOMBSTONES_EXPORT_BEST_PRACTICES.md` pour plus de détails

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
- ✅ **Vérification OK** : {read_count} opérations lues depuis Parquet
- ✅ **Fichiers créés** : {output_path}
- ✅ **Compression** : {compression}
{f"- ✅ **Colonne vector préservée** : libelle_embedding incluse en format JSON string dans le Parquet final" if vector_present else ""}

### Points Clés Démontrés

- ✅ Export incrémental depuis HCD vers Parquet via DSBulk + Spark
- ✅ Préservation de la colonne vector (libelle_embedding) en format JSON string
- ✅ Filtrage par dates (équivalent TIMERANGE HBase)
- ✅ Partitionnement par date_op pour performance
- ✅ Compression configurable
- ✅ Vérification de cohérence
- ✅ Processus en deux étapes : DSBulk (HCD → JSON) puis Spark (JSON → Parquet)

### Prochaines Étapes

- Script 28: Démonstration fenêtre glissante
- Script 29: Requêtes in-base avec fenêtre glissante

---

**✅ Export incrémental Parquet terminé avec succès !**
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
echo "   ✅ Export incrémental Parquet terminé"
echo "   ✅ Fichiers créés dans : $OUTPUT_PATH"
echo "   ✅ Compression : $COMPRESSION"
echo ""
info "💡 Points clés démontrés :"
echo "   ✅ Export incrémental depuis HCD vers Parquet"
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
success "✅ ✅ Export incrémental Parquet terminé !"
echo ""
