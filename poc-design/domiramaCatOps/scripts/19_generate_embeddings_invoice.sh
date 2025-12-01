#!/bin/bash
# ============================================
# Script 19 : Génération des Embeddings Facturation
# Génère les embeddings avec le modèle spécialisé facturation
# ============================================

set -e

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
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
info "  🔄 Génération des Embeddings Facturation"
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
    info "📦 Installation de sentence-transformers..."
    if pip install sentence-transformers 2>&1 | tail -5; then
        success "✅ Installation terminée"
    else
        error "❌ Erreur lors de l'installation"
        exit 1
    fi
    echo ""
else
    success "✅ sentence-transformers déjà installé"
    echo ""
fi

# Exécuter le script Python
info "🔄 Génération des embeddings facturation..."
echo "   Note : Le modèle sera téléchargé au premier lancement (~500MB)"
echo ""

if python3 "${PYTHON_DIR}/generate_embeddings_invoice.py"; then
    success "✅ Embeddings facturation générés avec succès"
else
    error "❌ Erreur lors de la génération"
    exit 1
fi

echo ""
success "✅ Script terminé avec succès"
echo ""

