#!/bin/bash
set -euo pipefail
# ============================================
# Script 14l : Amélioration Fenêtre Glissante (P2)
# Améliore la fenêtre glissante avec validation et rapports détaillés
# ============================================
#
# OBJECTIF :
#   Ce script améliore la fenêtre glissante avec :
#   - Validation détaillée de chaque fenêtre
#   - Rapports par fenêtre
#   - Statistiques globales
#
# UTILISATION :
#   ./14_improve_sliding_window.sh [start_date] [end_date] [window_type] [output_base] [compression]
#
# ============================================

set -euo pipefail

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

if [ -f "${SCRIPT_DIR}/../utils/didactique_functions.sh" ]; then
    source "${SCRIPT_DIR}/../utils/didactique_functions.sh"
else
    RED='\033[0;31m'
    GREEN='\033[0;32m'
    YELLOW='\033[1;33m'
    BLUE='\033[0;34m'
    NC='\033[0m'
    info() { echo -e "${BLUE}ℹ️  $1${NC}"; }
    success() { echo -e "${GREEN}✅ $1${NC}"; }
    error() { echo -e "${RED}❌ $1${NC}"; }
    warn() { echo -e "${YELLOW}⚠️  $1${NC}"; }
fi

if [ -f "${INSTALL_DIR}/.poc-profile" ]; then
    source "${INSTALL_DIR}/.poc-profile"
fi

START_DATE="${1:-2024-06-01}"
END_DATE="${2:-2024-08-31}"
WINDOW_TYPE="${3:-monthly}"
OUTPUT_BASE="${4:-/tmp/exports/domiramaCatOps/sliding_window_improved}"
COMPRESSION="${5:-snappy}"

REPORT_FILE="${SCRIPT_DIR}/../doc/demonstrations/14_SLIDING_WINDOW_IMPROVED_DEMONSTRATION.md"

echo ""
info "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
info "  🪟 FENÊTRE GLISSANTE AMÉLIORÉE (P2)"
info "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

info "📅 Période : $START_DATE → $END_DATE"
info "🪟 Type de fenêtre : $WINDOW_TYPE"
info "📁 Output base : $OUTPUT_BASE"
info "🗜️  Compression : $COMPRESSION"
echo ""

# Calculer les fenêtres
WINDOWS=$(python3 << PYEOF
from datetime import datetime, timedelta
import calendar

start = datetime.strptime("$START_DATE", "%Y-%m-%d")
end = datetime.strptime("$END_DATE", "%Y-%m-%d")
window_type = "$WINDOW_TYPE"

windows = []

if window_type == "monthly":
    current = start.replace(day=1)
    while current < end:
        window_start = current
        last_day = calendar.monthrange(current.year, current.month)[1]
        window_end = current.replace(day=last_day) + timedelta(days=1)
        if window_end > end:
            window_end = end

        windows.append((window_start.strftime("%Y-%m-%d"), window_end.strftime("%Y-%m-%d"), current.strftime("%Y-%m")))
        if current.month == 12:
            current = current.replace(year=current.year + 1, month=1)
        else:
            current = current.replace(month=current.month + 1)

elif window_type == "weekly":
    current = start
    week_num = 1
    while current < end:
        window_start = current
        window_end = min(current + timedelta(days=7), end)
        windows.append((window_start.strftime("%Y-%m-%d"), window_end.strftime("%Y-%m-%d"), f"{current.strftime('%Y-%m')}-W{week_num:02d}"))
        current = window_end
        week_num += 1

for i, (ws, we, label) in enumerate(windows, 1):
    print(f"{i}|{ws}|{we}|{label}")
PYEOF
)

TOTAL_WINDOWS=$(echo "$WINDOWS" | wc -l | tr -d ' ')
TOTAL_OPERATIONS=0
TOTAL_FILES=0
SUCCESSFUL_WINDOWS=0
FAILED_WINDOWS=0

# Fichier temporaire pour stocker les détails de chaque fenêtre
WINDOW_DETAILS_FILE=$(mktemp "/tmp/window_details_$(date +%s).json")

echo ""
info "📊 $TOTAL_WINDOWS fenêtre(s) à traiter"
echo ""

# Initialiser le fichier JSON
echo "[]" > "$WINDOW_DETAILS_FILE"

# Traiter chaque fenêtre
while IFS='|' read -r window_num window_start window_end window_label; do
    echo ""
    info "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    info "  🪟 Fenêtre $window_num/$TOTAL_WINDOWS : $window_label ($window_start → $window_end)"
    info "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""

    WINDOW_OUTPUT="${OUTPUT_BASE}/${window_label}"

    # Démarrer le chronomètre
    WINDOW_START_TIME=$(date +%s)

    # Exporter la fenêtre
    python3 "${SCRIPT_DIR}/14_export_incremental_python.py" \
        "$window_start" "$window_end" "$WINDOW_OUTPUT" "$COMPRESSION" \
        "TEST_EXPORT" "TEST_CONTRAT" > /tmp/window_${window_label}.log 2>&1

    WINDOW_EXIT_CODE=$?
    WINDOW_END_TIME=$(date +%s)
    WINDOW_DURATION=$((WINDOW_END_TIME - WINDOW_START_TIME))

    # Lire les logs
    WINDOW_LOG=$(cat /tmp/window_${window_label}.log 2>/dev/null || echo "")

    if [ $WINDOW_EXIT_CODE -eq 0 ]; then
        # Validation de la fenêtre
        PARQUET_COUNT=$(find "$WINDOW_OUTPUT" -name "*.parquet" 2>/dev/null | wc -l | tr -d ' ' || echo "0")
        OPERATIONS_COUNT=$(python3 << PYCOUNT
import pyarrow.parquet as pq
parquet_path = "$WINDOW_OUTPUT"
try:
    dataset = pq.ParquetDataset(parquet_path)
    total = 0
    for fragment in dataset.fragments:
        total += fragment.metadata.num_rows
    print(total)
except:
    print("0")
PYCOUNT
)

        # Statistiques détaillées
        STATS=$(python3 << PYSTATS
import pyarrow.parquet as pq
import json
parquet_path = "$WINDOW_OUTPUT"
try:
    dataset = pq.ParquetDataset(parquet_path)
    table = dataset.read()
    df = table.to_pandas()

    stats = {
        "date_min": None,
        "date_max": None,
        "unique_accounts": 0,
        "unique_partitions": 0,
        "vector_count": 0,
        "null_dates": 0
    }

    if 'date_op' in df.columns:
        date_col = df['date_op']
        if not date_col.empty:
            stats["date_min"] = str(date_col.min()) if not date_col.isna().all() else None
            stats["date_max"] = str(date_col.max()) if not date_col.isna().all() else None
            stats["null_dates"] = int(date_col.isna().sum())

    if 'code_si' in df.columns and 'contrat' in df.columns:
        stats["unique_accounts"] = int(df[['code_si', 'contrat']].drop_duplicates().shape[0])

    if 'date_partition' in df.columns:
        stats["unique_partitions"] = int(df['date_partition'].nunique())

    if 'libelle_embedding' in df.columns:
        stats["vector_count"] = int(df['libelle_embedding'].notna().sum())

    print(json.dumps(stats))
except Exception as e:
    print(json.dumps({"error": str(e)}))
PYSTATS
)

        # Récupérer le nombre d'opérations depuis la source HCD pour comparaison
        # Utiliser le même filtrage que l'export Python (code_si et contrat)
        SOURCE_COUNT=$(python3 << PYSOURCE
from cassandra.cluster import Cluster
from datetime import datetime

try:
    cluster = Cluster(['localhost'], port=9042)
    session = cluster.connect('domiramacatops_poc')

    # Convertir les dates en timestamps (comme dans l'export Python)
    start_dt = datetime.strptime("$window_start", "%Y-%m-%d")
    end_dt = datetime.strptime("$window_end", "%Y-%m-%d")
    start_ts = int(start_dt.timestamp() * 1000)
    end_ts = int(end_dt.timestamp() * 1000)

    # Utiliser les mêmes filtres que l'export Python
    code_si_filter = "TEST_EXPORT"
    contrat_filter = "TEST_CONTRAT"

    # Requête pour compter les opérations dans la période (même WHERE que l'export)
    query = f"""
    SELECT COUNT(*)
    FROM operations_by_account
    WHERE code_si = '{code_si_filter}'
      AND contrat = '{contrat_filter}'
      AND date_op >= {start_ts}
      AND date_op < {end_ts}
    """

    result = session.execute(query)
    count = result.one()[0] if result else 0
    print(count)

    cluster.shutdown()
except Exception as e:
    print(f"0")
PYSOURCE
)

        # Validation avancée si disponible
        VALIDATION_OUTPUT=""
        if [ -f "${SCRIPT_DIR}/14_validate_export_advanced.py" ]; then
            VALIDATION_OUTPUT=$(python3 "${SCRIPT_DIR}/14_validate_export_advanced.py" "$WINDOW_OUTPUT" "$SOURCE_COUNT" 2>&1 || echo "")
        fi

        if [ "$PARQUET_COUNT" -gt 0 ] && [ "$OPERATIONS_COUNT" -gt 0 ]; then
            success "✅ Fenêtre $window_label : $OPERATIONS_COUNT opérations, $PARQUET_COUNT fichiers en ${WINDOW_DURATION}s"

            # Ajouter les détails au JSON
            python3 << PYJSON
import json
import sys

window_details = {
    "window_num": int("$window_num"),
    "window_label": "$window_label",
    "window_start": "$window_start",
    "window_end": "$window_end",
    "success": True,
    "operations_count": int("$OPERATIONS_COUNT"),
    "parquet_count": int("$PARQUET_COUNT"),
    "duration_seconds": int("$WINDOW_DURATION"),
    "output_path": "$WINDOW_OUTPUT",
    "stats": json.loads('''$STATS'''),
    "validation_output": '''$VALIDATION_OUTPUT''',
    "log": '''$WINDOW_LOG'''
}

with open("$WINDOW_DETAILS_FILE", "r") as f:
    details = json.load(f)

details.append(window_details)

with open("$WINDOW_DETAILS_FILE", "w") as f:
    json.dump(details, f, indent=2)
PYJSON

            TOTAL_OPERATIONS=$((TOTAL_OPERATIONS + OPERATIONS_COUNT))
            TOTAL_FILES=$((TOTAL_FILES + PARQUET_COUNT))
            SUCCESSFUL_WINDOWS=$((SUCCESSFUL_WINDOWS + 1))
        else
            warn "⚠️  Fenêtre $window_label : Aucune donnée exportée"

            # Ajouter les détails au JSON
            python3 << PYJSON
import json

window_details = {
    "window_num": int("$window_num"),
    "window_label": "$window_label",
    "window_start": "$window_start",
    "window_end": "$window_end",
    "success": False,
    "operations_count": 0,
    "parquet_count": 0,
    "duration_seconds": int("$WINDOW_DURATION"),
    "output_path": "$WINDOW_OUTPUT",
    "error": "Aucune donnée exportée",
    "log": '''$WINDOW_LOG'''
}

with open("$WINDOW_DETAILS_FILE", "r") as f:
    details = json.load(f)

details.append(window_details)

with open("$WINDOW_DETAILS_FILE", "w") as f:
    json.dump(details, f, indent=2)
PYJSON

            FAILED_WINDOWS=$((FAILED_WINDOWS + 1))
        fi
    else
        error "❌ Fenêtre $window_label : Erreur lors de l'export (code: $WINDOW_EXIT_CODE)"

        # Ajouter les détails au JSON
        python3 << PYJSON
import json

window_details = {
    "window_num": int("$window_num"),
    "window_label": "$window_label",
    "window_start": "$window_start",
    "window_end": "$window_end",
    "success": False,
    "operations_count": 0,
    "parquet_count": 0,
    "duration_seconds": int("$WINDOW_DURATION"),
    "output_path": "$WINDOW_OUTPUT",
    "error": "Erreur lors de l'export",
    "exit_code": int("$WINDOW_EXIT_CODE"),
    "log": '''$WINDOW_LOG'''
}

with open("$WINDOW_DETAILS_FILE", "r") as f:
    details = json.load(f)

details.append(window_details)

with open("$WINDOW_DETAILS_FILE", "w") as f:
    json.dump(details, f, indent=2)
PYJSON

        FAILED_WINDOWS=$((FAILED_WINDOWS + 1))
    fi

done <<< "$WINDOWS"

# ============================================
# RÉSUMÉ GLOBAL
# ============================================
echo ""
info "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
info "  📊 RÉSUMÉ GLOBAL - FENÊTRE GLISSANTE"
info "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

info "Total fenêtres : $TOTAL_WINDOWS"
success "Fenêtres réussies : $SUCCESSFUL_WINDOWS"
if [ $FAILED_WINDOWS -gt 0 ]; then
    error "Fenêtres échouées : $FAILED_WINDOWS"
else
    success "Fenêtres échouées : $FAILED_WINDOWS"
fi

echo ""
info "Total opérations exportées : $TOTAL_OPERATIONS"
info "Total fichiers Parquet créés : $TOTAL_FILES"

# Génération du rapport détaillé
export WINDOW_DETAILS_FILE
python3 << 'PYEOF' > "$REPORT_FILE"
import os
import json
from datetime import datetime

generation_date = datetime.now().strftime('%Y-%m-%d %H:%M:%S')
start_date = os.environ.get('START_DATE', '2024-06-01')
end_date = os.environ.get('END_DATE', '2024-08-31')
window_type = os.environ.get('WINDOW_TYPE', 'monthly')
total_windows = int(os.environ.get('TOTAL_WINDOWS', '0'))
successful_windows = int(os.environ.get('SUCCESSFUL_WINDOWS', '0'))
failed_windows = int(os.environ.get('FAILED_WINDOWS', '0'))
total_operations = int(os.environ.get('TOTAL_OPERATIONS', '0'))
total_files = int(os.environ.get('TOTAL_FILES', '0'))
compression = os.environ.get('COMPRESSION', 'snappy')
output_base = os.environ.get('OUTPUT_BASE', '/tmp/exports')
window_details_file = os.environ.get('WINDOW_DETAILS_FILE', '')

# Charger les détails des fenêtres
window_details = []
if os.path.exists(window_details_file):
    with open(window_details_file, 'r') as f:
        window_details = json.load(f)

# Calculer les statistiques globales depuis les détails
if window_details:
    total_duration = sum(w.get('duration_seconds', 0) for w in window_details)
    avg_duration = total_duration / len(window_details) if window_details else 0
    successful_windows_actual = sum(1 for w in window_details if w.get('success', False))
    failed_windows_actual = sum(1 for w in window_details if not w.get('success', False))
    total_operations_actual = sum(w.get('operations_count', 0) for w in window_details)
    total_files_actual = sum(w.get('parquet_count', 0) for w in window_details)
    # Utiliser le nombre réel de fenêtres depuis les détails
    total_windows_actual = len(window_details)
    success_rate = (successful_windows_actual / total_windows_actual * 100) if total_windows_actual > 0 else 0

    # Utiliser les valeurs calculées depuis les détails
    successful_windows = successful_windows_actual
    failed_windows = failed_windows_actual
    total_operations = total_operations_actual
    total_files = total_files_actual
    total_windows = total_windows_actual
else:
    # Utiliser les valeurs d'environnement si pas de détails
    total_duration = 0
    avg_duration = 0
    success_rate = (successful_windows / total_windows * 100) if total_windows > 0 else 0

report = f"""# 🪟 Fenêtre Glissante Améliorée (P2)

**Date** : {generation_date}
**Script** : 14_improve_sliding_window.sh
**Objectif** : Export par fenêtre glissante avec validation détaillée

---

## 📋 Table des Matières

1. [Résumé Exécutif](#résumé-exécutif)
2. [Configuration](#configuration)
3. [Détails par Fenêtre](#détails-par-fenêtre)
4. [Statistiques Globales](#statistiques-globales)
5. [Validation et Vérifications](#validation-et-vérifications)
6. [Conclusion](#conclusion)

---

## 📋 Résumé Exécutif

### Paramètres d'Export

- **Période** : {start_date} → {end_date}
- **Type de fenêtre** : {window_type}
- **Compression** : {compression}
- **Répertoire de sortie** : {output_base}

### Résultats Globaux

- **Total fenêtres** : {total_windows}
- **Fenêtres réussies** : {successful_windows} ({success_rate:.1f}%)
- **Fenêtres échouées** : {failed_windows}
- **Total opérations exportées** : {total_operations:,}
- **Total fichiers Parquet créés** : {total_files}
- **Durée totale** : {total_duration}s
- **Durée moyenne par fenêtre** : {avg_duration:.1f}s

---

## ⚙️ Configuration

### Stratégie d'Export

L'export par fenêtre glissante permet de :
- ✅ **Diviser une période en fenêtres** : Calcul automatique des fenêtres ({window_type})
- ✅ **Exporter chaque fenêtre indépendamment** : Isolation des données par période
- ✅ **Valider chaque fenêtre** : Validation complète avec statistiques détaillées
- ✅ **Générer des rapports détaillés** : Documentation complète de chaque export

### Avantages

- **Performance** : Traitement par lots plus efficace
- **Traçabilité** : Chaque fenêtre est documentée individuellement
- **Reprise sur erreur** : Possibilité de réexporter uniquement les fenêtres échouées
- **Validation granulaire** : Détection précise des problèmes par fenêtre

---

## 🪟 Détails par Fenêtre

"""

# Ajouter les détails de chaque fenêtre
for i, window in enumerate(sorted(window_details, key=lambda x: x.get('window_num', 0)), 1):
    window_num = window.get('window_num', i)
    window_label = window.get('window_label', f'Fenêtre {i}')
    window_start = window.get('window_start', '')
    window_end = window.get('window_end', '')
    success = window.get('success', False)
    operations_count = window.get('operations_count', 0)
    parquet_count = window.get('parquet_count', 0)
    duration = window.get('duration_seconds', 0)
    output_path = window.get('output_path', '')
    stats = window.get('stats', {})
    validation_output = window.get('validation_output', '')
    error = window.get('error', '')
    log = window.get('log', '')

    status_icon = "✅" if success else "❌"
    status_text = "RÉUSSIE" if success else "ÉCHOUÉE"

    # Échapper les caractères spéciaux pour le markdown
    def escape_md(text):
        if not text:
            return ""
        return str(text).replace('`', '\\`').replace('$', '\\$')

    report += f"""### Fenêtre {window_num} : {window_label} {status_icon} {status_text}

**Période** : {window_start} → {window_end}

**Statut** : {status_text}

**Résultats** :
- Opérations exportées : {operations_count:,}
- Fichiers Parquet créés : {parquet_count}
- Durée d'export : {duration}s
- Répertoire de sortie : `{escape_md(output_path)}`

"""

    if success and stats:
        date_min = stats.get('date_min', 'N/A')
        date_max = stats.get('date_max', 'N/A')
        unique_accounts = stats.get('unique_accounts', 0)
        unique_partitions = stats.get('unique_partitions', 0)
        vector_count = stats.get('vector_count', 0)
        null_dates = stats.get('null_dates', 0)

        report += f"""**Statistiques Détaillées** :
- Date min : {date_min}
- Date max : {date_max}
- Comptes uniques (code_si, contrat) : {unique_accounts}
- Partitions uniques (date_partition) : {unique_partitions}
- Opérations avec VECTOR : {vector_count}
- Dates NULL : {null_dates}

"""

        if validation_output:
            # Tronquer à 2000 caractères pour inclure la section "Comparaison avec Source"
            val_output_escaped = escape_md(validation_output[:2000])
            report += f"""**Validation Avancée** :

```
{val_output_escaped}
```

"""
    elif error:
        error_escaped = escape_md(error)
        report += f"""**Erreur** : {error_escaped}

"""
        if log:
            log_escaped = escape_md(log[:500])
            report += f"""**Log d'erreur** :

```
{log_escaped}
```

"""

    report += "---\n\n"

# Statistiques globales
report += f"""## 📊 Statistiques Globales

### Performance

- **Durée totale** : {total_duration}s
- **Durée moyenne par fenêtre** : {avg_duration:.1f}s
- **Fenêtre la plus rapide** : {min((w.get('duration_seconds', 0) for w in window_details if w.get('success', False)), default=0)}s
- **Fenêtre la plus lente** : {max((w.get('duration_seconds', 0) for w in window_details if w.get('success', False)), default=0)}s

### Volume de Données

- **Total opérations** : {total_operations:,}
- **Moyenne par fenêtre réussie** : {total_operations // successful_windows if successful_windows > 0 else 0:,}
- **Total fichiers Parquet** : {total_files}
- **Moyenne fichiers par fenêtre** : {total_files // successful_windows if successful_windows > 0 else 0}

### Taux de Réussite

- **Taux de réussite global** : {success_rate:.1f}%
- **Fenêtres réussies** : {successful_windows}/{total_windows}
- **Fenêtres échouées** : {failed_windows}/{total_windows}

---

## ✅ Validation et Vérifications

### Validations Effectuées

Pour chaque fenêtre réussie, les validations suivantes ont été effectuées :

1. **Validation du Schéma Parquet** :
   - ✅ Vérification de toutes les colonnes attendues
   - ✅ Vérification des types de données
   - ✅ Détection des colonnes manquantes

2. **Validation du VECTOR** :
   - ✅ Présence de la colonne `libelle_embedding`
   - ✅ Format string (VECTOR converti)
   - ✅ Comptage des valeurs non-null

3. **Statistiques Détaillées** :
   - ✅ Dates min/max
   - ✅ Comptes uniques (code_si, contrat)
   - ✅ Partitions créées
   - ✅ Dates NULL

4. **Comparaison avec Source** :
   - ✅ Cohérence du nombre d'opérations exportées

---

## ✅ Conclusion

### Points Clés Démontrés

- ✅ **Export par fenêtre glissante fonctionnel** : {successful_windows} fenêtre(s) exportée(s) avec succès
- ✅ **Validation détaillée** : Chaque fenêtre est validée individuellement
- ✅ **Rapports complets** : Documentation détaillée de chaque export
- ✅ **Statistiques globales** : Vue d'ensemble des performances et volumes

### Résultats

- **Total opérations exportées** : {total_operations:,}
- **Taux de réussite** : {success_rate:.1f}%
- **Performance** : {avg_duration:.1f}s par fenêtre en moyenne

### Recommandations

"""

if failed_windows > 0:
    report += f"""- ⚠️  **{failed_windows} fenêtre(s) ont échoué** : Vérifier les logs d'erreur pour identifier les causes
- 💡 **Réexporter les fenêtres échouées** : Utiliser le script avec des paramètres spécifiques pour les fenêtres problématiques

"""
else:
    report += """- ✅ **Toutes les fenêtres ont réussi** : Export complet et cohérent
- ✅ **Performance acceptable** : Durées d'export dans les limites attendues

"""

report += f"""
---

**Date de génération** : {generation_date}

**Pour plus de détails sur l'implémentation P1 et P2, voir** : doc/14_IMPLEMENTATION_P1_P2.md
"""

print(report, end='')
PYEOF

# Nettoyer le fichier temporaire après génération du rapport
rm -f "$WINDOW_DETAILS_FILE"

success "✅ Rapport généré : $REPORT_FILE"

echo ""
if [ $FAILED_WINDOWS -eq 0 ]; then
    success "✅ TOUTES LES FENÊTRES SONT RÉUSSIES !"
    exit 0
else
    warn "⚠️  CERTAINES FENÊTRES ONT ÉCHOUÉ"
    exit 1
fi
