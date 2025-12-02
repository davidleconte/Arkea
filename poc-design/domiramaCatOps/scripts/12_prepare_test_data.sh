#!/bin/bash
# ============================================
# Script : Préparation des données de test pour 12_test_historique_opposition.sh
# Insère des données de test cohérentes pour tous les tests d'historique opposition
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
NC='\033[0m'
info() { echo -e "${BLUE}ℹ️  $1${NC}"; }
success() { echo -e "${GREEN}✅ $1${NC}"; }
warn() { echo -e "${YELLOW}⚠️  $1${NC}"; }

echo ""
info "🔧 Préparation des données de test pour historique_opposition..."
echo ""

# Valeurs de test cohérentes
TEST_CODE_EFS="1"
TEST_NO_PSE="PSE001"

# Vérifier si des données existent déjà
info "📊 Vérification des données existantes..."
EXISTING_COUNT=$($CQLSH -e "USE domiramacatops_poc; SELECT COUNT(*) FROM historique_opposition WHERE code_efs = '${TEST_CODE_EFS}' AND no_pse = '${TEST_NO_PSE}';" 2>&1 | grep -E "\([0-9]+ rows\)" | grep -oE "[0-9]+" | head -1 || echo "0")

if [ "$EXISTING_COUNT" -gt 0 ]; then
    warn "⚠️  Il existe déjà $EXISTING_COUNT entrées pour (code_efs=${TEST_CODE_EFS}, no_pse=${TEST_NO_PSE})"
    info "   Les nouvelles données seront ajoutées (pas de suppression des existantes)"
fi

echo ""

# Générer 30 entrées d'historique avec variété pour couvrir tous les tests
info "📝 Insertion de 30 entrées d'historique avec variété..."
echo ""

# Tableau des raisons possibles
RAISONS=(
    "Client demande désactivation"
    "Conformité RGPD"
    "Demande client"
    "Changement de politique"
    "Autre raison"
)

# Générer les entrées avec Python pour avoir des TIMEUUID et timestamps cohérents
python3 << PYEOF
import sys
from datetime import datetime, timedelta
from uuid import uuid4, uuid1
import random

code_efs = '${TEST_CODE_EFS}'
no_pse = '${TEST_NO_PSE}'
cqlsh_cmd = '${CQLSH}'

# Générer 30 entrées réparties sur toute l'année 2024
# - Mix de status : 'opposé' et 'autorisé'
# - Timestamps répartis sur 2024
# - Différentes raisons
raisons = [
    "Client demande désactivation",
    "Conformité RGPD",
    "Demande client",
    "Changement de politique",
    "Autre raison"
]

# Date de début 2024
start_date = datetime(2024, 1, 1)
end_date = datetime(2024, 12, 31)

# Générer 30 entrées
entries = []
for i in range(30):
    # Status alterné pour avoir des deux types
    status = "opposé" if i % 2 == 0 else "autorisé"

    # Timestamp réparti sur l'année
    days_offset = random.randint(0, 364)
    timestamp = start_date + timedelta(days=days_offset)

    # Raison aléatoire
    raison = random.choice(raisons)

    # TIMEUUID basé sur le timestamp (approximation)
    # Utiliser uuid1 qui est basé sur le temps
    horodate = uuid1()

    entries.append({
        'horodate': str(horodate),
        'status': status,
        'timestamp': timestamp.strftime('%Y-%m-%d %H:%M:%S+0000'),
        'raison': raison
    })

# Trier par timestamp pour avoir un ordre chronologique
entries.sort(key=lambda x: x['timestamp'])

# Insérer les entrées
import subprocess
import os

inserted = 0
for entry in entries:
    # Échapper les apostrophes dans la raison
    raison_escaped = entry['raison'].replace("'", "''")

    cql_query = f"""USE domiramacatops_poc; INSERT INTO historique_opposition (code_efs, no_pse, horodate, status, timestamp, raison) VALUES ('{code_efs}', '{no_pse}', {entry['horodate']}, '{entry['status']}', '{entry['timestamp']}', '{raison_escaped}');"""

    # Exécuter via cqlsh
    try:
        result = subprocess.run(
            cqlsh_cmd.split() + ['-e', cql_query],
            capture_output=True,
            text=True,
            timeout=10
        )
        if result.returncode == 0:
            inserted += 1
        else:
            print(f"Erreur insertion: {result.stderr}", file=sys.stderr)
    except Exception as e:
        print(f"Exception: {e}", file=sys.stderr)

print(f"✅ {inserted} entrées insérées sur {len(entries)}")
PYEOF

echo ""

# Vérifier le résultat
info "📊 Vérification finale..."
FINAL_COUNT=$($CQLSH -e "USE domiramacatops_poc; SELECT COUNT(*) FROM historique_opposition WHERE code_efs = '${TEST_CODE_EFS}' AND no_pse = '${TEST_NO_PSE}';" 2>&1 | grep -E "\([0-9]+ rows\)" | grep -oE "[0-9]+" | head -1 || echo "0")

if [ "$FINAL_COUNT" -gt 0 ]; then
    success "✅ Données de test préparées : $FINAL_COUNT entrées pour (code_efs=${TEST_CODE_EFS}, no_pse=${TEST_NO_PSE})"

    # Afficher un résumé
    info "📋 Résumé des données :"
    echo "   - Total entrées : $FINAL_COUNT"

    # Compter les status (côté application, car GROUP BY n'est pas supporté sur status et ALLOW FILTERING est interdit)
    # Récupérer toutes les données et compter côté application
    ALL_DATA=$($CQLSH -e "USE domiramacatops_poc; SELECT status FROM historique_opposition WHERE code_efs = '${TEST_CODE_EFS}' AND no_pse = '${TEST_NO_PSE}';" 2>&1)
    OPPOSE_COUNT=$(echo "$ALL_DATA" | grep -c "opposé" || echo "0")
    AUTORISE_COUNT=$(echo "$ALL_DATA" | grep -c "autorisé" || echo "0")

    echo "   - Status 'opposé' : $OPPOSE_COUNT"
    echo "   - Status 'autorisé' : $AUTORISE_COUNT"
else
    warn "⚠️  Aucune donnée trouvée après insertion"
fi

echo ""
success "✅ Préparation des données de test terminée"
echo ""
