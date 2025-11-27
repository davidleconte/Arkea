#!/bin/bash
# ============================================
# Script 07 : Configuration du POC Domirama
# Crée le schéma HCD et configure les index SAI
# ============================================

set -e

# Couleurs pour les messages
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

# Variables
INSTALL_DIR="/Users/david.leconte/Documents/Arkea"
HCD_DIR="${INSTALL_DIR}/binaire/hcd-1.2.3"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SCHEMA_FILE="${SCRIPT_DIR}/create_domirama_schema.cql"

# Vérifier que HCD est installé
if [ ! -d "$HCD_DIR" ]; then
    error "HCD non installé. Exécutez d'abord: ./01_install_hcd.sh"
    exit 1
fi

# Vérifier que HCD est démarré
if ! pgrep -f "cassandra" > /dev/null; then
    warn "HCD ne semble pas être démarré. Démarrage..."
    cd "$HCD_DIR"
    jenv local 11
    eval "$(jenv init -)"
    ./bin/hcd cassandra > /dev/null 2>&1 &
    sleep 10
    info "Attente du démarrage de HCD..."
    sleep 5
fi

# Vérifier que le fichier de schéma existe
if [ ! -f "$SCHEMA_FILE" ]; then
    error "Fichier de schéma non trouvé: $SCHEMA_FILE"
    exit 1
fi

cd "$HCD_DIR"
jenv local 11
eval "$(jenv init -)"

info "📋 Création du schéma Domirama dans HCD..."
info "   Keyspace: domirama_poc"
info "   Table: operations_by_account"
info "   Index SAI: idx_libelle_fulltext, idx_cat_auto, idx_montant"

# Exécuter le schéma CQL
if ./bin/cqlsh localhost 9042 -f "$SCHEMA_FILE" 2>&1 | grep -v "Warnings" | grep -v "Using"; then
    success "Schéma créé avec succès"
else
    # Vérifier si le schéma existe déjà
    if ./bin/cqlsh localhost 9042 -e "DESCRIBE KEYSPACE domirama_poc" 2>&1 | grep -q "domirama_poc"; then
        warn "Le schéma existe déjà. Vérification..."
        ./bin/cqlsh localhost 9042 -e "USE domirama_poc; DESCRIBE TABLE operations_by_account;" 2>&1 | grep -v "Warnings" | head -20
        success "Schéma vérifié"
    else
        error "Échec de la création du schéma"
        exit 1
    fi
fi

echo ""
info "🔍 Vérification des index SAI..."
INDEXES=$(./bin/cqlsh localhost 9042 -e "USE domirama_poc; DESCRIBE INDEXES;" 2>&1 | grep -v "Warnings" | grep "idx_" | wc -l | tr -d ' ')
if [ "$INDEXES" -gt 0 ]; then
    success "$INDEXES index(es) SAI créé(s)"
    ./bin/cqlsh localhost 9042 -e "USE domirama_poc; DESCRIBE INDEXES;" 2>&1 | grep -v "Warnings" | grep "idx_"
else
    warn "Aucun index SAI trouvé. Ils seront créés lors de la première utilisation."
fi

echo ""
success "✅ Configuration du POC Domirama terminée !"
echo ""
info "📝 Prochaines étapes:"
echo "   1. Charger des données: ./08_load_domirama_data.sh"
echo "   2. Tester la recherche: ./09_test_domirama_search.sh"
echo "   3. Vérifier les données: cqlsh -e \"USE domirama_poc; SELECT COUNT(*) FROM operations_by_account;\""

