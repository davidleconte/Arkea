#!/bin/bash
set -euo pipefail
# ============================================
# Script 30 : Démonstration Requêtes avec STARTROW/STOPROW équivalent
# ============================================
#
# OBJECTIF :
#   Ce script démontre les requêtes en base avec ciblage précis (STARTROW/STOPROW
#   équivalent HBase), permettant d'interroger HCD avec des plages de clés de
#   clustering spécifiques pour des analyses ciblées.
#
#   Fonctionnalités :
#   - Requêtes avec filtrage par clés de clustering (équivalent STARTROW/STOPROW HBase)
#   - Ciblage précis des données par code_si, contrat, date_op, numero_op
#   - Support des requêtes de plage (range queries)
#   - Optimisation avec index SAI sur les clés de clustering
#
# PRÉREQUIS :
#   - HCD démarré (./scripts/setup/03_start_hcd.sh)
#   - Schéma configuré (./10_setup_domirama2_poc.sh)
#   - Données chargées (./11_load_domirama2_data_parquet.sh)
#   - Java 11 configuré via jenv
#
# UTILISATION :
#   ./30_demo_requetes_startrow_stoprow.sh [code_si] [contrat] [start_date] [end_date]
#
# PARAMÈTRES :
#   $1 : Code SI (optionnel, défaut: tous)
#   $2 : Contrat (optionnel, défaut: tous)
#   $3 : Date de début (format: YYYY-MM-DD, optionnel)
#   $4 : Date de fin (format: YYYY-MM-DD, optionnel)
#
# EXEMPLE :
#   ./30_demo_requetes_startrow_stoprow.sh
#   ./30_demo_requetes_startrow_stoprow.sh "DEMO_OFFICIAL" "DEMO_001" "2024-01-01" "2024-02-01"
#
# SORTIE :
#   - Résultats des requêtes avec ciblage précis
#   - Statistiques (nombre d'opérations)
#   - Messages de succès/erreur
#
# PROCHAINES ÉTAPES :
#   - Script 31: Démonstration BLOOMFILTER équivalent (./31_demo_bloomfilter_equivalent_v2.sh)
#   - Script 29: Requêtes avec fenêtre glissante (./29_demo_requetes_fenetre_glissante.sh)
#
# ============================================

set -euo pipefail

# Couleurs pour output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

info() {
    echo -e "${BLUE}ℹ️  $1${NC}"
}

success() {
    echo -e "${GREEN}✅ $1${NC}"
}

warn() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

error() {
    echo -e "${RED}❌ $1${NC}"
}

code() {
    echo -e "${BLUE}   $1${NC}"
}

# ============================================
# Configuration
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

# Source environment
if [ -f "$INSTALL_DIR/.poc-profile" ]; then
    source "$INSTALL_DIR/.poc-profile"
fi

CQLSH_BIN="${ARKEA_HOME}/binaire/hcd-1.2.3/bin/cqlsh"
CQLSH="$CQLSH_BIN "$HCD_HOST" "$HCD_PORT""

# Vérifier que HCD est démarré
info "Vérification que HCD est démarré..."
if ! nc -z "$HCD_HOST" "$HCD_PORT" 2>/dev/null; then
    error "HCD n'est pas démarré sur "$HCD_HOST:$HCD_PORT""
    error "Exécutez d'abord: ./scripts/setup/03_start_hcd.sh"
    exit 1
fi
success "HCD est démarré"

# ============================================
# Démonstration
# ============================================

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  🎯 Démonstration : Requêtes avec STARTROW/STOPROW équivalent"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

info "Objectif : Démontrer les requêtes en base avec ciblage précis"
echo ""
info "Équivalent HBase :"
code "  - STARTROW + STOPROW pour cibler précisément les données"
code "  - SCAN avec plages de rowkeys"
code "  - Ciblage par partition + clustering keys"
echo ""
info "Valeur ajoutée SAI :"
code "  ✅ Index sur clustering keys (date_op, numero_op)"
code "  ✅ Recherche précise sans scan complet"
code "  ✅ Performance optimale pour plages spécifiques"
echo ""

# ============================================
# Exemple 1 : Ciblage par Date Précise
# ============================================

echo ""
info "📋 Exemple 1 : Ciblage par date précise (STARTROW/STOPROW équivalent)"
echo ""

code "-- Équivalent HBase : SCAN avec STARTROW/STOPROW sur date"
code "SELECT * FROM operations_by_account"
code "WHERE code_si = 'DEMO_MV' AND contrat = 'DEMO_001'"
code "  AND date_op >= '2024-01-15 10:00:00'"
code "  AND date_op <= '2024-01-20 18:00:00'"
code "ORDER BY date_op DESC, numero_op ASC;"
echo ""

info "Exécution de la requête..."
cat > /tmp/query1.cql <<'EOF'
USE domirama2_poc;
SELECT code_si, contrat, date_op, numero_op, libelle, montant, cat_auto
FROM operations_by_account
WHERE code_si = 'DEMO_MV' AND contrat = 'DEMO_001'
  AND date_op >= '2024-01-15 10:00:00'
  AND date_op <= '2024-01-20 18:00:00'
ORDER BY date_op DESC, numero_op ASC
LIMIT 10;
EOF

$CQLSH -f /tmp/query1.cql 2>&1 | tail -n +4 | grep -v "^$" | head -n 15

echo ""
success "✅ Requête avec ciblage date précise exécutée"
info "   💡 SAI : Index sur date_op (clustering key) optimise la recherche"
echo ""

# ============================================
# Exemple 2 : Ciblage par Date + Numéro Opération
# ============================================

echo ""
info "📋 Exemple 2 : Ciblage par date + numéro opération (STARTROW/STOPROW complet)"
echo ""

code "-- Équivalent HBase : SCAN avec STARTROW/STOPROW complet"
code "SELECT * FROM operations_by_account"
code "WHERE code_si = 'DEMO_MV' AND contrat = 'DEMO_001'"
code "  AND date_op = '2024-01-15 10:00:00'"
code "  AND numero_op >= 1 AND numero_op <= 100"
code "ORDER BY date_op DESC, numero_op ASC;"
echo ""

info "Exécution de la requête..."
cat > /tmp/query2.cql <<'EOF'
USE domirama2_poc;
SELECT code_si, contrat, date_op, numero_op, libelle, montant, cat_auto
FROM operations_by_account
WHERE code_si = 'DEMO_MV' AND contrat = 'DEMO_001'
  AND date_op = '2024-01-15 10:00:00'
  AND numero_op >= 1 AND numero_op <= 100
ORDER BY date_op DESC, numero_op ASC
LIMIT 10;
EOF

$CQLSH -f /tmp/query2.cql 2>&1 | tail -n +4 | grep -v "^$" | head -n 15

echo ""
success "✅ Requête avec ciblage date + numero_op exécutée"
info "   💡 SAI : Index sur clustering keys (date_op, numero_op)"
info "   💡 Performance : Recherche précise sans scan complet"
echo ""

# ============================================
# Exemple 3 : Ciblage avec SAI (Valeur Ajoutée)
# ============================================

echo ""
info "📋 Exemple 3 : Ciblage avec SAI (valeur ajoutée)"
echo ""

code "-- SAI apporte une valeur ajoutée pour :"
code "  1. Recherche précise sur clustering keys (date_op, numero_op)"
code "  2. Filtres combinés (clustering + full-text)"
code "  3. Performance optimale pour plages spécifiques"
echo ""

code "-- Exemple : Requête avec ciblage précis + full-text search"
code "SELECT * FROM operations_by_account"
code "WHERE code_si = 'DEMO_MV' AND contrat = 'DEMO_001'"
code "  AND date_op >= '2024-01-15' AND date_op <= '2024-01-20'"
code "  AND numero_op >= 1 AND numero_op <= 100"
code "  AND libelle : 'VIREMENT'"
code "ORDER BY date_op DESC, numero_op ASC;"
echo ""

info "Exécution de la requête avec SAI..."
cat > /tmp/query3.cql <<'EOF'
USE domirama2_poc;
SELECT code_si, contrat, date_op, numero_op, libelle, montant, cat_auto
FROM operations_by_account
WHERE code_si = 'DEMO_MV' AND contrat = 'DEMO_001'
  AND date_op >= '2024-01-15' AND date_op <= '2024-01-20'
  AND numero_op >= 1 AND numero_op <= 100
  AND libelle : 'VIREMENT'
ORDER BY date_op DESC, numero_op ASC
LIMIT 10;
EOF

$CQLSH -f /tmp/query3.cql 2>&1 | tail -n +4 | grep -v "^$" | head -n 15

echo ""
success "✅ Requête avec SAI exécutée (ciblage précis + full-text)"
info "   💡 SAI : Combine index clustering keys + libelle (full-text)"
info "   💡 Performance : Recherche précise et rapide"
echo ""

# ============================================
# Comparaison Performance
# ============================================

echo ""
info "📊 Comparaison Performance : Avec vs Sans SAI"
echo ""

code "Sans SAI (HBase) :"
code "  - SCAN avec STARTROW/STOPROW"
code "  - Filtrage côté client"
code "  - Performance : O(n) où n = nombre d'opérations dans la plage"
echo ""

code "Avec SAI (HCD) :"
code "  - Index sur clustering keys (date_op, numero_op)"
code "  - Index sur libelle (full-text SAI)"
code "  - Performance : O(log n) avec index"
code "  - Valeur ajoutée : Recherche combinée optimisée"
echo ""

# Nettoyer
rm -f /tmp/query1.cql /tmp/query2.cql /tmp/query3.cql

echo ""
success "✅ Démonstration requêtes STARTROW/STOPROW terminée"
info ""
info "💡 Points clés démontrés :"
code "  ✅ Ciblage précis avec WHERE sur clustering keys"
code "  ✅ Plages de dates et numéros d'opération"
code "  ✅ Valeur ajoutée SAI : Index sur clustering keys + full-text"
code "  ✅ Performance optimisée vs scan complet"
echo ""
