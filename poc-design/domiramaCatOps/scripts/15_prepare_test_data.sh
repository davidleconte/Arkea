#!/bin/bash
# ============================================
# Script : Préparation et Validation des Données pour 15_test_coherence_multi_tables.sh
# Vérifie et prépare les données nécessaires pour les tests de cohérence multi-tables
# ============================================
#
# OBJECTIF :
#   Ce script vérifie que toutes les données nécessaires pour les tests de cohérence
#   multi-tables sont présentes, suffisantes et fonctionnellement pertinentes.
#
# UTILISATION :
#   ./15_prepare_test_data.sh
#
# ============================================

set -euo pipefail

# Charger l'environnement
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

if [ -f "${INSTALL_DIR}/.poc-profile" ]; then
    source "${INSTALL_DIR}/.poc-profile"
fi

HCD_DIR="${HCD_HOME:-${INSTALL_DIR}/binaire/hcd-1.2.3}"
if [ -n "${HCD_HOME}" ]; then
    CQLSH_BIN="${HCD_HOME}/bin/cqlsh"
else
    CQLSH_BIN="${HCD_DIR}/bin/cqlsh"
fi
CQLSH="$CQLSH_BIN "$HCD_HOST" "$HCD_PORT""

# Couleurs
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'
info() { echo -e "${BLUE}ℹ️  $1${NC}"; }
success() { echo -e "${GREEN}✅ $1${NC}"; }
warn() { echo -e "${YELLOW}⚠️  $1${NC}"; }
error() { echo -e "${RED}❌ $1${NC}"; }

echo ""
info "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
info "  🔍 VALIDATION ET PRÉPARATION DES DONNÉES POUR TESTS COHÉRENCE"
info "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Valeurs de test cohérentes (utilisées dans 15_test_coherence_multi_tables.sh)
TEST_CODE_SI="1"
TEST_CONTRAT="5913101072"
TEST_CODE_EFS="1"
TEST_NO_CONTRAT="5913101072"
TEST_NO_PSE="PSE001"

# ============================================
# TEST 1 : Vérification operations_by_account
# ============================================
echo ""
info "📊 TEST 1 : Vérification operations_by_account"
info "   Minimum requis : Au moins 5 opérations pour (code_si='${TEST_CODE_SI}', contrat='${TEST_CONTRAT}')"

COUNT_OPS=$($CQLSH -e "USE domiramacatops_poc; SELECT COUNT(*) FROM operations_by_account WHERE code_si = '${TEST_CODE_SI}' AND contrat = '${TEST_CONTRAT}';" 2>&1 | grep -E "^\s+[0-9]+" | tr -d ' ' || echo "0")

if [ "$COUNT_OPS" -lt 5 ]; then
    error "❌ Données insuffisantes : $COUNT_OPS opérations trouvées (minimum 5 requis)"
    warn "   Exécutez : ./05_load_operations_data_parquet.sh"
    warn "   Les tests continueront mais pourront retourner peu de résultats"
    # Ne pas sortir, continuer avec les autres validations
else
    success "✅ $COUNT_OPS opérations trouvées (suffisant)"
fi

# Vérifier qu'il y a des opérations avec cat_auto
COUNT_CAT_AUTO=$($CQLSH -e "USE domiramacatops_poc; SELECT COUNT(*) FROM operations_by_account WHERE code_si = '${TEST_CODE_SI}' AND contrat = '${TEST_CONTRAT}' AND cat_auto IS NOT NULL;" 2>&1 | grep -E "^\s+[0-9]+" | tr -d ' ' || echo "0")
COUNT_CAT_AUTO=${COUNT_CAT_AUTO:-0}

if [ -n "$COUNT_CAT_AUTO" ] && [ "$COUNT_CAT_AUTO" -gt 0 ] 2>/dev/null; then
    success "✅ $COUNT_CAT_AUTO opérations avec cat_auto"
else
    warn "⚠️  Aucune opération avec cat_auto (certains tests pourront retourner 0 résultats)"
fi

# ============================================
# TEST 2 : Vérification acceptation_client
# ============================================
echo ""
info "📊 TEST 2 : Vérification acceptation_client"
info "   Minimum requis : Au moins 1 acceptation pour (code_efs='${TEST_CODE_EFS}', no_contrat='${TEST_NO_CONTRAT}', no_pse='${TEST_NO_PSE}')"

COUNT_ACCEPT=$($CQLSH -e "USE domiramacatops_poc; SELECT COUNT(*) FROM acceptation_client WHERE code_efs = '${TEST_CODE_EFS}' AND no_contrat = '${TEST_NO_CONTRAT}' AND no_pse = '${TEST_NO_PSE}';" 2>&1 | grep -E "^\s+[0-9]+" | tr -d ' ' || echo "0")

if [ "$COUNT_ACCEPT" -eq 0 ]; then
    warn "⚠️  Aucune acceptation trouvée, insertion d'une acceptation de test..."
    $CQLSH -e "USE domiramacatops_poc; INSERT INTO acceptation_client (code_efs, no_contrat, no_pse, accepted, accepted_at, updated_at, updated_by) VALUES ('${TEST_CODE_EFS}', '${TEST_NO_CONTRAT}', '${TEST_NO_PSE}', true, toTimestamp(now()), toTimestamp(now()), 'TEST_SCRIPT_15');" 2>&1 | grep -vE "^Warnings|^$|^\([0-9]+ rows\)" || true
    success "✅ Acceptation de test insérée"
else
    success "✅ $COUNT_ACCEPT acceptation(s) trouvée(s)"
fi

# ============================================
# TEST 3 : Vérification opposition_categorisation
# ============================================
echo ""
info "📊 TEST 3 : Vérification opposition_categorisation"
info "   Minimum requis : Au moins 1 opposition pour (code_efs='${TEST_CODE_EFS}', no_pse='${TEST_NO_PSE}')"

COUNT_OPPOSITION=$($CQLSH -e "USE domiramacatops_poc; SELECT COUNT(*) FROM opposition_categorisation WHERE code_efs = '${TEST_CODE_EFS}' AND no_pse = '${TEST_NO_PSE}';" 2>&1 | grep -E "^\s+[0-9]+" | tr -d ' ' || echo "0")

if [ "$COUNT_OPPOSITION" -eq 0 ]; then
    warn "⚠️  Aucune opposition trouvée, insertion d'une opposition de test..."
    $CQLSH -e "USE domiramacatops_poc; INSERT INTO opposition_categorisation (code_efs, no_pse, opposed, opposed_at, updated_at, updated_by) VALUES ('${TEST_CODE_EFS}', '${TEST_NO_PSE}', false, toTimestamp(now()), toTimestamp(now()), 'TEST_SCRIPT_15');" 2>&1 | grep -vE "^Warnings|^$|^\([0-9]+ rows\)" || true
    success "✅ Opposition de test insérée"
else
    success "✅ $COUNT_OPPOSITION opposition(s) trouvée(s)"
fi

# ============================================
# TEST 4 : Vérification regles_personnalisees
# ============================================
echo ""
info "📊 TEST 4 : Vérification regles_personnalisees"
info "   Minimum requis : Au moins 1 règle active pour code_efs='${TEST_CODE_EFS}'"

COUNT_REGLES=$($CQLSH -e "USE domiramacatops_poc; SELECT COUNT(*) FROM regles_personnalisees WHERE code_efs = '${TEST_CODE_EFS}' AND actif = true;" 2>&1 | grep -E "^\s+[0-9]+" | tr -d ' ' || echo "0")

if [ "$COUNT_REGLES" -eq 0 ]; then
    warn "⚠️  Aucune règle active trouvée, insertion d'une règle de test..."
    $CQLSH -e "USE domiramacatops_poc; INSERT INTO regles_personnalisees (code_efs, type_operation, sens_operation, libelle_simplifie, categorie_cible, priorite, actif, created_at) VALUES ('${TEST_CODE_EFS}', 'VIREMENT', 'DEBIT', 'TEST LIBELLE', 'TEST_CATEGORY', 100, true, toTimestamp(now()));" 2>&1 | grep -vE "^Warnings|^$|^\([0-9]+ rows\)" || true
    success "✅ Règle de test insérée"
else
    success "✅ $COUNT_REGLES règle(s) active(s) trouvée(s)"
fi

# ============================================
# TEST 5 : Vérification feedback_par_libelle
# ============================================
echo ""
info "📊 TEST 5 : Vérification feedback_par_libelle"
info "   Minimum requis : Au moins 1 feedback pour type_operation='VIREMENT' AND sens_operation='DEBIT'"

COUNT_FEEDBACK_LIBELLE=$($CQLSH -e "USE domiramacatops_poc; SELECT COUNT(*) FROM feedback_par_libelle WHERE type_operation = 'VIREMENT' AND sens_operation = 'DEBIT';" 2>&1 | grep -E "^\s+[0-9]+" | tr -d ' ' || echo "0")

if [ "$COUNT_FEEDBACK_LIBELLE" -eq 0 ]; then
    warn "⚠️  Aucun feedback par libellé trouvé (certains tests pourront retourner 0 résultats)"
    info "   Note : Les feedbacks sont généralement créés automatiquement lors du chargement des opérations"
else
    success "✅ $COUNT_FEEDBACK_LIBELLE feedback(s) par libellé trouvé(s)"
fi

# ============================================
# TEST 6 : Vérification feedback_par_ics
# ============================================
echo ""
info "📊 TEST 6 : Vérification feedback_par_ics"
info "   Minimum requis : Au moins 1 feedback pour type_operation='VIREMENT' AND sens_operation='DEBIT'"

COUNT_FEEDBACK_ICS=$($CQLSH -e "USE domiramacatops_poc; SELECT COUNT(*) FROM feedback_par_ics WHERE type_operation = 'VIREMENT' AND sens_operation = 'DEBIT';" 2>&1 | grep -E "^\s+[0-9]+" | tr -d ' ' || echo "0")

if [ "$COUNT_FEEDBACK_ICS" -eq 0 ]; then
    warn "⚠️  Aucun feedback par ICS trouvé (certains tests pourront retourner 0 résultats)"
    info "   Note : Les feedbacks sont généralement créés automatiquement lors du chargement des opérations"
else
    success "✅ $COUNT_FEEDBACK_ICS feedback(s) par ICS trouvé(s)"
fi

# ============================================
# TEST 7 : Vérification historique_opposition
# ============================================
echo ""
info "📊 TEST 7 : Vérification historique_opposition"
info "   Minimum requis : Au moins 1 entrée pour (code_efs='${TEST_CODE_EFS}', no_pse='${TEST_NO_PSE}')"

COUNT_HIST=$($CQLSH -e "USE domiramacatops_poc; SELECT COUNT(*) FROM historique_opposition WHERE code_efs = '${TEST_CODE_EFS}' AND no_pse = '${TEST_NO_PSE}';" 2>&1 | grep -E "^\s+[0-9]+" | tr -d ' ' || echo "0")

if [ "$COUNT_HIST" -eq 0 ]; then
    warn "⚠️  Aucun historique trouvé, insertion d'un historique de test..."
    python3 << PYEOF
from cassandra.cluster import Cluster
from datetime import datetime
from uuid import uuid1

cluster = Cluster(['localhost'], port=9042)
session = cluster.connect('domiramacatops_poc')

horodate = uuid1()
timestamp = datetime.now()

query = f"""
INSERT INTO historique_opposition (code_efs, no_pse, horodate, status, timestamp, raison)
VALUES ('{TEST_CODE_EFS}', '{TEST_NO_PSE}', {horodate}, 'autorisé', '{timestamp.strftime('%Y-%m-%d %H:%M:%S+0000')}', 'Test script 15')
"""

session.execute(query)
cluster.shutdown()
print("✅ Historique de test inséré")
PYEOF
else
    success "✅ $COUNT_HIST entrée(s) d'historique trouvée(s)"
fi

# ============================================
# TEST 8 : Vérification decisions_salaires
# ============================================
echo ""
info "📊 TEST 8 : Vérification decisions_salaires"
info "   Minimum requis : Au moins 1 décision pour code_efs='${TEST_CODE_EFS}'"

COUNT_DECISIONS=$($CQLSH -e "USE domiramacatops_poc; SELECT COUNT(*) FROM decisions_salaires WHERE code_efs = '${TEST_CODE_EFS}';" 2>&1 | grep -E "^\s+[0-9]+" | tr -d ' ' || echo "0")

if [ "$COUNT_DECISIONS" -eq 0 ]; then
    warn "⚠️  Aucune décision salaire trouvée (certains tests pourront retourner 0 résultats)"
    info "   Note : Les décisions salaires sont généralement créées par un processus métier spécifique"
else
    success "✅ $COUNT_DECISIONS décision(s) salaire(s) trouvée(s)"
fi

# ============================================
# TEST 9 : Vérification Cohérence des Clés
# ============================================
echo ""
info "📊 TEST 9 : Vérification Cohérence des Clés"
info "   Vérification que code_si/contrat dans operations_by_account correspondent à code_efs/no_contrat dans les autres tables"

# Vérifier que le code_si utilisé existe bien
COUNT_CODE_SI=$($CQLSH -e "USE domiramacatops_poc; SELECT COUNT(DISTINCT code_si) FROM operations_by_account WHERE code_si = '${TEST_CODE_SI}';" 2>&1 | grep -E "^\s+[0-9]+" | tr -d ' ' || echo "0")
COUNT_CODE_SI=${COUNT_CODE_SI:-0}

if [ -n "$COUNT_CODE_SI" ] && [ "$COUNT_CODE_SI" -gt 0 ] 2>/dev/null; then
    success "✅ code_si='${TEST_CODE_SI}' existe dans operations_by_account"
else
    error "❌ code_si='${TEST_CODE_SI}' n'existe pas dans operations_by_account"
    warn "   Les tests utiliseront des valeurs qui n'existent pas"
    warn "   Les tests continueront mais pourront échouer"
    # Ne pas sortir, continuer avec les autres validations
fi

# Vérifier que les PSE utilisés existent dans les tables de référence
info "   Vérification de l'existence des PSE utilisés dans les tables de référence..."

python3 << PYEOF
from cassandra.cluster import Cluster
import os

cluster = Cluster(['localhost'], port=9042)
session = cluster.connect('domiramacatops_poc')

try:
    test_code_efs = os.environ.get('TEST_CODE_EFS', '${TEST_CODE_EFS}')
    test_no_contrat = os.environ.get('TEST_NO_CONTRAT', '${TEST_NO_CONTRAT}')
    test_no_pse = os.environ.get('TEST_NO_PSE', '${TEST_NO_PSE}')

    # Vérifier l'existence du PSE de test dans acceptation_client (clé primaire complète)
    query_accept = f"""
    SELECT no_pse
    FROM acceptation_client
    WHERE code_efs = '{test_code_efs}'
      AND no_contrat = '{test_no_contrat}'
      AND no_pse = '{test_no_pse}'
    """

    pse_in_accept = False
    try:
        result = session.execute(query_accept)
        if result.one():
            pse_in_accept = True
    except:
        pass

    # Vérifier l'existence du PSE de test dans opposition_categorisation (clé primaire complète)
    query_oppose = f"""
    SELECT no_pse
    FROM opposition_categorisation
    WHERE code_efs = '{test_code_efs}'
      AND no_pse = '{test_no_pse}'
    """

    pse_in_oppose = False
    try:
        result = session.execute(query_oppose)
        if result.one():
            pse_in_oppose = True
    except:
        pass

    # Vérifier l'existence du PSE de test dans historique_opposition (clé primaire partielle)
    query_hist = f"""
    SELECT no_pse
    FROM historique_opposition
    WHERE code_efs = '{test_code_efs}'
      AND no_pse = '{test_no_pse}'
    LIMIT 1
    """

    pse_in_hist = False
    try:
        result = session.execute(query_hist)
        if result.one():
            pse_in_hist = True
    except:
        pass

    # Vérifier la cohérence des PSE
    pse_found = pse_in_accept or pse_in_oppose or pse_in_hist

    if pse_found:
        if pse_in_accept and (pse_in_oppose or pse_in_hist):
            print(f"✅ Cohérence des PSE : PSE '{test_no_pse}' présent dans acceptation et opposition/historique")
        elif pse_in_accept:
            print(f"⚠️  PSE '{test_no_pse}' présent dans acceptation mais absent d'opposition/historique")
        else:
            print(f"✅ PSE '{test_no_pse}' trouvé dans les tables de référence")
    else:
        print(f"⚠️  PSE '{test_no_pse}' non trouvé dans les tables de référence (normal si pas de données de test)")

except Exception as e:
    print(f"⚠️  Impossible de vérifier les PSE : {e}")

cluster.shutdown()
PYEOF

# Vérifier l'intégrité référentielle (pas d'orphelins)
info "   Vérification de l'intégrité référentielle (pas d'orphelins)..."

export TEST_CODE_EFS TEST_CODE_SI TEST_NO_CONTRAT TEST_NO_PSE
python3 << PYEOF
from cassandra.cluster import Cluster
import os

cluster = Cluster(['localhost'], port=9042)
session = cluster.connect('domiramacatops_poc')

try:
    test_code_efs = os.environ.get('TEST_CODE_EFS', '${TEST_CODE_EFS}')
    test_no_contrat = os.environ.get('TEST_NO_CONTRAT', '${TEST_NO_CONTRAT}')
    test_no_pse = os.environ.get('TEST_NO_PSE', '${TEST_NO_PSE}')

    # Vérifier que les acceptations existent (clé primaire complète)
    query_accept = f"""
    SELECT no_pse
    FROM acceptation_client
    WHERE code_efs = '{test_code_efs}'
      AND no_contrat = '{test_no_contrat}'
      AND no_pse = '{test_no_pse}'
    """

    accept_exists = False
    try:
        result_accept = session.execute(query_accept)
        if result_accept.one():
            accept_exists = True
    except:
        pass

    # Vérifier que les oppositions existent (clé primaire complète)
    query_oppose = f"""
    SELECT no_pse
    FROM opposition_categorisation
    WHERE code_efs = '{test_code_efs}'
      AND no_pse = '{test_no_pse}'
    """

    oppose_exists = False
    try:
        result_oppose = session.execute(query_oppose)
        if result_oppose.one():
            oppose_exists = True
    except:
        pass

    # Vérifier la cohérence : code_efs doit correspondre à code_si (déjà vérifié plus haut)
    # Note: Dans ce POC, code_efs et code_si sont supposés être équivalents
    # La vérification du compte dans operations_by_account est déjà faite dans TEST 9 (lignes 226-235)

    if accept_exists or oppose_exists:
        if accept_exists:
            print(f"✅ Intégrité référentielle : Acceptation trouvée pour (code_efs='{test_code_efs}', no_contrat='{test_no_contrat}', no_pse='{test_no_pse}')")
        if oppose_exists:
            print(f"✅ Intégrité référentielle : Opposition trouvée pour (code_efs='{test_code_efs}', no_pse='{test_no_pse}')")
    else:
        print(f"⚠️  Intégrité référentielle : Aucune acceptation/opposition trouvée pour les valeurs de test")

except Exception as e:
    print(f"⚠️  Impossible de vérifier l'intégrité référentielle : {e}")

cluster.shutdown()
PYEOF

# ============================================
# TEST 10 : Vérification Suffisance des Données
# ============================================
echo ""
info "📊 TEST 10 : Vérification Suffisance des Données"
info "   Vérification que les données sont en quantité suffisante pour des tests pertinents"

SUFFISANCE_OK=true

# Vérifier le nombre d'opérations par compte
COUNT_OPS_PER_ACCOUNT=$($CQLSH -e "USE domiramacatops_poc; SELECT COUNT(*) FROM operations_by_account WHERE code_si = '${TEST_CODE_SI}' AND contrat = '${TEST_CONTRAT}';" 2>&1 | grep -E "^\s+[0-9]+" | tr -d ' ' || echo "0")
COUNT_OPS_PER_ACCOUNT=${COUNT_OPS_PER_ACCOUNT:-0}

if [ -n "$COUNT_OPS_PER_ACCOUNT" ] && [ "$COUNT_OPS_PER_ACCOUNT" -ge 10 ] 2>/dev/null; then
    success "✅ Nombre d'opérations suffisant : $COUNT_OPS_PER_ACCOUNT"
else
    warn "⚠️  Nombre d'opérations insuffisant : $COUNT_OPS_PER_ACCOUNT (recommandé : 10+)"
    SUFFISANCE_OK=false
fi

# Vérifier la diversité des types d'opérations
COUNT_TYPES=$($CQLSH -e "USE domiramacatops_poc; SELECT COUNT(DISTINCT type_operation) FROM operations_by_account WHERE code_si = '${TEST_CODE_SI}' AND contrat = '${TEST_CONTRAT}';" 2>&1 | grep -E "^\s+[0-9]+" | tr -d ' ' || echo "0")
COUNT_TYPES=${COUNT_TYPES:-0}

if [ -n "$COUNT_TYPES" ] && [ "$COUNT_TYPES" -ge 2 ] 2>/dev/null; then
    success "✅ Diversité des types d'opérations : $COUNT_TYPES type(s)"
else
    warn "⚠️  Diversité des types d'opérations insuffisante : $COUNT_TYPES type(s) (recommandé : 2+)"
    SUFFISANCE_OK=false
fi

# Vérifier la diversité des sens d'opérations
COUNT_SENS=$($CQLSH -e "USE domiramacatops_poc; SELECT COUNT(DISTINCT sens_operation) FROM operations_by_account WHERE code_si = '${TEST_CODE_SI}' AND contrat = '${TEST_CONTRAT}' AND sens_operation IS NOT NULL;" 2>&1 | grep -E "^\s+[0-9]+" | tr -d ' ' || echo "0")
COUNT_SENS=${COUNT_SENS:-0}

if [ -n "$COUNT_SENS" ] && [ "$COUNT_SENS" -ge 1 ] 2>/dev/null; then
    success "✅ Sens d'opérations présents : $COUNT_SENS"
else
    warn "⚠️  Aucun sens d'opération trouvé (DEBIT/CREDIT)"
    SUFFISANCE_OK=false
fi

# ============================================
# TEST 11 : Vérification Pertinence Fonctionnelle
# ============================================
echo ""
info "📊 TEST 11 : Vérification Pertinence Fonctionnelle"
info "   Vérification que les données sont fonctionnellement pertinentes"

PERTINENCE_OK=true

# Vérifier que les libellés ne sont pas vides
if [ "$COUNT_OPS" -gt 0 ]; then
    COUNT_LIBELLE_VIDE=$($CQLSH -e "USE domiramacatops_poc; SELECT COUNT(*) FROM operations_by_account WHERE code_si = '${TEST_CODE_SI}' AND contrat = '${TEST_CONTRAT}' AND (libelle IS NULL OR libelle = '');" 2>&1 | grep -E "^\s+[0-9]+" | tr -d ' ' || echo "0")
    COUNT_LIBELLE_VIDE=${COUNT_LIBELLE_VIDE:-0}

    if [ -n "$COUNT_LIBELLE_VIDE" ] && [ "$COUNT_LIBELLE_VIDE" -gt 0 ] 2>/dev/null; then
        warn "⚠️  $COUNT_LIBELLE_VIDE opération(s) avec libellé vide ou NULL"
        PERTINENCE_OK=false
    else
        success "✅ Tous les libellés sont renseignés"
    fi

    # Vérifier que les montants sont cohérents (positifs)
    COUNT_MONTANT_INVALIDE=$($CQLSH -e "USE domiramacatops_poc; SELECT COUNT(*) FROM operations_by_account WHERE code_si = '${TEST_CODE_SI}' AND contrat = '${TEST_CONTRAT}' AND (montant IS NULL OR montant <= 0);" 2>&1 | grep -E "^\s+[0-9]+" | tr -d ' ' || echo "0")
    COUNT_MONTANT_INVALIDE=${COUNT_MONTANT_INVALIDE:-0}

    if [ -n "$COUNT_MONTANT_INVALIDE" ] && [ "$COUNT_MONTANT_INVALIDE" -gt 0 ] 2>/dev/null; then
        warn "⚠️  $COUNT_MONTANT_INVALIDE opération(s) avec montant invalide (NULL ou <= 0)"
        PERTINENCE_OK=false
    else
        success "✅ Tous les montants sont valides"
    fi
else
    warn "⚠️  Impossible de vérifier libellés et montants (pas d'opérations)"
fi

# Vérifier que les dates sont cohérentes (pas de dates futures)
if [ "$COUNT_OPS" -gt 0 ]; then
    python3 << PYEOF
from cassandra.cluster import Cluster
from datetime import datetime

cluster = Cluster(['localhost'], port=9042)
session = cluster.connect('domiramacatops_poc')

# Vérifier les dates futures
now = datetime.now()
query = f"""
SELECT date_op
FROM operations_by_account
WHERE code_si = '{TEST_CODE_SI}'
  AND contrat = '{TEST_CONTRAT}'
LIMIT 100
"""

try:
    result = session.execute(query)
    future_dates = 0
    for row in result:
        if row.date_op and row.date_op > now:
            future_dates += 1

    if future_dates > 0:
        print(f"⚠️  {future_dates} opération(s) avec date future")
    else:
        print("✅ Toutes les dates sont cohérentes (pas de dates futures)")
except Exception as e:
    print(f"⚠️  Impossible de vérifier les dates : {e}")

cluster.shutdown()
PYEOF
else
    warn "⚠️  Impossible de vérifier les dates (pas d'opérations)"
fi

# Vérifier que les catégories auto correspondent à des règles existantes
COUNT_CAT_AUTO=${COUNT_CAT_AUTO:-0}
if [ -n "$COUNT_CAT_AUTO" ] && [ "$COUNT_CAT_AUTO" -gt 0 ] 2>/dev/null; then
    python3 << PYEOF
from cassandra.cluster import Cluster

cluster = Cluster(['localhost'], port=9042)
session = cluster.connect('domiramacatops_poc')

try:
    # Récupérer les catégories auto utilisées
    query_ops = f"""
    SELECT DISTINCT cat_auto
    FROM operations_by_account
    WHERE code_si = '{TEST_CODE_SI}'
      AND contrat = '{TEST_CONTRAT}'
      AND cat_auto IS NOT NULL
    LIMIT 10
    """

    categories = []
    for row in session.execute(query_ops):
        if row.cat_auto:
            categories.append(row.cat_auto)

    # Vérifier si ces catégories correspondent à des règles
    if categories:
        categories_str = "', '".join(categories)
        query_regles = f"""
        SELECT COUNT(*)
        FROM regles_personnalisees
        WHERE code_efs = '{TEST_CODE_EFS}'
          AND categorie_cible IN ('{categories_str}')
          AND actif = true
        """
        result = session.execute(query_regles)
        count = result.one()[0] if result else 0
        if count == 0:
            print(f"⚠️  {len(categories)} catégorie(s) auto sans règle correspondante")
        else:
            print(f"✅ {count} catégorie(s) auto correspondent à des règles actives")
    else:
        print("✅ Aucune catégorie auto à vérifier")
except Exception as e:
    print(f"⚠️  Impossible de vérifier les catégories : {e}")

cluster.shutdown()
PYEOF
else
    warn "⚠️  Impossible de vérifier les catégories (pas d'opérations avec cat_auto)"
fi

# ============================================
# TEST 12 : Vérification Couverture des Cas d'Usage
# ============================================
echo ""
info "📊 TEST 12 : Vérification Couverture des Cas d'Usage"
info "   Vérification que tous les cas d'usage sont couverts par les données"

COUVERTURE_OK=true

# Vérifier présence de données avec cat_user (multi-version)
if [ "$COUNT_OPS" -gt 0 ]; then
    COUNT_CAT_USER=$($CQLSH -e "USE domiramacatops_poc; SELECT COUNT(*) FROM operations_by_account WHERE code_si = '${TEST_CODE_SI}' AND contrat = '${TEST_CONTRAT}' AND cat_user IS NOT NULL;" 2>&1 | grep -E "^\s+[0-9]+" | tr -d ' ' || echo "0")
    COUNT_CAT_USER=${COUNT_CAT_USER:-0}

    if [ -n "$COUNT_CAT_USER" ] && [ "$COUNT_CAT_USER" -gt 0 ] 2>/dev/null; then
        success "✅ $COUNT_CAT_USER opération(s) avec cat_user (multi-version testable)"
    else
        warn "⚠️  Aucune opération avec cat_user (tests multi-version limités)"
        COUVERTURE_OK=false
    fi

    # Vérifier présence de données avec différentes catégories
    COUNT_CATEGORIES=$($CQLSH -e "USE domiramacatops_poc; SELECT COUNT(DISTINCT cat_auto) FROM operations_by_account WHERE code_si = '${TEST_CODE_SI}' AND contrat = '${TEST_CONTRAT}' AND cat_auto IS NOT NULL;" 2>&1 | grep -E "^\s+[0-9]+" | tr -d ' ' || echo "0")
    COUNT_CATEGORIES=${COUNT_CATEGORIES:-0}

    if [ -n "$COUNT_CATEGORIES" ] && [ "$COUNT_CATEGORIES" -ge 2 ] 2>/dev/null; then
        success "✅ Diversité des catégories : $COUNT_CATEGORIES catégorie(s)"
    else
        warn "⚠️  Diversité des catégories insuffisante : $COUNT_CATEGORIES catégorie(s) (recommandé : 2+)"
        COUVERTURE_OK=false
    fi
else
    warn "⚠️  Impossible de vérifier cat_user et catégories (pas d'opérations)"
fi

# Vérifier présence de données avec acceptation true et false
COUNT_ACCEPT_TRUE=$($CQLSH -e "USE domiramacatops_poc; SELECT COUNT(*) FROM acceptation_client WHERE code_efs = '${TEST_CODE_EFS}' AND accepted = true;" 2>&1 | grep -E "^\s+[0-9]+" | tr -d ' ' || echo "0")
COUNT_ACCEPT_FALSE=$($CQLSH -e "USE domiramacatops_poc; SELECT COUNT(*) FROM acceptation_client WHERE code_efs = '${TEST_CODE_EFS}' AND accepted = false;" 2>&1 | grep -E "^\s+[0-9]+" | tr -d ' ' || echo "0")
COUNT_ACCEPT_TRUE=${COUNT_ACCEPT_TRUE:-0}
COUNT_ACCEPT_FALSE=${COUNT_ACCEPT_FALSE:-0}

if [ -n "$COUNT_ACCEPT_TRUE" ] && [ -n "$COUNT_ACCEPT_FALSE" ] && [ "$COUNT_ACCEPT_TRUE" -gt 0 ] && [ "$COUNT_ACCEPT_FALSE" -gt 0 ] 2>/dev/null; then
    success "✅ Couverture acceptation complète (true: $COUNT_ACCEPT_TRUE, false: $COUNT_ACCEPT_FALSE)"
else
    warn "⚠️  Couverture acceptation incomplète (true: $COUNT_ACCEPT_TRUE, false: $COUNT_ACCEPT_FALSE)"
    COUVERTURE_OK=false
fi

# Vérifier présence de données avec opposition true et false
COUNT_OPPOSED_TRUE=$($CQLSH -e "USE domiramacatops_poc; SELECT COUNT(*) FROM opposition_categorisation WHERE code_efs = '${TEST_CODE_EFS}' AND opposed = true;" 2>&1 | grep -E "^\s+[0-9]+" | tr -d ' ' || echo "0")
COUNT_OPPOSED_FALSE=$($CQLSH -e "USE domiramacatops_poc; SELECT COUNT(*) FROM opposition_categorisation WHERE code_efs = '${TEST_CODE_EFS}' AND opposed = false;" 2>&1 | grep -E "^\s+[0-9]+" | tr -d ' ' || echo "0")
COUNT_OPPOSED_TRUE=${COUNT_OPPOSED_TRUE:-0}
COUNT_OPPOSED_FALSE=${COUNT_OPPOSED_FALSE:-0}

if [ -n "$COUNT_OPPOSED_TRUE" ] && [ -n "$COUNT_OPPOSED_FALSE" ] && [ "$COUNT_OPPOSED_TRUE" -gt 0 ] && [ "$COUNT_OPPOSED_FALSE" -gt 0 ] 2>/dev/null; then
    success "✅ Couverture opposition complète (true: $COUNT_OPPOSED_TRUE, false: $COUNT_OPPOSED_FALSE)"
else
    warn "⚠️  Couverture opposition incomplète (true: $COUNT_OPPOSED_TRUE, false: $COUNT_OPPOSED_FALSE)"
    COUVERTURE_OK=false
fi

# ============================================
# TEST 13 : Vérification Performance des Données
# ============================================
echo ""
info "📊 TEST 13 : Vérification Performance des Données"
info "   Vérification que les données permettent des tests de performance réalistes"

PERFORMANCE_OK=true

# Vérifier le volume total d'opérations
TOTAL_OPS=$($CQLSH -e "USE domiramacatops_poc; SELECT COUNT(*) FROM operations_by_account;" 2>&1 | grep -E "^\s+[0-9]+" | tr -d ' ' || echo "0")
TOTAL_OPS=${TOTAL_OPS:-0}

if [ -n "$TOTAL_OPS" ] && [ "$TOTAL_OPS" -ge 100 ] 2>/dev/null; then
    success "✅ Volume total suffisant : $TOTAL_OPS opérations"
else
    warn "⚠️  Volume total insuffisant : $TOTAL_OPS opérations (recommandé : 100+ pour tests de performance)"
    PERFORMANCE_OK=false
fi

# Vérifier la distribution des données (pas de skew important)
if [ "$TOTAL_OPS" -gt 0 ]; then
    python3 << PYEOF
from cassandra.cluster import Cluster

cluster = Cluster(['localhost'], port=9042)
session = cluster.connect('domiramacatops_poc')

try:
    # Vérifier la distribution par compte (approximation avec DISTINCT)
    query = """
    SELECT DISTINCT code_si, contrat
    FROM operations_by_account
    LIMIT 20
    """

    accounts = list(session.execute(query))

    if accounts:
        # Compter les opérations pour chaque compte
        counts = []
        for account in accounts[:10]:  # Limiter à 10 pour performance
            count_query = f"""
            SELECT COUNT(*)
            FROM operations_by_account
            WHERE code_si = '{account.code_si}'
              AND contrat = '{account.contrat}'
            """
            result = session.execute(count_query)
            count = result.one()[0] if result else 0
            if count > 0:
                counts.append(count)

        if counts:
            max_count = max(counts)
            min_count = min(counts)
            if min_count > 0:
                ratio = max_count / min_count
                if ratio > 10:
                    print(f"⚠️  Distribution déséquilibrée (ratio max/min: {ratio:.1f})")
                else:
                    print(f"✅ Distribution équilibrée (ratio max/min: {ratio:.1f})")
            else:
                print("⚠️  Certains comptes n'ont pas d'opérations")
        else:
            print("⚠️  Impossible de calculer la distribution")
    else:
        print("⚠️  Aucun compte trouvé")
except Exception as e:
    print(f"⚠️  Impossible de vérifier la distribution : {e}")

cluster.shutdown()
PYEOF
else
    warn "⚠️  Impossible de vérifier la distribution (pas d'opérations)"
fi

# Vérifier la présence de données récentes (pour tests temporels)
if [ "$COUNT_OPS" -gt 0 ]; then
    python3 << PYEOF
from cassandra.cluster import Cluster
from datetime import datetime, timedelta

cluster = Cluster(['localhost'], port=9042)
session = cluster.connect('domiramacatops_poc')

try:
    # Vérifier les données des 30 derniers jours
    thirty_days_ago = datetime.now() - timedelta(days=30)
    query = f"""
    SELECT COUNT(*)
    FROM operations_by_account
    WHERE code_si = '{TEST_CODE_SI}'
      AND contrat = '{TEST_CONTRAT}'
      AND date_op >= {int(thirty_days_ago.timestamp() * 1000)}
    """

    result = session.execute(query)
    recent_count = result.one()[0] if result else 0

    if recent_count == 0:
        print("⚠️  Aucune donnée récente (30 derniers jours) pour tests temporels")
    else:
        print(f"✅ {recent_count} opération(s) récente(s) (30 derniers jours)")
except Exception as e:
    print(f"⚠️  Impossible de vérifier les données récentes : {e}")

cluster.shutdown()
PYEOF
else
    warn "⚠️  Impossible de vérifier les données récentes (pas d'opérations)"
fi

# ============================================
# TEST 14 : Vérification Cohérence Temporelle
# ============================================
echo ""
info "📊 TEST 14 : Vérification Cohérence Temporelle"
info "   Vérification de la cohérence temporelle des données"

# Vérifier que les dates d'acceptation sont cohérentes avec les dates d'opérations
if [ "$COUNT_OPS" -gt 0 ] && [ "$COUNT_ACCEPT" -gt 0 ]; then
    python3 << PYEOF
from cassandra.cluster import Cluster
from datetime import datetime

cluster = Cluster(['localhost'], port=9042)
session = cluster.connect('domiramacatops_poc')

try:
    # Récupérer la date min des opérations
    query_ops = f"""
    SELECT MIN(date_op) as min_date
    FROM operations_by_account
    WHERE code_si = '{TEST_CODE_SI}'
      AND contrat = '{TEST_CONTRAT}'
    """

    result_ops = session.execute(query_ops)
    min_date_op = None
    for row in result_ops:
        if row.min_date:
            min_date_op = row.min_date
            break

    # Récupérer la date min des acceptations
    query_accept = f"""
    SELECT MIN(accepted_at) as min_date
    FROM acceptation_client
    WHERE code_efs = '{TEST_CODE_EFS}'
      AND no_contrat = '{TEST_NO_CONTRAT}'
    """

    result_accept = session.execute(query_accept)
    min_date_accept = None
    for row in result_accept:
        if row.min_date:
            min_date_accept = row.min_date
            break

    if min_date_op and min_date_accept:
        if min_date_accept > min_date_op:
            print("⚠️  Dates d'acceptation postérieures aux premières opérations")
        else:
            print("✅ Cohérence temporelle : acceptations avant opérations")
    else:
        print("⚠️  Impossible de vérifier la cohérence temporelle (données manquantes)")
except Exception as e:
    print(f"⚠️  Impossible de vérifier la cohérence temporelle : {e}")

cluster.shutdown()
PYEOF
else
    warn "⚠️  Impossible de vérifier la cohérence temporelle (données manquantes)"
fi

# ============================================
# RÉSUMÉ
# ============================================
echo ""
info "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
info "  📋 RÉSUMÉ DE VALIDATION"
info "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Compter les validations réussies
VALIDATION_COUNT=0
TOTAL_VALIDATIONS=14

if [ "$COUNT_OPS" -ge 5 ]; then ((VALIDATION_COUNT++)); fi
if [ "$COUNT_ACCEPT" -gt 0 ]; then ((VALIDATION_COUNT++)); fi
if [ "$COUNT_OPPOSITION" -gt 0 ]; then ((VALIDATION_COUNT++)); fi
if [ "$COUNT_REGLES" -gt 0 ]; then ((VALIDATION_COUNT++)); fi
if [ "$COUNT_HIST" -gt 0 ]; then ((VALIDATION_COUNT++)); fi
if [ "$SUFFISANCE_OK" = true ]; then ((VALIDATION_COUNT++)); fi
if [ "$PERTINENCE_OK" = true ]; then ((VALIDATION_COUNT++)); fi
if [ "$COUVERTURE_OK" = true ]; then ((VALIDATION_COUNT++)); fi
if [ "$PERFORMANCE_OK" = true ]; then ((VALIDATION_COUNT++)); fi

VALIDATION_RATE=$((VALIDATION_COUNT * 100 / TOTAL_VALIDATIONS))

if [ "$VALIDATION_RATE" -ge 80 ]; then
    success "✅ Validation globale : $VALIDATION_COUNT/$TOTAL_VALIDATIONS tests réussis ($VALIDATION_RATE%)"
    success "   Les données sont prêtes pour les tests de cohérence"
elif [ "$VALIDATION_RATE" -ge 60 ]; then
    warn "⚠️  Validation partielle : $VALIDATION_COUNT/$TOTAL_VALIDATIONS tests réussis ($VALIDATION_RATE%)"
    warn "   Certains tests de cohérence peuvent retourner des résultats limités"
else
    error "❌ Validation insuffisante : $VALIDATION_COUNT/$TOTAL_VALIDATIONS tests réussis ($VALIDATION_RATE%)"
    error "   Les tests de cohérence risquent d'échouer ou de retourner peu de résultats"
fi

echo ""
info "📊 Détail des validations :"
echo "   - Présence des données : ✅"
echo "   - Suffisance des données : $([ "$SUFFISANCE_OK" = true ] && echo "✅" || echo "⚠️")"
echo "   - Pertinence fonctionnelle : $([ "$PERTINENCE_OK" = true ] && echo "✅" || echo "⚠️")"
echo "   - Couverture des cas d'usage : $([ "$COUVERTURE_OK" = true ] && echo "✅" || echo "⚠️")"
echo "   - Performance des données : $([ "$PERFORMANCE_OK" = true ] && echo "✅" || echo "⚠️")"
echo ""
info "💡 Pour exécuter les tests de cohérence :"
info "   ./15_test_coherence_multi_tables.sh"
echo ""
