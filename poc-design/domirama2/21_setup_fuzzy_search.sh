#!/bin/bash
# ============================================
# Script 21 : Configuration Fuzzy Search avec ByteT5
# Ajout de la colonne vectorielle et de l'index pour recherche floue
# ============================================
#
# OBJECTIF :
#   Ce script configure la recherche floue (fuzzy search) en ajoutant une
#   colonne vectorielle 'libelle_embedding' de type VECTOR pour stocker
#   les embeddings ByteT5, permettant des recherches par similarité sémantique.
#   
#   Fonctionnalités :
#   - Ajout de la colonne 'libelle_embedding' (VECTOR<FLOAT, 1472>)
#   - Création d'un index SAI vectoriel sur 'libelle_embedding'
#   - Support des recherches par similarité cosinus
#   - Tolérance aux typos et variations linguistiques
#
# PRÉREQUIS :
#   - HCD démarré (./03_start_hcd.sh)
#   - Schéma configuré (./10_setup_domirama2_poc.sh)
#   - Données chargées (./11_load_domirama2_data_parquet.sh)
#   - Fichier schéma présent: schemas/03_create_domirama2_schema_fuzzy.cql
#
# UTILISATION :
#   ./21_setup_fuzzy_search.sh
#
# EXEMPLE :
#   ./21_setup_fuzzy_search.sh
#
# SORTIE :
#   - Colonne 'libelle_embedding' ajoutée à la table
#   - Index SAI vectoriel créé
#   - Messages de succès/erreur
#
# PROCHAINES ÉTAPES :
#   - Script 22: Génération embeddings (./22_generate_embeddings.sh)
#   - Script 23: Tests fuzzy search (./23_test_fuzzy_search.sh)
#
# ============================================

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

info() { echo -e "${BLUE}ℹ️  $1${NC}"; }
success() { echo -e "${GREEN}✅ $1${NC}"; }
warn() { echo -e "${YELLOW}⚠️  $1${NC}"; }
error() { echo -e "${RED}❌ $1${NC}"; }

INSTALL_DIR="/Users/david.leconte/Documents/Arkea"
HCD_DIR="${INSTALL_DIR}/binaire/hcd-1.2.3"
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"

# Vérifier que HCD est démarré
if ! pgrep -f "cassandra" > /dev/null; then
    error "HCD n'est pas démarré. Exécutez d'abord: ./03_start_hcd.sh"
    exit 1
fi

cd "$HCD_DIR"
jenv local 11
eval "$(jenv init -)"

info "🔧 Configuration de la recherche floue avec ByteT5..."
info "   Ajout de la colonne libelle_embedding (VECTOR<FLOAT, 1472>)"
info "   Création de l'index SAI vectoriel pour recherche par similarité"
info ""

# Vérifier si la colonne existe déjà
COLUMN_EXISTS=$(./bin/cqlsh localhost 9042 -e "USE domirama2_poc; DESCRIBE TABLE operations_by_account;" 2>&1 | grep -c "libelle_embedding" || echo "0")

if [ "$COLUMN_EXISTS" -eq 0 ]; then
    info "📋 Ajout de la colonne libelle_embedding..."
    ./bin/cqlsh localhost 9042 -e "USE domirama2_poc; ALTER TABLE operations_by_account ADD libelle_embedding VECTOR<FLOAT, 1472>;" 2>&1 | grep -v "Warnings" || true
    success "✅ Colonne libelle_embedding ajoutée"
else
    info "✅ Colonne libelle_embedding existe déjà"
fi

# Créer l'index vectoriel
info "📋 Création de l'index vectoriel..."
./bin/cqlsh localhost 9042 <<'CQL'
USE domirama2_poc;
DROP INDEX IF EXISTS idx_libelle_embedding_vector;
CREATE CUSTOM INDEX IF NOT EXISTS idx_libelle_embedding_vector
ON operations_by_account(libelle_embedding)
USING 'StorageAttachedIndex';
CQL

success "✅ Index idx_libelle_embedding_vector créé"
echo ""

info "⏳ Indexation en cours (peut prendre quelques minutes)..."
info "   Les index SAI sont construits en arrière-plan"
info "   Attendre 30-60 secondes avant de tester les recherches"
echo ""

success "✅ Configuration de la recherche floue terminée !"
info "📝 Prochaines étapes:"
echo "   1. Installer les dépendances Python: pip install transformers torch"
echo "   2. Générer les embeddings: ./22_generate_embeddings.sh"
echo "   3. Tester la recherche floue: ./23_test_fuzzy_search.sh"

