#!/bin/bash
# ============================================
# Script : Préparation des données de test pour 13_test_dynamic_columns.sh
# Met à jour les colonnes dérivées (meta_source, meta_device, etc.) pour les données existantes
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
info "🔧 Préparation des données de test pour colonnes dynamiques (MAP)..."
echo ""

# Vérifier que les colonnes dérivées existent
info "📊 Vérification des colonnes dérivées..."
META_SOURCE_EXISTS=$($CQLSH -e "DESCRIBE TABLE domiramacatops_poc.operations_by_account;" 2>&1 | grep -c "meta_source" || echo "0")
if [ "$META_SOURCE_EXISTS" -eq 0 ]; then
    error "Colonnes dérivées non trouvées. Exécutez d'abord: ./schemas/13_create_meta_flags_indexes.cql"
    exit 1
fi
success "✅ Colonnes dérivées existent"

# Vérifier les données existantes
info "📊 Vérification des données existantes..."
EXISTING_COUNT=$($CQLSH -e "USE domiramacatops_poc; SELECT COUNT(*) FROM operations_by_account WHERE code_si = '1' AND contrat = '100000000';" 2>&1 | grep -E "\([0-9]+ rows\)" | grep -oE "[0-9]+" | head -1 || echo "0")

if [ "$EXISTING_COUNT" -eq 0 ]; then
    warn "⚠️  Aucune donnée trouvée pour (code_si='1', contrat='100000000')"
    warn "   Exécutez d'abord: ./05_load_operations_data_parquet.sh"
    exit 1
fi

info "   $EXISTING_COUNT opérations trouvées pour (code_si='1', contrat='100000000')"
echo ""

# Mettre à jour les colonnes dérivées en extrayant les valeurs du MAP meta_flags
info "📝 Mise à jour des colonnes dérivées depuis meta_flags..."
echo ""

# Utiliser Python pour lire les données, extraire les valeurs du MAP, et mettre à jour les colonnes dérivées
python3 << PYEOF
import sys
import subprocess
import json
import re

cqlsh_cmd = '${CQLSH}'

# Récupérer toutes les opérations avec meta_flags
print("Récupération des opérations avec meta_flags...", file=sys.stderr)
query = "USE domiramacatops_poc; SELECT code_si, contrat, date_op, numero_op, meta_flags FROM operations_by_account WHERE code_si = '1' AND contrat = '100000000' LIMIT 1000;"
result = subprocess.run(
    cqlsh_cmd.split() + ['-e', query],
    capture_output=True,
    text=True,
    timeout=30
)

if result.returncode != 0:
    print(f"Erreur lors de la récupération des données: {result.stderr}", file=sys.stderr)
    sys.exit(1)

# Parser les résultats (format cqlsh)
lines = result.stdout.split('\n')
operations = []
current_op = None
in_data = False

for line in lines:
    line = line.strip()
    if not line or line.startswith('(') or line.startswith('Warnings') or line.startswith('---'):
        continue

    # Détecter les lignes de données (commencent par un nombre ou contiennent des pipes)
    if '|' in line and not line.startswith('code_si'):
        parts = [p.strip() for p in line.split('|')]
        if len(parts) >= 5:
            code_si = parts[0]
            contrat = parts[1]
            date_op = parts[2]
            numero_op = parts[3]
            meta_flags_str = parts[4] if len(parts) > 4 else ''

            # Parser meta_flags (format MAP: {'key1': 'value1', 'key2': 'value2'})
            meta_flags = {}
            if meta_flags_str and meta_flags_str != 'null':
                # Extraire les paires clé-valeur du MAP
                # Format: {'source': 'mobile', 'device': 'iphone'}
                matches = re.findall(r"'([^']+)':\s*'([^']+)'", meta_flags_str)
                for key, value in matches:
                    meta_flags[key] = value

            operations.append({
                'code_si': code_si,
                'contrat': contrat,
                'date_op': date_op,
                'numero_op': numero_op,
                'meta_flags': meta_flags
            })

print(f"✅ {len(operations)} opérations récupérées")

# Mettre à jour les colonnes dérivées
updated = 0
for op in operations:
    meta_flags = op['meta_flags']

    # Construire la clause SET pour les colonnes dérivées
    set_clauses = []
    if 'source' in meta_flags:
        set_clauses.append(f"meta_source = '{meta_flags['source']}'")
    if 'device' in meta_flags:
        set_clauses.append(f"meta_device = '{meta_flags['device']}'")
    if 'channel' in meta_flags:
        set_clauses.append(f"meta_channel = '{meta_flags['channel']}'")
    if 'fraud_score' in meta_flags:
        set_clauses.append(f"meta_fraud_score = '{meta_flags['fraud_score']}'")
    if 'ip' in meta_flags:
        set_clauses.append(f"meta_ip = '{meta_flags['ip']}'")
    if 'location' in meta_flags:
        set_clauses.append(f"meta_location = '{meta_flags['location']}'")

    if set_clauses:
        # Échapper les apostrophes dans date_op si nécessaire
        date_op_escaped = op['date_op'].replace("'", "''")

        update_query = f"""USE domiramacatops_poc; UPDATE operations_by_account SET {', '.join(set_clauses)} WHERE code_si = '{op['code_si']}' AND contrat = '{op['contrat']}' AND date_op = '{date_op_escaped}' AND numero_op = {op['numero_op']};"""

        try:
            result = subprocess.run(
                cqlsh_cmd.split() + ['-e', update_query],
                capture_output=True,
                text=True,
                timeout=10
            )
            if result.returncode == 0:
                updated += 1
        except Exception as e:
            print(f"Erreur lors de la mise à jour: {e}", file=sys.stderr)

print(f"✅ {updated} opérations mises à jour avec colonnes dérivées")
PYEOF

if [ $? -eq 0 ]; then
    success "✅ Colonnes dérivées mises à jour avec succès"
else
    error "❌ Erreur lors de la mise à jour des colonnes dérivées"
    exit 1
fi

echo ""
info "📊 Vérification finale..."
UPDATED_COUNT=$($CQLSH -e "USE domiramacatops_poc; SELECT COUNT(*) FROM operations_by_account WHERE code_si = '1' AND contrat = '100000000' AND meta_source IS NOT NULL;" 2>&1 | grep -E "\([0-9]+ rows\)" | grep -oE "[0-9]+" | head -1 || echo "0")

if [ -n "$UPDATED_COUNT" ] && [ "$UPDATED_COUNT" != "" ] && [ "$UPDATED_COUNT" -gt 0 ]; then
    success "✅ $UPDATED_COUNT opérations avec meta_source renseigné"
else
    warn "⚠️  Aucune opération avec meta_source renseigné"
    warn "   Les données peuvent ne pas avoir de meta_flags ou les clés ne correspondent pas"
fi

echo ""
success "✅ Préparation des données terminée"
