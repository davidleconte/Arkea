#!/bin/bash
set -euo pipefail
# ============================================
# Script 22 : Génération des Embeddings ByteT5
# Génère les embeddings pour tous les libellés existants dans HCD
# ============================================
#
# OBJECTIF :
#   Ce script génère les embeddings ByteT5 pour tous les libellés existants
#   dans la table 'operations_by_account' et les met à jour dans la colonne
#   'libelle_embedding'.
#
#   Le modèle ByteT5 (google/byt5-small) :
#   - Génère des embeddings de 1472 dimensions
#   - Tolère les typos et variations linguistiques
#   - Multilingue (français, anglais, etc.)
#   - Robuste aux caractères manquants ou inversés
#
# PRÉREQUIS :
#   - HCD démarré (./scripts/setup/03_start_hcd.sh)
#   - Schéma configuré (./10_setup_domirama2_poc.sh)
#   - Données chargées (./11_load_domirama2_data_parquet.sh)
#   - Fuzzy search configuré (./21_setup_fuzzy_search.sh)
#   - Python 3.8+ avec transformers et torch installés
#   - Clé API Hugging Face configurée (HF_API_KEY dans .poc-profile)
#   - Script Python présent: examples/python/embeddings/generate_embeddings_bytet5.py
#
# UTILISATION :
#   ./22_generate_embeddings.sh [batch_size] [limit]
#
# PARAMÈTRES :
#   $1 : Taille du batch (optionnel, défaut: 100)
#   $2 : Limite du nombre d'opérations (optionnel, défaut: toutes)
#
# EXEMPLE :
#   ./22_generate_embeddings.sh
#   ./22_generate_embeddings.sh 50 1000
#
# SORTIE :
#   - Embeddings générés et mis à jour dans HCD
#   - Statistiques de génération (nombre d'opérations traitées)
#   - Messages de progression
#   - Messages de succès/erreur
#
# PROCHAINES ÉTAPES :
#   - Script 23: Tests fuzzy search (./23_test_fuzzy_search.sh)
#   - Script 24: Démonstration fuzzy search (./24_demonstration_fuzzy_search.sh)
#
# ============================================

set -euo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

info() { echo -e "${BLUE}ℹ️  $1${NC}"; }
success() { echo -e "${GREEN}✅ $1${NC}"; }
warn() { echo -e "${YELLOW}⚠️  $1${NC}"; }
error() { echo -e "${RED}❌ $1${NC}"; }

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

# Vérifier que HCD est démarré
# Vérifier les prérequis HCD
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

# Vérifier que Python et les dépendances sont installées
if ! command -v python3 &> /dev/null; then
    error "Python3 n'est pas installé"
    exit 1
fi

info "🔍 Vérification des dépendances Python..."
if ! python3 -c "import transformers" 2>/dev/null; then
    warn "⚠️  transformers n'est pas installé"
    info "📦 Installation des dépendances..."
    pip3 install transformers torch --quiet
    success "✅ Dépendances installées"
else
    info "✅ Dépendances Python OK"
fi

cd "$SCRIPT_DIR"

info "📥 Génération des embeddings ByteT5 pour les libellés..."
info "   Modèle: google/byt5-small"
info "   Dimension: 1472"
info ""

# Créer un script Scala temporaire pour générer les embeddings
# Note: La génération d'embeddings avec ByteT5 nécessite Python/transformers
# Pour l'instant, on utilise un script Python standalone qui sera appelé depuis Spark
# ou on génère les embeddings en batch avec Python puis on les insère avec Spark

# Charger la clé API Hugging Face depuis .poc-profile
cd "$INSTALL_DIR"
source .poc-profile 2>/dev/null || true

if [ -z "$HF_API_KEY" ]; then
    warn "⚠️  HF_API_KEY non définie, utilisation de la valeur par défaut"
    export HF_API_KEY="${HF_API_KEY:-}"
fi

info "📝 Note: La génération d'embeddings ByteT5 nécessite Python/transformers"
info "   Clé API Hugging Face: ${HF_API_KEY:0:10}..."
info ""

# Vérifier si le script Python amélioré existe, sinon utiliser l'ancien
EMBEDDINGS_SCRIPT="${SCRIPT_DIR}/examples/python/embeddings/generate_embeddings_batch_v2.py"
if [ ! -f "$EMBEDDINGS_SCRIPT" ]; then
    EMBEDDINGS_SCRIPT="${SCRIPT_DIR}/examples/python/embeddings/generate_embeddings_batch.py"
fi

if [ -f "$EMBEDDINGS_SCRIPT" ]; then
    info "🚀 Lancement de la génération batch des embeddings..."
    if [[ "$EMBEDDINGS_SCRIPT" == *"_v2.py" ]]; then
        info "   Script: generate_embeddings_batch_v2.py (Version améliorée)"
        info "   ✅ Combine plusieurs colonnes : libelle, cat_auto, type_operation, devise"
    else
        info "   Script: generate_embeddings_batch.py (Version standard)"
    fi
    info ""

    # Paramètres optionnels
    BATCH_SIZE="${1:-100}"
    FORCE="${2:-}"

    # Construire la commande
    CMD="python3 \"$EMBEDDINGS_SCRIPT\""
    if [ "$FORCE" = "--force" ]; then
        CMD="$CMD --force"
        info "⚠️  Mode régénération forcée activé"
    fi

    eval "$CMD" 2>&1 | grep -v "^$" | tail -50

    # Vérifier le nombre d'embeddings générés
    cd "$HCD_DIR"
    jenv local 11
    eval "$(jenv init -)"

    sleep 2
    EMBEDDED_COUNT=$(./bin/cqlsh "$HCD_HOST" "$HCD_PORT" -e "USE domirama2_poc; SELECT COUNT(*) FROM operations_by_account WHERE libelle_embedding IS NOT NULL ALLOW FILTERING;" 2>&1 | grep -v "Warnings" | grep -E "^[[:space:]]*[0-9]+" | head -1 | tr -d ' ' || echo "0")

    if [ -n "$EMBEDDED_COUNT" ] && [ "$EMBEDDED_COUNT" -gt 0 ]; then
        success "✅ $EMBEDDED_COUNT opération(s) avec embeddings générés"
    else
        warn "⚠️  Aucun embedding trouvé (peut-être en cours de génération)"
    fi
else
    warn "⚠️  Script de génération batch non trouvé: $EMBEDDINGS_SCRIPT"
    info "   Pour générer les embeddings manuellement:"
    info "   python3 examples/python/embeddings/generate_embeddings_bytet5.py"
fi

success "✅ Génération des embeddings terminée !"
info "📝 Prochaine étape: Exécuter ./23_test_fuzzy_search.sh"
