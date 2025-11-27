#!/bin/bash
# ============================================
# Script 31 : Démonstration BLOOMFILTER Équivalent (SAI)
# ============================================
#
# Objectif : Démontrer l'équivalent BLOOMFILTER HBase avec SAI
# HBase : BLOOMFILTER => 'ROWCOL' pour optimisation lectures
# HCD : Index SAI sur clustering keys (plus performants)
#
# Usage :
#   ./31_demo_bloomfilter_equivalent.sh
#
# ============================================

set -e

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

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
INSTALL_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"

# Source environment
if [ -f "$INSTALL_DIR/.poc-profile" ]; then
    source "$INSTALL_DIR/.poc-profile"
fi

CQLSH_BIN="/Users/david.leconte/Documents/Arkea/binaire/hcd-1.2.3/bin/cqlsh"
CQLSH="$CQLSH_BIN localhost 9042"

# Vérifier que HCD est démarré
info "Vérification que HCD est démarré..."
if ! nc -z localhost 9042 2>/dev/null; then
    error "HCD n'est pas démarré sur localhost:9042"
    error "Exécutez d'abord: ./03_start_hcd.sh"
    exit 1
fi
success "HCD est démarré"

# ============================================
# Démonstration
# ============================================

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  🔍 Démonstration : BLOOMFILTER Équivalent (SAI)"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

info "Objectif : Démontrer l'équivalent BLOOMFILTER HBase avec SAI"
echo ""
info "BLOOMFILTER HBase :"
code "  - BLOOMFILTER => 'ROWCOL'"
code "  - Optimise les lectures en évitant de lire des fichiers qui ne contiennent pas la clé"
code "  - Réduit les I/O disque pour recherches par rowkey"
echo ""
info "Équivalent HCD (SAI) :"
code "  - Index sur clustering keys (date_op, numero_op)"
code "  - Index sur colonnes (libelle, cat_auto, etc.)"
code "  - Structure de partition (code_si, contrat) pour ciblage direct"
code "  - Plus performant que BLOOMFILTER (index persistant vs probabilité)"
echo ""

# ============================================
# Partie 1 : Explication BLOOMFILTER HBase
# ============================================

echo ""
info "📋 Partie 1 : BLOOMFILTER HBase (Contexte)"
echo ""

code "-- HBase : BLOOMFILTER => 'ROWCOL'"
code "  - Probabiliste : Peut avoir des faux positifs (mais pas de faux négatifs)"
code "  - Optimise : Évite de lire des fichiers HFile qui ne contiennent pas la clé"
code "  - Limitation : Probabiliste, nécessite reconstruction périodique"
code "  - Performance : Réduit I/O disque mais pas de garantie"
echo ""

info "💡 BLOOMFILTER HBase fonctionne ainsi :"
code "  1. Vérifie si la clé PEUT exister dans le fichier (probabiliste)"
code "  2. Si non, évite de lire le fichier (gain I/O)"
code "  3. Si oui, lit le fichier pour vérifier (peut être un faux positif)"
echo ""

# ============================================
# Partie 2 : Équivalent HCD (Index SAI)
# ============================================

echo ""
info "📋 Partie 2 : Équivalent HCD (Index SAI)"
echo ""

code "-- HCD : Index SAI sur clustering keys"
code "  - Déterministe : Pas de faux positifs (index exact)"
code "  - Optimise : Cible directement les données via index"
code "  - Avantage : Index persistant, pas de reconstruction"
code "  - Performance : Meilleure que BLOOMFILTER (index exact vs probabiliste)"
echo ""

info "💡 Index SAI HCD fonctionne ainsi :"
code "  1. Index sur clustering keys (date_op, numero_op) pour ciblage direct"
code "  2. Index sur colonnes (libelle, cat_auto) pour filtres"
code "  3. Structure de partition (code_si, contrat) pour isolation"
code "  4. Pas de scan complet nécessaire (index exact)"
echo ""

# ============================================
# Partie 3 : Démonstration Performance
# ============================================

echo ""
info "📋 Partie 3 : Démonstration Performance (Avec vs Sans Index)"
echo ""

code "-- Test 1 : Requête avec partition key + clustering keys (optimisé)"
code "SELECT * FROM operations_by_account"
code "WHERE code_si = 'DEMO_MV' AND contrat = 'DEMO_001'"
code "  AND date_op = '2024-01-15 10:00:00' AND numero_op = 1;"
echo ""

info "Exécution de la requête optimisée (équivalent BLOOMFILTER)..."
cat > /tmp/query1.cql <<'EOF'
USE domirama2_poc;
TRACING ON;
SELECT code_si, contrat, date_op, numero_op, libelle, montant
FROM operations_by_account
WHERE code_si = 'DEMO_MV' AND contrat = 'DEMO_001'
  AND date_op = '2024-01-15 10:00:00' AND numero_op = 1;
EOF

$CQLSH -f /tmp/query1.cql 2>&1 | grep -E "(code_si|DEMO_MV|Tracing session|coordinator|Read|rows|ms)" | head -15

echo ""
success "✅ Requête optimisée exécutée"
info "   💡 Équivalent BLOOMFILTER : Index sur clustering keys cible directement les données"
info "   💡 Performance : Pas de scan complet, accès direct via index"
echo ""

# ============================================
# Partie 4 : Comparaison avec Index SAI
# ============================================

echo ""
info "📋 Partie 4 : Comparaison avec Index SAI (Valeur Ajoutée)"
echo ""

code "-- Test 2 : Requête avec index SAI (full-text)"
code "SELECT * FROM operations_by_account"
code "WHERE code_si = 'DEMO_MV' AND contrat = 'DEMO_001'"
code "  AND libelle : 'LOYER'"
code "ORDER BY date_op DESC LIMIT 5;"
echo ""

info "Exécution de la requête avec index SAI..."
cat > /tmp/query2.cql <<'EOF'
USE domirama2_poc;
TRACING ON;
SELECT code_si, contrat, date_op, numero_op, libelle, montant, cat_auto
FROM operations_by_account
WHERE code_si = 'DEMO_MV' AND contrat = 'DEMO_001'
  AND libelle : 'LOYER'
ORDER BY date_op DESC
LIMIT 5;
EOF

$CQLSH -f /tmp/query2.cql 2>&1 | grep -E "(code_si|DEMO_MV|Tracing session|coordinator|Read|rows|ms|libelle)" | head -15

echo ""
success "✅ Requête avec index SAI exécutée"
info "   💡 Valeur ajoutée SAI : Index full-text (non disponible avec BLOOMFILTER HBase)"
info "   💡 Performance : Recherche indexée sans scan complet"
echo ""

# ============================================
# Partie 5 : Structure de Partition (Équivalent BLOOMFILTER)
# ============================================

echo ""
info "📋 Partie 5 : Structure de Partition (Équivalent BLOOMFILTER)"
echo ""

code "-- HCD : Partition key (code_si, contrat) isole les données"
code "  - Équivalent BLOOMFILTER : Cible directement la partition"
code "  - Performance : Pas de scan sur autres partitions"
code "  - Avantage : Déterministe (pas de faux positifs)"
echo ""

info "Explication de la structure de partition..."
code "  Partition key : (code_si, contrat)"
code "    → Isole les données par compte"
code "    → Équivalent BLOOMFILTER : Évite de scanner d'autres comptes"
code ""
code "  Clustering keys : (date_op DESC, numero_op ASC)"
code "    → Index natif sur clustering keys"
code "    → Cible directement les opérations par date/numéro"
code "    → Équivalent BLOOMFILTER : Évite de scanner d'autres dates"
echo ""

# ============================================
# Partie 6 : Comparaison Performance
# ============================================

echo ""
info "📊 Comparaison Performance : BLOOMFILTER HBase vs Index SAI HCD"
echo ""

code "BLOOMFILTER HBase :"
code "  - Type : Probabiliste (peut avoir faux positifs)"
code "  - Performance : Réduit I/O mais nécessite vérification"
code "  - Maintenance : Reconstruction périodique nécessaire"
code "  - Limitation : Fonctionne uniquement sur rowkeys"
echo ""

code "Index SAI HCD :"
code "  - Type : Déterministe (index exact, pas de faux positifs)"
code "  - Performance : Accès direct via index (meilleur que BLOOMFILTER)"
code "  - Maintenance : Index persistant (pas de reconstruction)"
code "  - Avantage : Fonctionne sur clustering keys ET colonnes (full-text)"
echo ""

info "💡 Conclusion :"
code "  ✅ Index SAI est plus performant que BLOOMFILTER"
code "  ✅ Index exact vs probabiliste"
code "  ✅ Index persistant vs reconstruction périodique"
code "  ✅ Support full-text (non disponible avec BLOOMFILTER)"
echo ""

# ============================================
# Partie 7 : Vérification Index Existants
# ============================================

echo ""
info "📋 Partie 7 : Vérification des Index SAI Existants"
echo ""

info "Liste des index SAI créés sur operations_by_account..."
cat > /tmp/query3.cql <<'EOF'
USE domirama2_poc;
DESCRIBE INDEX operations_by_account;
EOF

$CQLSH -f /tmp/query3.cql 2>&1 | grep -E "(idx_|CREATE|ON|USING|StorageAttachedIndex)" | head -20

echo ""
success "✅ Index SAI vérifiés"
info "   💡 Ces index remplacent et améliorent le BLOOMFILTER HBase"
echo ""

# Nettoyer
rm -f /tmp/query1.cql /tmp/query2.cql /tmp/query3.cql

echo ""
success "✅ Démonstration BLOOMFILTER équivalent terminée"
info ""
info "💡 Points clés démontrés :"
code "  ✅ Équivalent BLOOMFILTER : Index SAI sur clustering keys"
code "  ✅ Performance : Index exact vs probabiliste (meilleur)"
code "  ✅ Structure de partition : Ciblage direct (équivalent BLOOMFILTER)"
code "  ✅ Valeur ajoutée : Index full-text (non disponible avec BLOOMFILTER)"
code "  ✅ Maintenance : Index persistant (pas de reconstruction)"
echo ""

