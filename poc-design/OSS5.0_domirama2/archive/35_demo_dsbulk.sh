#!/bin/bash
# ============================================
# Script 35 : Démonstration DSBulk avec Parquet
# ============================================
#
# Objectif : Démontrer DSBulk et son utilisation avec Parquet
# DSBulk : DataStax Bulk Loader pour import/export massif
# Parquet : Format columnar pour Spark
#
# Usage :
#   ./35_demo_dsbulk.sh
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
echo "  📦 Démonstration : DSBulk avec Parquet"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

info "Objectif : Démontrer DSBulk et son utilisation avec Parquet"
echo ""

# ============================================
# Partie 1 : Qu'est-ce que DSBulk ?
# ============================================

echo ""
info "📋 Partie 1 : Qu'est-ce que DSBulk ?"
echo ""

echo "┌─────────────────────────────────────────────────────────────┐"
echo "│  DSBulk (DataStax Bulk Loader)                                │"
echo "├─────────────────────────────────────────────────────────────┤"
echo "│  Outil : Import/Export massif vers/depuis Cassandra/HCD      │"
echo "│  Formats supportés : CSV, JSON, CQL                          │"
echo "│  Parquet : Non supporté directement (nécessite conversion)  │"
echo "│  Usage : Bulk load, export, migration                        │"
echo "└─────────────────────────────────────────────────────────────┘"
echo ""

highlight "DSBulk supporte :"
code "  ✅ CSV : Format tabulaire standard"
code "  ✅ JSON : Format structuré"
code "  ✅ CQL : Requêtes CQL"
code "  ⚠️  Parquet : Non supporté directement"
echo ""

highlight "Solution pour Parquet :"
code "  ✅ Spark : Convertir Parquet → CSV → DSBulk"
code "  ✅ Spark : Utiliser Spark-Cassandra-Connector directement"
code "  ✅ DSBulk : Utiliser CSV généré depuis Parquet"
echo ""

# ============================================
# Partie 2 : Vérification Installation DSBulk
# ============================================

echo ""
info "📋 Partie 2 : Vérification Installation DSBulk"
echo ""

DSBULK_BIN=""
if command -v dsbulk &> /dev/null; then
    DSBULK_BIN="dsbulk"
    success "DSBulk trouvé dans PATH"
elif [ -f "$INSTALL_DIR/binaire/dsbulk/bin/dsbulk" ]; then
    DSBULK_BIN="$INSTALL_DIR/binaire/dsbulk/bin/dsbulk"
    success "DSBulk trouvé dans binaire/dsbulk"
else
    warn "DSBulk n'est pas installé"
    info "Installation de DSBulk..."

    # Télécharger DSBulk
    DSBULK_VERSION="1.11.0"
    DSBULK_URL="https://downloads.datastax.com/dsbulk/dsbulk-${DSBULK_VERSION}.tar.gz"
    DSBULK_DIR="$INSTALL_DIR/binaire/dsbulk"

    mkdir -p "$DSBULK_DIR"

    info "Téléchargement de DSBulk ${DSBULK_VERSION}..."
    if [ ! -f "$INSTALL_DIR/software/dsbulk-${DSBULK_VERSION}.tar.gz" ]; then
        mkdir -p "$INSTALL_DIR/software"
        curl -L -o "$INSTALL_DIR/software/dsbulk-${DSBULK_VERSION}.tar.gz" "$DSBULK_URL" || {
            error "Impossible de télécharger DSBulk"
            warn "DSBulk sera simulé pour la démonstration"
            DSBULK_BIN=""
        }
    fi

    if [ -f "$INSTALL_DIR/software/dsbulk-${DSBULK_VERSION}.tar.gz" ]; then
        info "Extraction de DSBulk..."
        tar -xzf "$INSTALL_DIR/software/dsbulk-${DSBULK_VERSION}.tar.gz" -C "$DSBULK_DIR" --strip-components=1
        DSBULK_BIN="$DSBULK_DIR/bin/dsbulk"
        success "DSBulk installé"
    fi
fi

if [ -n "$DSBULK_BIN" ] && [ -f "$DSBULK_BIN" ]; then
    info "Vérification de la version DSBulk..."
    "$DSBULK_BIN" --version 2>&1 | head -3 || true
    success "DSBulk opérationnel"
else
    warn "DSBulk non disponible, démonstration avec exemples de commandes"
    DSBULK_BIN="dsbulk"  # Pour les exemples
fi

echo ""

# ============================================
# Partie 3 : DSBulk et Parquet - Analyse
# ============================================

echo ""
info "📋 Partie 3 : DSBulk et Parquet - Analyse"
echo ""

code "-- DSBulk ne supporte PAS directement Parquet"
code "  Formats supportés : CSV, JSON, CQL"
code "  Parquet : Format columnar binaire (non supporté)"
echo ""

code "-- Solution 1 : Conversion Parquet → CSV → DSBulk"
code "  Spark : Lire Parquet, écrire CSV"
code "  DSBulk : Importer CSV vers HCD"
code "  Avantage : Utilise DSBulk pour import optimisé"
code "  Inconvénient : Conversion intermédiaire"
echo ""

code "-- Solution 2 : Spark Direct (Recommandé)"
code "  Spark : Lire Parquet, écrire directement dans HCD"
code "  Spark-Cassandra-Connector : Intégration native"
code "  Avantage : Pas de conversion, performance optimale"
code "  Inconvénient : Nécessite Spark"
echo ""

highlight "Recommandation :"
code "  ✅ Pour Parquet : Utiliser Spark directement (déjà démontré)"
code "  ✅ Pour CSV/JSON : Utiliser DSBulk (performance optimale)"
code "  ✅ Pour migration : DSBulk avec CSV généré depuis Parquet"
echo ""

# ============================================
# Partie 4 : Démonstration DSBulk avec CSV
# ============================================

echo ""
info "📋 Partie 4 : Démonstration DSBulk avec CSV (Format Supporté)"
echo ""

code "-- Exemple 1 : Export depuis HCD vers CSV"
code "dsbulk unload -h localhost -k domirama2_poc -t operations_by_account"
code "  -url /tmp/export_dsbulk"
code "  -header true"
echo ""

if [ -n "$DSBULK_BIN" ] && [ -f "$DSBULK_BIN" ]; then
    info "Export de quelques lignes depuis HCD vers CSV..."

    # Créer un répertoire temporaire
    EXPORT_DIR="/tmp/export_dsbulk_$(date +%s)"
    mkdir -p "$EXPORT_DIR"

    # Export limité à 10 lignes pour la démo
    "$DSBULK_BIN" unload \
        -h localhost \
        -k domirama2_poc \
        -t operations_by_account \
        -url "$EXPORT_DIR" \
        -header true \
        -maxConcurrentQueries 1 \
        -query "SELECT code_si, contrat, date_op, numero_op, libelle, montant FROM operations_by_account WHERE code_si = 'DEMO_MV' AND contrat = 'DEMO_001' LIMIT 10" \
        2>&1 | tail -20 || warn "Export DSBulk échoué (peut nécessiter configuration)"

    if [ -f "$EXPORT_DIR/operations_by_account-000001.csv" ]; then
        success "Export CSV réussi"
        info "Aperçu du fichier CSV exporté..."
        head -5 "$EXPORT_DIR/operations_by_account-000001.csv" 2>/dev/null || true
        rm -rf "$EXPORT_DIR"
    else
        warn "Export CSV non disponible (configuration requise)"
    fi
else
    code "  (DSBulk non installé, commande d'exemple)"
fi

echo ""

code "-- Exemple 2 : Import depuis CSV vers HCD"
code "dsbulk load -h localhost -k domirama2_poc -t operations_by_account"
code "  -url /tmp/import_dsbulk/data.csv"
code "  -header true"
code "  -batchSize 100"
echo ""

highlight "Avantages DSBulk :"
code "  ✅ Performance : Optimisé pour bulk load"
code "  ✅ Gestion erreurs : Retry automatique"
code "  ✅ Monitoring : Statistiques détaillées"
code "  ✅ Formats : CSV, JSON supportés"
echo ""

# ============================================
# Partie 5 : Parquet → CSV → DSBulk (Workflow)
# ============================================

echo ""
info "📋 Partie 5 : Workflow Parquet → CSV → DSBulk"
echo ""

code "-- Étape 1 : Convertir Parquet en CSV avec Spark"
code "spark.read.parquet(\"/path/to/data.parquet\")"
code "  .write"
code "  .option(\"header\", \"true\")"
code "  .csv(\"/tmp/parquet_to_csv\")"
echo ""

code "-- Étape 2 : Importer CSV avec DSBulk"
code "dsbulk load -h localhost -k domirama2_poc -t operations_by_account"
code "  -url /tmp/parquet_to_csv"
code "  -header true"
echo ""

highlight "Workflow complet :"
code "  ✅ Parquet (source) → Spark (conversion) → CSV (intermédiaire) → DSBulk (import) → HCD"
code "  ⚠️  Nécessite conversion intermédiaire"
code "  💡 Alternative : Spark direct (déjà démontré)"
echo ""

# ============================================
# Partie 6 : Comparaison DSBulk vs Spark
# ============================================

echo ""
info "📊 Partie 6 : Comparaison DSBulk vs Spark"
echo ""

echo "┌─────────────────────────────────────────────────────────────┐"
echo "│  Comparaison : DSBulk vs Spark pour Import/Export            │"
echo "├─────────────────────────────────────────────────────────────┤"
echo "│                                                               │"
echo "│  DSBulk :                                                     │"
echo "│    Formats     : CSV, JSON, CQL                              │"
echo "│    Parquet     : ❌ Non supporté (nécessite conversion)      │"
echo "│    Performance : ✅ Excellente pour CSV/JSON                 │"
echo "│    Usage       : Bulk load, export, migration                │"
echo "│                                                               │"
echo "│  Spark :                                                      │"
echo "│    Formats     : Parquet, CSV, JSON, ORC, etc.               │"
echo "│    Parquet     : ✅ Support natif                            │"
echo "│    Performance : ✅ Excellente pour Parquet                  │"
echo "│    Usage       : ETL, transformation, analytics             │"
echo "│                                                               │"
echo "└─────────────────────────────────────────────────────────────┘"
echo ""

highlight "Recommandation :"
code "  ✅ Parquet → HCD : Spark directement (déjà démontré)"
code "  ✅ CSV/JSON → HCD : DSBulk (performance optimale)"
code "  ✅ Export HCD → CSV : DSBulk (performance optimale)"
code "  ✅ Export HCD → Parquet : Spark (format natif)"
echo ""

# ============================================
# Partie 7 : Démonstration Pratique
# ============================================

echo ""
info "📋 Partie 7 : Démonstration Pratique"
echo ""

code "-- Scénario : Migration depuis Parquet vers HCD"
echo ""

code "Option 1 : Spark Direct (Recommandé pour Parquet)"
code "  spark.read.parquet(\"/data/operations.parquet\")"
code "    .write"
code "    .format(\"org.apache.spark.sql.cassandra\")"
code "    .options(Map(\"keyspace\" -> \"domirama2_poc\", \"table\" -> \"operations_by_account\"))"
code "    .save()"
echo ""

code "Option 2 : Parquet → CSV → DSBulk"
code "  # Étape 1 : Conversion Parquet → CSV"
code "  spark.read.parquet(\"/data/operations.parquet\")"
code "    .write.csv(\"/tmp/operations.csv\")"
code ""
code "  # Étape 2 : Import CSV → HCD"
code "  dsbulk load -h localhost -k domirama2_poc -t operations_by_account"
code "    -url /tmp/operations.csv"
code "    -header true"
echo ""

highlight "Conclusion :"
code "  ✅ Pour Parquet : Spark direct (déjà démontré dans POC)"
code "  ✅ Pour CSV/JSON : DSBulk (performance optimale)"
code "  ✅ DSBulk + Parquet : Nécessite conversion intermédiaire"
echo ""

# ============================================
# Partie 8 : Résumé et Conclusion
# ============================================

echo ""
info "📋 Partie 8 : Résumé et Conclusion"
echo ""

echo "✅ DSBulk - Fonctionnalités :"
echo ""
echo "   1. Formats supportés"
echo "      → CSV : ✅ Supporté"
echo "      → JSON : ✅ Supporté"
echo "      → CQL : ✅ Supporté"
echo "      → Parquet : ❌ Non supporté directement"
echo ""
echo "   2. Cas d'usage"
echo "      → Bulk load depuis CSV/JSON"
echo "      → Export vers CSV/JSON"
echo "      → Migration de données"
echo ""
echo "   3. Parquet"
echo "      → Non supporté directement"
echo "      → Solution : Conversion Parquet → CSV → DSBulk"
echo "      → Alternative : Spark direct (recommandé)"
echo ""

echo "🎯 Recommandation pour Parquet :"
echo ""
echo "   ✅ Utiliser Spark directement (déjà démontré dans POC)"
echo "   ✅ Spark-Cassandra-Connector : Intégration native"
echo "   ✅ Performance optimale : Pas de conversion intermédiaire"
echo "   ✅ Format natif : Parquet supporté nativement"
echo ""

echo "🎯 Recommandation pour CSV/JSON :"
echo ""
echo "   ✅ Utiliser DSBulk (performance optimale)"
echo "   ✅ Bulk load optimisé"
echo "   ✅ Gestion erreurs automatique"
echo "   ✅ Monitoring intégré"
echo ""

echo ""
success "✅ Démonstration DSBulk terminée"
info ""
info "💡 Points clés démontrés :"
code "  ✅ DSBulk : Formats CSV, JSON, CQL supportés"
code "  ⚠️  Parquet : Non supporté directement par DSBulk"
code "  ✅ Solution Parquet : Spark direct (recommandé)"
code "  ✅ Alternative : Conversion Parquet → CSV → DSBulk"
code "  ✅ Comparaison : DSBulk vs Spark"
echo ""
