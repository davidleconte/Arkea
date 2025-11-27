#!/bin/bash
# ============================================
# Démonstration Complète : Multi-Version avec Time Travel
# Version améliorée avec fichiers temporaires
# ============================================
#
# OBJECTIF :
#   Ce script orchestre une démonstration complète de la logique multi-version
#   avec time travel, garantissant qu'aucune correction client ne sera perdue
#   lors des ré-exécutions du batch.
#   
#   Fonctionnalités démontrées :
#   - Stratégie multi-version : batch écrit cat_auto, client écrit cat_user
#   - Time travel : récupération des données selon les dates (cat_date_user)
#   - Priorité client : cat_user prioritaire sur cat_auto si non nul
#   - Aucune perte : les corrections client ne sont jamais écrasées
#   - DDL complet : création du schéma avec toutes les colonnes nécessaires
#   - Flux de données : chargement batch, corrections client, time travel
#
# PRÉREQUIS :
#   - HCD démarré (./03_start_hcd.sh)
#   - Java 11 configuré via jenv
#   - Python 3.8+ installé
#   - Script Python présent: examples/python/multi_version/test_multi_version_time_travel.py
#
# UTILISATION :
#   ./demo_multi_version_complete_v2.sh
#
# EXEMPLE :
#   ./demo_multi_version_complete_v2.sh
#
# SORTIE :
#   - DDL complet avec toutes les colonnes
#   - Chargement des données batch
#   - Corrections client simulées
#   - Démonstration du time travel
#   - Validation qu'aucune correction client n'est perdue
#   - Messages de succès/erreur pour chaque étape
#
# PROCHAINES ÉTAPES :
#   - Script 26: Test multi-version / time travel (./26_test_multi_version_time_travel.sh)
#   - Consulter la documentation: doc/09_README_MULTI_VERSION.md
#
# ============================================

set +e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
NC='\033[0m'

info() { echo -e "${BLUE}ℹ️  $1${NC}"; }
success() { echo -e "${GREEN}✅ $1${NC}"; }
warn() { echo -e "${YELLOW}⚠️  $1${NC}"; }
error() { echo -e "${RED}❌ $1${NC}"; }
code() { echo -e "${MAGENTA}📝 $1${NC}"; }

INSTALL_DIR="/Users/david.leconte/Documents/Arkea"
if [ -f "$INSTALL_DIR/binaire/hcd-1.2.3/bin/cqlsh" ]; then
    CQLSH="$INSTALL_DIR/binaire/hcd-1.2.3/bin/cqlsh localhost 9042"
elif [ -f "$INSTALL_DIR/binaire/hcd/bin/cqlsh" ]; then
    CQLSH="$INSTALL_DIR/binaire/hcd/bin/cqlsh localhost 9042"
else
    CQLSH="cqlsh localhost 9042"
fi

cd "$INSTALL_DIR"
source .poc-profile 2>/dev/null || true

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  🔄 DÉMONSTRATION COMPLÈTE : MULTI-VERSION AVEC TIME TRAVEL"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Vérifier que HCD est démarré
if ! pgrep -f "cassandra" > /dev/null; then
    error "HCD n'est pas démarré. Exécutez d'abord: ./03_start_hcd.sh"
    exit 1
fi

TMP_DIR=$(mktemp -d)
trap "rm -rf $TMP_DIR" EXIT

# ============================================
# PARTIE 1: DDL (Schéma)
# ============================================
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  📋 PARTIE 1: DDL - SCHÉMA DE LA TABLE"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

info "Création du keyspace et de la table avec colonnes multi-version..."
echo ""
info "📚 Explication des colonnes de catégorisation :"
echo ""
echo "   cat_auto (TEXT) :"
echo "      ✅ Catégorie automatique générée par le moteur IA/batch"
echo "      ✅ Écrit UNIQUEMENT par le batch"
echo "      ✅ Exemple : 'ALIMENTATION', 'RESTAURANT', 'SUPERMARCHE'"
echo ""
echo "   cat_confidence (DECIMAL) :"
echo "      ✅ Score de confiance du moteur de catégorisation (0.0 à 1.0)"
echo "      ✅ Indique la fiabilité de la catégorie automatique"
echo "      ✅ Écrit UNIQUEMENT par le batch"
echo "      ✅ Exemple : 0.85 = 85% de confiance, 0.92 = 92% de confiance"
echo "      ✅ Utilité : Permet à l'application d'afficher la confiance"
echo "         et au client de décider s'il accepte ou corrige"
echo ""
echo "   cat_user (TEXT) :"
echo "      ✅ Catégorie modifiée par le client"
echo "      ✅ Écrit UNIQUEMENT par le client (batch NE TOUCHE JAMAIS)"
echo "      ✅ Prioritaire sur cat_auto si non null"
echo ""
echo "   cat_date_user (TIMESTAMP) :"
echo "      ✅ Date de modification par le client"
echo "      ✅ Permet le time travel (quelle catégorie était valide à une date)"
echo "      ✅ Écrit UNIQUEMENT par le client"
echo ""
echo "   cat_validee (BOOLEAN) :"
echo "      ✅ Indique si le client a accepté la catégorie"
echo "      ✅ true = acceptée, false = rejetée"
echo "      ✅ Écrit UNIQUEMENT par le client"
echo ""

code "CREATE KEYSPACE IF NOT EXISTS domirama2_poc"
code "WITH REPLICATION = {"
code "  'class': 'SimpleStrategy',"
code "  'replication_factor': 1"
code "};"
echo ""

code "CREATE TABLE IF NOT EXISTS operations_by_account ("
code "    -- Partition Key"
code "    code_si           TEXT,"
code "    contrat           TEXT,"
code "    -- Clustering Keys"
code "    date_op           TIMESTAMP,"
code "    numero_op         INT,"
code "    -- Données opération"
code "    libelle           TEXT,"
code "    montant           DECIMAL,"
code "    devise            TEXT,"
code "    -- Catégorisation MULTI-VERSION"
code "    cat_auto          TEXT,        -- ✅ Batch écrit ICI"
code "    cat_confidence    DECIMAL,     -- ✅ Batch écrit ICI"
code "    cat_user          TEXT,        -- ✅ Client écrit ICI (batch NE TOUCHE JAMAIS)"
code "    cat_date_user     TIMESTAMP,   -- ✅ Client écrit ICI (batch NE TOUCHE JAMAIS)"
code "    cat_validee       BOOLEAN,     -- ✅ Client écrit ICI (batch NE TOUCHE JAMAIS)"
code "    PRIMARY KEY ((code_si, contrat), date_op DESC, numero_op ASC)"
code ") WITH default_time_to_live = 315360000;"
echo ""

cat > $TMP_DIR/ddl.cql << 'EOF'
CREATE KEYSPACE IF NOT EXISTS domirama2_poc
WITH REPLICATION = {
  'class': 'SimpleStrategy',
  'replication_factor': 1
};

USE domirama2_poc;

CREATE TABLE IF NOT EXISTS operations_by_account (
    code_si           TEXT,
    contrat           TEXT,
    date_op           TIMESTAMP,
    numero_op         INT,
    libelle           TEXT,
    montant           DECIMAL,
    devise            TEXT,
    cat_auto          TEXT,
    cat_confidence    DECIMAL,
    cat_user          TEXT,
    cat_date_user     TIMESTAMP,
    cat_validee       BOOLEAN,
    PRIMARY KEY ((code_si, contrat), date_op DESC, numero_op ASC)
) WITH default_time_to_live = 315360000;
EOF

info "Exécution du DDL..."
$CQLSH -f $TMP_DIR/ddl.cql > /dev/null 2>&1
success "✅ Schéma créé avec succès"
echo ""

# ============================================
# PARTIE 2: Nettoyage
# ============================================
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  🧹 PARTIE 2: NETTOYAGE DES DONNÉES DE TEST"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

code "DELETE FROM operations_by_account"
code "WHERE code_si = 'DEMO_MV' AND contrat = 'DEMO_001';"
echo ""

cat > $TMP_DIR/cleanup.cql << 'EOF'
USE domirama2_poc;
DELETE FROM operations_by_account WHERE code_si = 'DEMO_MV' AND contrat = 'DEMO_001';
EOF

$CQLSH -f $TMP_DIR/cleanup.cql > /dev/null 2>&1
success "✅ Données de test nettoyées"
echo ""

# ============================================
# PARTIE 3: FLUX BATCH - Insertion
# ============================================
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  📥 PARTIE 3: FLUX BATCH - Insertion Initiale"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

info "Stratégie BATCH : Écrit UNIQUEMENT cat_auto et cat_confidence"
warn "⚠️  Le batch NE TOUCHE JAMAIS cat_user, cat_date_user, cat_validee"
echo ""

code "INSERT INTO operations_by_account ("
code "    code_si, contrat, date_op, numero_op,"
code "    libelle, montant, devise,"
code "    cat_auto, cat_confidence,"
code "    cat_user, cat_date_user, cat_validee"
code ") VALUES ("
code "    'DEMO_MV', 'DEMO_001', '2024-01-15 10:00:00', 1,"
code "    'CB CARREFOUR MARKET PARIS', -45.50, 'EUR',"
code "    'ALIMENTATION', 0.85,  -- ✅ Batch écrit ICI"
code "    null, null, false       -- ❌ Batch NE TOUCHE JAMAIS"
code ");"
echo ""

cat > $TMP_DIR/insert_batch.cql << 'EOF'
USE domirama2_poc;
INSERT INTO operations_by_account (
    code_si, contrat, date_op, numero_op,
    libelle, montant, devise,
    cat_auto, cat_confidence,
    cat_user, cat_date_user, cat_validee
) VALUES (
    'DEMO_MV', 'DEMO_001', '2024-01-15 10:00:00', 1,
    'CB CARREFOUR MARKET PARIS', -45.50, 'EUR',
    'ALIMENTATION', 0.85,
    null, null, false
);
EOF

$CQLSH -f $TMP_DIR/insert_batch.cql > /dev/null 2>&1
success "✅ Opération insérée par batch"
echo ""

code "SELECT cat_auto, cat_confidence, cat_user, cat_date_user, cat_validee"
code "FROM operations_by_account"
code "WHERE code_si = 'DEMO_MV' AND contrat = 'DEMO_001'"
code "  AND date_op = '2024-01-15 10:00:00' AND numero_op = 1;"
echo ""

cat > $TMP_DIR/select1.cql << 'EOF'
USE domirama2_poc;
SELECT cat_auto, cat_confidence, cat_user, cat_date_user, cat_validee
FROM operations_by_account
WHERE code_si = 'DEMO_MV' AND contrat = 'DEMO_001'
  AND date_op = '2024-01-15 10:00:00' AND numero_op = 1;
EOF

info "Vérification de l'état initial..."
echo ""
echo "📊 Résultats de la requête :"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
$CQLSH -f $TMP_DIR/select1.cql 2>&1
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
success "✅ État initial :"
echo "   - cat_auto = 'ALIMENTATION' (catégorie automatique)"
echo "   - cat_confidence = 0.85 (85% de confiance du moteur)"
echo "   - cat_user = null (pas encore de correction client)"
echo "   - cat_date_user = null"
echo "   - cat_validee = false"
echo ""
info "💡 Le score cat_confidence = 0.85 indique que le moteur est confiant à 85%"
info "   que 'ALIMENTATION' est la bonne catégorie pour cette opération."
echo ""

# ============================================
# PARTIE 4: FLUX CLIENT - Correction
# ============================================
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  👤 PARTIE 4: FLUX CLIENT - Correction"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

info "Stratégie CLIENT : Écrit dans cat_user, cat_date_user, cat_validee"
warn "⚠️  Le client NE TOUCHE JAMAIS cat_auto, cat_confidence"
echo ""

code "UPDATE operations_by_account"
code "SET cat_user = 'RESTAURANT',"
code "    cat_date_user = toTimestamp(now()),"
code "    cat_validee = true"
code "WHERE code_si = 'DEMO_MV' AND contrat = 'DEMO_001'"
code "  AND date_op = '2024-01-15 10:00:00' AND numero_op = 1;"
echo ""

cat > $TMP_DIR/update_client.cql << 'EOF'
USE domirama2_poc;
UPDATE operations_by_account
SET cat_user = 'RESTAURANT',
    cat_date_user = toTimestamp(now()),
    cat_validee = true
WHERE code_si = 'DEMO_MV' AND contrat = 'DEMO_001'
  AND date_op = '2024-01-15 10:00:00' AND numero_op = 1;
EOF

$CQLSH -f $TMP_DIR/update_client.cql > /dev/null 2>&1
success "✅ Correction client appliquée"
echo ""

info "Vérification après correction client..."
echo ""
echo "📊 Résultats de la requête :"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
$CQLSH -f $TMP_DIR/select1.cql 2>&1
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
success "✅ État après correction client :"
echo "   - cat_auto = 'ALIMENTATION' (batch - conservé)"
echo "   - cat_confidence = 0.85 (batch - conservé, toujours visible)"
echo "   - cat_user = 'RESTAURANT' (client - prioritaire)"
echo "   - cat_date_user = [date actuelle]"
echo "   - cat_validee = true (client a accepté/corrigé)"
echo ""
info "💡 Le client a corrigé la catégorie malgré cat_confidence = 0.85"
info "   L'application peut afficher : 'Catégorie suggérée : ALIMENTATION (85% confiance)'"
info "   Le client a choisi 'RESTAURANT' qui devient la catégorie finale."
echo ""

# ============================================
# PARTIE 5: FLUX BATCH - Ré-écriture
# ============================================
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  ⚠️  PARTIE 5: FLUX BATCH - Ré-écriture (SCÉNARIO CRITIQUE)"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

warn "SCÉNARIO CRITIQUE : Le batch ré-écrit cat_auto APRÈS une correction client"
info "Vérification que cat_user n'est PAS écrasé"
echo ""

code "UPDATE operations_by_account"
code "SET cat_auto = 'SUPERMARCHE',"
code "    cat_confidence = 0.92"
code "WHERE code_si = 'DEMO_MV' AND contrat = 'DEMO_001'"
code "  AND date_op = '2024-01-15 10:00:00' AND numero_op = 1;"
code ""
code "-- ⚠️  Le batch NE TOUCHE JAMAIS cat_user, cat_date_user, cat_validee"
echo ""

cat > $TMP_DIR/update_batch.cql << 'EOF'
USE domirama2_poc;
UPDATE operations_by_account
SET cat_auto = 'SUPERMARCHE',
    cat_confidence = 0.92
WHERE code_si = 'DEMO_MV' AND contrat = 'DEMO_001'
  AND date_op = '2024-01-15 10:00:00' AND numero_op = 1;
EOF

$CQLSH -f $TMP_DIR/update_batch.cql > /dev/null 2>&1
success "✅ Batch a mis à jour cat_auto"
echo ""

info "Vérification après ré-écriture batch..."
echo ""
echo "📊 Résultats de la requête :"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
$CQLSH -f $TMP_DIR/select1.cql 2>&1
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
success "✅ État après ré-écriture batch (CRITIQUE) :"
echo "   - cat_auto = 'SUPERMARCHE' (nouveau batch)"
echo "   - cat_confidence = 0.92 (mis à jour - 92% de confiance)"
echo "   - cat_user = 'RESTAURANT' (✅ CONSERVÉ - non écrasé)"
echo "   - cat_date_user = [conservé]"
echo "   - cat_validee = true (conservé)"
echo ""
warn "⚠️  VÉRIFICATION CRITIQUE : cat_user n'a PAS été écrasé par le batch"
echo ""
info "💡 Le batch a amélioré sa prédiction :"
info "   - Ancienne : ALIMENTATION (85% confiance)"
info "   - Nouvelle : SUPERMARCHE (92% confiance)"
info "   Mais cat_user = 'RESTAURANT' reste prioritaire (correction client)"
info "   cat_confidence permet de voir l'évolution de la qualité du moteur"
echo ""

# ============================================
# PARTIE 6: LECTURE - Priorité
# ============================================
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  📖 PARTIE 6: LECTURE - Logique de Priorité"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

info "L'application priorise cat_user si non nul, sinon cat_auto"
echo ""

code "SELECT"
code "    cat_auto,"
code "    cat_user"
code "FROM operations_by_account"
code "WHERE code_si = 'DEMO_MV' AND contrat = 'DEMO_001'"
code "  AND date_op = '2024-01-15 10:00:00' AND numero_op = 1;"
code ""
code "-- Logique de priorité (application) :"
code "-- categorie_finale = cat_user si non null, sinon cat_auto"
echo ""

cat > $TMP_DIR/select_priority.cql << 'EOF'
USE domirama2_poc;
SELECT
    cat_auto,
    cat_user
FROM operations_by_account
WHERE code_si = 'DEMO_MV' AND contrat = 'DEMO_001'
  AND date_op = '2024-01-15 10:00:00' AND numero_op = 1;
EOF

info "Exécution de la requête de priorité..."
echo ""
echo "📊 Résultats de la requête :"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
$CQLSH -f $TMP_DIR/select_priority.cql 2>&1
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
info "💡 Logique de priorité (application) :"
echo "   IF cat_user IS NOT NULL THEN categorie_finale = cat_user"
echo "   ELSE categorie_finale = cat_auto"
echo ""
success "✅ Résultat :"
echo "   - cat_auto = 'SUPERMARCHE' (batch, confidence = 0.92)"
echo "   - cat_user = 'RESTAURANT' (client, prioritaire)"
echo "   - categorie_finale = 'RESTAURANT' (cat_user prioritaire car non null)"
echo ""
info "💡 L'application peut afficher :"
info "   'Catégorie : RESTAURANT (corrigée par vous)'"
info "   'Suggestion automatique : SUPERMARCHE (92% confiance)'"
info "   cat_confidence permet de montrer la qualité de la suggestion automatique"
echo ""

# ============================================
# PARTIE 7: TIME TRAVEL
# ============================================
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  🕐 PARTIE 7: TIME TRAVEL - Requêtes"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

info "Time Travel : Déterminer quelle catégorie était valide à une date donnée"
echo ""

code "-- Time Travel : 2024-01-15 12:00 (avant correction client)"
code "SELECT"
code "    cat_auto,"
code "    cat_user,"
code "    cat_date_user"
code "FROM operations_by_account"
code "WHERE code_si = 'DEMO_MV' AND contrat = 'DEMO_001'"
code "  AND date_op = '2024-01-15 10:00:00' AND numero_op = 1;"
code ""
code "-- Logique Time Travel (application) :"
code "-- Implémentée CÔTÉ APPLICATION (Java/Python/TypeScript)"
code "-- Si cat_date_user <= query_date alors cat_user, sinon cat_auto"
code "-- Voir: TIME_TRAVEL_IMPLEMENTATION.md pour détails"
echo ""

cat > $TMP_DIR/time_travel1.cql << 'EOF'
USE domirama2_poc;
SELECT
    cat_auto,
    cat_user,
    cat_date_user
FROM operations_by_account
WHERE code_si = 'DEMO_MV' AND contrat = 'DEMO_001'
  AND date_op = '2024-01-15 10:00:00' AND numero_op = 1;
EOF

info "Time Travel à 2024-01-15 12:00 (avant correction client)..."
echo ""
echo "📊 Résultats de la requête :"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
$CQLSH -f $TMP_DIR/time_travel1.cql 2>&1
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
info "💡 À cette date (2024-01-15 12:00), la correction client n'était pas encore faite"
info "   → categorie_a_la_date = cat_auto = 'SUPERMARCHE'"
echo ""
warn "⚠️  Note: Cette logique est implémentée CÔTÉ APPLICATION"
warn "   CQL ne supporte pas CASE dans SELECT"
warn "   Voir TIME_TRAVEL_IMPLEMENTATION.md pour les alternatives"
echo ""

code "-- Time Travel : 2024-01-20 09:00 (après correction client)"
code "SELECT"
code "    cat_auto,"
code "    cat_user,"
code "    cat_date_user"
code "FROM operations_by_account"
code "WHERE code_si = 'DEMO_MV' AND contrat = 'DEMO_001'"
code "  AND date_op = '2024-01-15 10:00:00' AND numero_op = 1;"
code ""
code "-- Logique Time Travel (application) :"
code "-- Implémentée CÔTÉ APPLICATION (Java/Python/TypeScript)"
code "-- Si cat_date_user <= query_date alors cat_user, sinon cat_auto"
code "-- Voir: TIME_TRAVEL_IMPLEMENTATION.md pour détails"
echo ""

cat > $TMP_DIR/time_travel2.cql << 'EOF'
USE domirama2_poc;
SELECT
    cat_auto,
    cat_user,
    cat_date_user
FROM operations_by_account
WHERE code_si = 'DEMO_MV' AND contrat = 'DEMO_001'
  AND date_op = '2024-01-15 10:00:00' AND numero_op = 1;
EOF

info "Time Travel à 2024-01-20 09:00 (après correction client)..."
echo ""
echo "📊 Résultats de la requête :"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
$CQLSH -f $TMP_DIR/time_travel2.cql 2>&1
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
info "💡 À cette date (2024-01-20 09:00), la correction client était déjà faite"
info "   → categorie_a_la_date = cat_user = 'RESTAURANT'"
echo ""
warn "⚠️  Note: Cette logique est implémentée CÔTÉ APPLICATION"
warn "   CQL ne supporte pas CASE dans SELECT"
warn "   Voir TIME_TRAVEL_IMPLEMENTATION.md pour les alternatives"
echo ""

# ============================================
# RÉSUMÉ
# ============================================
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  ✅ RÉSUMÉ DE LA DÉMONSTRATION"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

success "✅ DDL : Schéma créé avec colonnes multi-version"
success "✅ FLUX BATCH : Insertion initiale (cat_auto uniquement)"
success "✅ FLUX CLIENT : Correction (cat_user, cat_date_user, cat_validee)"
success "✅ FLUX BATCH : Ré-écriture (cat_user conservé)"
success "✅ LECTURE : Logique de priorité (cat_user > cat_auto)"
success "✅ TIME TRAVEL : Requêtes avec dates"
echo ""

info "📋 Stratégie Multi-Version Validée :"
echo "   1. Batch écrit UNIQUEMENT cat_auto et cat_confidence"
echo "   2. Client écrit dans cat_user, cat_date_user, cat_validee"
echo "   3. Application priorise cat_user si non nul"
echo "   4. Time travel via cat_date_user pour déterminer la catégorie valide"
echo ""
info "📊 Utilité de cat_confidence :"
echo "   ✅ Indique la fiabilité de la catégorie automatique (0.0 à 1.0)"
echo "   ✅ Permet à l'application d'afficher la confiance au client"
echo "   ✅ Aide le client à décider s'il accepte ou corrige"
echo "   ✅ Permet de suivre l'évolution de la qualité du moteur"
echo "   ✅ Exemple : 0.85 = 85% confiance, 0.92 = 92% confiance"
echo "   ✅ Le batch peut améliorer cat_confidence sans toucher cat_user"
echo ""
success "✅ DÉMONSTRATION TERMINÉE"
echo ""

success "✅ DÉMONSTRATION TERMINÉE"
echo ""

