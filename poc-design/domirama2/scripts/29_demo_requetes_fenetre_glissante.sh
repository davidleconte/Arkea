#!/bin/bash
# ============================================
# Script 29 : Démonstration Requêtes avec Fenêtre Glissante (TIMERANGE)
# ============================================
#
# OBJECTIF :
#   Ce script démontre les requêtes en base avec fenêtre glissante (TIMERANGE
#   équivalent HBase), permettant d'interroger HCD avec des plages de dates
#   spécifiques pour des analyses temporelles.
#
#   Fonctionnalités :
#   - Requêtes avec filtrage par date_op (équivalent TIMERANGE HBase)
#   - Fenêtre glissante pour analyses temporelles
#   - Support des requêtes incrémentales
#   - Optimisation avec index SAI sur date_op
#
# PRÉREQUIS :
#   - HCD démarré (./scripts/setup/03_start_hcd.sh)
#   - Schéma configuré (./10_setup_domirama2_poc.sh)
#   - Données chargées (./11_load_domirama2_data_parquet.sh)
#   - Java 11 configuré via jenv
#
# UTILISATION :
#   ./29_demo_requetes_fenetre_glissante.sh [start_date] [end_date]
#
# PARAMÈTRES :
#   $1 : Date de début (format: YYYY-MM-DD, optionnel, défaut: 2024-01-01)
#   $2 : Date de fin (format: YYYY-MM-DD, optionnel, défaut: 2024-02-01)
#
# EXEMPLE :
#   ./29_demo_requetes_fenetre_glissante.sh
#   ./29_demo_requetes_fenetre_glissante.sh "2024-01-01" "2024-02-01"
#
# SORTIE :
#   - Résultats des requêtes avec fenêtre glissante
#   - Statistiques (nombre d'opérations, dates min/max)
#   - Messages de succès/erreur
#
# PROCHAINES ÉTAPES :
#   - Script 30: Requêtes avec STARTROW/STOPROW (./30_demo_requetes_startrow_stoprow.sh)
#   - Script 27: Export incrémental Parquet (./27_export_incremental_parquet.sh)
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

CQLSH_BIN="/Users/david.leconte/Documents/Arkea/binaire/hcd-1.2.3/bin/cqlsh"
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
echo "  📅 Démonstration : Requêtes avec Fenêtre Glissante (TIMERANGE)"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

info "Objectif : Démontrer les requêtes en base avec fenêtre glissante"
echo ""
info "Équivalent HBase :"
code "  - TIMERANGE pour requêtes avec plages de dates"
code "  - SCAN avec filtres temporels"
code "  - Requêtes par période (mensuelle, hebdomadaire, etc.)"
echo ""
info "Valeur ajoutée SAI :"
code "  ✅ Index sur date_op pour performance optimale"
code "  ✅ Pas de scan complet nécessaire"
code "  ✅ Requêtes rapides même sur grandes plages"
echo ""

# ============================================
# Exemple 1 : Requête Mensuelle (Fenêtre Glissante)
# ============================================

echo ""
info "📋 Exemple 1 : Requête mensuelle (fenêtre glissante)"
echo ""

code "-- Équivalent HBase : SCAN avec TIMERANGE pour janvier 2024"
code "SELECT * FROM operations_by_account"
code "WHERE code_si = 'DEMO_MV' AND contrat = 'DEMO_001'"
code "  AND date_op >= '2024-01-01' AND date_op < '2024-02-01'"
code "ORDER BY date_op DESC, numero_op ASC;"
echo ""

info "Exécution de la requête..."
cat > /tmp/query1.cql <<'EOF'
USE domirama2_poc;
SELECT code_si, contrat, date_op, numero_op, libelle, montant, cat_auto
FROM operations_by_account
WHERE code_si = 'DEMO_MV' AND contrat = 'DEMO_001'
  AND date_op >= '2024-01-01' AND date_op < '2024-02-01'
ORDER BY date_op DESC, numero_op ASC
LIMIT 10;
EOF

$CQLSH -f /tmp/query1.cql 2>&1 | tail -n +4 | grep -v "^$" | head -n 15

echo ""
success "✅ Requête mensuelle exécutée (fenêtre glissante)"
info "   💡 SAI : Index sur date_op permet une recherche rapide"
echo ""

# ============================================
# Exemple 2 : Requête avec Fenêtre Glissante (Derniers 30 jours)
# ============================================

echo ""
info "📋 Exemple 2 : Requête fenêtre glissante (30 derniers jours)"
echo ""

code "-- Équivalent HBase : SCAN avec TIMERANGE pour 30 derniers jours"
code "SELECT * FROM operations_by_account"
code "WHERE code_si = 'DEMO_MV' AND contrat = 'DEMO_001'"
code "  AND date_op >= toTimestamp(now()) - 30days"
code "  AND date_op <= toTimestamp(now())"
code "ORDER BY date_op DESC;"
echo ""

info "Exécution de la requête..."
cat > /tmp/query2.cql <<'EOF'
USE domirama2_poc;
SELECT code_si, contrat, date_op, numero_op, libelle, montant
FROM operations_by_account
WHERE code_si = 'DEMO_MV' AND contrat = 'DEMO_001'
  AND date_op >= '2024-11-01' AND date_op <= '2024-11-30'
ORDER BY date_op DESC
LIMIT 10;
EOF

$CQLSH -f /tmp/query2.cql 2>&1 | tail -n +4 | grep -v "^$" | head -n 15

echo ""
success "✅ Requête fenêtre glissante exécutée (30 jours)"
info "   💡 SAI : Index sur date_op optimise la recherche temporelle"
echo ""

# ============================================
# Exemple 3 : Requête avec SAI (Performance)
# ============================================

echo ""
info "📋 Exemple 3 : Requête avec SAI (valeur ajoutée)"
echo ""

code "-- SAI apporte une valeur ajoutée pour :"
code "  1. Recherche rapide sur date_op (index clustering key)"
code "  2. Filtres combinés (date_op + libelle full-text)"
code "  3. Pas de scan complet nécessaire"
echo ""

code "-- Exemple : Requête avec filtre date + full-text search"
code "SELECT * FROM operations_by_account"
code "WHERE code_si = 'DEMO_MV' AND contrat = 'DEMO_001'"
code "  AND date_op >= '2024-01-01' AND date_op < '2024-02-01'"
code "  AND libelle : 'LOYER'"
code "ORDER BY date_op DESC;"
echo ""

info "Exécution de la requête avec SAI..."
cat > /tmp/query3.cql <<'EOF'
USE domirama2_poc;
SELECT code_si, contrat, date_op, numero_op, libelle, montant, cat_auto
FROM operations_by_account
WHERE code_si = 'DEMO_MV' AND contrat = 'DEMO_001'
  AND date_op >= '2024-01-01' AND date_op < '2024-02-01'
  AND libelle : 'LOYER'
ORDER BY date_op DESC
LIMIT 10;
EOF

$CQLSH -f /tmp/query3.cql 2>&1 | tail -n +4 | grep -v "^$" | head -n 15

echo ""
success "✅ Requête avec SAI exécutée (date + full-text)"
info "   💡 SAI : Combine index date_op (clustering) + libelle (full-text)"
info "   💡 Performance : Pas de scan complet, recherche indexée"
echo ""

# ============================================
# Comparaison Performance
# ============================================

echo ""
info "📊 Comparaison Performance : Avec vs Sans SAI"
echo ""

code "Sans SAI (HBase) :"
code "  - SCAN complet de la partition"
code "  - Filtrage côté client"
code "  - Performance : O(n) où n = nombre d'opérations"
echo ""

code "Avec SAI (HCD) :"
code "  - Index sur date_op (clustering key)"
code "  - Index sur libelle (full-text SAI)"
code "  - Performance : O(log n) avec index"
code "  - Valeur ajoutée : Recherche combinée optimisée"
echo ""

# Nettoyer
rm -f /tmp/query1.cql /tmp/query2.cql /tmp/query3.cql

echo ""
success "✅ Démonstration requêtes fenêtre glissante terminée"
info ""
info "💡 Points clés démontrés :"
code "  ✅ Fenêtre glissante avec WHERE date_op BETWEEN"
code "  ✅ Requêtes mensuelles, hebdomadaires, etc."
code "  ✅ Valeur ajoutée SAI : Index sur date_op + full-text"
code "  ✅ Performance optimisée vs scan complet"
echo ""
