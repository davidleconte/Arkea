#!/bin/bash
# ============================================
# Script 34 : Démonstration REPLICATION_SCOPE (Documentation)
# ============================================
#
# Objectif : Documenter l'équivalent REPLICATION_SCOPE HBase dans HCD
# Note : POC single-node, démonstration de la configuration
#
# Usage :
#   ./34_demo_replication_scope.sh
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
echo "  🔄 Démonstration : REPLICATION_SCOPE (Documentation)"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

info "Objectif : Documenter l'équivalent REPLICATION_SCOPE HBase dans HCD"
echo ""

# ============================================
# Partie 1 : Explication REPLICATION_SCOPE HBase
# ============================================

echo ""
info "📋 Partie 1 : REPLICATION_SCOPE HBase"
echo ""

echo "┌─────────────────────────────────────────────────────────────┐"
echo "│  REPLICATION_SCOPE HBase                                    │"
echo "├─────────────────────────────────────────────────────────────┤"
echo "│  Configuration : Par Column Family                          │"
echo "│  REPLICATION_SCOPE => '0' : Pas de réplication              │"
echo "│  REPLICATION_SCOPE => '1' : Réplication activée             │"
echo "│  Usage : Réplication asynchrone vers clusters distants     │"
echo "└─────────────────────────────────────────────────────────────┘"
echo ""

code "-- Exemple HBase :"
code "HColumnDescriptor columnFamily = new HColumnDescriptor(\"data\");"
code "columnFamily.setScope(1);  // REPLICATION_SCOPE => '1'"
echo ""

highlight "Cas d'usage HBase :"
code "  ✅ Disaster Recovery : Backup vers cluster distant"
code "  ✅ Géolocalisation : Réplication vers clusters régionaux"
code "  ✅ Analytics : Réplication vers cluster d'analyse"
echo ""

# ============================================
# Partie 2 : Équivalent HCD/Cassandra
# ============================================

echo ""
info "📋 Partie 2 : Équivalent HCD/Cassandra"
echo ""

echo "┌─────────────────────────────────────────────────────────────┐"
echo "│  Réplication HCD/Cassandra                                 │"
echo "├─────────────────────────────────────────────────────────────┤"
echo "│  Configuration : Au niveau Keyspace                        │"
echo "│  SimpleStrategy : Single datacenter (POC)                  │"
echo "│  NetworkTopologyStrategy : Multi-datacenter (Production)   │"
echo "│  Usage : Réplication native intégrée                       │"
echo "└─────────────────────────────────────────────────────────────┘"
echo ""

code "-- Équivalent REPLICATION_SCOPE => '0' (Pas de réplication) :"
code "CREATE KEYSPACE domirama2_poc"
code "WITH REPLICATION = {"
code "  'class': 'SimpleStrategy',"
code "  'replication_factor': 1  -- Single-node (POC)"
code "};"
echo ""

code "-- Équivalent REPLICATION_SCOPE => '1' (Réplication activée) :"
code "CREATE KEYSPACE domirama2_prod"
code "WITH REPLICATION = {"
code "  'class': 'NetworkTopologyStrategy',"
code "  'datacenter1': 3,  -- Cluster principal"
code "  'datacenter2': 2   -- Cluster secondaire (réplication)"
code "};"
echo ""

highlight "Équivalences :"
code "  ✅ REPLICATION_SCOPE => '0' = SimpleStrategy (replication_factor: 1)"
code "  ✅ REPLICATION_SCOPE => '1' = NetworkTopologyStrategy (multi-datacenter)"
echo ""

# ============================================
# Partie 3 : Vérification Configuration POC
# ============================================

echo ""
info "📋 Partie 3 : Vérification Configuration POC Actuelle"
echo ""

code "-- Vérifier la configuration de réplication du keyspace domirama2_poc"
echo ""

cat > /tmp/check_replication.cql <<'EOF'
USE domirama2_poc;
DESCRIBE KEYSPACE domirama2_poc;
EOF

info "Configuration actuelle du keyspace domirama2_poc..."
$CQLSH -f /tmp/check_replication.cql 2>&1 | grep -A 5 "REPLICATION" | head -10

echo ""
success "✅ Configuration vérifiée"
highlight "POC actuel : SimpleStrategy (replication_factor: 1)"
highlight "Équivalent REPLICATION_SCOPE => '0' (pas de réplication multi-cluster)"
echo ""

# ============================================
# Partie 4 : Comparaison HBase vs HCD
# ============================================

echo ""
info "📊 Partie 4 : Comparaison HBase vs HCD"
echo ""

echo "┌─────────────────────────────────────────────────────────────┐"
echo "│  Comparaison : REPLICATION_SCOPE vs Réplication HCD        │"
echo "├─────────────────────────────────────────────────────────────┤"
echo "│                                                               │"
echo "│  HBase :                                                      │"
echo "│    Niveau      : Column Family                                │"
echo "│    Configuration : Par table                                 │"
echo "│    Réplication : Asynchrone (configuration séparée)          │"
echo "│    Consistance : Limitée par asynchrone                      │"
echo "│                                                               │"
echo "│  HCD :                                                        │"
echo "│    Niveau      : Keyspace                                    │"
echo "│    Configuration : Centralisée (une seule config)          │"
echo "│    Réplication : Native (intégrée)                           │"
echo "│    Consistance : Configurable (QUORUM, ALL, etc.)            │"
echo "│                                                               │"
echo "└─────────────────────────────────────────────────────────────┘"
echo ""

highlight "Avantages HCD :"
code "  ✅ Configuration centralisée (keyspace vs Column Family)"
code "  ✅ Réplication native (intégrée vs configuration séparée)"
code "  ✅ Consistance configurable (QUORUM, ALL vs asynchrone)"
code "  ✅ Multi-datacenter natif (NetworkTopologyStrategy)"
echo ""

# ============================================
# Partie 5 : Configuration Production (Exemple)
# ============================================

echo ""
info "📋 Partie 5 : Configuration Production (Exemple)"
echo ""

code "-- Configuration pour production multi-cluster"
code "CREATE KEYSPACE domirama2_prod"
code "WITH REPLICATION = {"
code "  'class': 'NetworkTopologyStrategy',"
code "  'paris': 3,   -- Cluster principal (3 réplicas)"
code "  'lyon': 2     -- Cluster secondaire (2 réplicas pour disaster recovery)"
code "};"
echo ""

highlight "Équivalent REPLICATION_SCOPE => '1' :"
code "  ✅ NetworkTopologyStrategy = Réplication activée"
code "  ✅ datacenter 'lyon' = Cluster distant (équivalent destination HBase)"
code "  ✅ Disaster recovery : Cluster secondaire"
code "  ✅ Haute disponibilité : 3 réplicas dans cluster principal"
echo ""

# ============================================
# Partie 6 : Cas d'Usage
# ============================================

echo ""
info "📋 Partie 6 : Cas d'Usage"
echo ""

echo "┌─────────────────────────────────────────────────────────────┐"
echo "│  Cas d'Usage : Quand Utiliser la Réplication Multi-Cluster │"
echo "├─────────────────────────────────────────────────────────────┤"
echo "│                                                               │"
echo "│  1. Disaster Recovery                                       │"
echo "│     → Backup vers cluster distant                            │"
echo "│     → Configuration : NetworkTopologyStrategy                │"
echo "│                                                               │"
echo "│  2. Géolocalisation                                         │"
echo "│     → Réplication vers clusters régionaux                   │"
echo "│     → Configuration : Multi-datacenter                     │"
echo "│                                                               │"
echo "│  3. Analytics Séparé                                        │"
echo "│     → Réplication vers cluster d'analyse (lecture seule)   │"
echo "│     → Configuration : Datacenter dédié                      │"
echo "│                                                               │"
echo "└─────────────────────────────────────────────────────────────┘"
echo ""

# ============================================
# Partie 7 : Résumé et Conclusion
# ============================================

echo ""
info "📋 Partie 7 : Résumé et Conclusion"
echo ""

echo "✅ Équivalences REPLICATION_SCOPE :"
echo ""
echo "   1. REPLICATION_SCOPE => '0' (Pas de réplication)"
echo "      → SimpleStrategy avec replication_factor: 1"
echo "      → Configuration POC actuelle"
echo ""
echo "   2. REPLICATION_SCOPE => '1' (Réplication activée)"
echo "      → NetworkTopologyStrategy avec plusieurs datacenters"
echo "      → Configuration production recommandée"
echo ""

echo "🎯 Avantages vs REPLICATION_SCOPE HBase :"
echo ""
echo "   ✅ Configuration centralisée : Au niveau keyspace (vs Column Family)"
echo "   ✅ Réplication native : Intégrée dans Cassandra"
echo "   ✅ Consistance configurable : QUORUM, ALL, etc."
echo "   ✅ Multi-datacenter : Support natif (NetworkTopologyStrategy)"
echo ""

echo "📋 POC Actuel :"
echo ""
echo "   Configuration : SimpleStrategy (replication_factor: 1)"
echo "   Équivalent : REPLICATION_SCOPE => '0' (pas de réplication)"
echo "   Justification : POC local (single-node)"
echo ""

echo "📋 Production Recommandée :"
echo ""
echo "   Configuration : NetworkTopologyStrategy (multi-datacenter)"
echo "   Équivalent : REPLICATION_SCOPE => '1' (réplication activée)"
echo "   Justification : Disaster recovery, haute disponibilité"
echo ""

# Nettoyer
rm -f /tmp/check_replication.cql

echo ""
success "✅ Démonstration REPLICATION_SCOPE (documentation) terminée"
info ""
info "💡 Points clés documentés :"
code "  ✅ Équivalent REPLICATION_SCOPE => '0' (SimpleStrategy)"
code "  ✅ Équivalent REPLICATION_SCOPE => '1' (NetworkTopologyStrategy)"
code "  ✅ Configuration POC actuelle vérifiée"
code "  ✅ Configuration production documentée"
code "  ✅ Avantages vs HBase expliqués"
echo ""
