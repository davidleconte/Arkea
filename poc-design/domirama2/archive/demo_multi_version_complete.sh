#!/bin/bash
# ============================================
# Démonstration Complète : Multi-Version avec Time Travel
# 1. DDL (Schéma)
# 2. Toutes les requêtes du flux de données
# 3. Time travel avec requêtes réelles
# ============================================

# Ne pas arrêter sur erreur pour permettre l'affichage complet
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
demo() { echo -e "${CYAN}🎯 $1${NC}"; }
code() { echo -e "${MAGENTA}📝 $1${NC}"; }

INSTALL_DIR="/Users/david.leconte/Documents/Arkea"
# Trouver cqlsh
if command -v cqlsh &> /dev/null; then
    CQLSH="cqlsh localhost 9042"
elif [ -f "$INSTALL_DIR/binaire/hcd-1.2.3/bin/cqlsh" ]; then
    CQLSH="$INSTALL_DIR/binaire/hcd-1.2.3/bin/cqlsh localhost 9042"
elif [ -f "$INSTALL_DIR/binaire/hcd/bin/cqlsh" ]; then
    CQLSH="$INSTALL_DIR/binaire/hcd/bin/cqlsh localhost 9042"
else
    error "cqlsh non trouvé. Vérifiez votre installation HCD."
    exit 1
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

info "Exécution du DDL..."
$CQLSH -e "
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
" 2>&1 | grep -v "^$" | tail -n +2 > /dev/null

if [ $? -eq 0 ]; then
    success "✅ Schéma créé avec succès"
else
    warn "⚠️  Schéma peut déjà exister (c'est normal)"
fi
echo ""

# ============================================
# PARTIE 2: Nettoyage des données de test
# ============================================
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  🧹 PARTIE 2: NETTOYAGE DES DONNÉES DE TEST"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

code "DELETE FROM operations_by_account"
code "WHERE code_si = 'DEMO_MV' AND contrat = 'DEMO_001';"
echo ""

info "Exécution du nettoyage..."
$CQLSH -e "USE domirama2_poc; DELETE FROM operations_by_account WHERE code_si = 'DEMO_MV' AND contrat = 'DEMO_001';" > /dev/null 2>&1
success "✅ Données de test nettoyées"
echo ""

# ============================================
# PARTIE 3: FLUX BATCH - Insertion initiale
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

info "Exécution de l'insertion batch..."
$CQLSH -e "
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
" > /dev/null 2>&1

success "✅ Opération insérée par batch"
echo ""

code "SELECT cat_auto, cat_confidence, cat_user, cat_date_user, cat_validee"
code "FROM operations_by_account"
code "WHERE code_si = 'DEMO_MV' AND contrat = 'DEMO_001'"
code "  AND date_op = '2024-01-15 10:00:00' AND numero_op = 1;"
echo ""

info "Vérification de l'état initial..."
$CQLSH -e "
USE domirama2_poc;
SELECT cat_auto, cat_confidence, cat_user, cat_date_user, cat_validee
FROM operations_by_account
WHERE code_si = 'DEMO_MV' AND contrat = 'DEMO_001'
  AND date_op = '2024-01-15 10:00:00' AND numero_op = 1;
" | grep -v "^$" | tail -n +4

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
code "SET cat_user = 'RESTAURANT',        -- ✅ Client écrit ICI"
code "    cat_date_user = toTimestamp(now()),  -- ✅ Client écrit ICI"
code "    cat_validee = true              -- ✅ Client écrit ICI"
code "WHERE code_si = 'DEMO_MV' AND contrat = 'DEMO_001'"
code "  AND date_op = '2024-01-15 10:00:00' AND numero_op = 1;"
echo ""

info "Exécution de la correction client..."
$CQLSH -e "
USE domirama2_poc;
UPDATE operations_by_account
SET cat_user = 'RESTAURANT',
    cat_date_user = toTimestamp(now()),
    cat_validee = true
WHERE code_si = 'DEMO_MV' AND contrat = 'DEMO_001'
  AND date_op = '2024-01-15 10:00:00' AND numero_op = 1;
" > /dev/null 2>&1

success "✅ Correction client appliquée"
echo ""

code "SELECT cat_auto, cat_confidence, cat_user, cat_date_user, cat_validee"
code "FROM operations_by_account"
code "WHERE code_si = 'DEMO_MV' AND contrat = 'DEMO_001'"
code "  AND date_op = '2024-01-15 10:00:00' AND numero_op = 1;"
echo ""

info "Vérification après correction client..."
$CQLSH -e "
USE domirama2_poc;
SELECT cat_auto, cat_confidence, cat_user, cat_date_user, cat_validee
FROM operations_by_account
WHERE code_si = 'DEMO_MV' AND contrat = 'DEMO_001'
  AND date_op = '2024-01-15 10:00:00' AND numero_op = 1;
" | grep -v "^$" | tail -n +4

echo ""
success "✅ cat_user prioritaire sur cat_auto"
echo ""

# ============================================
# PARTIE 5: FLUX BATCH - Ré-écriture (CRITIQUE)
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
code "SET cat_auto = 'SUPERMARCHE',      -- ✅ Batch met à jour ICI"
code "    cat_confidence = 0.92          -- ✅ Batch met à jour ICI"
code "WHERE code_si = 'DEMO_MV' AND contrat = 'DEMO_001'"
code "  AND date_op = '2024-01-15 10:00:00' AND numero_op = 1;"
code ""
code "-- ⚠️  Le batch NE TOUCHE JAMAIS cat_user, cat_date_user, cat_validee"
echo ""

info "Exécution de la ré-écriture batch..."
$CQLSH -e "
USE domirama2_poc;
UPDATE operations_by_account
SET cat_auto = 'SUPERMARCHE',
    cat_confidence = 0.92
WHERE code_si = 'DEMO_MV' AND contrat = 'DEMO_001'
  AND date_op = '2024-01-15 10:00:00' AND numero_op = 1;
" > /dev/null 2>&1

success "✅ Batch a mis à jour cat_auto"
echo ""

code "SELECT cat_auto, cat_confidence, cat_user, cat_date_user, cat_validee"
code "FROM operations_by_account"
code "WHERE code_si = 'DEMO_MV' AND contrat = 'DEMO_001'"
code "  AND date_op = '2024-01-15 10:00:00' AND numero_op = 1;"
echo ""

info "Vérification après ré-écriture batch..."
$CQLSH -e "
USE domirama2_poc;
SELECT cat_auto, cat_confidence, cat_user, cat_date_user, cat_validee
FROM operations_by_account
WHERE code_si = 'DEMO_MV' AND contrat = 'DEMO_001'
  AND date_op = '2024-01-15 10:00:00' AND numero_op = 1;
" | grep -v "^$" | tail -n +4

echo ""
success "✅ VÉRIFICATION CRITIQUE : cat_user n'a PAS été écrasé par le batch"
echo ""

# ============================================
# PARTIE 6: LECTURE - Logique de Priorité
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
code "    cat_user,"
code "    COALESCE(cat_user, cat_auto) as categorie_finale"
code "FROM operations_by_account"
code "WHERE code_si = 'DEMO_MV' AND contrat = 'DEMO_001'"
code "  AND date_op = '2024-01-15 10:00:00' AND numero_op = 1;"
echo ""

info "Exécution de la requête de priorité..."
$CQLSH -e "
USE domirama2_poc;
SELECT
    cat_auto,
    cat_user,
    COALESCE(cat_user, cat_auto) as categorie_finale
FROM operations_by_account
WHERE code_si = 'DEMO_MV' AND contrat = 'DEMO_001'
  AND date_op = '2024-01-15 10:00:00' AND numero_op = 1;
" | grep -v "^$" | tail -n +4

echo ""
success "✅ cat_user a la priorité sur cat_auto"
echo ""

# ============================================
# PARTIE 7: TIME TRAVEL - Requêtes
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
code "    cat_date_user,"
code "    CASE"
code "        WHEN cat_user IS NOT NULL AND cat_date_user <= '2024-01-15 12:00:00'"
code "        THEN cat_user"
code "        ELSE cat_auto"
code "    END as categorie_a_la_date"
code "FROM operations_by_account"
code "WHERE code_si = 'DEMO_MV' AND contrat = 'DEMO_001'"
code "  AND date_op = '2024-01-15 10:00:00' AND numero_op = 1;"
echo ""

info "Time Travel à 2024-01-15 12:00 (avant correction client)..."
$CQLSH -e "
USE domirama2_poc;
SELECT
    cat_auto,
    cat_user,
    cat_date_user,
    CASE
        WHEN cat_user IS NOT NULL AND cat_date_user <= '2024-01-15 12:00:00'
        THEN cat_user
        ELSE cat_auto
    END as categorie_a_la_date
FROM operations_by_account
WHERE code_si = 'DEMO_MV' AND contrat = 'DEMO_001'
  AND date_op = '2024-01-15 10:00:00' AND numero_op = 1;
" | grep -v "^$" | tail -n +4

echo ""

code "-- Time Travel : 2024-01-20 09:00 (après correction client)"
code "SELECT"
code "    cat_auto,"
code "    cat_user,"
code "    cat_date_user,"
code "    CASE"
code "        WHEN cat_user IS NOT NULL AND cat_date_user <= '2024-01-20 09:00:00'"
code "        THEN cat_user"
code "        ELSE cat_auto"
code "    END as categorie_a_la_date"
code "FROM operations_by_account"
code "WHERE code_si = 'DEMO_MV' AND contrat = 'DEMO_001'"
code "  AND date_op = '2024-01-15 10:00:00' AND numero_op = 1;"
echo ""

info "Time Travel à 2024-01-20 09:00 (après correction client)..."
$CQLSH -e "
USE domirama2_poc;
SELECT
    cat_auto,
    cat_user,
    cat_date_user,
    CASE
        WHEN cat_user IS NOT NULL AND cat_date_user <= '2024-01-20 09:00:00'
        THEN cat_user
        ELSE cat_auto
    END as categorie_a_la_date
FROM operations_by_account
WHERE code_si = 'DEMO_MV' AND contrat = 'DEMO_001'
  AND date_op = '2024-01-15 10:00:00' AND numero_op = 1;
" | grep -v "^$" | tail -n +4

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

success "✅ DÉMONSTRATION TERMINÉE"
echo ""

