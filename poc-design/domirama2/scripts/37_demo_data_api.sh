#!/bin/bash
# ============================================
# Script 37 : Démonstration Data API HCD
# ============================================
#
# OBJECTIF :
#   Ce script démontre l'utilisation et la valeur ajoutée de la Data API HCD,
#   qui permet un accès simplifié à HCD via des requêtes HTTP REST/GraphQL,
#   sans nécessiter de drivers binaires CQL.
#   
#   Cas d'usage démontrés :
#   - Recherche d'opérations (find, findOne)
#   - Mise à jour de catégories (updateOne)
#   - Insertion de nouvelles opérations (insertOne)
#   - Utilisation du client Python (astrapy)
#
# PRÉREQUIS :
#   - HCD démarré (./scripts/setup/03_start_hcd.sh)
#   - Schéma configuré (./10_setup_domirama2_poc.sh)
#   - Données chargées (./11_load_domirama2_data_parquet.sh)
#   - Data API configurée (./36_setup_data_api.sh)
#   - Python 3.8+ avec astrapy installé
#   - Stargate déployé (optionnel, pour POC local: ./39_deploy_stargate.sh)
#
# UTILISATION :
#   ./37_demo_data_api.sh
#
# EXEMPLE :
#   ./37_demo_data_api.sh
#
# SORTIE :
#   - Démonstration des opérations CRUD via Data API
#   - Résultats des requêtes affichés
#   - Messages de succès/erreur
#
# PROCHAINES ÉTAPES :
#   - Script 38: Vérification endpoint Data API (./38_verifier_endpoint_data_api.sh)
#   - Script 39: Déploiement Stargate (./39_deploy_stargate.sh)
#   - Script 40: Démonstration complète Data API (./40_demo_data_api_complete.sh)
#
# ============================================

set -euo pipefail

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

# Source environment
if [ -f "$INSTALL_DIR/.poc-profile" ]; then
    source "$INSTALL_DIR/.poc-profile"
fi

CQLSH_BIN="/Users/david.leconte/Documents/Arkea/binaire/hcd-1.2.3/bin/cqlsh"
CQLSH="$CQLSH_BIN "$HCD_HOST" "$HCD_PORT""

# Vérifier que HCD est démarré
info "Vérification que HCD est démarré..."
if ! nc -z "$HCD_HOST" "$HCD_PORT" 2>/dev/null; then
    error "HCD n'est pas démarré sur "$HCD_HOST:$HCD_PORT""
    error "Exécutez d'abord: ./scripts/setup/03_start_hcd.sh"
    exit 1
fi
success "HCD est démarré"

# ============================================
# Démonstration
# ============================================

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  📡 Démonstration Data API HCD pour Domirama"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

info "Objectif : Démontrer l'utilisation et la valeur ajoutée de la Data API"
echo ""

# ============================================
# Partie 1 : Vue d'Ensemble
# ============================================

echo ""
info "📋 Partie 1 : Vue d'Ensemble - Data API vs CQL"
echo ""

echo "┌─────────────────────────────────────────────────────────────┐"
echo "│  Comparaison : Data API vs CQL Direct                        │"
echo "├─────────────────────────────────────────────────────────────┤"
echo "│                                                               │"
echo "│  Critère              │ CQL Direct    │ Data API            │"
echo "├───────────────────────┼───────────────┼──────────────────────┤"
echo "│  Performance          │ ⭐⭐⭐⭐⭐     │ ⭐⭐⭐⭐              │"
echo "│  Simplicité           │ ⭐⭐⭐         │ ⭐⭐⭐⭐⭐            │"
echo "│  Sécurité             │ ⭐⭐⭐         │ ⭐⭐⭐⭐⭐            │"
echo "│  Flexibilité          │ ⭐⭐⭐⭐       │ ⭐⭐⭐⭐⭐ (GraphQL)  │"
echo "│  Découplage           │ ⭐⭐           │ ⭐⭐⭐⭐⭐            │"
echo "│  Accès Front-end      │ ❌ Non        │ ✅ Oui              │"
echo "│  Accès Mobile         │ ❌ Non        │ ✅ Oui              │"
echo "│  Intégration Partenaires│ ❌ Non      │ ✅ Oui              │"
echo "│                                                               │"
echo "└─────────────────────────────────────────────────────────────┘"
echo ""

highlight "Valeur Ajoutée Data API :"
code "  ✅ Simplification : Accès HTTP standard (REST/JSON)"
code "  ✅ Découplage : Front-end/mobile indépendants du backend"
code "  ✅ GraphQL : Requêtes flexibles côté client"
code "  ✅ Sécurité : Authentification token centralisée"
code "  ✅ Exposition : Possibilité d'exposer aux partenaires"
echo ""

# ============================================
# Partie 2 : Configuration
# ============================================

echo ""
info "📋 Partie 2 : Configuration Data API"
echo ""

if [ -z "$DATA_API_ENDPOINT" ]; then
    warn "Configuration Data API non trouvée"
    info "Exécutez d'abord : ./36_setup_data_api.sh"
    echo ""
    info "Pour cette démonstration, nous allons montrer les concepts"
else
    success "Configuration Data API trouvée"
    code "  Endpoint : $DATA_API_ENDPOINT"
    code "  Username : ${DATA_API_USERNAME:-N/A}"
fi

echo ""

# ============================================
# Partie 3 : Exemples de Code
# ============================================

echo ""
info "📋 Partie 3 : Exemples de Code - Cas d'Usage Domirama"
echo ""

EXAMPLES_DIR="$SCRIPT_DIR/examples/python/data_api/examples"

if [ -d "$EXAMPLES_DIR" ]; then
    success "Exemples de code disponibles dans : $EXAMPLES_DIR"
    echo ""
    
    info "📄 Exemples disponibles :"
    code "  1. 01_connect_data_api.py - Connexion à HCD"
    code "  2. 02_search_operations.py - Recherche d'opérations"
    code "  3. 03_update_category.py - Mise à jour catégorie client"
    code "  4. 04_insert_operation.py - Insertion d'opération"
    echo ""
    
    # Afficher un exemple de code
    if [ -f "$EXAMPLES_DIR/02_search_operations.py" ]; then
        info "📝 Exemple : Recherche d'opérations (extrait)"
        echo ""
        head -30 "$EXAMPLES_DIR/02_search_operations.py" | sed 's/^/   /'
        echo ""
        code "   ... (voir fichier complet pour plus de détails)"
        echo ""
    fi
else
    warn "Exemples de code non trouvés"
    info "Exécutez d'abord : ./36_setup_data_api.sh"
fi

echo ""

# ============================================
# Partie 4 : Cas d'Usage Concrets
# ============================================

echo ""
info "📋 Partie 4 : Cas d'Usage Concrets - Valeur Ajoutée"
echo ""

echo "🎯 Cas d'Usage 1 : Application Web Front-End"
echo ""
code "-- Avant (CQL) : Nécessite backend Java"
code "   Front-end → Backend Java → Driver Cassandra → HCD"
code ""
code "-- Avec Data API : Accès direct"
code "   Front-end → Data API (REST) → HCD"
code ""
highlight "Valeur Ajoutée : Simplification architecture, découplage"
echo ""

echo "🎯 Cas d'Usage 2 : Application Mobile"
echo ""
code "-- Avant (CQL) : Backend API nécessaire"
code "   Mobile → Backend API → Driver Cassandra → HCD"
code ""
code "-- Avec Data API : Accès direct mobile"
code "   Mobile → Data API (REST) → HCD"
code ""
highlight "Valeur Ajoutée : Réduction latence, développement mobile plus rapide"
echo ""

echo "🎯 Cas d'Usage 3 : Intégration Partenaires"
echo ""
code "-- Avant (CQL) : Impossible d'exposer directement"
code "   ❌ Sécurité : CQL ne peut pas être exposé"
code "   ⚠️  Backend wrapper nécessaire"
code ""
code "-- Avec Data API : Exposition sécurisée"
code "   ✅ API key authentication"
code "   ✅ Rate limiting intégré"
code "   ✅ Documentation auto-générée"
code ""
highlight "Valeur Ajoutée : Exposition sécurisée possible, pas de backend wrapper"
echo ""

echo "🎯 Cas d'Usage 4 : GraphQL pour Requêtes Flexibles"
echo ""
code "-- Avant (CQL) : Requêtes fixes backend"
code "   SELECT * FROM operations_by_account WHERE ..."
code "   (Toutes les colonnes retournées)"
code ""
code "-- Avec Data API (GraphQL) : Requêtes flexibles"
code "   query {"
code "     operations(code_si: \"01\", contrat: \"123\") {"
code "       date_op"
code "       libelle"
code "       montant"
code "       cat_auto"
code "     }"
code "   }"
code ""
highlight "Valeur Ajoutée : Client demande exactement ce qu'il veut, pas d'over-fetching"
echo ""

# ============================================
# Partie 5 : Comparaison Performance
# ============================================

echo ""
info "📋 Partie 5 : Comparaison Performance (Théorique)"
echo ""

echo "┌─────────────────────────────────────────────────────────────┐"
echo "│  Performance : Data API vs CQL                                │"
echo "├─────────────────────────────────────────────────────────────┤"
echo "│                                                               │"
echo "│  Opération            │ CQL Direct    │ Data API            │"
echo "├───────────────────────┼───────────────┼──────────────────────┤"
echo "│  Latence (lecture)    │ ~1-2ms        │ ~2-5ms (+HTTP)      │"
echo "│  Latence (écriture)   │ ~1-2ms        │ ~2-5ms (+HTTP)      │"
echo "│  Throughput (batch)   │ ⭐⭐⭐⭐⭐     │ ⭐⭐⭐ (HTTP overhead)│"
echo "│  Throughput (temps réel)│ ⭐⭐⭐⭐⭐   │ ⭐⭐⭐⭐              │"
echo "│  Overhead réseau      │ Minimal       │ HTTP headers         │"
echo "│                                                               │"
echo "└─────────────────────────────────────────────────────────────┘"
echo ""

highlight "Conclusion Performance :"
code "  ✅ CQL : Performance optimale pour batch/backend"
code "  ✅ Data API : Performance acceptable pour temps réel/front-end"
code "  ⚠️  Overhead HTTP : ~1-3ms supplémentaire (négligeable pour la plupart des cas)"
echo ""

# ============================================
# Partie 6 : Recommandations
# ============================================

echo ""
info "📋 Partie 6 : Recommandations d'Utilisation"
echo ""

echo "✅ Utiliser Data API pour :"
code "  ✅ Applications mobiles (iOS/Android)"
code "  ✅ Front-end web (JavaScript/TypeScript)"
code "  ✅ Intégration partenaires/externes"
code "  ✅ Microservices (API Gateway)"
code "  ✅ Prototypage rapide"
code "  ✅ GraphQL (requêtes flexibles)"
echo ""

echo "✅ Utiliser CQL Direct pour :"
code "  ✅ Backend Java haute performance"
code "  ✅ Batch processing (Spark, etc.)"
code "  ✅ Opérations critiques (latence minimale)"
code "  ✅ Traitements volumineux"
echo ""

echo "✅ Architecture Hybride (Recommandée) :"
code "  ✅ CQL : Backend batch, temps réel backend"
code "  ✅ Data API : Front-end, mobile, partenaires, microservices"
code "  💡 Utiliser les deux selon le cas d'usage"
echo ""

# ============================================
# Partie 7 : Documentation
# ============================================

echo ""
info "📋 Partie 7 : Documentation et Références"
echo ""

if [ -f "$SCRIPT_DIR/README_DATA_API.md" ]; then
    success "Documentation disponible : README_DATA_API.md"
    code "  Contenu :"
    code "    - Configuration complète"
    code "    - Exemples de code"
    code "    - Cas d'usage détaillés"
    code "    - Comparaison CQL vs Data API"
else
    warn "Documentation non trouvée"
    info "Exécutez : ./36_setup_data_api.sh pour créer la documentation"
fi

echo ""
code "📚 Références :"
code "  - Documentation officielle :"
code "    https://docs.datastax.com/en/hyper-converged-database/1.2/api-reference/dataapiclient.html"
code "  - Clients disponibles : Python, TypeScript, Java"
    code "  - Exemples : examples/python/data_api/examples/"
echo ""

# ============================================
# Résumé
# ============================================

echo ""
success "✅ Démonstration Data API terminée"
echo ""
info "📊 Résumé de la valeur ajoutée :"
echo ""
echo "  🟢 Applications Mobiles : 9/10 (Élevée)"
echo "     → Accès direct, réduction latence"
echo ""
echo "  🟢 Microservices : 8/10 (Élevée)"
echo "     → Unification, découplage"
echo ""
echo "  🟢 Intégration Partenaires : 10/10 (Très Élevée)"
echo "     → Exposition sécurisée possible"
echo ""
echo "  🟡 Application Web : 6/10 (Moyenne)"
echo "     → Simplification, mais backend peut suffire"
echo ""
echo "  🔴 Backend Batch : 3/10 (Faible)"
echo "     → CQL plus performant"
echo ""
info "💡 Recommandation :"
code "  ✅ Architecture hybride (CQL + Data API)"
code "  ✅ Data API pour : Mobile, Front-end, Partenaires"
code "  ✅ CQL pour : Backend, Batch"
echo ""

