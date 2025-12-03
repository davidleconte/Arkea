#!/bin/bash
# ============================================
# Script 41 : Démonstration Recherche Wildcard Avancée
# Démonstration complète de la recherche avec wildcards complexes
# ============================================
#
# OBJECTIF :
#   Ce script présente une démonstration complète et professionnelle de la
#   recherche avec wildcards avancés dans domirama2, incluant :
#   - Patterns complexes avec wildcards multiples
#   - Recherche multi-champs (libelle + cat_auto + cat_user)
#   - Cas d'usage métier réalistes
#   - Comparaison de performances (LIKE vs Full-Text vs Vector)
#   - Optimisations et bonnes pratiques
#
#   Cette démonstration est conçue pour être utilisée dans un contexte
#   professionnel de présentation client ou de documentation technique.
#
# PRÉREQUIS :
#   - HCD démarré (./scripts/setup/03_start_hcd.sh)
#   - Schéma configuré (./10_setup_domirama2_poc.sh)
#   - Données chargées (./11_load_domirama2_data_parquet.sh)
#   - Fuzzy search configuré (./21_setup_fuzzy_search.sh)
#   - Embeddings générés (./22_generate_embeddings.sh)
#   - Python 3.8+ avec cassandra-driver, transformers, torch installés
#   - Clé API Hugging Face configurée (HF_API_KEY dans .poc-profile)
#   - Module Python présent: examples/python/search/like_wildcard_search.py
#   - Script 40 exécuté avec succès (./40_test_like_patterns.sh)
#
# UTILISATION :
#   ./41_demo_wildcard_search.sh
#
# EXEMPLE :
#   ./41_demo_wildcard_search.sh
#
# SORTIE :
#   - Démonstration complète des patterns wildcard avancés
#   - Cas d'usage métier détaillés
#   - Comparaison de performances
#   - Recommandations d'optimisation
#   - Documentation professionnelle générée automatiquement
#
# PROCHAINES ÉTAPES :
#   - Intégration dans l'application métier
#   - Optimisation des performances selon les cas d'usage
#   - Consulter la documentation: doc/demonstrations/41_WILDCARD_SEARCH_DEMO.md
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
highlight() { echo -e "${BOLD}${YELLOW}💡 $1${NC}"; }

# ============================================
# CONFIGURATION
# ============================================
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
if [ -f "${SCRIPT_DIR}/utils/didactique_functions.sh" ]; then
    source "${SCRIPT_DIR}/utils/didactique_functions.sh"
    setup_paths
else
    SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    # Remonter jusqu'à la racine du projet Arkea (scripts -> domirama2 -> poc-design -> Arkea)
    INSTALL_DIR="${ARKEA_HOME:-$(cd "$SCRIPT_DIR/../../.." && pwd)}"
    HCD_DIR="${HCD_DIR:-${INSTALL_DIR}/binaire/hcd-1.2.3}"
    SPARK_HOME="${SPARK_HOME:-${INSTALL_DIR}/binaire/spark-3.5.1}"
    HCD_HOST="${HCD_HOST:-localhost}"
    HCD_PORT="${HCD_PORT:-9042}"
fi

PYTHON_SCRIPT="${SCRIPT_DIR}/../examples/python/search/like_wildcard_search.py"
REPORT_FILE="${SCRIPT_DIR}/../doc/demonstrations/41_WILDCARD_SEARCH_DEMO.md"

mkdir -p "$(dirname "$REPORT_FILE")"

# Vérifications
if ! check_hcd_prerequisites 2>/dev/null; then
    if ! pgrep -f "cassandra" > /dev/null; then
        error "HCD n'est pas démarré. Exécutez d'abord: ./scripts/setup/03_start_hcd.sh"
        exit 1
    fi
    if ! nc -z "$HCD_HOST" "$HCD_PORT" 2>/dev/null; then
        error "HCD n'est pas accessible sur $HCD_HOST:$HCD_PORT"
        exit 1
    fi
fi

if ! command -v python3 &> /dev/null; then
    error "Python3 n'est pas installé"
    exit 1
fi

if [ ! -f "$PYTHON_SCRIPT" ]; then
    error "Module Python non trouvé: $PYTHON_SCRIPT"
    exit 1
fi

cd "$HCD_DIR"
set +u  # Désactiver temporairement la vérification des variables non définies pour jenv
jenv local 11 2>/dev/null || true
eval "$(jenv init -)" 2>/dev/null || true
set -u  # Réactiver la vérification

if ! ./bin/cqlsh "$HCD_HOST" "$HCD_PORT" -e "DESCRIBE KEYSPACE domirama2_poc;" > /dev/null 2>&1; then
    error "Le keyspace domirama2_poc n'existe pas. Exécutez d'abord: ./10_setup_domirama2_poc.sh"
    exit 1
fi

cd "$INSTALL_DIR"
if [ -f ".poc-profile" ]; then
    source ".poc-profile" 2>/dev/null || true
fi

if [ -z "${HF_API_KEY:-}" ]; then
    export HF_API_KEY="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"
    warn "⚠️  HF_API_KEY non définie dans .poc-profile, utilisation de la clé par défaut."
fi

# ============================================
# EN-TÊTE PROFESSIONNEL
# ============================================
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  🎯 DÉMONSTRATION PROFESSIONNELLE : Recherche Wildcard Avancée"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
info "📚 Cette démonstration professionnelle présente :"
echo "   ✅ Patterns wildcard complexes (multiples wildcards)"
echo "   ✅ Recherche multi-champs (libelle + cat_auto + cat_user)"
echo "   ✅ Cas d'usage métier réalistes"
echo "   ✅ Comparaison de performances (LIKE vs Full-Text vs Vector)"
echo "   ✅ Optimisations et bonnes pratiques"
echo "   ✅ Documentation professionnelle générée automatiquement"
echo ""

# ============================================
# PARTIE 1: PATTERNS WILDCARD COMPLEXES
# ============================================
echo ""
section "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
section "  🔧 PARTIE 1: PATTERNS WILDCARD COMPLEXES"
section "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

info "📚 PATTERNS COMPLEXES - Wildcards Multiples :"
echo ""
echo "   Les patterns avec plusieurs wildcards permettent de rechercher"
echo "   des séquences de mots séparées par du texte arbitraire."
echo ""
echo "   Exemples de patterns complexes :"
echo ""
code "   Pattern: '%LOYER%IMP%'"
echo "   Regex:   '.*LOYER.*IMP.*'"
echo "   Trouve:  'LOYER IMPAYE', 'LOYER IMPAYE MENSUEL', etc."
echo ""
code "   Pattern: '*CARREFOUR*PAIEMENT*'"
echo "   Regex:   '.*CARREFOUR.*PAIEMENT.*'"
echo "   Trouve:  'CARREFOUR PAIEMENT CARTE', 'CARREFOUR PAIEMENT CB', etc."
echo ""

info "📝 IMPLÉMENTATION - Conversion Multi-Wildcards :"
echo ""
code "   def build_regex_pattern(query_pattern):"
code "       # Remplacer tous les wildcards (* et %) par placeholder"
code "       temp = query_pattern.replace('*', '__WILDCARD__')"
code "       temp = temp.replace('%', '__WILDCARD__')"
code "       # Échapper les caractères spéciaux"
code "       escaped = re.escape(temp)"
code "       # Remplacer placeholder par '.*' (n'importe quels caractères)"
code "       return escaped.replace('__WILDCARD__', '.*')"
echo ""

# ============================================
# PARTIE 2: RECHERCHE MULTI-CHAMPS
# ============================================
echo ""
section "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
section "  🔍 PARTIE 2: RECHERCHE MULTI-CHAMPS"
section "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

info "📚 RECHERCHE MULTI-CHAMPS - Logique AND/OR :"
echo ""
echo "   La recherche multi-champs permet d'appliquer des patterns LIKE"
echo "   sur plusieurs colonnes simultanément avec logique AND ou OR."
echo ""
echo "   Logique AND (match_all=True) :"
echo "      ✅ Tous les patterns doivent matcher"
echo "      ✅ Plus restrictif, résultats plus précis"
echo ""
echo "   Logique OR (match_all=False) :"
echo "      ✅ Au moins un pattern doit matcher"
echo "      ✅ Plus permissif, résultats plus nombreux"
echo ""

info "📝 EXEMPLE - Recherche Multi-Champs :"
echo ""
code "   like_queries = ["
code "       \"libelle LIKE '%LOYER%'\","
code "       \"cat_auto LIKE '%IMP%'\""
code "   ]"
code ""
code "   results = multi_field_like_search("
code "       session=session,"
code "       query_text='loyer impaye',"
code "       like_queries=like_queries,"
code "       match_all=True  # AND: les deux doivent matcher"
code "   )"
echo ""

# ============================================
# PARTIE 3: CAS D'USAGE MÉTIER
# ============================================
echo ""
section "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
section "  💼 PARTIE 3: CAS D'USAGE MÉTIER"
section "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

info "📚 CAS D'USAGE 1 - Recherche de Libellés Partiels :"
echo ""
echo "   Scénario : Trouver toutes les opérations contenant 'LOYER'"
echo "   dans le libellé, même avec des variations."
echo ""
code "   Requête: libelle LIKE '%LOYER%'"
code "   Vector:  'loyer'"
echo ""
expected "   Résultats attendus :"
echo "      - 'LOYER IMPAYE'"
echo "      - 'LOYER MENSUEL'"
echo "      - 'LOYERS IMPAYES'"
echo ""

info "📚 CAS D'USAGE 2 - Recherche avec Typos :"
echo ""
echo "   Scénario : Trouver 'LOYER' malgré la typo 'LOYR'"
echo "   grâce à la recherche vectorielle."
echo ""
code "   Requête: libelle LIKE '%LOYR%'"
code "   Vector:  'loyr'  (typo)"
echo ""
expected "   Résultats attendus :"
echo "      - 'LOYER IMPAYE' (trouvé par similarité vectorielle)"
echo "      - 'LOYER MENSUEL' (trouvé par similarité vectorielle)"
echo ""

info "📚 CAS D'USAGE 3 - Recherche de Catégories :"
echo ""
echo "   Scénario : Trouver toutes les catégories contenant 'IMP'"
echo "   pour filtrer les opérations impayées."
echo ""
code "   Requête: cat_auto LIKE '%IMP%'"
code "   Vector:  'impaye'"
echo ""
expected "   Résultats attendus :"
echo "      - Catégories: 'IMP', 'IMP_PAYE', 'IMP_LOYER', etc."
echo ""

info "📚 CAS D'USAGE 4 - Recherche Combinée :"
echo ""
echo "   Scénario : Recherche sémantique + filtrage textuel précis"
echo "   pour améliorer la précision."
echo ""
code "   Requête: libelle LIKE '%LOYER%'"
code "   Vector:  'loyer impaye'"
code "   Filtre:  montant < -100"
echo ""
expected "   Résultats attendus :"
echo "      - Opérations avec 'LOYER' dans le libellé"
echo "      - Montants négatifs significatifs"
echo "      - Triés par similarité vectorielle"
echo ""

# ============================================
# PARTIE 4: EXÉCUTION DES DÉMONSTRATIONS
# ============================================
echo ""
section "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
section "  🚀 PARTIE 4: EXÉCUTION DES DÉMONSTRATIONS"
section "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Récupérer un code_si et contrat
info "🔍 Récupération d'un code_si et contrat pour les tests..."
cd "$HCD_DIR"
SAMPLE_QUERY="SELECT code_si, contrat FROM domirama2_poc.operations_by_account LIMIT 1"
SAMPLE_RESULT=$(./bin/cqlsh "$HCD_HOST" "$HCD_PORT" -e "$SAMPLE_QUERY" 2>/dev/null | grep -v "^$" | tail -n +4 | head -1)

if [ -z "$SAMPLE_RESULT" ]; then
    error "Aucune donnée trouvée dans la table. Exécutez d'abord: ./11_load_domirama2_data_parquet.sh"
    exit 1
fi

CODE_SI=$(echo "$SAMPLE_RESULT" | awk -F'|' '{print $1}' | xargs)
CONTRAT=$(echo "$SAMPLE_RESULT" | awk -F'|' '{print $2}' | xargs)

if [ -z "$CODE_SI" ] || [ -z "$CONTRAT" ]; then
    error "Impossible de parser code_si et contrat depuis les données"
    exit 1
fi

success "✅ Code SI: $CODE_SI, Contrat: $CONTRAT"
echo ""

# Créer le script Python de démonstration avancée
DEMO_PYTHON_SCRIPT=$(mktemp /tmp/demo_wildcard_XXXXXX.py)
cat > "$DEMO_PYTHON_SCRIPT" << 'PYTHON_EOF'
#!/usr/bin/env python3
"""Script de démonstration avancée pour les wildcards"""

import sys
import os
import time
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

from cassandra.cluster import Cluster
from like_wildcard_search import (
    hybrid_like_search,
    multi_field_like_search,
    build_regex_pattern,
    parse_explicit_like
)

# Configuration
HCD_HOST = os.getenv("HCD_HOST", "localhost")
HCD_PORT = int(os.getenv("HCD_PORT", "9042"))
CODE_SI = sys.argv[1]
CONTRAT = sys.argv[2]

# Connexion à HCD
cluster = Cluster([HCD_HOST], port=HCD_PORT)
session = cluster.connect('domirama2_poc')

print("=" * 70)
print("  🎯 DÉMONSTRATION PROFESSIONNELLE : Recherche Wildcard Avancée")
print("=" * 70)
print()

# ============================================
# DÉMO 1: Patterns Complexes avec Wildcards Multiples
# ============================================
print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
print("  DÉMONSTRATION 1: Patterns Complexes - Wildcards Multiples")
print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
print()

complex_patterns = [
    ("%LOYER%IMP%", "loyer impaye", "Trouve les libellés contenant LOYER et IMP"),
    ("*CARREFOUR*PAIEMENT*", "carrefour paiement", "Trouve les paiements Carrefour"),
    ("%VIREMENT*SALAIRE%", "virement salaire", "Trouve les virements de salaire"),
]

for pattern, vector_query, description in complex_patterns:
    print(f"📋 Pattern: libelle LIKE '{pattern}'")
    print(f"📋 Description: {description}")
    print(f"📋 Vector: '{vector_query}'")
    print(f"📋 Regex: {build_regex_pattern(pattern)}")
    print()

    start_time = time.time()
    results = hybrid_like_search(
        session=session,
        query_text=vector_query,
        like_query=f"libelle LIKE '{pattern}'",
        code_si=CODE_SI,
        contrat=CONTRAT,
        limit=5
    )
    elapsed_time = (time.time() - start_time) * 1000

    print(f"📊 Résultats: {len(results)} trouvés en {elapsed_time:.2f}ms")
    for i, row in enumerate(results, 1):
        sim = getattr(row, 'sim', 0.0)
        print(f"   {i}. {row.libelle} (Similarité: {sim:.3f})")
    print()

# ============================================
# DÉMO 2: Recherche Multi-Champs
# ============================================
print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
print("  DÉMONSTRATION 2: Recherche Multi-Champs (AND)")
print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
print()

print("📋 Requêtes LIKE multiples:")
print("   - libelle LIKE '%LOYER%'")
print("   - cat_auto LIKE '%IMP%'")
print("📋 Logique: AND (les deux doivent matcher)")
print("📋 Vector: 'loyer impaye'")
print()

start_time = time.time()
results = multi_field_like_search(
    session=session,
    query_text="loyer impaye",
    like_queries=[
        "libelle LIKE '%LOYER%'",
        "cat_auto LIKE '%IMP%'"
    ],
    code_si=CODE_SI,
    contrat=CONTRAT,
    limit=5,
    match_all=True  # AND
)
elapsed_time = (time.time() - start_time) * 1000

print(f"📊 Résultats: {len(results)} trouvés en {elapsed_time:.2f}ms")
for i, row in enumerate(results, 1):
    sim = getattr(row, 'sim', 0.0)
    cat = getattr(row, 'cat_auto', 'N/A')
    print(f"   {i}. {row.libelle} | Cat: {cat} (Similarité: {sim:.3f})")
print()

# ============================================
# DÉMO 3: Recherche Multi-Champs (OR)
# ============================================
print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
print("  DÉMONSTRATION 3: Recherche Multi-Champs (OR)")
print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
print()

print("📋 Requêtes LIKE multiples:")
print("   - libelle LIKE '%LOYER%'")
print("   - libelle LIKE '%IMP%'")
print("📋 Logique: OR (au moins un doit matcher)")
print("📋 Vector: 'loyer impaye'")
print()

start_time = time.time()
results = multi_field_like_search(
    session=session,
    query_text="loyer impaye",
    like_queries=[
        "libelle LIKE '%LOYER%'",
        "libelle LIKE '%IMP%'"
    ],
    code_si=CODE_SI,
    contrat=CONTRAT,
    limit=5,
    match_all=False  # OR
)
elapsed_time = (time.time() - start_time) * 1000

print(f"📊 Résultats: {len(results)} trouvés en {elapsed_time:.2f}ms")
for i, row in enumerate(results, 1):
    sim = getattr(row, 'sim', 0.0)
    print(f"   {i}. {row.libelle} (Similarité: {sim:.3f})")
print()

# ============================================
# DÉMO 4: Cas d'Usage Métier - Recherche avec Filtres
# ============================================
print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
print("  DÉMONSTRATION 4: Cas d'Usage Métier - Recherche avec Filtres")
print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
print()

print("📋 Scénario: Trouver les opérations LOYER avec montant < -100")
print("📋 Requête LIKE: libelle LIKE '%LOYER%'")
print("📋 Filtre CQL: montant < -100")
print("📋 Vector: 'loyer impaye'")
print()

start_time = time.time()
results = hybrid_like_search(
    session=session,
    query_text="loyer impaye",
    like_query="libelle LIKE '%LOYER%'",
    code_si=CODE_SI,
    contrat=CONTRAT,
    filter_dict={"montant": {"$lte": -100}},
    limit=5
)
elapsed_time = (time.time() - start_time) * 1000

print(f"📊 Résultats: {len(results)} trouvés en {elapsed_time:.2f}ms")
for i, row in enumerate(results, 1):
    sim = getattr(row, 'sim', 0.0)
    montant = float(getattr(row, 'montant', 0))
    print(f"   {i}. {row.libelle} | Montant: {montant:.2f}€ (Similarité: {sim:.3f})")
print()

session.shutdown()
cluster.shutdown()

print("=" * 70)
print("  ✅ DÉMONSTRATION TERMINÉE AVEC SUCCÈS")
print("=" * 70)
PYTHON_EOF

chmod +x "$DEMO_PYTHON_SCRIPT"

# Exécuter la démonstration
cd "$SCRIPT_DIR/../examples/python/search"
info "🚀 Exécution de la démonstration wildcard avancée..."
echo ""

python3 "$DEMO_PYTHON_SCRIPT" "$CODE_SI" "$CONTRAT" 2>&1 | tee /tmp/wildcard_demo_results.txt

# Nettoyer
rm -f "$DEMO_PYTHON_SCRIPT"

# ============================================
# PARTIE 5: COMPARAISON DE PERFORMANCES
# ============================================
echo ""
section "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
section "  ⚡ PARTIE 5: COMPARAISON DE PERFORMANCES"
section "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

info "📊 COMPARAISON - LIKE vs Full-Text vs Vector :"
echo ""
echo "   Approche          |  Avantages                    |  Limitations"
echo "   ──────────────────────────────────────────────────────────────"
echo "   LIKE (hybride)    |  ✅ Filtrage précis           |  ⚠️  Filtrage client-side"
echo "                    |  ✅ Tolère typos (vector)     |  ⚠️  Nécessite plus de résultats"
echo "                    |  ✅ Patterns complexes         |"
echo ""
echo "   Full-Text (SAI)  |  ✅ Index intégré             |  ❌ Pas de patterns LIKE"
echo "                    |  ✅ Recherche rapide           |  ❌ Moins tolérant aux typos"
echo ""
echo "   Vector (ANN)     |  ✅ Tolère typos               |  ❌ Pas de filtrage textuel"
echo "                    |  ✅ Similarité sémantique      |  ❌ Nécessite embeddings"
echo ""

highlight "💡 RECOMMANDATION :"
echo ""
echo "   Utiliser l'approche hybride (LIKE + Vector) pour :"
echo "      ✅ Recherches nécessitant filtrage textuel précis"
echo "      ✅ Recherches avec typos possibles"
echo "      ✅ Patterns complexes avec wildcards"
echo ""

# ============================================
# PARTIE 6: OPTIMISATIONS ET BONNES PRATIQUES
# ============================================
echo ""
section "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
section "  🎯 PARTIE 6: OPTIMISATIONS ET BONNES PRATIQUES"
section "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

info "📚 BONNES PRATIQUES - Optimisation des Performances :"
echo ""
echo "   1️⃣  Limiter le nombre de résultats vectoriels :"
echo "      - Utiliser vector_limit raisonnable (50-100)"
echo "      - Éviter de récupérer trop de candidats"
echo ""
echo "   2️⃣  Combiner avec filtres CQL standards :"
echo "      - Appliquer filtres CQL avant filtrage LIKE"
echo "      - Réduire le nombre de résultats à filtrer"
echo ""
echo "   3️⃣  Utiliser index appropriés :"
echo "      - Index SAI sur colonnes filtrées"
echo "      - Index vectoriel sur libelle_embedding"
echo ""
echo "   4️⃣  Éviter patterns trop génériques :"
echo "      - '%TEXT%' peut matcher trop de résultats"
echo "      - Préférer patterns plus spécifiques"
echo ""

info "📚 LIMITATIONS - À Connaître :"
echo ""
echo "   ⚠️  Filtrage client-side :"
echo "      - Nécessite de récupérer plus de résultats"
echo "      - Impact sur performance si trop de résultats"
echo ""
echo "   ⚠️  Pas de support natif CQL :"
echo "      - Solution de contournement avec regex"
echo "      - Nécessite code applicatif"
echo ""

# ============================================
# PARTIE 7: RÉSUMÉ ET DOCUMENTATION
# ============================================
echo ""
section "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
section "  📊 PARTIE 7: RÉSUMÉ ET DOCUMENTATION"
section "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

success "✅ Démonstration terminée avec succès !"
echo ""
echo "   Résultats disponibles dans :"
echo "      📄 /tmp/wildcard_demo_results.txt"
echo ""

info "📝 Génération de la documentation professionnelle..."
cat > "$REPORT_FILE" << 'DOC_EOF'
# Démonstration Professionnelle : Recherche Wildcard Avancée

**Date** : $(date +%Y-%m-%d)
**Script** : `41_demo_wildcard_search.sh`
**Objectif** : Démonstration complète de la recherche avec wildcards avancés

## Résumé Exécutif

Cette démonstration présente une implémentation professionnelle des patterns LIKE et wildcards dans HCD, combinant recherche vectorielle et filtrage client-side pour une recherche précise et tolérante aux erreurs.

## Approche Technique

### Architecture Hybride

1. **Recherche Vectorielle (ANN)** : Réduit le nombre de candidats
2. **Filtrage Client-Side (Regex)** : Applique le pattern LIKE
3. **Tri par Similarité** : Maintient la pertinence des résultats

### Fonctionnalités

- ✅ Patterns simples et complexes avec wildcards
- ✅ Recherche multi-champs (AND/OR)
- ✅ Intégration avec filtres CQL standards
- ✅ Optimisations de performance

## Cas d'Usage Métier

Voir les résultats détaillés dans `/tmp/wildcard_demo_results.txt`

## Recommandations

- Utiliser l'approche hybride pour recherches nécessitant précision et tolérance aux typos
- Limiter le nombre de résultats vectoriels pour optimiser les performances
- Combiner avec filtres CQL standards pour réduire le nombre de candidats

DOC_EOF

success "✅ Documentation générée: $REPORT_FILE"
echo ""

success "🎉 Démonstration professionnelle terminée avec succès !"
echo ""
