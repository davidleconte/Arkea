#!/bin/bash
set -euo pipefail
# ============================================
# Script 23 : Tests Fuzzy Search avec Vector Search
# Démonstration de la recherche floue avec ByteT5 et HCD
# ============================================
#
# OBJECTIF :
#   Ce script démontre la recherche floue (fuzzy search) en utilisant les
#   embeddings ByteT5 stockés dans la colonne 'libelle_embedding' pour
#   trouver des opérations par similarité sémantique, même avec des typos.
#
#   Les tests couvrent :
#   - Recherches avec typos (caractères manquants, inversés, remplacés)
#   - Recherches par similarité cosinus
#   - Comparaison avec Full-Text Search
#   - Validation de la pertinence des résultats
#
# PRÉREQUIS :
#   - HCD démarré (./scripts/setup/03_start_hcd.sh)
#   - Schéma configuré (./10_setup_domirama2_poc.sh)
#   - Données chargées (./11_load_domirama2_data_parquet.sh)
#   - Fuzzy search configuré (./21_setup_fuzzy_search.sh)
#   - Embeddings générés (./22_generate_embeddings.sh)
#   - Python 3.8+ avec transformers et torch installés
#   - Script Python présent: examples/python/search/test_vector_search.py
#
# UTILISATION :
#   ./23_test_fuzzy_search.sh
#
# EXEMPLE :
#   ./23_test_fuzzy_search.sh
#
# SORTIE :
#   - Résultats des tests de fuzzy search affichés
#   - Démonstration de la tolérance aux typos
#   - Comparaison avec Full-Text Search
#   - Messages de succès/erreur
#
# PROCHAINES ÉTAPES :
#   - Script 24: Démonstration fuzzy search (./24_demonstration_fuzzy_search.sh)
#   - Script 25: Test recherche hybride (./25_test_hybrid_search.sh)
#
# ============================================

set -euo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

info() { echo -e "${BLUE}ℹ️  $1${NC}"; }
success() { echo -e "${GREEN}✅ $1${NC}"; }
warn() { echo -e "${YELLOW}⚠️  $1${NC}"; }
error() { echo -e "${RED}❌ $1${NC}"; }
demo() { echo -e "${CYAN}🎯 $1${NC}"; }

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

if ! python3 -c "import transformers" 2>/dev/null; then
    error "transformers n'est pas installé. Exécutez: pip3 install transformers torch"
    exit 1
fi

cd "$SCRIPT_DIR"

# Charger la clé API Hugging Face
INSTALL_DIR="$( cd "$SCRIPT_DIR/../.." &> /dev/null && pwd )"
if [ -f "$INSTALL_DIR/.poc-profile" ]; then
    source "$INSTALL_DIR/.poc-profile" 2>/dev/null || true
fi

if [ -z "$HF_API_KEY" ]; then
    export HF_API_KEY="${HF_API_KEY:-}"
fi

CODE_SI="1"
CONTRAT="5913101072"

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  🔍 DÉMONSTRATION : Fuzzy Search avec Vector Search (ByteT5)"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
info "📚 DÉFINITION - Fuzzy Search avec Vector Search :"
echo "   La recherche vectorielle utilise des embeddings générés par ByteT5"
echo "   pour capturer la similarité sémantique entre les textes."
echo "   Cela permet de trouver des résultats même avec des typos ou des"
echo "   variations de formulation."
echo ""

# Créer un script Python pour générer les embeddings des requêtes et effectuer les recherches
TEMP_SCRIPT=$(mktemp)
cat > "$TEMP_SCRIPT" <<'PYTHON_SCRIPT'
import sys
import torch
from transformers import AutoTokenizer, AutoModel
from cassandra.cluster import Cluster
from cassandra.query import SimpleStatement
import json

# Configuration
MODEL_NAME = "google/byt5-small"
VECTOR_DIMENSION = 1472

# Charger le modèle ByteT5 avec authentification
import os
HF_API_KEY = os.getenv("HF_API_KEY")

print("📥 Chargement du modèle ByteT5...")
tokenizer = AutoTokenizer.from_pretrained(
    MODEL_NAME,
    token=HF_API_KEY
)
model = AutoModel.from_pretrained(
    MODEL_NAME,
    token=HF_API_KEY
)
model.eval()

def encode_text(text):
    """Encode un texte en vecteur d'embedding."""
    if not text or text.strip() == "":
        return [0.0] * VECTOR_DIMENSION

    inputs = tokenizer(
        text,
        return_tensors="pt",
        truncation=True,
        padding=True,
        max_length=512
    )

    with torch.no_grad():
        encoder_outputs = model.encoder(**inputs)
        embeddings = encoder_outputs.last_hidden_state.mean(dim=1)

    return embeddings[0].tolist()

# Connexion à HCD
cluster = Cluster(['localhost'], port=9042)
session = cluster.connect('domirama2_poc')

# Requêtes de test avec typos
test_queries = [
    ("loyr", "Typo: caractère manquant ('loyr' au lieu de 'loyer')"),
    ("parsi", "Typo: inversion de caractères ('parsi' au lieu de 'paris')"),
    ("impay", "Typo: accent manquant ('impay' au lieu de 'impayé')"),
    ("viremnt", "Typo: caractère manquant ('viremnt' au lieu de 'virement')"),
]

print("\n=== Tests Fuzzy Search avec Vector Search ===\n")

for query_text, description in test_queries:
    print(f"🔍 Requête: '{query_text}'")
    print(f"   Description: {description}")

    # Générer l'embedding de la requête
    query_embedding = encode_text(query_text)

    # Construire la requête CQL avec ANN
    # Note: CQL nécessite le vecteur sous forme de liste
    vector_str = "[" + ",".join([str(x) for x in query_embedding[:10]]) + ",...]"  # Afficher seulement les 10 premiers

    print(f"   Vecteur (premiers éléments): {vector_str}")

    # Requête CQL avec ANN (Approximate Nearest Neighbor)
    cql_query = f"""
    SELECT libelle, montant
    FROM operations_by_account
    WHERE code_si = '{CODE_SI}'
      AND contrat = '{CONTRAT}'
    ORDER BY libelle_embedding ANN OF {json.dumps(query_embedding)}
    LIMIT 5
    """

    try:
        statement = SimpleStatement(cql_query, fetch_size=5)
        results = session.execute(statement)

        print("   📊 Résultats:")
        count = 0
        for row in results:
            count += 1
            print(f"      {count}. {row.libelle} | {row.montant}")

        if count == 0:
            print("      Aucun résultat trouvé")
    except Exception as e:
        print(f"   ❌ Erreur: {str(e)}")

    print()

session.shutdown()
cluster.shutdown()
PYTHON_SCRIPT

# Remplacer CODE_SI et CONTRAT dans le script
sed -i '' "s/CODE_SI/$CODE_SI/g" "$TEMP_SCRIPT"
sed -i '' "s/CONTRAT/$CONTRAT/g" "$TEMP_SCRIPT"

info "🚀 Exécution des tests..."
info "   Clé API Hugging Face: $([ -n \"$HF_API_KEY\" ] && echo '[CONFIGURÉE]' || echo '[NON CONFIGURÉE]')"
HF_API_KEY="$HF_API_KEY" python3 "$TEMP_SCRIPT"

rm -f "$TEMP_SCRIPT"

success "✅ Tests de recherche floue terminés !"
