#!/bin/bash
set -euo pipefail
# ============================================
# Script 05b : Mise à Jour des Compteurs Feedbacks
# Exécute les UPDATE COUNTER pour les feedbacks après chargement batch
# ============================================
#
# OBJECTIF :
#   Ce script exécute les UPDATE COUNTER pour mettre à jour les compteurs
#   dans feedback_par_libelle après le chargement batch des opérations.
#
#   IMPORTANT :
#   - Spark Cassandra Connector ne supporte pas directement UPDATE COUNTER
#   - Solution : Générer un script CQL et l'exécuter via cqlsh
#   - Les compteurs sont incrémentés atomiquement via CQL
#
# PRÉREQUIS :
#   - HCD démarré
#   - Données chargées (./05_load_operations_data_parquet.sh)
#   - Table feedback_par_libelle existe
#
# UTILISATION :
#   ./05_update_feedbacks_counters.sh
#
# SORTIE :
#   - Compteurs count_engine mis à jour dans feedback_par_libelle
#   - Rapport de mise à jour
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
BOLD='\033[1m'
NC='\033[0m'

info() { echo -e "${BLUE}ℹ️  $1${NC}"; }
success() { echo -e "${GREEN}✅ $1${NC}"; }
warn() { echo -e "${YELLOW}⚠️  $1${NC}"; }
error() { echo -e "${RED}❌ $1${NC}"; }
section() { echo -e "${BOLD}${CYAN}$1${NC}"; }

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

# Charger l'environnement POC (Spark et Kafka déjà installés sur MBP)
if [ -f "${INSTALL_DIR}/.poc-profile" ]; then
    source "${INSTALL_DIR}/.poc-profile"
fi

# HCD_HOME devrait être défini par .poc-profile
HCD_DIR="${HCD_HOME:-${INSTALL_DIR}/binaire/hcd-1.2.3}"

# ============================================
# VÉRIFICATIONS
# ============================================
if ! pgrep -f "cassandra" > /dev/null; then
    error "HCD n'est pas démarré. Exécutez d'abord: ./scripts/setup/03_start_hcd.sh"
    exit 1
fi

cd "$HCD_DIR"
jenv local 11
eval "$(jenv init -)"

if ! ./bin/cqlsh "$HCD_HOST" "$HCD_PORT" -e "DESCRIBE KEYSPACE domiramacatops_poc;" > /dev/null 2>&1; then
    error "Le keyspace domiramacatops_poc n'existe pas. Exécutez d'abord: ./01_setup_domiramaCatOps_keyspace.sh"
    exit 1
fi

# SPARK_HOME devrait être défini par .poc-profile (Spark déjà installé sur MBP)
if [ -z "$SPARK_HOME" ] || [ ! -d "$SPARK_HOME" ]; then
    error "SPARK_HOME non défini ou invalide. Vérifiez .poc-profile"
    error "Spark est déjà installé sur le MBP, mais SPARK_HOME n'est pas configuré"
    exit 1
fi
export PATH=$SPARK_HOME/bin:$PATH

# ============================================
# EN-TÊTE
# ============================================
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  🔄 MISE À JOUR DES COMPTEURS FEEDBACKS"
echo "  Exécution des UPDATE COUNTER pour feedback_par_libelle"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# ============================================
# PARTIE 1: EXTRACTION DES FEEDBACKS À METTRE À JOUR
# ============================================
echo ""
section "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
section "  📊 PARTIE 1: EXTRACTION DES FEEDBACKS À METTRE À JOUR"
section "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

info "📝 Extraction des feedbacks depuis operations_by_account..."
echo ""

# Créer le script Python pour extraire les feedbacks (contourne le problème VECTOR avec Spark)
PYTHON_EXTRACT_SCRIPT=$(mktemp)
cat > "$PYTHON_EXTRACT_SCRIPT" << PYTHON_EOF
#!/usr/bin/env python3
"""
Script pour extraire les feedbacks depuis HCD et générer le script CQL
pour mettre à jour les compteurs feedback_par_libelle.
"""
import os
import sys
from cassandra.cluster import Cluster
from cassandra import ConsistencyLevel
from collections import defaultdict
import re

KEYSPACE = "domiramacatops_poc"
TABLE = "operations_by_account"
CQL_OUTPUT = "${SCRIPT_DIR}/temp_feedbacks_update.cql"

def normalize_libelle(libelle):
    """Normaliser libelle pour feedbacks (même normalisation que pour règles)"""
    if not libelle:
        return ""
    libelle = libelle.strip().upper()
    # Supprimer préfixes
    libelle = re.sub(r'^CB ', '', libelle)
    libelle = re.sub(r'^PRELEVEMENT ', '', libelle)
    libelle = re.sub(r'^VIREMENT ', '', libelle)
    return libelle

print("📥 Lecture des opérations depuis HCD...")
cluster = Cluster(['localhost'], port=9042)
session = cluster.connect()
session.set_keyspace(KEYSPACE)
session.default_consistency_level = ConsistencyLevel.LOCAL_QUORUM

# Récupérer toutes les partitions
partitions = list(session.execute("SELECT DISTINCT code_si, contrat FROM operations_by_account"))

# Préparer la requête
select_prep = session.prepare("SELECT type_operation, sens_operation, libelle, cat_auto FROM operations_by_account WHERE code_si = ? AND contrat = ?")

# Compter les feedbacks par (type_operation, sens_operation, libelle_simplifie, categorie)
feedbacks_count = defaultdict(int)
total_ops = 0

for i, p in enumerate(partitions):
    if (i + 1) % 100 == 0:
        print(f"   Partition {i+1}/{len(partitions)}...")

    rows = list(session.execute(select_prep, [p.code_si, p.contrat]))

    for row in rows:
        total_ops += 1
        if row.cat_auto and row.cat_auto.strip():
            libelle_simplifie = normalize_libelle(row.libelle)
            if libelle_simplifie:
                key = (row.type_operation or "AUTRE", row.sens_operation or "DEBIT", libelle_simplifie, row.cat_auto)
                feedbacks_count[key] += 1

print(f"✅ {total_ops} opérations lues")
print(f"📊 {len(feedbacks_count)} feedbacks uniques à mettre à jour")

# Générer le script CQL avec batches de 100 UPDATE (pour éviter les timeouts)
print("📊 Génération du script CQL...")
BATCH_SIZE = 100
with open(CQL_OUTPUT, 'w') as f:
    f.write("USE domiramacatops_poc;\n")
    f.write("\n")
    f.write("-- Mise à jour des compteurs feedbacks (généré automatiquement)\n")
    f.write("-- Divisé en batches de 100 UPDATE pour éviter les timeouts\n")
    f.write("\n")

    items = list(feedbacks_count.items())
    total_batches = (len(items) + BATCH_SIZE - 1) // BATCH_SIZE

    for batch_num in range(total_batches):
        start_idx = batch_num * BATCH_SIZE
        end_idx = min(start_idx + BATCH_SIZE, len(items))
        batch_items = items[start_idx:end_idx]

        f.write(f"-- Batch {batch_num + 1}/{total_batches} ({len(batch_items)} UPDATE)\n")
        f.write("BEGIN COUNTER BATCH\n")

        for (type_op, sens_op, libelle, categorie), count in batch_items:
            # Échapper les quotes
            type_op_escaped = type_op.replace("'", "''")
            sens_op_escaped = sens_op.replace("'", "''")
            libelle_escaped = libelle.replace("'", "''")
            categorie_escaped = categorie.replace("'", "''")

            f.write(f"UPDATE feedback_par_libelle SET count_engine = count_engine + {count} WHERE type_operation = '{type_op_escaped}' AND sens_operation = '{sens_op_escaped}' AND libelle_simplifie = '{libelle_escaped}' AND categorie = '{categorie_escaped}';\n")

        f.write("APPLY BATCH;\n")
        f.write("\n")

print(f"✅ Script CQL généré : {CQL_OUTPUT}")
print(f"📊 Total : {len(feedbacks_count)} UPDATE à exécuter")

session.shutdown()
cluster.shutdown()
PYTHON_EOF

chmod +x "$PYTHON_EXTRACT_SCRIPT"

# Vérifier les dépendances Python
if ! command -v python3 &> /dev/null; then
    error "❌ Python3 n'est pas installé"
    exit 1
fi

if ! python3 -c "import cassandra" 2>/dev/null; then
    warn "⚠️  cassandra-driver n'est pas installé, installation..."
    pip3 install cassandra-driver --quiet
fi

# Exécuter Python
info "🚀 Exécution de Python pour extraction..."
python3 "$PYTHON_EXTRACT_SCRIPT" 2>&1 | grep -E "(✅|📊|📥|ERROR|Exception|lignes|CQL|Partition)" || true

PYTHON_EXIT_CODE=${PIPESTATUS[0]}
rm -f "$PYTHON_EXTRACT_SCRIPT"

if [ $PYTHON_EXIT_CODE -ne 0 ]; then
    error "❌ Erreur lors de l'extraction des feedbacks"
    exit 1
fi

# ============================================
# PARTIE 2: EXÉCUTION DES UPDATE COUNTER
# ============================================
echo ""
section "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
section "  🔄 PARTIE 2: EXÉCUTION DES UPDATE COUNTER"
section "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

CQL_FILE="${SCRIPT_DIR}/temp_feedbacks_update.cql"

if [ ! -f "$CQL_FILE" ]; then
    error "Fichier CQL non généré : $CQL_FILE"
    exit 1
fi

info "📝 Exécution du script CQL..."
echo ""

# Afficher un aperçu
info "📋 Aperçu du script CQL (10 premières lignes) :"
head -15 "$CQL_FILE" | sed 's/^/   │ /'
echo ""

# Exécuter le script CQL
info "🚀 Exécution des UPDATE COUNTER..."
cd "$HCD_DIR"
jenv local 11
eval "$(jenv init -)"

CQL_OUTPUT=$(./bin/cqlsh "$HCD_HOST" "$HCD_PORT" -f "$CQL_FILE" 2>&1)
CQL_EXIT_CODE=$?

if [ $CQL_EXIT_CODE -eq 0 ]; then
    success "✅ UPDATE COUNTER exécutés avec succès"
else
    warn "⚠️  Certaines erreurs peuvent s'être produites"
    echo "$CQL_OUTPUT" | grep -E "(ERROR|Exception|Invalid)" || true
fi

# Supprimer le fichier temporaire
rm -f "$CQL_FILE"

# ============================================
# PARTIE 3: VÉRIFICATION
# ============================================
echo ""
section "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
section "  🔍 PARTIE 3: VÉRIFICATION DES COMPTEURS"
section "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

info "🔍 Vérification des compteurs mis à jour..."
echo ""

# Afficher quelques exemples
VERIFICATION_CQL=$(cat << 'EOF'
USE domiramacatops_poc;

-- Afficher quelques compteurs mis à jour
SELECT type_operation, sens_operation, libelle_simplifie, categorie, count_engine, count_client
FROM feedback_par_libelle
WHERE type_operation = 'VIREMENT'
  AND sens_operation = 'DEBIT'
LIMIT 10;
EOF
)

echo "$VERIFICATION_CQL" | ./bin/cqlsh "$HCD_HOST" "$HCD_PORT" 2>&1 | grep -v "Warnings" | head -15 | sed 's/^/   │ /'

# ============================================
# RÉSUMÉ
# ============================================
echo ""
section "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
section "  ✅ RÉSUMÉ"
section "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

success "✅ Mise à jour des compteurs terminée !"
echo ""
info "📊 Résumé :"
echo "   - Compteurs count_engine mis à jour dans feedback_par_libelle"
echo "   - Utilisation de BEGIN COUNTER BATCH pour atomicité"
echo "   - Compteurs incrémentés selon le nombre d'opérations par feedback"
echo ""
info "📝 Note :"
echo "   - Les compteurs COUNTER sont eventually consistent"
echo "   - Utilisation de LOCAL_QUORUM pour convergence rapide"
echo ""

success "✅ Script terminé !"
