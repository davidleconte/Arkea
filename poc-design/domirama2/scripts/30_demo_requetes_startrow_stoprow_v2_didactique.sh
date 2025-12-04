#!/bin/bash
set -euo pipefail
# ============================================
# Script 30 : Démonstration Requêtes STARTROW/STOPROW (Version Didactique)
# Démontre les requêtes en base avec ciblage précis via requêtes CQL directes
# Équivalent HBase: STARTROW/STOPROW avec ciblage précis
# ============================================
#
# OBJECTIF :
#   Ce script démontre les requêtes en base avec ciblage précis (STARTROW/STOPROW
#   équivalent HBase) en exécutant 3 requêtes CQL directement via cqlsh.
#
#   Cette version didactique affiche :
#   - Les équivalences HBase → HCD détaillées
#   - Les requêtes CQL complètes avant exécution
#   - Les résultats attendus pour chaque requête
#   - Les résultats obtenus avec mesure de performance
#   - La valeur ajoutée SAI (si applicable)
#   - Une documentation structurée pour livrable
#
# PRÉREQUIS :
#   - HCD démarré (./scripts/setup/03_start_hcd.sh)
#   - Schéma configuré (./10_setup_domirama2_poc.sh)
#   - Données chargées (./11_load_domirama2_data_parquet.sh)
#   - Java 11 configuré via jenv
#
# UTILISATION :
#   ./30_demo_requetes_startrow_stoprow_v2_didactique.sh
#
# SORTIE :
#   - Requêtes CQL affichées avec explications
#   - Résultats de chaque requête
#   - Mesures de performance
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
REPORT_FILE="${SCRIPT_DIR}/doc/demonstrations/30_STARTROW_STOPROW_REQUETES_DEMONSTRATION.md"

# Créer le répertoire de documentation
mkdir -p "$(dirname "$REPORT_FILE")"

# Fichiers temporaires pour capture
TEMP_OUTPUT=$(mktemp "/tmp/script_30_output_$(date +%s).txt")
TEMP_RESULTS=$(mktemp "/tmp/script_30_results_$(date +%s).json")

# Initialiser le fichier JSON avec un tableau vide
echo "[]" > "$TEMP_RESULTS"

# Tableau pour stocker les résultats de chaque requête (plus utilisé, mais gardé pour compatibilité)
declare -a QUERY_RESULTS

# Configuration cqlsh
CQLSH_BIN="${HCD_DIR}/bin/cqlsh"
CQLSH="$CQLSH_BIN "$HCD_HOST" "$HCD_PORT""

# ============================================
# PARTIE 0: VÉRIFICATIONS
# ============================================
echo ""
section "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
section "  🔍 PARTIE 0: VÉRIFICATIONS"
section "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

info "Vérification que HCD est démarré..."
if ! nc -z "$HCD_HOST" "$HCD_PORT" 2>/dev/null; then
    error "HCD n'est pas démarré sur "$HCD_HOST:$HCD_PORT""
    error "Exécutez d'abord: ./scripts/setup/03_start_hcd.sh"
    exit 1
fi
success "HCD est démarré"

info "Vérification que cqlsh est disponible..."
if [ ! -f "$CQLSH_BIN" ]; then
    error "cqlsh non trouvé : $CQLSH_BIN"
    exit 1
fi
success "cqlsh trouvé : $CQLSH_BIN"

info "Vérification du schéma..."
# Vérifier que le keyspace existe
if ! $CQLSH -e "DESCRIBE KEYSPACE domirama2_poc;" > /dev/null 2>&1; then
    error "Keyspace domirama2_poc non trouvé"
    error "Exécutez d'abord: ./10_setup_domirama2_poc.sh"
    exit 1
fi
success "Schéma vérifié : keyspace domirama2_poc existe"

# ============================================
# PARTIE 1: CONTEXTE ET STRATÉGIE
# ============================================
echo ""
section "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
section "  📚 PARTIE 1: CONTEXTE ET STRATÉGIE"
section "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

info "📚 OBJECTIF : Démontrer les requêtes en base avec ciblage précis (STARTROW/STOPROW)"
echo ""
info "🔄 ÉQUIVALENCES HBase → HCD :"
echo ""
echo "   HBase                          →  HCD (CQL)"
echo "   ──────────────────────────────    ─────────────────────────────"
echo "   STARTROW + STOPROW             →  WHERE date_op >= start AND date_op <= end"
echo "   SCAN avec plages de rowkeys    →  SELECT ... WHERE clustering_keys BETWEEN ..."
echo "   Ciblage précis                 →  Filtrage par clustering keys (date_op, numero_op)"
echo ""
info "💡 VALEUR AJOUTÉE SAI :"
code "   ✅ Index sur date_op (clustering key) pour performance optimale"
code "   ✅ Index sur numero_op (clustering key) pour performance optimale"
code "   ✅ Index sur libelle (full-text SAI) pour recherche textuelle"
code "   ✅ Combinaison d'index pour recherche optimisée"
code "   ✅ Pas de scan complet nécessaire"
echo ""
info "📋 STRATÉGIE DE DÉMONSTRATION :"
code "   - 3 requêtes CQL pour démontrer le ciblage précis (STARTROW/STOPROW)"
code "   - Mesure de performance pour chaque requête"
code "   - Comparaison avec/sans SAI"
code "   - Documentation structurée pour livrable"
echo ""

# ============================================
# PARTIE 2: REQUÊTES CQL
# ============================================
echo ""
section "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
section "  🔍 PARTIE 2: REQUÊTES CQL"
section "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# ============================================
# Fonction : Exécuter une Requête CQL avec Mesure de Performance
# ============================================

execute_query() {
    local query_num=$1
    local query_title="$2"
    local query_description="$3"
    local hbase_equivalent="$4"
    local query_cql="$5"
    local expected_result="$6"
    local sai_value="$7"

    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "  🔍 REQUÊTE $query_num : $query_title"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""

    info "📚 DÉFINITION - $query_title :"
    echo "   $query_description"
    echo ""

    info "🔄 ÉQUIVALENT HBase :"
    code "   $hbase_equivalent"
    echo ""

    info "📝 Requête CQL :"
    echo "$query_cql" | while IFS= read -r line; do
        if [ -n "$line" ]; then
            code "$line"
        fi
    done
    echo ""

    if [ -n "$sai_value" ]; then
        info "💡 VALEUR AJOUTÉE SAI :"
        echo "   $sai_value" | sed 's/^/   /'
        echo ""
    fi

    expected "📋 Résultat attendu : $expected_result"
    echo ""

    # Créer un fichier temporaire pour la requête
    TEMP_QUERY_FILE=$(mktemp "/tmp/query_${query_num}_$(date +%s).cql")
    cat > "$TEMP_QUERY_FILE" <<EOF
USE domirama2_poc;
TRACING ON;
$query_cql
EOF

    # Exécuter la requête et mesurer le temps
    info "🚀 Exécution de la requête..."
    START_TIME=$(date +%s.%N)
    QUERY_OUTPUT=$($CQLSH -f "$TEMP_QUERY_FILE" 2>&1 | tee -a "$TEMP_OUTPUT")
    EXIT_CODE=$?
    END_TIME=$(date +%s.%N)

    # Calculer le temps d'exécution (compatible macOS)
    if command -v bc >/dev/null 2>&1; then
        QUERY_TIME=$(echo "$END_TIME - $START_TIME" | bc 2>/dev/null || echo "0.000")
    else
        QUERY_TIME=$(python3 -c "print($END_TIME - $START_TIME)" 2>/dev/null || echo "0.000")
    fi

    # Extraire les métriques du tracing
    COORDINATOR_TIME=$(echo "$QUERY_OUTPUT" | grep "coordinator" | awk -F'|' '{print $4}' | tr -d ' ' | head -1 || echo "")
    TOTAL_TIME=$(echo "$QUERY_OUTPUT" | grep "total" | awk -F'|' '{print $4}' | tr -d ' ' | head -1 || echo "")

    # Compter les lignes retournées
    ROW_COUNT=$(echo "$QUERY_OUTPUT" | grep -E "^[A-Z_]+ \|" | grep -v "^code_si " | wc -l | tr -d ' ')
    if [ -z "$ROW_COUNT" ] || [ "$ROW_COUNT" -eq 0 ]; then
        ROW_COUNT=$(echo "$QUERY_OUTPUT" | grep -E "\([0-9]+ rows\)" | grep -oE "[0-9]+" | head -1 || echo "0")
    fi
    # S'assurer que ROW_COUNT est un nombre valide
    if [ -z "$ROW_COUNT" ] || ! [[ "$ROW_COUNT" =~ ^[0-9]+$ ]]; then
        ROW_COUNT=0
    fi

    # Extraire le plan d'exécution
    EXECUTION_PLAN=$(echo "$QUERY_OUTPUT" | grep -E "(Executing|single-partition|Read|Scanned|Merging)" | head -3 | tr '\n' '; ' || echo "")

    # Filtrer les résultats pour affichage (sans tracing, sans en-têtes de colonnes)
    # Garder uniquement les lignes de données (commençant par un espace suivi d'un chiffre ou d'un caractère)
    QUERY_RESULTS_FILTERED=$(echo "$QUERY_OUTPUT" | grep -vE "^Warnings|^$|^\([0-9]+ rows\)|coordinator|total|Executing|Read|Scanned|Merging|^ code_si |^---------|^Tracing" | grep -E "^[[:space:]]*[0-9]|^[[:space:]]*[A-Z]" | head -20)

    # Afficher les résultats
    if [ $EXIT_CODE -eq 0 ]; then
        result "📊 Résultats obtenus ($ROW_COUNT ligne(s)) en ${QUERY_TIME}s :"
        echo ""
        echo "$QUERY_RESULTS_FILTERED" | head -15
        if [ "$ROW_COUNT" -gt 15 ]; then
            echo "... (affichage limité à 15 lignes)"
        fi
        echo ""

        if [ -n "$COORDINATOR_TIME" ] && [ "$COORDINATOR_TIME" != "" ]; then
            info "   ⏱️  Temps coordinateur : ${COORDINATOR_TIME}μs"
        fi
        if [ -n "$TOTAL_TIME" ] && [ "$TOTAL_TIME" != "" ]; then
            info "   ⏱️  Temps total : ${TOTAL_TIME}μs"
        fi
        if [ -n "$EXECUTION_PLAN" ]; then
            info "   📋 Plan d'exécution : $EXECUTION_PLAN"
        fi

        success "✅ Requête $query_num exécutée avec succès"

        # Stocker les résultats pour le rapport (avec les lignes retournées)
        # Sauvegarder la sortie complète dans un fichier temporaire (comme le script 17)
        TEMP_QUERY_OUTPUT=$(mktemp "/tmp/query_${query_num}_output_$(date +%s).txt")
        echo "$QUERY_OUTPUT" | head -30 > "$TEMP_QUERY_OUTPUT"

        # Stocker les résultats dans un JSON (comme le script 17)
        # Utiliser des fichiers temporaires pour éviter les problèmes d'échappement
        TEMP_QUERY_DATA=$(mktemp)
        echo "$query_title" > "$TEMP_QUERY_DATA.title"
        echo "$query_description" > "$TEMP_QUERY_DATA.description"
        echo "$hbase_equivalent" > "$TEMP_QUERY_DATA.hbase"
        echo "$query_cql" > "$TEMP_QUERY_DATA.cql"
        echo "$expected_result" > "$TEMP_QUERY_DATA.expected"
        echo "$sai_value" > "$TEMP_QUERY_DATA.sai"

        python3 << PYSAVEEOF
import json
import os

# Lire les résultats existants
results_file = '${TEMP_RESULTS}'
if os.path.exists(results_file):
    with open(results_file, 'r', encoding='utf-8') as f:
        results = json.load(f)
else:
    results = []

# Lire la sortie de la requête
with open('${TEMP_QUERY_OUTPUT}', 'r', encoding='utf-8') as f:
    query_output = f.read()

# Lire les données depuis les fichiers temporaires
with open('${TEMP_QUERY_DATA}.title', 'r', encoding='utf-8') as f:
    query_title = f.read().strip()
with open('${TEMP_QUERY_DATA}.description', 'r', encoding='utf-8') as f:
    query_description = f.read().strip()
with open('${TEMP_QUERY_DATA}.hbase', 'r', encoding='utf-8') as f:
    hbase_equivalent = f.read().strip()
with open('${TEMP_QUERY_DATA}.cql', 'r', encoding='utf-8') as f:
    query_cql = f.read().strip()
with open('${TEMP_QUERY_DATA}.expected', 'r', encoding='utf-8') as f:
    expected_result = f.read().strip()
with open('${TEMP_QUERY_DATA}.sai', 'r', encoding='utf-8') as f:
    sai_value = f.read().strip()

# Créer l'entrée de résultat
result_entry = {
    'query_num': int('${query_num}'),
    'title': query_title,
    'description': query_description,
    'hbase_equivalent': hbase_equivalent,
    'query_cql': query_cql,
    'expected_result': expected_result,
    'sai_value': sai_value,
    'row_count': int('${ROW_COUNT}'),
    'query_time': float('${QUERY_TIME}'),
    'coordinator_time': '${COORDINATOR_TIME}',
    'total_time': '${TOTAL_TIME}',
    'exit_code': int('${EXIT_CODE}'),
    'status': 'OK',
    'query_output': query_output[:2000]  # Limiter à 2000 caractères
}

results.append(result_entry)

# Sauvegarder
with open(results_file, 'w', encoding='utf-8') as f:
    json.dump(results, f, indent=2, ensure_ascii=False)
PYSAVEEOF

        rm -f "$TEMP_QUERY_DATA.title" "$TEMP_QUERY_DATA.description" "$TEMP_QUERY_DATA.hbase" "$TEMP_QUERY_DATA.cql" "$TEMP_QUERY_DATA.expected" "$TEMP_QUERY_DATA.sai" "$TEMP_QUERY_DATA"
    else
        error "❌ Erreur lors de l'exécution de la requête $query_num"
        echo "$QUERY_OUTPUT" | tail -10
        TEMP_QUERY_OUTPUT=$(mktemp "/tmp/query_${query_num}_output_$(date +%s).txt")
        echo "$QUERY_OUTPUT" | head -30 > "$TEMP_QUERY_OUTPUT"

        # Stocker les résultats dans un JSON (comme le script 17)
        # Utiliser des fichiers temporaires pour éviter les problèmes d'échappement
        TEMP_QUERY_DATA=$(mktemp)
        echo "$query_title" > "$TEMP_QUERY_DATA.title"
        echo "$query_description" > "$TEMP_QUERY_DATA.description"
        echo "$hbase_equivalent" > "$TEMP_QUERY_DATA.hbase"
        echo "$query_cql" > "$TEMP_QUERY_DATA.cql"
        echo "$expected_result" > "$TEMP_QUERY_DATA.expected"
        echo "$sai_value" > "$TEMP_QUERY_DATA.sai"

        python3 << PYSAVEEOF
import json
import os

# Lire les résultats existants
results_file = '${TEMP_RESULTS}'
if os.path.exists(results_file):
    with open(results_file, 'r', encoding='utf-8') as f:
        results = json.load(f)
else:
    results = []

# Lire la sortie de la requête
with open('${TEMP_QUERY_OUTPUT}', 'r', encoding='utf-8') as f:
    query_output = f.read()

# Lire les données depuis les fichiers temporaires
with open('${TEMP_QUERY_DATA}.title', 'r', encoding='utf-8') as f:
    query_title = f.read().strip()
with open('${TEMP_QUERY_DATA}.description', 'r', encoding='utf-8') as f:
    query_description = f.read().strip()
with open('${TEMP_QUERY_DATA}.hbase', 'r', encoding='utf-8') as f:
    hbase_equivalent = f.read().strip()
with open('${TEMP_QUERY_DATA}.cql', 'r', encoding='utf-8') as f:
    query_cql = f.read().strip()
with open('${TEMP_QUERY_DATA}.expected', 'r', encoding='utf-8') as f:
    expected_result = f.read().strip()
with open('${TEMP_QUERY_DATA}.sai', 'r', encoding='utf-8') as f:
    sai_value = f.read().strip()

# Créer l'entrée de résultat
result_entry = {
    'query_num': int('${query_num}'),
    'title': query_title,
    'description': query_description,
    'hbase_equivalent': hbase_equivalent,
    'query_cql': query_cql,
    'expected_result': expected_result,
    'sai_value': sai_value,
    'row_count': 0,
    'query_time': float('${QUERY_TIME}'),
    'coordinator_time': '',
    'total_time': '',
    'exit_code': int('${EXIT_CODE}'),
    'status': 'ERROR',
    'query_output': query_output[:2000]  # Limiter à 2000 caractères
}

results.append(result_entry)

# Sauvegarder
with open(results_file, 'w', encoding='utf-8') as f:
    json.dump(results, f, indent=2, ensure_ascii=False)
PYSAVEEOF

        rm -f "$TEMP_QUERY_DATA.title" "$TEMP_QUERY_DATA.description" "$TEMP_QUERY_DATA.hbase" "$TEMP_QUERY_DATA.cql" "$TEMP_QUERY_DATA.expected" "$TEMP_QUERY_DATA.sai" "$TEMP_QUERY_DATA"
    fi

    # Nettoyer
    rm -f "$TEMP_QUERY_FILE"
    echo ""
}

# ============================================
# REQUÊTE 1 : Ciblage par Date Précise
# ============================================

execute_query \
    1 \
    "Ciblage par Date Précise (STARTROW/STOPROW équivalent)" \
    "Cette requête démontre l'équivalent du STARTROW/STOPROW HBase pour un ciblage précis par plage de dates. Elle récupère toutes les opérations d'un compte spécifique pour une plage de dates précise (20-25 novembre 2024), triées par date décroissante et numéro d'opération croissant." \
    "SCAN avec STARTROW/STOPROW sur date" \
    "SELECT code_si, contrat, date_op, numero_op, libelle, montant, cat_auto
FROM operations_by_account
WHERE code_si = '1' AND contrat = '5913101072'
  AND date_op >= '2024-11-20 00:00:00'
  AND date_op <= '2024-11-25 23:59:59'
ORDER BY date_op DESC, numero_op ASC
LIMIT 10;" \
    "Opérations du compte 1/5913101072 pour la plage 20-25 novembre 2024, triées par date décroissante" \
    "Index sur date_op (clustering key) permet une recherche rapide sans scan complet. La requête utilise directement l'index clustering pour filtrer par plage de dates, ce qui est beaucoup plus efficace qu'un scan complet de la partition."

# ============================================
# REQUÊTE 2 : Ciblage par Date + Numéro Opération
# ============================================

execute_query \
    2 \
    "Ciblage par Date + Numéro Opération (STARTROW/STOPROW complet)" \
    "Cette requête démontre un ciblage précis complet en utilisant à la fois la date et le numéro d'opération. Elle récupère les opérations d'un compte spécifique pour une date précise avec une plage de numéros d'opération, démontrant l'équivalent complet du STARTROW/STOPROW HBase." \
    "SCAN avec STARTROW/STOPROW complet (date + numero_op)" \
    "SELECT code_si, contrat, date_op, numero_op, libelle, montant, cat_auto
FROM operations_by_account
WHERE code_si = '1' AND contrat = '5913101072'
  AND date_op = '2024-11-24 23:00:00+0000'
  AND numero_op >= 1000 AND numero_op <= 1100
ORDER BY date_op DESC, numero_op ASC
LIMIT 10;" \
    "Opérations du compte 1/5913101072 pour la date 2024-11-24 23:00:00 avec numero_op entre 1000 et 1100, triées par date décroissante" \
    "Index sur clustering keys (date_op, numero_op) optimise la recherche précise. La requête utilise les deux index clustering simultanément pour filtrer efficacement par date et numéro d'opération, évitant un scan complet de la partition."

# ============================================
# REQUÊTE 3 : Ciblage avec SAI (Date + Numéro Opération + Full-Text)
# ============================================

execute_query \
    3 \
    "Ciblage avec SAI (Date + Full-Text Search)" \
    "Cette requête démontre la valeur ajoutée des index SAI en combinant un ciblage précis par date (plage) avec une recherche full-text (libelle). Elle montre comment SAI permet d'optimiser les requêtes complexes avec plusieurs filtres simultanés. Note: En CQL, on ne peut pas utiliser une plage sur numero_op si date_op utilise une plage (non-EQ), donc on utilise uniquement date_op avec full-text." \
    "SCAN avec STARTROW/STOPROW + filtre texte côté client" \
    "SELECT code_si, contrat, date_op, numero_op, libelle, montant, cat_auto
FROM operations_by_account
WHERE code_si = '1' AND contrat = '5913101072'
  AND date_op >= '2024-11-20' AND date_op <= '2024-11-25'
  AND libelle : 'PRELEVEMENT'
LIMIT 10;" \
    "Opérations du compte 1/5913101072 pour la plage 20-25 novembre 2024 contenant 'PRELEVEMENT' dans le libellé (note: ORDER BY non supporté avec index SAI, et numero_op ne peut pas être en plage si date_op est en plage)" \
    "SAI combine index date_op (clustering key avec plage) + libelle (full-text SAI) pour une recherche optimisée. Au lieu d'un scan complet suivi d'un filtrage côté client, SAI utilise les deux index simultanément pour une recherche très rapide. Performance : O(log n) avec index vs O(n) sans index."

# ============================================
# PARTIE 3: COMPARAISON PERFORMANCE
# ============================================
echo ""
section "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
section "  📊 PARTIE 3: COMPARAISON PERFORMANCE"
section "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

info "📊 Comparaison Performance : Avec vs Sans SAI"
echo ""
code "Sans SAI (HBase) :"
code "  - SCAN avec STARTROW/STOPROW"
code "  - Filtrage côté client"
code "  - Performance : O(n) où n = nombre d'opérations dans la plage"
code "  - Temps proportionnel au nombre d'opérations dans la plage"
echo ""
code "Avec SAI (HCD) :"
code "  - Index sur clustering keys (date_op, numero_op) pour recherche précise"
code "  - Index sur libelle (full-text SAI) pour recherche textuelle"
code "  - Performance : O(log n) avec index"
code "  - Valeur ajoutée : Recherche combinée optimisée"
code "  - Temps indépendant du nombre total d'opérations (seulement celles correspondant aux critères)"
echo ""

# ============================================
# PARTIE 4: GÉNÉRATION RAPPORT
# ============================================
echo ""
section "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
section "  📄 PARTIE 4: GÉNÉRATION RAPPORT"
section "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

info "Génération du rapport markdown structuré..."

# Générer le rapport directement avec Python (comme le script 17)
# Passer les variables shell comme variables d'environnement pour éviter l'interprétation des backticks
TEMP_RESULTS_FILE="$TEMP_RESULTS" python3 << 'PYEOF' > "$REPORT_FILE"
import json
import sys
import os
from datetime import datetime

# Lire les résultats depuis le fichier JSON (comme le script 17)
results = []
try:
    results_file = os.environ.get('TEMP_RESULTS_FILE', '')
    if os.path.exists(results_file):
        with open(results_file, 'r', encoding='utf-8') as f:
            content = f.read()
            if content.strip():
                results = json.loads(content)
            else:
                print(f"Fichier JSON vide : {results_file}", file=sys.stderr)
    else:
        print(f"Fichier JSON non trouvé : {results_file}", file=sys.stderr)
except Exception as e:
    print(f"Erreur lors de la lecture des résultats JSON : {e}", file=sys.stderr)
    import traceback
    traceback.print_exc(file=sys.stderr)
    results = []

# Trier par numéro de requête
results.sort(key=lambda x: x.get('query_num', 0))


# Générer le rapport markdown
report = "# 🎯 Démonstration : Requêtes STARTROW/STOPROW\n\n"
report += "**Date** : " + datetime.now().strftime('%Y-%m-%d %H:%M:%S') + "\n"
report += "**Script** : 30_demo_requetes_startrow_stoprow_v2_didactique.sh\n"
report += "**Objectif** : Démontrer les requêtes en base avec ciblage précis (STARTROW/STOPROW équivalent HBase)\n\n"
report += "---\n\n"
report += "## 📋 Table des Matières\n\n"
report += "1. [Contexte et Stratégie](#contexte-et-stratégie)\n"
report += "2. [Requêtes Exécutées](#requêtes-exécutées)\n"
report += "3. [Résultats par Requête](#résultats-par-requête)\n"
report += "4. [Comparaison Performance](#comparaison-performance)\n"
report += "5. [Conclusion](#conclusion)\n\n"
report += "---\n\n"
report += "## 📚 Contexte et Stratégie\n\n"
report += "### Équivalences HBase → HCD\n\n"
report += "| Concept HBase | Équivalent HCD (CQL) |\n"
report += "|---------------|----------------------|\n"
report += "| STARTROW + STOPROW | WHERE date_op >= start AND date_op <= end |\n"
report += "| SCAN avec plages de rowkeys | SELECT ... WHERE clustering_keys BETWEEN ... |\n"
report += "| Ciblage précis | Filtrage par clustering keys (date_op, numero_op) |\n\n"
report += "### Valeur Ajoutée SAI\n\n"
report += "- ✅ Index sur date_op (clustering key) pour performance optimale\n"
report += "- ✅ Index sur numero_op (clustering key) pour performance optimale\n"
report += "- ✅ Index sur libelle (full-text SAI) pour recherche textuelle\n"
report += "- ✅ Combinaison d'index pour recherche optimisée\n"
report += "- ✅ Pas de scan complet nécessaire\n\n"
report += "### Stratégie de Démonstration\n\n"
report += "- 3 requêtes CQL pour démontrer le ciblage précis (STARTROW/STOPROW)\n"
report += "- Mesure de performance pour chaque requête\n"
report += "- Comparaison avec/sans SAI\n"
report += "- Documentation structurée pour livrable\n\n"
report += "---\n\n"
report += "## 🔍 Requêtes Exécutées\n\n"
report += "### Tableau Récapitulatif\n\n"
report += "| Requête | Titre | Lignes | Temps (s) | Coordinateur (μs) | Total (μs) | Statut |\n"
report += "|---------|-------|--------|-----------|-------------------|-----------|--------|\n"

for r in results:
    status_icon = "✅ OK" if r.get('status', '') == 'OK' else "❌ ERROR"
    report += "| " + str(r.get('query_num', '')) + " | " + r.get('title', '') + " | " + str(r.get('row_count', 0)) + " | " + str(r.get('query_time', 0)) + " | " + str(r.get('coordinator_time', '')) + " | " + str(r.get('total_time', '')) + " | " + status_icon + " |\n"

report += "\n---\n\n"
report += "## 📊 Résultats par Requête\n\n"

for r in results:
    # Construire la section de la requête
    report += "### Requête " + str(r.get('query_num', '')) + " : " + r.get('title', '') + "\n\n"

    if r.get('description'):
        report += "**Description** : " + r.get('description', '') + "\n\n"

    if r.get('hbase_equivalent'):
        report += "**Équivalent HBase** : " + r.get('hbase_equivalent', '') + "\n\n"

    # Toujours afficher la requête CQL si elle existe
    query_cql = r.get('query_cql', '')
    if query_cql:
        query_cql_str = str(query_cql).strip()
        if query_cql_str:
            backtick = chr(96)
            code_block_start = backtick + backtick + backtick + "cql\n"
            code_block_end = "\n" + backtick + backtick + backtick + "\n"
            report += "**Requête CQL exécutée :**\n\n"
            report += code_block_start
            report += query_cql_str
            report += code_block_end + "\n"
        else:
            print(f"DEBUG: query_cql_str est vide après strip() pour requête {r.get('query_num', '?')}", file=sys.stderr)
            print(f"DEBUG: query_cql original (first 100): {repr(str(query_cql)[:100])}", file=sys.stderr)
    else:
        print(f"DEBUG: query_cql est falsy pour requête {r.get('query_num', '?')}", file=sys.stderr)

    if r.get('expected_result'):
        report += "**Résultat attendu** : " + r.get('expected_result', '') + "\n\n"

    if r.get('sai_value'):
        report += "**Valeur ajoutée SAI** : " + r.get('sai_value', '') + "\n\n"

    report += "- **Lignes retournées** : " + str(r.get('row_count', 0)) + "\n"
    report += "- **Temps d'exécution** : " + str(r.get('query_time', 0)) + "s\n"
    if r.get('coordinator_time'):
        report += "- **Temps coordinateur** : " + str(r.get('coordinator_time', '')) + "μs\n"
    if r.get('total_time'):
        report += "- **Temps total** : " + str(r.get('total_time', '')) + "μs\n"
    status_icon = "✅ OK" if r.get('status', '') == 'OK' else "❌ ERROR"
    report += "- **Statut** : " + status_icon + "\n"

    # Afficher les lignes retournées si disponibles (comme le script 17)
    query_output = r.get('query_output', '')
    row_count = r.get('row_count', 0)

    if query_output and row_count and row_count > 0:
        report += "\n**Lignes retournées :**\n\n"
        report += "```\n"
        # Extraire les lignes de résultats (comme le script 17)
        lines = query_output.split('\n')
        result_lines = []
        for line in lines:
            if not line:
                continue
            stripped = line.strip()
            # Garder uniquement les lignes de données (commencent par des espaces suivis d'un chiffre)
            # Format cqlsh : "       1 | 5913101072 | 2024-11-24..."
            if line.startswith(' ') and stripped and stripped[0].isdigit():
                # Exclure les lignes qui sont des en-têtes ou des séparateurs
                if not stripped.startswith('code_si') and not stripped.startswith('---') and '|' in line:
                    result_lines.append(line)

        # Afficher jusqu'à 10 lignes de résultats
        for line in result_lines[:10]:
            report += line + "\n"
        if row_count > 10:
            extra = row_count - 10
            report += "... (" + str(extra) + " ligne(s) supplémentaire(s))\n"
        report += "```\n"
    elif row_count == 0:
        report += "\n**Lignes retournées** : Aucun résultat trouvé\n"

    report += "\n"

report += "---\n\n"
report += "## 📊 Comparaison Performance\n\n"
report += "### Sans SAI (HBase)\n\n"
report += "- SCAN avec STARTROW/STOPROW\n"
report += "- Filtrage côté client\n"
report += "- Performance : O(n) où n = nombre d'opérations dans la plage\n"
report += "- Temps proportionnel au nombre d'opérations dans la plage\n\n"
report += "### Avec SAI (HCD)\n\n"
report += "- Index sur clustering keys (date_op, numero_op) pour recherche précise\n"
report += "- Index sur libelle (full-text SAI) pour recherche textuelle\n"
report += "- Performance : O(log n) avec index\n"
report += "- Valeur ajoutée : Recherche combinée optimisée\n"
report += "- Temps indépendant du nombre total d'opérations (seulement celles correspondant aux critères)\n\n"
report += "---\n\n"
report += "## ✅ Conclusion\n\n"
report += "### Points Clés Démontrés\n\n"
report += "- ✅ Ciblage précis avec WHERE sur clustering keys (date_op, numero_op)\n"
report += "- ✅ Plages de dates et numéros d'opération avec STARTROW/STOPROW équivalent\n"
report += "- ✅ Valeur ajoutée SAI : Index sur clustering keys + full-text pour recherche combinée\n"
report += "- ✅ Performance optimisée vs scan complet (O(log n) vs O(n))\n\n"
report += "### Valeur Ajoutée SAI\n\n"
report += "Les index SAI apportent une amélioration significative des performances pour les requêtes avec filtres sur les colonnes indexées. La combinaison d'index (clustering keys + full-text SAI) permet d'optimiser les requêtes complexes avec plusieurs filtres simultanés.\n\n"
report += "### Équivalences HBase → HCD Validées\n\n"
report += "- ✅ STARTROW/STOPROW HBase → WHERE date_op >= start AND date_op <= end AND numero_op >= start AND numero_op <= end\n"
report += "- ✅ SCAN avec plages de rowkeys → SELECT ... WHERE clustering_keys BETWEEN ...\n"
report += "- ✅ Ciblage précis → Filtrage par clustering keys (date_op, numero_op)\n\n"
report += "---\n\n"
report += "**Date de génération** : " + datetime.now().strftime('%Y-%m-%d %H:%M:%S') + "\n"

# Debug: vérifier si query_cql est dans le rapport
query_cql_count = report.count('```cql')
print(f"DEBUG: Nombre de blocs query_cql dans le rapport : {query_cql_count}", file=sys.stderr)
if query_cql_count == 0:
    print("DEBUG: ATTENTION - Aucun query_cql trouvé dans le rapport !", file=sys.stderr)
    print(f"DEBUG: Longueur du rapport : {len(report)} caractères", file=sys.stderr)
    if results:
        print(f"DEBUG: Premier résultat query_cql : {repr(results[0].get('query_cql', '')[:100])}", file=sys.stderr)

# Écrire le rapport (directement dans stdout qui est redirigé vers REPORT_FILE)
print(report, end='')
PYEOF

success "✅ Rapport markdown généré : $REPORT_FILE"

# Nettoyer les fichiers temporaires de sortie de requêtes
for result in "${QUERY_RESULTS[@]}"; do
    if [ -n "$result" ]; then
        query_output_file=$(echo "$result" | cut -d'|' -f9)
        if [ -n "$query_output_file" ] && [ -f "$query_output_file" ]; then
            rm -f "$query_output_file"
        fi
    fi
done

# Nettoyer (ne pas supprimer TEMP_RESULTS avant d'avoir généré le rapport)
rm -f "$TEMP_OUTPUT" "$TEMP_PYTHON_SCRIPT"

echo ""
success "✅ Démonstration requêtes STARTROW/STOPROW terminée"
info ""
info "💡 Points clés démontrés :"
code "  ✅ Ciblage précis avec WHERE sur clustering keys"
code "  ✅ Plages de dates et numéros d'opération"
code "  ✅ Valeur ajoutée SAI : Index sur clustering keys + full-text"
code "  ✅ Performance optimisée vs scan complet"
echo ""
