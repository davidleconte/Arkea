#!/bin/bash
# ============================================
# Script 18 : Génération des Embeddings e5-large
# Génère les embeddings multilingual-e5-large pour les opérations existantes
# ============================================
#
# OBJECTIF :
#   Ce script génère les embeddings e5-large pour toutes les opérations
#   et les met à jour dans la colonne libelle_embedding_e5.
#
# PRÉREQUIS :
#   - HCD démarré
#   - Colonne libelle_embedding_e5 créée (script 17)
#   - Python 3.8+ avec sentence-transformers installé
#
# UTILISATION :
#   ./18_generate_embeddings_e5.sh
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

PYTHON_DIR="${SCRIPT_DIR}/../examples/python/search"
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
info "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
info "  🔄 Génération des Embeddings e5-large"
info "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Vérifications
if ! command -v python3 &> /dev/null; then
    error "Python 3 n'est pas installé"
    exit 1
fi

# Vérifier sentence-transformers
if ! python3 -c "import sentence_transformers" 2>/dev/null; then
    warn "⚠️  sentence-transformers n'est pas installé"
    echo ""
    echo "   Installation requise :"
    echo "   pip install sentence-transformers"
    echo ""
    read -p "   Voulez-vous installer maintenant ? (o/N) " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Oo]$ ]]; then
        info "📦 Installation de sentence-transformers..."
        pip install sentence-transformers
        success "✅ Installation terminée"
    else
        error "❌ Installation requise pour continuer"
        exit 1
    fi
fi

# Exécuter le script Python
info "🔄 Génération des embeddings..."
echo ""

if python3 "${PYTHON_DIR}/generate_embeddings_e5.py"; then
    success "✅ Embeddings e5-large générés avec succès"
else
    error "❌ Erreur lors de la génération"
    exit 1
fi

echo ""
success "✅ Script terminé avec succès"
echo ""
