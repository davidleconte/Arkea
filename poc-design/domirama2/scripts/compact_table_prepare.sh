#!/bin/bash
# ============================================
# Script : Préparation Compaction pour Éviter Tombstones
# Objectif : Exécuter tous les prérequis nécessaires avant compaction
# ============================================
#
# PRÉREQUIS POUR COMPACTION :
#   1. Vérifier l'état du cluster (nodetool status)
#   2. Vérifier gc_grace_seconds de la table
#   3. Effectuer un repair complet (propagation des tombstones)
#   4. Vérifier l'espace disque disponible
#   5. Effectuer la compaction
#   6. Vérifier les résultats
#
# NOTE : Le drain n'est PAS nécessaire pour la compaction.
#        Le drain sert uniquement à arrêter proprement un nœud.
#
# UTILISATION :
#   ./compact_table_prepare.sh [keyspace] [table]
#
# PARAMÈTRES :
#   $1 : Keyspace (optionnel, défaut: domirama2_poc)
#   $2 : Table (optionnel, défaut: operations_by_account)
#
# ============================================

set -euo pipefail

# Couleurs
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

info() { echo -e "${BLUE}ℹ️  $1${NC}"; }
success() { echo -e "${GREEN}✅ $1${NC}"; }
warn() { echo -e "${YELLOW}⚠️  $1${NC}"; }
error() { echo -e "${RED}❌ $1${NC}"; }
section() { echo -e "${BOLD}${CYAN}$1${NC}"; }

# Configuration - Utiliser setup_paths si disponible
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
if [ -f "$SCRIPT_DIR/../utils/didactique_functions.sh" ]; then
    source "$SCRIPT_DIR/../utils/didactique_functions.sh"
    setup_paths
else
    # Fallback si les fonctions ne sont pas disponibles
    INSTALL_DIR="${ARKEA_HOME:-$(cd "$SCRIPT_DIR/../.." && pwd)}"
    HCD_DIR="${HCD_DIR:-${INSTALL_DIR}/binaire/hcd-1.2.3}"
    HCD_HOST="${HCD_HOST:-localhost}"
    HCD_PORT="${HCD_PORT:-9042}"
fi

if [ -z "${HCD_DIR:-}" ]; then
    error "HCD_DIR non trouvé. Veuillez définir HCD_DIR manuellement."
    exit 1
fi

NODETOOL="${HCD_DIR}/bin/nodetool"
CQLSH="${HCD_DIR}/bin/cqlsh"
HCD_HOST="${HCD_HOST:-localhost}"
HCD_PORT="${HCD_PORT:-9042}"

# Paramètres
KEYSPACE="${1:-domirama2_poc}"
TABLE="${2:-operations_by_account}"

# Vérifications
if [ ! -f "$NODETOOL" ]; then
    error "nodetool non trouvé : $NODETOOL"
    exit 1
fi

if [ ! -f "$CQLSH" ]; then
    error "cqlsh non trouvé : $CQLSH"
    exit 1
fi

if ! nc -z "$HCD_HOST" "$HCD_PORT" 2>/dev/null; then
    error "HCD n'est pas démarré sur ${HCD_HOST}:${HCD_PORT}"
    exit 1
fi

echo ""
section "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
section "  🔧 PRÉPARATION COMPACTION : $KEYSPACE.$TABLE"
section "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# ============================================
# ÉTAPE 1 : Vérification État du Cluster
# ============================================
echo ""
section "📊 ÉTAPE 1 : Vérification État du Cluster"
echo ""

info "Vérification de l'état du cluster..."
if "$NODETOOL" status 2>&1 | grep -q "UN"; then
    success "Cluster opérationnel"
    "$NODETOOL" status | grep -E "UN|DN|UJ" || true
else
    warn "Impossible de vérifier l'état du cluster (mode standalone ?)"
fi

# ============================================
# ÉTAPE 2 : Vérification gc_grace_seconds
# ============================================
echo ""
section "⏱️  ÉTAPE 2 : Vérification gc_grace_seconds"
echo ""

info "Vérification de gc_grace_seconds pour $KEYSPACE.$TABLE..."
GC_GRACE=$("$CQLSH" "$HCD_HOST" "$HCD_PORT" -e "DESCRIBE TABLE $KEYSPACE.$TABLE;" 2>/dev/null | grep -i "gc_grace_seconds" | grep -oE '[0-9]+' || echo "864000")

if [ -n "$GC_GRACE" ]; then
    GC_GRACE_DAYS=$((GC_GRACE / 86400))
    success "gc_grace_seconds : $GC_GRACE secondes ($GC_GRACE_DAYS jours)"

    if [ "$GC_GRACE" -lt 864000 ]; then
        warn "gc_grace_seconds est inférieur à 10 jours (défaut)"
        warn "   Assurez-vous que les repairs sont effectués régulièrement"
    fi
else
    warn "gc_grace_seconds non trouvé (utilise la valeur par défaut : 10 jours)"
    GC_GRACE=864000
fi

# ============================================
# ÉTAPE 3 : Repair Complet (Recommandé)
# ============================================
echo ""
section "🔧 ÉTAPE 3 : Repair Complet (Propagation des Tombstones)"
echo ""

info "Le repair est RECOMMANDÉ avant compaction pour :"
echo "   - Propager les tombstones sur tous les nœuds"
echo "   - Éviter la réapparition de données supprimées (zombie data)"
echo "   - Garantir la cohérence du cluster"
echo ""

read -p "Voulez-vous effectuer un repair complet ? (o/N) : " -n 1 -r
echo ""

if [[ $REPLY =~ ^[OoYy]$ ]]; then
    info "Lancement du repair complet pour $KEYSPACE.$TABLE..."
    warn "⚠️  Cette opération peut prendre du temps selon la taille des données"

    if "$NODETOOL" repair -pr "$KEYSPACE" "$TABLE" 2>&1; then
        success "Repair terminé avec succès"
    else
        error "Erreur lors du repair"
        warn "Le repair peut échouer en mode standalone (1 nœud)"
        warn "Continuez quand même avec la compaction ?"
        read -p "(o/N) : " -n 1 -r
        echo ""
        if [[ ! $REPLY =~ ^[OoYy]$ ]]; then
            error "Arrêt du script"
            exit 1
        fi
    fi
else
    warn "Repair ignoré"
    warn "⚠️  ATTENTION : Sans repair, les tombstones peuvent ne pas être propagés"
    warn "   Risque de réapparition de données supprimées après compaction"
fi

# ============================================
# ÉTAPE 4 : Vérification Espace Disque
# ============================================
echo ""
section "💾 ÉTAPE 4 : Vérification Espace Disque"
echo ""

info "Vérification de l'espace disque disponible..."
DISK_USAGE=$(df -h "$HCD_DIR" | tail -1 | awk '{print $5}' | sed 's/%//')
DISK_AVAILABLE=$(df -h "$HCD_DIR" | tail -1 | awk '{print $4}')

success "Espace disque utilisé : ${DISK_USAGE}%"
success "Espace disponible : $DISK_AVAILABLE"

if [ "$DISK_USAGE" -gt 80 ]; then
    warn "⚠️  Espace disque utilisé > 80%"
    warn "   La compaction peut nécessiter de l'espace temporaire"
    warn "   Vérifiez l'espace disponible avant de continuer"
fi

# ============================================
# ÉTAPE 5 : Compaction
# ============================================
echo ""
section "🗜️  ÉTAPE 5 : Compaction de la Table"
echo ""

info "Lancement de la compaction pour $KEYSPACE.$TABLE..."
warn "⚠️  Cette opération peut prendre du temps selon la taille des données"
warn "⚠️  La compaction va :"
echo "   - Fusionner les SSTables"
echo "   - Purger les tombstones expirés (> gc_grace_seconds)"
echo "   - Optimiser l'utilisation de l'espace disque"
echo ""

read -p "Confirmer la compaction ? (o/N) : " -n 1 -r
echo ""

if [[ $REPLY =~ ^[OoYy]$ ]]; then
    info "Compaction en cours..."

    if "$NODETOOL" compact "$KEYSPACE" "$TABLE" 2>&1; then
        success "Compaction lancée avec succès"
        info "La compaction s'exécute en arrière-plan"
        info "Vous pouvez surveiller la progression avec :"
        echo "   $NODETOOL compactionstats"
    else
        error "Erreur lors du lancement de la compaction"
        exit 1
    fi
else
    warn "Compaction annulée"
    exit 0
fi

# ============================================
# ÉTAPE 6 : Vérification Post-Compaction
# ============================================
echo ""
section "📊 ÉTAPE 6 : Vérification Post-Compaction"
echo ""

info "Attente de 5 secondes avant vérification..."
sleep 5

info "Statut de la compaction :"
"$NODETOOL" compactionstats 2>&1 | grep -E "pending|active|completed" || echo "Aucune compaction active"

info "Statistiques de la table :"
"$NODETOOL" tablestats "$KEYSPACE" "$TABLE" 2>&1 | head -20 || true

echo ""
success "✅ Préparation compaction terminée"
echo ""
info "📋 Prochaines étapes :"
echo "   1. Attendre la fin de la compaction (surveiller avec: nodetool compactionstats)"
echo "   2. Vérifier les tombstones restants (SELECT COUNT(*) FROM $KEYSPACE.$TABLE)"
echo "   3. Lancer l'export : ./27_export_incremental_parquet_v2_didactique.sh"
echo ""
