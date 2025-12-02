#!/bin/bash
set -euo pipefail
# ============================================
# Script : Insertion de données de test avec meta_flags et colonnes dérivées
# Insère des opérations avec des valeurs meta_flags variées et met à jour les colonnes dérivées
# ============================================

set +e

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
info "🔧 Insertion de données de test avec meta_flags et colonnes dérivées..."
echo ""

# Vérifier que HCD est démarré
if ! nc -z "$HCD_HOST" "$HCD_PORT" 2>/dev/null; then
    error "HCD n'est pas démarré sur localhost:9042"
    error "Exécutez d'abord: ./scripts/setup/03_start_hcd.sh"
    exit 1
fi

# Vérifier que les colonnes dérivées existent
info "📊 Vérification des colonnes dérivées..."
META_SOURCE_EXISTS=$($CQLSH -e "DESCRIBE TABLE domiramacatops_poc.operations_by_account;" 2>&1 | grep -c "meta_source" || echo "0")
if [ "$META_SOURCE_EXISTS" -eq 0 ]; then
    error "Colonnes dérivées non trouvées. Exécutez d'abord: ./13_create_meta_flags_indexes.sh"
    exit 1
fi
success "✅ Colonnes dérivées existent"

# Utiliser Python pour insérer les données avec meta_flags et colonnes dérivées
info "📝 Insertion de données de test avec meta_flags variées..."
echo ""

python3 << PYEOF
import sys
import subprocess
from datetime import datetime, timedelta
import random
import uuid

cqlsh_cmd = '${CQLSH}'

# Valeurs de test pour meta_flags
sources = ['mobile', 'web', 'mobile', 'web', 'mobile']
devices = ['iphone', 'android', 'iphone', 'desktop', 'android']
channels = ['app', 'web', 'app', 'web', 'app']
ips = ['192.168.1.1', '192.168.1.2', '10.0.0.1', '10.0.0.2', '172.16.0.1']
locations = ['paris', 'lyon', 'marseille', 'toulouse', 'nice']
fraud_scores = ['0.1', '0.3', '0.5', '0.7', '0.85']

# Code EFS et contrat de test
code_si = '1'
contrat = '100000000'

# Date de base
base_date = datetime(2024, 1, 20, 10, 0, 0)

# Générer 50 opérations avec meta_flags variées
operations = []
for i in range(50):
    # Générer meta_flags avec différentes combinaisons
    meta_flags = {}

    # Source (toujours présent)
    source = random.choice(sources)
    meta_flags['source'] = source

    # Device (80% de chance)
    if random.random() < 0.8:
        device = random.choice(devices)
        meta_flags['device'] = device
    else:
        device = None

    # Channel (70% de chance)
    if random.random() < 0.7:
        channel = random.choice(channels)
        meta_flags['channel'] = channel
    else:
        channel = None

    # IP (60% de chance)
    if random.random() < 0.6:
        ip = random.choice(ips)
        meta_flags['ip'] = ip
    else:
        ip = None

    # Location (50% de chance)
    if random.random() < 0.5:
        location = random.choice(locations)
        meta_flags['location'] = location
    else:
        location = None

    # Fraud score (40% de chance)
    if random.random() < 0.4:
        fraud_score = random.choice(fraud_scores)
        meta_flags['fraud_score'] = fraud_score
    else:
        fraud_score = None

    # Date opération (incrémenter de i heures)
    date_op = base_date + timedelta(hours=i)
    date_op_str = date_op.strftime('%Y-%m-%d %H:%M:%S')

    # Numéro opération
    numero_op = i + 1

    # Libellé
    libelles = [
        'VIREMENT SEPA',
        'PRELEVEMENT AUTOMATIQUE',
        'CARTE BANCAIRE',
        'VIREMENT INTERNE',
        'CHEQUE'
    ]
    libelle = random.choice(libelles)

    # Montant
    montant = round(random.uniform(10.0, 1000.0), 2)

    operations.append({
        'code_si': code_si,
        'contrat': contrat,
        'date_op': date_op_str,
        'numero_op': numero_op,
        'libelle': libelle,
        'montant': montant,
        'meta_flags': meta_flags,
        'meta_source': source,
        'meta_device': device,
        'meta_channel': channel,
        'meta_ip': ip,
        'meta_location': location,
        'meta_fraud_score': fraud_score
    })

print(f"✅ {len(operations)} opérations préparées")

# Construire la requête CQL pour chaque opération
inserted = 0
for op in operations:
    # Construire la représentation MAP pour meta_flags
    meta_flags_map = '{'
    meta_flags_parts = []
    for key, value in op['meta_flags'].items():
        if value is not None:
            # Échapper les apostrophes dans les valeurs
            value_escaped = value.replace("'", "''")
            meta_flags_parts.append(f"'{key}': '{value_escaped}'")
    meta_flags_map += ', '.join(meta_flags_parts)
    meta_flags_map += '}'

    # Construire les valeurs pour les colonnes dérivées (NULL si None)
    meta_source_val = f"'{op['meta_source']}'" if op['meta_source'] else 'NULL'
    meta_device_val = f"'{op['meta_device']}'" if op['meta_device'] else 'NULL'
    meta_channel_val = f"'{op['meta_channel']}'" if op['meta_channel'] else 'NULL'
    meta_ip_val = f"'{op['meta_ip']}'" if op['meta_ip'] else 'NULL'
    meta_location_val = f"'{op['meta_location']}'" if op['meta_location'] else 'NULL'
    meta_fraud_score_val = f"'{op['meta_fraud_score']}'" if op['meta_fraud_score'] else 'NULL'

    # Échapper le libellé
    libelle_escaped = op['libelle'].replace("'", "''")

    # Construire la requête INSERT
    insert_query = f"""USE domiramacatops_poc; INSERT INTO operations_by_account (
    code_si, contrat, date_op, numero_op, libelle, montant, devise, type_operation, sens_operation,
    meta_flags, meta_source, meta_device, meta_channel, meta_ip, meta_location, meta_fraud_score
) VALUES (
    '{op['code_si']}', '{op['contrat']}', '{op['date_op']}', {op['numero_op']},
    '{libelle_escaped}', {op['montant']}, 'EUR', 'VIREMENT', 'DEBIT',
    {meta_flags_map},
    {meta_source_val}, {meta_device_val}, {meta_channel_val}, {meta_ip_val}, {meta_location_val}, {meta_fraud_score_val}
);"""

    try:
        result = subprocess.run(
            cqlsh_cmd.split() + ['-e', insert_query],
            capture_output=True,
            text=True,
            timeout=10
        )
        if result.returncode == 0:
            inserted += 1
        else:
            print(f"Erreur insertion opération {op['numero_op']}: {result.stderr}", file=sys.stderr)
    except Exception as e:
        print(f"Exception insertion opération {op['numero_op']}: {e}", file=sys.stderr)

print(f"✅ {inserted} opérations insérées sur {len(operations)}")
PYEOF

if [ $? -eq 0 ]; then
    success "✅ Données de test insérées avec succès"
else
    error "❌ Erreur lors de l'insertion des données de test"
    exit 1
fi

echo ""
info "📊 Vérification des données insérées..."

# Vérifier le nombre d'opérations avec meta_source renseigné
COUNT_WITH_SOURCE=$($CQLSH -e "USE domiramacatops_poc; SELECT COUNT(*) FROM operations_by_account WHERE code_si = '1' AND contrat = '100000000' AND meta_source IS NOT NULL;" 2>&1 | grep -E "\([0-9]+ rows\)" | grep -oE "[0-9]+" | head -1 || echo "0")

if [ -n "$COUNT_WITH_SOURCE" ] && [ "$COUNT_WITH_SOURCE" != "" ] && [ "$COUNT_WITH_SOURCE" -gt 0 ]; then
    success "✅ $COUNT_WITH_SOURCE opérations avec meta_source renseigné"
else
    warn "⚠️  Aucune opération avec meta_source renseigné"
fi

# Vérifier le nombre d'opérations avec meta_device renseigné
COUNT_WITH_DEVICE=$($CQLSH -e "USE domiramacatops_poc; SELECT COUNT(*) FROM operations_by_account WHERE code_si = '1' AND contrat = '100000000' AND meta_device IS NOT NULL;" 2>&1 | grep -E "\([0-9]+ rows\)" | grep -oE "[0-9]+" | head -1 || echo "0")

if [ -n "$COUNT_WITH_DEVICE" ] && [ "$COUNT_WITH_DEVICE" != "" ] && [ "$COUNT_WITH_DEVICE" -gt 0 ]; then
    success "✅ $COUNT_WITH_DEVICE opérations avec meta_device renseigné"
else
    warn "⚠️  Aucune opération avec meta_device renseigné"
fi

# Afficher un échantillon
echo ""
info "📋 Échantillon des données insérées (5 premières opérations) :"
$CQLSH -e "USE domiramacatops_poc; SELECT code_si, contrat, date_op, numero_op, libelle, meta_source, meta_device, meta_channel FROM operations_by_account WHERE code_si = '1' AND contrat = '100000000' AND meta_source IS NOT NULL LIMIT 5;" 2>&1 | grep -vE "^Warnings|^\([0-9]+ rows\)|coordinator|total|Executing|Read|Scanned|Merging|Tracing|Activity|Requests|responses|Parsing|Sending|MULTI_RANGE|Query execution|Limit|Filter|Fetch|LiteralIndexScan|single-partition|stage READ|RequestResponse|activity|timestamp|source|client|Processing|Request complete|Tracing session|Execute CQL3 query|^[[:space:]]*$" | head -10

echo ""
success "✅ Script terminé"
