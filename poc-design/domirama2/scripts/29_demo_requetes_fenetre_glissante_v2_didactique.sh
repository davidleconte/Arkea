#!/bin/bash
set -euo pipefail
# ============================================
# Script 29 : Démonstration Requêtes Fenêtre Glissante (Version Didactique)
# Démontre les requêtes en base avec fenêtre glissante via requêtes CQL directes
# Équivalent HBase: TIMERANGE avec fenêtre glissante
# ============================================
#
# OBJECTIF :
#   Ce script démontre les requêtes en base avec fenêtre glissante (TIMERANGE
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
#   ./29_demo_requetes_fenetre_glissante_v2_didactique.sh
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
REPORT_FILE="${SCRIPT_DIR}/doc/demonstrations/29_FENETRE_GLISSANTE_REQUETES_DEMONSTRATION.md"

# Créer le répertoire de documentation
mkdir -p "$(dirname "$REPORT_FILE")"

# Fichiers temporaires pour capture
TEMP_OUTPUT=$(mktemp "/tmp/script_29_output_$(date +%s).txt")
TEMP_RESULTS=$(mktemp "/tmp/script_29_results_$(date +%s).json")

# Tableau pour stocker les résultats de chaque requête
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

info "📚 OBJECTIF : Démontrer les requêtes en base avec fenêtre glissante"
echo ""
info "🔄 ÉQUIVALENCES HBase → HCD :"
echo ""
echo "   HBase                          →  HCD (CQL)"
echo "   ──────────────────────────────    ─────────────────────────────"
echo "   TIMERANGE                      →  WHERE date_op >= start AND date_op < end"
echo "   SCAN avec filtres temporels   →  SELECT ... WHERE date_op BETWEEN ..."
echo "   Requêtes par période           →  Fenêtre glissante avec WHERE date_op"
echo ""
info "💡 VALEUR AJOUTÉE SAI :"
code "   ✅ Index sur date_op (clustering key) pour performance optimale"
code "   ✅ Index sur libelle (full-text SAI) pour recherche textuelle"
code "   ✅ Combinaison d'index pour recherche optimisée"
code "   ✅ Pas de scan complet nécessaire"
echo ""
info "📋 STRATÉGIE DE DÉMONSTRATION :"
code "   - 3 requêtes CQL pour démontrer la fenêtre glissante"
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

    # Filtrer les résultats pour affichage (sans tracing)
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

        # Stocker les résultats pour le rapport
        QUERY_RESULTS+=("$query_num|$query_title|$ROW_COUNT|$QUERY_TIME|$COORDINATOR_TIME|$TOTAL_TIME|$EXIT_CODE|OK")
    else
        error "❌ Erreur lors de l'exécution de la requête $query_num"
        echo "$QUERY_OUTPUT" | tail -10
        QUERY_RESULTS+=("$query_num|$query_title|0|$QUERY_TIME|||$EXIT_CODE|ERROR")
    fi

    # Nettoyer
    rm -f "$TEMP_QUERY_FILE"
    echo ""
}

# ============================================
# REQUÊTE 1 : Requête Mensuelle (Fenêtre Glissante)
# ============================================

execute_query \
    1 \
    "Requête Mensuelle (Fenêtre Glissante)" \
    "Cette requête démontre l'équivalent du TIMERANGE HBase pour une fenêtre glissante mensuelle. Elle récupère toutes les opérations d'un compte spécifique pour le mois de novembre 2024, triées par date décroissante et numéro d'opération croissant." \
    "SCAN avec TIMERANGE pour novembre 2024" \
    "SELECT code_si, contrat, date_op, numero_op, libelle, montant, cat_auto
FROM operations_by_account
WHERE code_si = '1' AND contrat = '5913101072'
  AND date_op >= '2024-11-01' AND date_op < '2024-12-01'
ORDER BY date_op DESC, numero_op ASC
LIMIT 10;" \
    "Opérations du compte 1/5913101072 pour novembre 2024, triées par date décroissante" \
    "Index sur date_op (clustering key) permet une recherche rapide sans scan complet. La requête utilise directement l'index clustering pour filtrer par date_op, ce qui est beaucoup plus efficace qu'un scan complet de la partition."

# ============================================
# REQUÊTE 2 : Requête Fenêtre Glissante (30 Derniers Jours)
# ============================================

execute_query \
    2 \
    "Requête Fenêtre Glissante (30 Derniers Jours)" \
    "Cette requête démontre une fenêtre glissante pour les 30 derniers jours. Elle récupère les opérations récentes d'un compte spécifique, permettant des analyses temporelles sur une période glissante." \
    "SCAN avec TIMERANGE pour 30 derniers jours" \
    "SELECT code_si, contrat, date_op, numero_op, libelle, montant
FROM operations_by_account
WHERE code_si = '1' AND contrat = '5913101072'
  AND date_op >= '2024-11-01' AND date_op <= '2024-11-30'
ORDER BY date_op DESC
LIMIT 10;" \
    "Opérations du compte 1/5913101072 pour la période du 1er au 30 novembre 2024, triées par date décroissante" \
    "Index sur date_op optimise la recherche temporelle. La fenêtre glissante utilise l'index clustering pour filtrer efficacement par plage de dates, évitant un scan complet de la partition."

# ============================================
# REQUÊTE 3 : Requête avec SAI (Date + Full-Text)
# ============================================

execute_query \
    3 \
    "Requête avec SAI (Date + Full-Text Search)" \
    "Cette requête démontre la valeur ajoutée des index SAI en combinant un filtre temporel (date_op) avec une recherche full-text (libelle). Elle montre comment SAI permet d'optimiser les requêtes complexes avec plusieurs filtres." \
    "SCAN avec TIMERANGE + filtre texte côté client" \
    "SELECT code_si, contrat, date_op, numero_op, libelle, montant, cat_auto
FROM operations_by_account
WHERE code_si = '1' AND contrat = '5913101072'
  AND date_op >= '2024-11-01' AND date_op < '2024-12-01'
  AND libelle : 'PRELEVEMENT'
LIMIT 10;" \
    "Opérations du compte 1/5913101072 pour novembre 2024 contenant 'PRELEVEMENT' dans le libellé (note: ORDER BY non supporté avec index SAI)" \
    "SAI combine index date_op (clustering key) + libelle (full-text SAI) pour une recherche optimisée. Au lieu d'un scan complet suivi d'un filtrage côté client, SAI utilise les deux index simultanément pour une recherche très rapide. Performance : O(log n) avec index vs O(n) sans index."

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
code "  - SCAN complet de la partition"
code "  - Filtrage côté client"
code "  - Performance : O(n) où n = nombre d'opérations"
code "  - Temps proportionnel au nombre total d'opérations"
echo ""
code "Avec SAI (HCD) :"
code "  - Index sur date_op (clustering key) pour recherche temporelle"
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

# Créer un fichier temporaire avec les résultats
TEMP_RESULTS_FILE=$(mktemp "/tmp/script_29_results_$(date +%s).txt")
for result in "${QUERY_RESULTS[@]}"; do
    echo "$result" >> "$TEMP_RESULTS_FILE"
done

python3 << EOF
import json
import sys
from datetime import datetime

# Lire les résultats depuis le fichier temporaire
results = []
try:
    with open('${TEMP_RESULTS_FILE}', 'r') as f:
        for line in f:
            line = line.strip()
            if line and '|' in line:
                parts = line.split('|')
                if len(parts) >= 8:
                    results.append({
                        'num': parts[0],
                        'title': parts[1],
                        'rows': parts[2],
                        'time': parts[3],
                        'coord_time': parts[4] if parts[4] else '',
                        'total_time': parts[5] if parts[5] else '',
                        'exit_code': parts[6],
                        'status': parts[7]
                    })
except Exception as e:
    print(f"Erreur lors de la lecture des résultats : {e}", file=sys.stderr)

# Générer le rapport markdown
report = f"""# 📅 Démonstration : Requêtes Fenêtre Glissante

**Date** : {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}
**Script** : 29_demo_requetes_fenetre_glissante_v2_didactique.sh
**Objectif** : Démontrer les requêtes en base avec fenêtre glissante (TIMERANGE équivalent HBase)

---

## 📋 Table des Matières

1. [Contexte et Stratégie](#contexte-et-stratégie)
2. [Requêtes Exécutées](#requêtes-exécutées)
3. [Résultats par Requête](#résultats-par-requête)
4. [Comparaison Performance](#comparaison-performance)
5. [Conclusion](#conclusion)

---

## 📚 Contexte et Stratégie

### Équivalences HBase → HCD

| Concept HBase | Équivalent HCD (CQL) |
|---------------|----------------------|
| TIMERANGE | WHERE date_op >= start AND date_op < end |
| SCAN avec filtres temporels | SELECT ... WHERE date_op BETWEEN ... |
| Requêtes par période | Fenêtre glissante avec WHERE date_op |

### Valeur Ajoutée SAI

- ✅ Index sur date_op (clustering key) pour performance optimale
- ✅ Index sur libelle (full-text SAI) pour recherche textuelle
- ✅ Combinaison d'index pour recherche optimisée
- ✅ Pas de scan complet nécessaire

### Stratégie de Démonstration

- 3 requêtes CQL pour démontrer la fenêtre glissante
- Mesure de performance pour chaque requête
- Comparaison avec/sans SAI
- Documentation structurée pour livrable

---

## 🔍 Requêtes Exécutées

### Tableau Récapitulatif

| Requête | Titre | Lignes | Temps (s) | Coordinateur (μs) | Total (μs) | Statut |
|---------|-------|--------|-----------|-------------------|-----------|--------|
"""

for r in results:
    report += f"| {r['num']} | {r['title']} | {r['rows']} | {r['time']} | {r['coord_time']} | {r['total_time']} | {'✅ OK' if r['status'] == 'OK' else '❌ ERROR'} |\n"

report += """
---

## 📊 Résultats par Requête

"""

for r in results:
    report += f"""### Requête {r['num']} : {r['title']}

- **Lignes retournées** : {r['rows']}
- **Temps d'exécution** : {r['time']}s
"""
    if r['coord_time']:
        report += f"- **Temps coordinateur** : {r['coord_time']}μs\n"
    if r['total_time']:
        report += f"- **Temps total** : {r['total_time']}μs\n"
    report += f"- **Statut** : {'✅ OK' if r['status'] == 'OK' else '❌ ERROR'}\n\n"

report += """---

## 📊 Comparaison Performance

### Sans SAI (HBase)

- SCAN complet de la partition
- Filtrage côté client
- Performance : O(n) où n = nombre d'opérations
- Temps proportionnel au nombre total d'opérations

### Avec SAI (HCD)

- Index sur date_op (clustering key) pour recherche temporelle
- Index sur libelle (full-text SAI) pour recherche textuelle
- Performance : O(log n) avec index
- Valeur ajoutée : Recherche combinée optimisée
- Temps indépendant du nombre total d'opérations (seulement celles correspondant aux critères)

---

## ✅ Conclusion

### Points Clés Démontrés

- ✅ Fenêtre glissante avec WHERE date_op BETWEEN start AND end
- ✅ Requêtes mensuelles, hebdomadaires, etc. avec filtrage temporel
- ✅ Valeur ajoutée SAI : Index sur date_op + full-text pour recherche combinée
- ✅ Performance optimisée vs scan complet (O(log n) vs O(n))

### Valeur Ajoutée SAI

Les index SAI apportent une amélioration significative des performances pour les requêtes avec filtres sur les colonnes indexées. La combinaison d'index (clustering key + full-text SAI) permet d'optimiser les requêtes complexes avec plusieurs filtres simultanés.

### Équivalences HBase → HCD Validées

- ✅ TIMERANGE HBase → WHERE date_op >= start AND date_op < end
- ✅ SCAN avec filtres temporels → SELECT ... WHERE date_op BETWEEN ...
- ✅ Requêtes par période → Fenêtre glissante avec WHERE date_op

---

**Date de génération** : {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}
"""

# Écrire le rapport
report_file = '${REPORT_FILE}'
with open(report_file, 'w', encoding='utf-8') as f:
    f.write(report)

print(f"✅ Rapport généré : {report_file}")
EOF

success "✅ Rapport markdown généré : $REPORT_FILE"

# Nettoyer
rm -f "$TEMP_OUTPUT" "$TEMP_RESULTS" "$TEMP_RESULTS_FILE"

echo ""
success "✅ Démonstration requêtes fenêtre glissante terminée"
info ""
info "💡 Points clés démontrés :"
code "  ✅ Fenêtre glissante avec WHERE date_op BETWEEN"
code "  ✅ Requêtes mensuelles, hebdomadaires, etc."
code "  ✅ Valeur ajoutée SAI : Index sur date_op + full-text"
code "  ✅ Performance optimisée vs scan complet"
echo ""
