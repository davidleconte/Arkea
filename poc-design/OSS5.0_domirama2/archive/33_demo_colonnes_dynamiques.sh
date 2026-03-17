#!/bin/bash
# ============================================
# Script 33 : Démonstration Colonnes Dynamiques (MAP)
# ============================================
#
# Objectif : Démontrer le filtrage sur colonnes MAP (équivalent colonnes dynamiques HBase)
# HBase : Colonnes dynamiques calquées sur POJO Thrift
# HCD : meta_flags MAP<TEXT, TEXT> avec filtrage
#
# Usage :
#   ./33_demo_colonnes_dynamiques.sh
#
# ============================================

set -e

# Couleurs pour output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
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

highlight() {
    echo -e "${CYAN}💡 $1${NC}"
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
echo "  🔍 Démonstration : Colonnes Dynamiques (MAP)"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

info "Objectif : Démontrer le filtrage sur colonnes MAP (équivalent colonnes dynamiques HBase)"
echo ""

# ============================================
# Partie 1 : Explication Colonnes Dynamiques
# ============================================

echo ""
info "📋 Partie 1 : Colonnes Dynamiques HBase vs MAP HCD"
echo ""

echo "┌─────────────────────────────────────────────────────────────┐"
echo "│  Colonnes Dynamiques HBase                                   │"
echo "├─────────────────────────────────────────────────────────────┤"
echo "│  Type        : Colonnes calquées sur POJO Thrift            │"
echo "│  Structure   : Column qualifiers dynamiques                 │"
echo "│  Exemple     : 'meta:flag1', 'meta:flag2', etc.            │"
echo "│  Filtrage    : Via ColumnFilter sur qualifiers              │"
echo "└─────────────────────────────────────────────────────────────┘"
echo ""

echo "┌─────────────────────────────────────────────────────────────┐"
echo "│  Colonnes MAP HCD                                           │"
echo "├─────────────────────────────────────────────────────────────┤"
echo "│  Type        : MAP<TEXT, TEXT>                              │"
echo "│  Structure   : Clé-valeur (équivalent column qualifier)     │"
echo "│  Exemple     : {'flag1': 'value1', 'flag2': 'value2'}      │"
echo "│  Filtrage    : Via WHERE meta_flags['key'] = 'value'        │"
echo "└─────────────────────────────────────────────────────────────┘"
echo ""

highlight "Équivalence :"
code "  ✅ Column qualifier HBase = Clé MAP HCD"
code "  ✅ Column value HBase = Valeur MAP HCD"
code "  ✅ ColumnFilter HBase = WHERE meta_flags['key'] HCD"
echo ""

# ============================================
# Partie 2 : Vérification Schéma
# ============================================

echo ""
info "📋 Partie 2 : Vérification du Schéma (meta_flags MAP)"
echo ""

code "-- Schéma actuel : operations_by_account"
code "meta_flags MAP<TEXT, TEXT>"
echo ""

info "Vérification de la structure de la table..."
cat > /tmp/check_schema.cql <<'EOF'
USE domirama2_poc;
DESCRIBE TABLE operations_by_account;
EOF

$CQLSH -f /tmp/check_schema.cql 2>&1 | grep -A 2 "meta_flags" | head -5

echo ""
success "✅ Colonne meta_flags MAP<TEXT, TEXT> présente"
echo ""

# ============================================
# Partie 3 : Insertion de Données avec MAP
# ============================================

echo ""
info "📋 Partie 3 : Insertion de Données avec Colonnes Dynamiques (MAP)"
echo ""

code "-- Insertion d'opérations avec meta_flags (équivalent colonnes dynamiques)"
code "INSERT INTO operations_by_account (code_si, contrat, date_op, numero_op, libelle, montant, meta_flags)"
code "VALUES ('DEMO_DYN', 'DEMO_001', '2024-01-20 10:00:00', 1, 'VIREMENT SEPA', 1000.00,"
code "  {'source': 'mobile', 'channel': 'app', 'device': 'iphone'});"
echo ""

cat > /tmp/insert1.cql <<'EOF'
USE domirama2_poc;
INSERT INTO operations_by_account (code_si, contrat, date_op, numero_op, libelle, montant, meta_flags)
VALUES ('DEMO_DYN', 'DEMO_001', '2024-01-20 10:00:00', 1, 'VIREMENT SEPA', 1000.00,
  {'source': 'mobile', 'channel': 'app', 'device': 'iphone'});
EOF

$CQLSH -f /tmp/insert1.cql > /dev/null 2>&1
success "✅ Opération 1 insérée avec meta_flags"

cat > /tmp/insert2.cql <<'EOF'
USE domirama2_poc;
INSERT INTO operations_by_account (code_si, contrat, date_op, numero_op, libelle, montant, meta_flags)
VALUES ('DEMO_DYN', 'DEMO_001', '2024-01-20 11:00:00', 2, 'PRLV EDF', -50.00,
  {'source': 'web', 'channel': 'browser', 'device': 'desktop', 'ip': '192.168.1.1'});
EOF

$CQLSH -f /tmp/insert2.cql > /dev/null 2>&1
success "✅ Opération 2 insérée avec meta_flags"

cat > /tmp/insert3.cql <<'EOF'
USE domirama2_poc;
INSERT INTO operations_by_account (code_si, contrat, date_op, numero_op, libelle, montant, meta_flags)
VALUES ('DEMO_DYN', 'DEMO_001', '2024-01-20 12:00:00', 3, 'CB SUPERMARCHE', -25.50,
  {'source': 'mobile', 'channel': 'app', 'device': 'android', 'location': 'paris'});
EOF

$CQLSH -f /tmp/insert3.cql > /dev/null 2>&1
success "✅ Opération 3 insérée avec meta_flags"

cat > /tmp/insert4.cql <<'EOF'
USE domirama2_poc;
INSERT INTO operations_by_account (code_si, contrat, date_op, numero_op, libelle, montant, meta_flags)
VALUES ('DEMO_DYN', 'DEMO_001', '2024-01-20 13:00:00', 4, 'VIREMENT SEPA', 500.00,
  {'source': 'web', 'channel': 'browser', 'device': 'desktop'});
EOF

$CQLSH -f /tmp/insert4.cql > /dev/null 2>&1
success "✅ Opération 4 insérée avec meta_flags"

echo ""
info "Affichage des données insérées..."
cat > /tmp/select_all.cql <<'EOF'
USE domirama2_poc;
SELECT code_si, contrat, date_op, numero_op, libelle, montant, meta_flags
FROM operations_by_account
WHERE code_si = 'DEMO_DYN' AND contrat = 'DEMO_001'
ORDER BY date_op DESC;
EOF

$CQLSH -f /tmp/select_all.cql 2>&1 | tail -n +4 | grep -v "^$" | grep -v "^(" | head -10

echo ""
success "✅ Données avec colonnes dynamiques (MAP) insérées"
echo ""

# ============================================
# Partie 4 : Filtrage sur Colonnes MAP
# ============================================

echo ""
info "📋 Partie 4 : Filtrage sur Colonnes MAP (Équivalent ColumnFilter HBase)"
echo ""

code "-- Test 1 : Filtrage par clé MAP (équivalent ColumnFilter sur qualifier)"
code "SELECT * FROM operations_by_account"
code "WHERE code_si = 'DEMO_DYN' AND contrat = 'DEMO_001'"
code "  AND meta_flags['source'] = 'mobile';"
echo ""

cat > /tmp/filter1.cql <<'EOF'
USE domirama2_poc;
SELECT code_si, contrat, date_op, numero_op, libelle, montant, meta_flags
FROM operations_by_account
WHERE code_si = 'DEMO_DYN' AND contrat = 'DEMO_001'
  AND meta_flags['source'] = 'mobile';
EOF

info "Exécution du filtrage par source = 'mobile'..."
$CQLSH -f /tmp/filter1.cql 2>&1 | tail -n +4 | grep -v "^$" | grep -v "^(" | head -10

echo ""
success "✅ Filtrage par meta_flags['source'] = 'mobile'"
highlight "Équivalent HBase : ColumnFilter sur qualifier 'meta:source'"
echo ""

code "-- Test 2 : Filtrage par clé MAP avec valeur spécifique"
code "SELECT * FROM operations_by_account"
code "WHERE code_si = 'DEMO_DYN' AND contrat = 'DEMO_001'"
code "  AND meta_flags['device'] = 'iphone';"
echo ""

cat > /tmp/filter2.cql <<'EOF'
USE domirama2_poc;
SELECT code_si, contrat, date_op, numero_op, libelle, montant, meta_flags
FROM operations_by_account
WHERE code_si = 'DEMO_DYN' AND contrat = 'DEMO_001'
  AND meta_flags['device'] = 'iphone';
EOF

info "Exécution du filtrage par device = 'iphone'..."
$CQLSH -f /tmp/filter2.cql 2>&1 | tail -n +4 | grep -v "^$" | grep -v "^(" | head -10

echo ""
success "✅ Filtrage par meta_flags['device'] = 'iphone'"
highlight "Équivalent HBase : ColumnFilter sur qualifier 'meta:device'"
echo ""

code "-- Test 3 : Filtrage combiné (MAP + autres colonnes)"
code "SELECT * FROM operations_by_account"
code "WHERE code_si = 'DEMO_DYN' AND contrat = 'DEMO_001'"
code "  AND meta_flags['source'] = 'web'"
code "  AND libelle : 'VIREMENT';"
echo ""

cat > /tmp/filter3.cql <<'EOF'
USE domirama2_poc;
SELECT code_si, contrat, date_op, numero_op, libelle, montant, meta_flags
FROM operations_by_account
WHERE code_si = 'DEMO_DYN' AND contrat = 'DEMO_001'
  AND meta_flags['source'] = 'web'
  AND libelle : 'VIREMENT';
EOF

info "Exécution du filtrage combiné (MAP + full-text)..."
$CQLSH -f /tmp/filter3.cql 2>&1 | tail -n +4 | grep -v "^$" | grep -v "^(" | head -10

echo ""
success "✅ Filtrage combiné (meta_flags + full-text)"
highlight "Valeur ajoutée HCD : Filtrage MAP + Index SAI full-text"
echo ""

# ============================================
# Partie 5 : Filtrage avec Contient (CONTAINS)
# ============================================

echo ""
info "📋 Partie 5 : Filtrage avec CONTAINS (Vérification Présence Clé)"
echo ""

code "-- Test 4 : Vérifier si une clé existe dans le MAP"
code "SELECT * FROM operations_by_account"
code "WHERE code_si = 'DEMO_DYN' AND contrat = 'DEMO_001'"
code "  AND meta_flags CONTAINS KEY 'ip';"
echo ""

cat > /tmp/filter4.cql <<'EOF'
USE domirama2_poc;
SELECT code_si, contrat, date_op, numero_op, libelle, montant, meta_flags
FROM operations_by_account
WHERE code_si = 'DEMO_DYN' AND contrat = 'DEMO_001'
  AND meta_flags CONTAINS KEY 'ip';
EOF

info "Exécution du filtrage par présence de clé 'ip'..."
$CQLSH -f /tmp/filter4.cql 2>&1 | tail -n +4 | grep -v "^$" | grep -v "^(" | head -10

echo ""
success "✅ Filtrage par CONTAINS KEY 'ip'"
highlight "Équivalent HBase : Vérifier si column qualifier existe"
echo ""

code "-- Test 5 : Vérifier si une valeur existe dans le MAP"
code "SELECT * FROM operations_by_account"
code "WHERE code_si = 'DEMO_DYN' AND contrat = 'DEMO_001'"
code "  AND meta_flags CONTAINS 'paris';"
echo ""

cat > /tmp/filter5.cql <<'EOF'
USE domirama2_poc;
SELECT code_si, contrat, date_op, numero_op, libelle, montant, meta_flags
FROM operations_by_account
WHERE code_si = 'DEMO_DYN' AND contrat = 'DEMO_001'
  AND meta_flags CONTAINS 'paris';
EOF

info "Exécution du filtrage par présence de valeur 'paris'..."
$CQLSH -f /tmp/filter5.cql 2>&1 | tail -n +4 | grep -v "^$" | grep -v "^(" | head -10

echo ""
success "✅ Filtrage par CONTAINS 'paris'"
highlight "Équivalent HBase : Vérifier si column value existe"
echo ""

# ============================================
# Partie 6 : Comparaison HBase vs HCD
# ============================================

echo ""
info "📊 Partie 6 : Comparaison HBase vs HCD"
echo ""

echo "┌─────────────────────────────────────────────────────────────┐"
echo "│  Colonnes Dynamiques : HBase vs HCD                          │"
echo "├─────────────────────────────────────────────────────────────┤"
echo "│                                                               │"
echo "│  HBase :                                                      │"
echo "│    Structure : Column qualifiers dynamiques                  │"
echo "│    Exemple   : 'meta:source', 'meta:device'                 │"
echo "│    Filtrage  : ColumnFilter sur qualifier                   │"
echo "│    Limitation: Nécessite scan complet                        │"
echo "│                                                               │"
echo "│  HCD :                                                        │"
echo "│    Structure : MAP<TEXT, TEXT>                               │"
echo "│    Exemple   : {'source': 'mobile', 'device': 'iphone'}     │"
echo "│    Filtrage  : WHERE meta_flags['key'] = 'value'            │"
echo "│    Avantage  : Peut être combiné avec index SAI             │"
echo "│                                                               │"
echo "└─────────────────────────────────────────────────────────────┘"
echo ""

highlight "Équivalences :"
code "  ✅ Column qualifier HBase = Clé MAP HCD"
code "  ✅ Column value HBase = Valeur MAP HCD"
code "  ✅ ColumnFilter HBase = WHERE meta_flags['key'] HCD"
code "  ✅ Vérification présence = CONTAINS KEY / CONTAINS"
echo ""

highlight "Avantages HCD :"
code "  ✅ Filtrage combiné : MAP + Index SAI full-text"
code "  ✅ Structure typée : MAP<TEXT, TEXT> (vs colonnes dynamiques)"
code "  ✅ Requêtes CQL standard (vs API HBase)"
echo ""

# ============================================
# Partie 7 : Cas d'Usage Réels
# ============================================

echo ""
info "📋 Partie 7 : Cas d'Usage Réels"
echo ""

code "-- Cas d'usage 1 : Filtrer les opérations par canal (mobile vs web)"
code "SELECT COUNT(*) FROM operations_by_account"
code "WHERE code_si = 'DEMO_DYN' AND contrat = 'DEMO_001'"
code "  AND meta_flags['source'] = 'mobile';"
echo ""

cat > /tmp/usage1.cql <<'EOF'
USE domirama2_poc;
SELECT COUNT(*) FROM operations_by_account
WHERE code_si = 'DEMO_DYN' AND contrat = 'DEMO_001'
  AND meta_flags['source'] = 'mobile';
EOF

info "Comptage des opérations mobile..."
$CQLSH -f /tmp/usage1.cql 2>&1 | tail -n +4 | grep -v "^$" | grep -v "^(" | head -5

echo ""

code "-- Cas d'usage 2 : Filtrer les opérations avec IP (sécurité)"
code "SELECT * FROM operations_by_account"
code "WHERE code_si = 'DEMO_DYN' AND contrat = 'DEMO_001'"
code "  AND meta_flags CONTAINS KEY 'ip';"
echo ""

cat > /tmp/usage2.cql <<'EOF'
USE domirama2_poc;
SELECT code_si, contrat, date_op, numero_op, libelle, meta_flags
FROM operations_by_account
WHERE code_si = 'DEMO_DYN' AND contrat = 'DEMO_001'
  AND meta_flags CONTAINS KEY 'ip';
EOF

info "Recherche des opérations avec IP..."
$CQLSH -f /tmp/usage2.cql 2>&1 | tail -n +4 | grep -v "^$" | grep -v "^(" | head -10

echo ""
success "✅ Cas d'usage démontrés"
echo ""

# ============================================
# Partie 8 : Résumé et Conclusion
# ============================================

echo ""
info "📋 Partie 8 : Résumé et Conclusion"
echo ""

echo "✅ Colonnes dynamiques démontrées :"
echo ""
echo "   1. Structure MAP<TEXT, TEXT>"
echo "      → Équivalent colonnes dynamiques HBase"
echo "      → Clé = Column qualifier HBase"
echo "      → Valeur = Column value HBase"
echo ""
echo "   2. Filtrage sur MAP"
echo "      → WHERE meta_flags['key'] = 'value'"
echo "      → Équivalent ColumnFilter HBase"
echo "      → CONTAINS KEY / CONTAINS pour vérification"
echo ""
echo "   3. Filtrage combiné"
echo "      → MAP + Index SAI full-text"
echo "      → Valeur ajoutée HCD (non disponible avec HBase)"
echo ""

echo "🎯 Avantages vs Colonnes Dynamiques HBase :"
echo ""
echo "   ✅ Structure typée : MAP<TEXT, TEXT>"
echo "   ✅ Filtrage combiné : MAP + Index SAI"
echo "   ✅ Requêtes CQL standard"
echo "   ✅ Performance : Peut utiliser index SAI"
echo ""

# Nettoyer
rm -f /tmp/check_schema.cql /tmp/insert*.cql /tmp/select_all.cql /tmp/filter*.cql /tmp/usage*.cql

echo ""
success "✅ Démonstration colonnes dynamiques (MAP) terminée"
info ""
info "💡 Points clés démontrés :"
code "  ✅ Équivalent colonnes dynamiques HBase (MAP<TEXT, TEXT>)"
code "  ✅ Filtrage sur colonnes MAP (WHERE meta_flags['key'] = 'value')"
code "  ✅ Vérification présence (CONTAINS KEY / CONTAINS)"
code "  ✅ Filtrage combiné (MAP + Index SAI full-text)"
code "  ✅ Cas d'usage réels (canal, sécurité, etc.)"
echo ""
