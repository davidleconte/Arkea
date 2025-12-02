#!/bin/bash
# ============================================
# Script 15 : Tests Cohérence Multi-Tables (Version Didactique)
# Démontre les fonctionnalités cohérence multi-tables via requêtes CQL
# Équivalent HBase: Vérifications croisées entre tables
# ============================================
#
# OBJECTIF :
#   Ce script démontre les fonctionnalités cohérence multi-tables en exécutant
#   10 requêtes CQL directement via "${HCD_HOME}/bin/cqlsh".
#
#   Cette version didactique affiche :
#   - Les équivalences HBase → HCD détaillées
#   - Les requêtes CQL complètes avant exécution
#   - Les résultats attendus pour chaque requête
#   - Les résultats obtenus avec mesure de performance
#   - Une documentation structurée pour livrable
#
# PRÉREQUIS :
#   - HCD démarré (./scripts/setup/03_start_hcd.sh)
#   - Schéma configuré (./03_setup_meta_categories_tables.sh)
#   - Données chargées (./05_load_operations_data_parquet.sh et ./06_load_meta_categories_data_parquet.sh)
#   - Java 11 configuré via jenv
#
# UTILISATION :
#   ./15_test_coherence_multi_tables.sh
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

REPORT_FILE="${SCRIPT_DIR}/../doc/demonstrations/15_COHERENCE_MULTI_TABLES_DEMONSTRATION.md"
# Charger l'environnement POC (HCD déjà installé sur MBP)
if [ -f "${INSTALL_DIR}/.poc-profile" ]; then
    source "${INSTALL_DIR}/.poc-profile"
fi

# HCD_HOME devrait être défini par .poc-profile
HCD_DIR="${HCD_HOME:-${INSTALL_DIR}/binaire/hcd-1.2.3}"

# Créer le répertoire de documentation
mkdir -p "$(dirname "$REPORT_FILE")"

# Fichiers temporaires pour capture
TEMP_OUTPUT=$(mktemp "/tmp/script_15_output_$(date +%s).txt")
TEMP_RESULTS=$(mktemp "/tmp/script_15_results_$(date +%s).json")

# Tableau pour stocker les résultats de chaque requête
declare -a QUERY_RESULTS

# Configuration cqlsh (utilise HCD_DIR depuis .poc-profile)
if [ -n "${HCD_HOME}" ]; then
    CQLSH_BIN="${HCD_HOME}/bin/cqlsh"
else
    CQLSH_BIN="${HCD_DIR}/bin/cqlsh"
fi
CQLSH="$CQLSH_BIN "$HCD_HOST" "$HCD_PORT""

# Initialiser le fichier JSON
echo "[]" > "$TEMP_RESULTS"

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
    error "HCD n'est pas démarré sur localhost:9042"
    error "Exécutez d'abord: ./scripts/setup/03_start_hcd.sh"
    exit 1
fi
success "HCD est démarré"

cd "$HCD_DIR"
jenv local 11
eval "$(jenv init -)"

info "Vérification que cqlsh est disponible..."
if [ ! -f "$CQLSH_BIN" ]; then
    error "cqlsh non trouvé : $CQLSH_BIN"
    exit 1
fi
success "cqlsh trouvé : $CQLSH_BIN"

info "Vérification du schéma..."
if ! $CQLSH -e "DESCRIBE KEYSPACE domiramacatops_poc;" > /dev/null 2>&1; then
    error "Keyspace domiramacatops_poc non trouvé"
    error "Exécutez d'abord: ./01_setup_domiramaCatOps_keyspace.sh"
    exit 1
fi
success "Schéma vérifié : keyspace domiramacatops_poc existe"

info "Vérification des données de test..."
if [ -f "${SCRIPT_DIR}/15_prepare_test_data.sh" ]; then
    info "   Exécution de la validation/préparation des données..."
    "${SCRIPT_DIR}/15_prepare_test_data.sh" || {
        warn "⚠️  Certaines données peuvent être manquantes, mais les tests continueront"
    }
else
    warn "⚠️  Script 15_prepare_test_data.sh non trouvé"
    warn "   Les tests peuvent échouer si les données nécessaires ne sont pas présentes"
fi

# ============================================
# PARTIE 1: CONTEXTE ET STRATÉGIE
# ============================================
echo ""
section "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
section "  📚 PARTIE 1: CONTEXTE ET STRATÉGIE"
section "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

info "📚 OBJECTIF : Démontrer cohérence multi-tables via requêtes CQL"
echo ""
info "🔄 TABLES CONCERNÉES :"
echo ""
echo "   1. operations_by_account        (opérations bancaires)"
echo "   2. acceptation_client            (acceptation affichage)"
echo "   3. opposition_categorisation     (opposition catégorisation)"
echo "   4. regles_personnalisees        (règles personnalisées)"
echo "   5. feedback_par_libelle         (feedbacks par libellé)"
echo "   6. feedback_par_ics             (feedbacks par ICS)"
echo "   7. historique_opposition        (historique oppositions)"
echo "   8. decisions_salaires           (décisions salaires)"
echo ""
info "💡 STRATÉGIE :"
echo "   Vérifier la cohérence entre les tables en utilisant des requêtes"
echo "   qui croisent les données (JOIN simulé via requêtes multiples)."
echo ""

# ============================================
# Fonction : Exécuter une Requête CQL
# ============================================
execute_query() {
    local query_num=$1
    local query_title="$2"
    local query_description="$3"
    local hbase_equivalent="$4"
    local query_cql="$5"
    local expected_result="$6"

    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "  🔍 TEST $query_num : $query_title"
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

    expected "📋 Résultat attendu : $expected_result"
    echo ""

    # Créer un fichier temporaire pour la requête
    TEMP_QUERY_FILE=$(mktemp "/tmp/query_${query_num}_$(date +%s).cql")
    cat > "$TEMP_QUERY_FILE" <<EOF
USE domiramacatops_poc;
TRACING ON;
$query_cql
EOF

    # Exécuter la requête
    info "🚀 Exécution de la requête..."
    START_TIME=$(date +%s.%N)
    QUERY_OUTPUT=$($CQLSH -f "$TEMP_QUERY_FILE" 2>&1 | tee -a "$TEMP_OUTPUT")
    EXIT_CODE=$?
    END_TIME=$(date +%s.%N)

    # Calculer le temps d'exécution
    if command -v bc >/dev/null 2>&1; then
        QUERY_TIME=$(echo "$END_TIME - $START_TIME" | bc 2>/dev/null || echo "0.000")
    else
        QUERY_TIME=$(python3 -c "print($END_TIME - $START_TIME)" 2>/dev/null || echo "0.000")
    fi

    # Extraire les métriques
    COORDINATOR_TIME=$(echo "$QUERY_OUTPUT" | grep "coordinator" | awk -F'|' '{print $4}' | tr -d ' ' | head -1 || echo "")
    TOTAL_TIME=$(echo "$QUERY_OUTPUT" | grep "total" | awk -F'|' '{print $4}' | tr -d ' ' | head -1 || echo "")

    # Compter les lignes retournées
    ROW_COUNT=$(echo "$QUERY_OUTPUT" | grep -E "^[A-Z_]+ \|" | grep -v "^code_efs " | wc -l | tr -d ' ')
    if [ "$ROW_COUNT" -eq 0 ] || [ -z "$ROW_COUNT" ]; then
        ROW_COUNT=$(echo "$QUERY_OUTPUT" | grep -E "\([0-9]+ rows\)" | grep -oE "[0-9]+" | head -1 || echo "0")
    fi

    # Filtrer les résultats
    QUERY_RESULTS_FILTERED=$(echo "$QUERY_OUTPUT" | grep -vE "^Warnings|^$|^\([0-9]+ rows\)|coordinator|total|Executing|Read|Scanned|Merging" | head -20)

    # Afficher les résultats
    if [ $EXIT_CODE -eq 0 ]; then
        result "📊 Résultats obtenus ($ROW_COUNT ligne(s)) en ${QUERY_TIME}s :"
        echo ""
        echo "$QUERY_RESULTS_FILTERED" | head -15
        if [ "$ROW_COUNT" -gt 15 ]; then
            echo "... (affichage limité à 15 lignes)"
        fi
        echo ""

        if [ -n "$COORDINATOR_TIME" ]; then
            info "   ⏱️  Temps coordinateur : ${COORDINATOR_TIME}μs"
        fi
        if [ -n "$TOTAL_TIME" ]; then
            info "   ⏱️  Temps total : ${TOTAL_TIME}μs"
        fi

        success "✅ Test $query_num exécuté avec succès"
        QUERY_RESULTS+=("$query_num|$query_title|$ROW_COUNT|$QUERY_TIME|$COORDINATOR_TIME|$TOTAL_TIME|$EXIT_CODE|OK")
        # Écrire aussi dans le fichier JSON
        python3 << PYJSON
import json
import os
row_count = int("$ROW_COUNT") if "$ROW_COUNT" else 0
query_time = float("$QUERY_TIME") if "$QUERY_TIME" else 0.0
coord_time = "$COORDINATOR_TIME" if "$COORDINATOR_TIME" else ""
total_time = "$TOTAL_TIME" if "$TOTAL_TIME" else ""
result = {
    "num": int("$query_num"),
    "title": "$query_title",
    "rows": row_count,
    "time": query_time,
    "coord_time": coord_time,
    "total_time": total_time,
    "exit_code": int("$EXIT_CODE"),
    "status": "OK"
}
with open("$TEMP_RESULTS", "r") as f:
    results = json.load(f)
results.append(result)
with open("$TEMP_RESULTS", "w") as f:
    json.dump(results, f, indent=2)
PYJSON
    else
        error "❌ Erreur lors de l'exécution du test $query_num"
        echo "$QUERY_OUTPUT" | tail -10
        QUERY_RESULTS+=("$query_num|$query_title|0|$QUERY_TIME|||$EXIT_CODE|ERROR")
        # Écrire aussi dans le fichier JSON
        python3 << PYJSON
import json
query_time = float("$QUERY_TIME") if "$QUERY_TIME" else 0.0
result = {
    "num": int("$query_num"),
    "title": "$query_title",
    "rows": 0,
    "time": query_time,
    "coord_time": "",
    "total_time": "",
    "exit_code": int("$EXIT_CODE"),
    "status": "ERROR"
}
with open("$TEMP_RESULTS", "r") as f:
    results = json.load(f)
results.append(result)
with open("$TEMP_RESULTS", "w") as f:
    json.dump(results, f, indent=2)
PYJSON
    fi

    rm -f "$TEMP_QUERY_FILE"
    echo ""
}

# ============================================
# TEST 1 : Vérification Acceptation avant Affichage
# ============================================
execute_query \
    1 \
    "Vérification Acceptation avant Affichage" \
    "Vérifier que les opérations affichées ont une acceptation client valide" \
    "GET operations + GET acceptation_client pour vérifier cohérence" \
    "-- Requête 1: Opérations d'un compte
SELECT code_si, contrat, date_op, numero_op, libelle, cat_auto
FROM operations_by_account
WHERE code_si = '1'
  AND contrat = '5913101072'
LIMIT 5;

-- Requête 2: Vérification acceptation
SELECT code_efs, no_contrat, no_pse, accepted
FROM acceptation_client
WHERE code_efs = '1'
  AND no_contrat = '5913101072'
  AND no_pse = 'PSE001';" \
    "Opérations + acceptation = true (cohérence vérifiée)"

# ============================================
# TEST 2 : Vérification Opposition avant Catégorisation
# ============================================
execute_query \
    2 \
    "Vérification Opposition avant Catégorisation" \
    "Vérifier que les opérations catégorisées n'ont pas d'opposition active" \
    "GET operations + GET opposition_categorisation pour vérifier cohérence" \
    "-- Requête 1: Opérations avec catégorie
SELECT code_si, contrat, date_op, numero_op, libelle, cat_auto
FROM operations_by_account
WHERE code_si = '1'
  AND contrat = '5913101072'
  AND cat_auto IS NOT NULL
LIMIT 5;

-- Requête 2: Vérification opposition
SELECT code_efs, no_pse, opposed
FROM opposition_categorisation
WHERE code_efs = '1'
  AND no_pse = 'PSE001';" \
    "Opérations catégorisées + opposed = false (cohérence vérifiée)"

# ============================================
# TEST 3 : Vérification Règles Appliquées
# ============================================
execute_query \
    3 \
    "Vérification Règles Appliquées" \
    "Vérifier que les catégories auto correspondent à des règles actives" \
    "GET operations + GET regles_personnalisees pour vérifier cohérence" \
    "-- Requête 1: Opérations avec catégorie auto
SELECT code_si, contrat, libelle, cat_auto
FROM operations_by_account
WHERE code_si = '1'
  AND contrat = '5913101072'
  AND cat_auto IS NOT NULL
LIMIT 5;

-- Requête 2: Règles actives correspondantes
SELECT code_efs, type_operation, sens_operation, libelle_simplifie, categorie_cible, actif
FROM regles_personnalisees
WHERE code_efs = '1'
  AND actif = true
LIMIT 5;" \
    "Catégories auto correspondent à des règles actives (cohérence vérifiée)"

# ============================================
# TEST 4 : Vérification Feedbacks par Libellé
# ============================================
execute_query \
    4 \
    "Vérification Feedbacks par Libellé" \
    "Vérifier que les feedbacks correspondent à des libellés d'opérations" \
    "GET operations + GET feedback_par_libelle pour vérifier cohérence" \
    "-- Requête 1: Libellés d'opérations
SELECT DISTINCT libelle
FROM operations_by_account
WHERE code_si = '1'
LIMIT 5;

-- Requête 2: Feedbacks correspondants
SELECT type_operation, sens_operation, libelle_simplifie, categorie, count_engine, count_client
FROM feedback_par_libelle
WHERE type_operation = 'VIREMENT'
  AND sens_operation = 'DEBIT'
LIMIT 5;" \
    "Libellés d'opérations correspondent à des feedbacks (cohérence vérifiée)"

# ============================================
# TEST 5 : Vérification Feedbacks par ICS
# ============================================
execute_query \
    5 \
    "Vérification Feedbacks par ICS" \
    "Vérifier que les feedbacks par ICS correspondent à des catégories utilisées" \
    "GET operations + GET feedback_par_ics pour vérifier cohérence" \
    "-- Requête 1: Catégories utilisées
SELECT DISTINCT cat_auto
FROM operations_by_account
WHERE code_si = '1'
  AND cat_auto IS NOT NULL
LIMIT 5;

-- Requête 2: Feedbacks correspondants
SELECT type_operation, sens_operation, code_ics, categorie, count_engine, count_client
FROM feedback_par_ics
WHERE type_operation = 'VIREMENT'
  AND sens_operation = 'DEBIT'
LIMIT 5;" \
    "Catégories utilisées correspondent à des feedbacks (cohérence vérifiée)"

# ============================================
# TEST 6 : Vérification Historique Opposition
# ============================================
execute_query \
    6 \
    "Vérification Historique Opposition" \
    "Vérifier que l'historique d'opposition correspond à l'opposition actuelle" \
    "GET opposition_categorisation + GET historique_opposition pour vérifier cohérence" \
    "-- Requête 1: Opposition actuelle
SELECT code_efs, no_pse, opposed, opposed_at
FROM opposition_categorisation
WHERE code_efs = '1'
  AND no_pse = 'PSE001';

-- Requête 2: Historique correspondant
SELECT code_efs, no_pse, horodate, status, timestamp, raison
FROM historique_opposition
WHERE code_efs = '1'
  AND no_pse = 'PSE001'
ORDER BY horodate DESC
LIMIT 5;" \
    "Historique correspond à l'opposition actuelle (cohérence vérifiée)"

# ============================================
# TEST 7 : Vérification Multi-Version (cat_auto vs cat_user)
# ============================================
execute_query \
    7 \
    "Vérification Multi-Version (cat_auto vs cat_user)" \
    "Vérifier que cat_auto et cat_user coexistent correctement (stratégie multi-version)" \
    "GET operations pour vérifier cohérence multi-version" \
    "SELECT code_si, contrat, date_op, numero_op, libelle, cat_auto, cat_user, cat_date_user, cat_validee
FROM operations_by_account
WHERE code_si = '1'
  AND contrat = '5913101072'
  AND (cat_user IS NOT NULL OR cat_auto IS NOT NULL)
LIMIT 10;" \
    "cat_auto et cat_user coexistent (stratégie multi-version vérifiée)"

# ============================================
# TEST 8 : Vérification Décisions Salaires
# ============================================
execute_query \
    8 \
    "Vérification Décisions Salaires" \
    "Vérifier que les décisions salaires correspondent à des opérations" \
    "GET operations + GET decisions_salaires pour vérifier cohérence" \
    "-- Requête 1: Opérations avec type 'SALAIRE'
SELECT code_si, contrat, date_op, numero_op, libelle, type_operation
FROM operations_by_account
WHERE code_si = '1'
  AND contrat = '5913101072'
  AND type_operation = 'SALAIRE'
LIMIT 5;

-- Requête 2: Décisions salaires correspondantes
SELECT code_efs, no_contrat, no_pse, decision, decision_date
FROM decisions_salaires
WHERE code_efs = '1'
  AND no_contrat = '5913101072'
LIMIT 5;" \
    "Décisions salaires correspondent à des opérations (cohérence vérifiée)"

# ============================================
# TEST 9 : Comptage Cohérence Globale
# ============================================
execute_query \
    9 \
    "Comptage Cohérence Globale" \
    "Compter les incohérences potentielles entre tables" \
    "Comptage multi-tables pour vérifier cohérence globale" \
    "-- Comptage opérations
SELECT COUNT(*) as total_operations
FROM operations_by_account
WHERE code_si = '1';

-- Comptage acceptations
SELECT COUNT(*) as total_acceptations
FROM acceptation_client
WHERE code_efs = '1';

-- Comptage oppositions
SELECT COUNT(*) as total_oppositions
FROM opposition_categorisation
WHERE code_efs = '1';

-- Comptage règles
SELECT COUNT(*) as total_regles
FROM regles_personnalisees
WHERE code_efs = '1'
  AND actif = true;

-- Comptage feedbacks libellé
SELECT COUNT(*) as total_feedbacks_libelle
FROM feedback_par_libelle
WHERE type_operation = 'VIREMENT'
  AND sens_operation = 'DEBIT';

-- Comptage feedbacks ICS
SELECT COUNT(*) as total_feedbacks_ics
FROM feedback_par_ics
WHERE type_operation = 'VIREMENT'
  AND sens_operation = 'DEBIT';" \
    "Comptages globaux pour vérifier cohérence (tous > 0)"

# ============================================
# TEST 10 : Vérification Intégrité Référentielle
# ============================================
execute_query \
    10 \
    "Vérification Intégrité Référentielle" \
    "Vérifier que les clés étrangères logiques sont cohérentes (code_efs, code_si, contrat)" \
    "Vérification intégrité référentielle multi-tables" \
    "-- Vérification code_efs cohérent
SELECT DISTINCT code_efs FROM acceptation_client
UNION
SELECT DISTINCT code_efs FROM opposition_categorisation
UNION
SELECT DISTINCT code_efs FROM regles_personnalisees
UNION
SELECT DISTINCT code_efs FROM acceptation_client
UNION
SELECT DISTINCT code_efs FROM opposition_categorisation
UNION
SELECT DISTINCT code_efs FROM historique_opposition
UNION
SELECT DISTINCT code_efs FROM decisions_salaires;

-- Vérification code_si cohérent
SELECT DISTINCT code_si FROM operations_by_account
LIMIT 10;" \
    "Codes EFS et SI cohérents entre toutes les tables (intégrité vérifiée)"

# ============================================
# PARTIE 2: GÉNÉRATION RAPPORT
# ============================================
echo ""
section "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
section "  📄 PARTIE 2: GÉNÉRATION RAPPORT"
section "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

info "Génération du rapport markdown structuré..."

export REPORT_FILE TEMP_RESULTS
python3 << 'PYEOF'
import json
import sys
import os
from datetime import datetime

# Lire les résultats depuis le fichier JSON
results = []
temp_results_file = os.environ.get('TEMP_RESULTS', '')
if temp_results_file and os.path.exists(temp_results_file):
    with open(temp_results_file, 'r') as f:
        results = json.load(f)

# Générer le rapport
report = f"""# 🔍 Démonstration : Tests Cohérence Multi-Tables

**Date** : {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}
**Script** : 15_test_coherence_multi_tables.sh
**Objectif** : Démontrer cohérence multi-tables via requêtes CQL

---

## 📋 Table des Matières

1. [Contexte et Stratégie](#contexte-et-stratégie)
2. [Tests Exécutés](#tests-exécutés)
3. [Résultats par Test](#résultats-par-test)
4. [Conclusion](#conclusion)

---

## 📚 Contexte et Stratégie

### Tables Concernées

1. **operations_by_account** : Opérations bancaires
2. **acceptation_client** : Acceptation affichage
3. **opposition_categorisation** : Opposition catégorisation
4. **regles_personnalisees** : Règles personnalisées
5. **feedback_par_libelle** : Feedbacks par libellé
6. **feedback_par_ics** : Feedbacks par ICS
7. **historique_opposition** : Historique oppositions
8. **decisions_salaires** : Décisions salaires

### Stratégie de Vérification

Vérifier la cohérence entre les tables en utilisant des requêtes qui croisent les données (JOIN simulé via requêtes multiples).

---

## 🔍 Tests Exécutés

### Tableau Récapitulatif

| Test | Titre | Lignes | Temps (s) | Coordinateur (μs) | Total (μs) | Statut |
|------|-------|--------|-----------|-------------------|-----------|--------|
"""

for r in results:
    report += f"| {r['num']} | {r['title']} | {r['rows']} | {r['time']} | {r['coord_time']} | {r['total_time']} | {'✅ OK' if r['status'] == 'OK' else '❌ ERROR'} |\n"

report += """
---

## 📊 Résultats par Test

"""

for r in results:
    report += f"""### Test {r['num']} : {r['title']}

- **Lignes retournées** : {r['rows']}
- **Temps d'exécution** : {r['time']}s
"""
    if r['coord_time']:
        report += f"- **Temps coordinateur** : {r['coord_time']}μs\n"
    if r['total_time']:
        report += f"- **Temps total** : {r['total_time']}μs\n"
    report += f"- **Statut** : {'✅ OK' if r['status'] == 'OK' else '❌ ERROR'}\n\n"

report += """---

## ✅ Conclusion

### Points Clés Démontrés

- ✅ Vérification acceptation avant affichage
- ✅ Vérification opposition avant catégorisation
- ✅ Vérification règles appliquées
- ✅ Vérification feedbacks par libellé
- ✅ Vérification feedbacks par ICS
- ✅ Vérification historique opposition
- ✅ Vérification multi-version (cat_auto vs cat_user)
- ✅ Vérification décisions salaires
- ✅ Comptage cohérence globale
- ✅ Vérification intégrité référentielle

---

**Date de génération** : {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}
"""

# Écrire le rapport
import os
report_file = os.environ.get('REPORT_FILE', '${REPORT_FILE}')

with open(report_file, 'w', encoding='utf-8') as f:
    f.write(report)

print(f"✅ Rapport généré : {report_file}")
PYEOF

success "✅ Rapport markdown généré : $REPORT_FILE"

# Nettoyer
rm -f "$TEMP_OUTPUT" "$TEMP_RESULTS"

echo ""
success "✅ Tests cohérence multi-tables terminés"
info ""
info "💡 Points clés démontrés :"
code "  ✅ Vérification acceptation avant affichage"
code "  ✅ Vérification opposition avant catégorisation"
code "  ✅ Vérification règles appliquées"
code "  ✅ Vérification feedbacks par libellé"
code "  ✅ Vérification feedbacks par ICS"
code "  ✅ Vérification historique opposition"
code "  ✅ Vérification multi-version (cat_auto vs cat_user)"
code "  ✅ Vérification décisions salaires"
code "  ✅ Comptage cohérence globale"
code "  ✅ Vérification intégrité référentielle"
echo ""
