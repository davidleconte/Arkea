#!/bin/bash
# ============================================
# Script : Vérification des Embeddings dans la Table
# Vérifie si les embeddings sont déjà générés dans la table operations_by_account
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

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
INSTALL_DIR="${ARKEA_HOME:-$(cd "$SCRIPT_DIR/../../.." && pwd)}"
HCD_DIR="${HCD_DIR:-${INSTALL_DIR}/binaire/hcd-1.2.3}"
HCD_HOST="${HCD_HOST:-localhost}"
HCD_PORT="${HCD_PORT:-9042}"

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  🔍 VÉRIFICATION DES EMBEDDINGS DANS LA TABLE"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Vérifier que HCD est démarré
if ! nc -z "$HCD_HOST" "$HCD_PORT" 2>/dev/null; then
    error "HCD n'est pas accessible sur $HCD_HOST:$HCD_PORT"
    exit 1
fi

cd "$HCD_DIR"
set +u
eval "$(jenv init -)" 2>/dev/null || true
set -u

# Vérifier si la colonne libelle_embedding existe
info "📋 Vérification de la colonne libelle_embedding..."
COLUMN_CHECK=$(./bin/cqlsh "$HCD_HOST" "$HCD_PORT" -e "DESCRIBE TABLE domirama2_poc.operations_by_account;" 2>&1 | grep -c "libelle_embedding" || echo "0")

if [ "$COLUMN_CHECK" -eq 0 ]; then
    warn "⚠️  La colonne libelle_embedding n'existe pas dans la table."
    warn "⚠️  Exécutez d'abord: ./21_setup_fuzzy_search.sh"
    exit 1
fi

success "✅ La colonne libelle_embedding existe dans la table."
echo ""

# Compter le nombre total d'opérations et celles avec embeddings
info "📊 Statistiques des embeddings..."
STATS_OUTPUT=$(./bin/cqlsh "$HCD_HOST" "$HCD_PORT" -e "SELECT COUNT(*) as total, COUNT(libelle_embedding) as avec_embedding FROM domirama2_poc.operations_by_account;" 2>&1)

# Parser les résultats CQL (format: total | avec_embedding suivi de la ligne de données)
# La ligne de données est après les séparateurs "---"
DATA_LINE=$(echo "$STATS_OUTPUT" | awk '/^---/{getline; print; exit}' | head -1)

if [ -n "$DATA_LINE" ]; then
    # Extraire les valeurs numériques
    TOTAL=$(echo "$DATA_LINE" | awk -F'|' '{print $1}' | grep -oE '[0-9]+' | head -1)
    AVEC_EMBEDDING=$(echo "$DATA_LINE" | awk -F'|' '{print $2}' | grep -oE '[0-9]+' | head -1)

    if [ -n "$TOTAL" ] && [ -n "$AVEC_EMBEDDING" ]; then
        echo "   Total d'opérations dans la table : $TOTAL"
        echo "   Opérations avec embeddings : $AVEC_EMBEDDING"

        if [ "$TOTAL" -gt 0 ]; then
            PERCENTAGE=$(echo "scale=2; $AVEC_EMBEDDING * 100 / $TOTAL" | bc 2>/dev/null || echo "0")
            echo "   Pourcentage avec embeddings : ${PERCENTAGE}%"
        fi

        echo ""

        if [ "$AVEC_EMBEDDING" -eq 0 ]; then
            warn "⚠️  Aucun embedding trouvé dans la table."
            warn "⚠️  Exécutez: ./22_generate_embeddings.sh pour générer les embeddings."
        elif [ "$AVEC_EMBEDDING" -lt "$TOTAL" ]; then
            SANS_EMBEDDING=$((TOTAL - AVEC_EMBEDDING))
            warn "⚠️  Seulement $AVEC_EMBEDDING sur $TOTAL opérations ont des embeddings ($SANS_EMBEDDING manquants)."
            warn "⚠️  Exécutez: ./22_generate_embeddings.sh pour compléter les embeddings."
        else
            success "✅ Tous les embeddings sont générés ($AVEC_EMBEDDING/$TOTAL) !"
        fi
    else
        warn "⚠️  Impossible de parser les statistiques. Affichage brut :"
        echo "$STATS_OUTPUT"
    fi
else
    warn "⚠️  Impossible de trouver les données. Affichage brut :"
    echo "$STATS_OUTPUT"
fi

echo ""

# Vérifier un exemple d'opération avec embedding
info "📝 Vérification d'un exemple d'embedding..."
# Récupérer une opération et vérifier si elle a un embedding
SAMPLE_OUTPUT=$(./bin/cqlsh "$HCD_HOST" "$HCD_PORT" -e "SELECT code_si, contrat, libelle FROM domirama2_poc.operations_by_account LIMIT 1;" 2>&1)

if echo "$SAMPLE_OUTPUT" | grep -q "code_si"; then
    CODE_SI=$(echo "$SAMPLE_OUTPUT" | awk '/^---/{getline; print; exit}' | awk -F'|' '{print $1}' | xargs)
    CONTRAT=$(echo "$SAMPLE_OUTPUT" | awk '/^---/{getline; print; exit}' | awk -F'|' '{print $2}' | xargs)
    LIBELLE=$(echo "$SAMPLE_OUTPUT" | awk '/^---/{getline; print; exit}' | awk -F'|' '{print $3}' | xargs)

    if [ -n "$CODE_SI" ] && [ -n "$CONTRAT" ]; then
        # Vérifier si cette opération a un embedding
        EMBEDDING_CHECK=$(./bin/cqlsh "$HCD_HOST" "$HCD_PORT" -e "SELECT libelle_embedding FROM domirama2_poc.operations_by_account WHERE code_si = '$CODE_SI' AND contrat = '$CONTRAT' LIMIT 1;" 2>&1)

        if echo "$EMBEDDING_CHECK" | grep -qE "\[.*\]|vector"; then
            echo "   Exemple trouvé :"
            echo "   - Code SI: $CODE_SI"
            echo "   - Contrat: $CONTRAT"
            echo "   - Libellé: $LIBELLE"
            success "✅ Cette opération a un embedding."
        else
            echo "   Exemple trouvé :"
            echo "   - Code SI: $CODE_SI"
            echo "   - Contrat: $CONTRAT"
            echo "   - Libellé: $LIBELLE"
            warn "⚠️  Cette opération n'a pas d'embedding."
        fi
    fi
fi

echo ""
success "🎉 Vérification terminée !"
echo ""
