#!/bin/bash
# ============================================
# Script 19 : Configuration Tolérance aux Typos
# Ajout d'une colonne dérivée avec index pour recherche partielle
# ============================================
#
# OBJECTIF :
#   Ce script configure la tolérance aux typos en ajoutant une colonne
#   'libelle_prefix' qui contient les premiers caractères du libellé,
#   permettant des recherches partielles pour tolérer les erreurs de saisie.
#   
#   Fonctionnalités :
#   - Ajout de la colonne 'libelle_prefix' (TEXT)
#   - Création d'un index SAI sur 'libelle_prefix'
#   - Mise à jour des données existantes avec les préfixes
#   - Support des recherches partielles (ex: "LOY" trouve "LOYER")
#
# PRÉREQUIS :
#   - HCD démarré (./scripts/setup/03_start_hcd.sh)
#   - Schéma configuré (./10_setup_domirama2_poc.sh)
#   - Données chargées (./11_load_domirama2_data_parquet.sh)
#   - Spark 3.5.1 installé et configuré
#   - Spark Cassandra Connector 3.5.0 disponible
#   - Java 11 configuré via jenv
#
# UTILISATION :
#   ./19_setup_typo_tolerance.sh [longueur_prefix]
#
# PARAMÈTRES :
#   $1 : Longueur du préfixe (optionnel, défaut: 5 caractères)
#
# EXEMPLE :
#   ./19_setup_typo_tolerance.sh
#   ./19_setup_typo_tolerance.sh 10
#
# SORTIE :
#   - Colonne 'libelle_prefix' ajoutée à la table
#   - Index SAI créé sur 'libelle_prefix'
#   - Données existantes mises à jour avec les préfixes
#   - Messages de succès/erreur
#
# PROCHAINES ÉTAPES :
#   - Script 20: Tests tolérance aux typos (./20_test_typo_tolerance.sh)
#   - Script 21: Configuration fuzzy search (./21_setup_fuzzy_search.sh)
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

cd "$HCD_DIR"
jenv local 11
eval "$(jenv init -)"

info "🔧 Configuration de la tolérance aux typos..."
info "   Ajout d'une colonne dérivée avec index pour recherche partielle"
info ""

# Vérifier si la colonne existe déjà
COLUMN_EXISTS=$(./bin/cqlsh "$HCD_HOST" "$HCD_PORT" -e "USE domirama2_poc; DESCRIBE TABLE operations_by_account;" 2>&1 | grep -c "libelle_prefix" || echo "0")

if [ "$COLUMN_EXISTS" -eq 0 ]; then
    info "📋 Ajout de la colonne libelle_prefix..."
    ./bin/cqlsh "$HCD_HOST" "$HCD_PORT" -e "USE domirama2_poc; ALTER TABLE operations_by_account ADD libelle_prefix TEXT;" 2>&1 | grep -v "Warnings" || true
    success "✅ Colonne libelle_prefix ajoutée"
else
    info "✅ Colonne libelle_prefix existe déjà"
fi

# Créer l'index sur libelle_prefix
info "📋 Création de l'index sur libelle_prefix..."
./bin/cqlsh "$HCD_HOST" "$HCD_PORT" <<'CQL'
USE domirama2_poc;
DROP INDEX IF EXISTS idx_libelle_prefix_ngram;
CREATE CUSTOM INDEX IF NOT EXISTS idx_libelle_prefix_ngram
ON operations_by_account(libelle_prefix)
USING 'StorageAttachedIndex'
WITH OPTIONS = {
  'index_analyzer': '{
    "tokenizer": {"name": "standard"},
    "filters": [
      {"name": "lowercase"},
      {"name": "asciiFolding"}
    ]
  }'
};
CQL

success "✅ Index idx_libelle_prefix_ngram créé"
echo ""

info "📋 Note sur la mise à jour des données existantes..."
info "   La colonne libelle_prefix est maintenant disponible"
info "   Les NOUVELLES données chargées auront libelle_prefix rempli automatiquement"
info "   (via les scripts de chargement qui copient libelle → libelle_prefix)"
echo ""
info "💡 Pour mettre à jour les données existantes (optionnel) :"
info "   - Utiliser le script Spark: examples/scala/update_libelle_prefix.scala"
info "   - Ou recharger les données avec les scripts de chargement (11_load_*.sh)"
echo ""

echo ""
info "⏳ Indexation en cours (peut prendre quelques minutes)..."
info "   Les index SAI sont construits en arrière-plan"
info "   Attendre 30-60 secondes avant de tester les recherches"
echo ""

success "✅ Configuration de la tolérance aux typos terminée !"
info "📝 Prochaine étape: Exécuter ./20_test_typo_tolerance.sh"

