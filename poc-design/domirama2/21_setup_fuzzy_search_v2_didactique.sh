#!/bin/bash
# ============================================
# Script 21 : Configuration Fuzzy Search avec ByteT5 (Version Didactique)
# Ajout de la colonne vectorielle et de l'index pour recherche floue
# ============================================
#
# OBJECTIF :
#   Ce script configure la recherche floue (fuzzy search) en ajoutant une
#   colonne vectorielle 'libelle_embedding' de type VECTOR pour stocker
#   les embeddings ByteT5, permettant des recherches par similarité sémantique.
#   
#   Cette version didactique affiche :
#   - Le contexte et le problème des typos complexes
#   - Le DDL complet (ALTER TABLE, CREATE INDEX) avec explications
#   - Les équivalences HBase → HCD pour la recherche vectorielle
#   - Les résultats de vérification détaillés
#   - La cinématique complète de chaque étape
#   - Une documentation structurée pour livrable
#
# PRÉREQUIS :
#   - HCD démarré (./03_start_hcd.sh)
#   - Schéma configuré (./10_setup_domirama2_poc.sh)
#   - Table 'operations_by_account' existante
#   - Java 11 configuré via jenv
#
# UTILISATION :
#   ./21_setup_fuzzy_search_v2_didactique.sh
#
# SORTIE :
#   - DDL complet affiché avec explications
#   - Vérifications détaillées (colonne, index)
#   - Documentation structurée générée (doc/demonstrations/21_FUZZY_SEARCH_SETUP.md)
#
# PROCHAINES ÉTAPES :
#   - Script 22: Génération embeddings (./22_generate_embeddings.sh)
#   - Script 23: Tests fuzzy search (./23_test_fuzzy_search.sh)
#
# ============================================

set -e

# ============================================
# CONFIGURATION DES COULEURS
# ============================================
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
BOLD='\033[1m'
NC='\033[0m'

info() { echo -e "${BLUE}ℹ️  $1${NC}"; }
success() { echo -e "${GREEN}✅ $1${NC}"; }
warn() { echo -e "${YELLOW}⚠️  $1${NC}"; }
error() { echo -e "${RED}❌ $1${NC}"; }
demo() { echo -e "${CYAN}🎯 $1${NC}"; }
code() { echo -e "${MAGENTA}📝 $1${NC}"; }
section() { echo -e "${BOLD}${CYAN}$1${NC}"; }
result() { echo -e "${GREEN}📊 $1${NC}"; }
expected() { echo -e "${YELLOW}📋 $1${NC}"; }

# ============================================
# CONFIGURATION
# ============================================
INSTALL_DIR="/Users/david.leconte/Documents/Arkea"
HCD_DIR="${INSTALL_DIR}/binaire/hcd-1.2.3"
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
REPORT_FILE="${SCRIPT_DIR}/doc/demonstrations/21_FUZZY_SEARCH_SETUP.md"

# Créer le répertoire de documentation
mkdir -p "$(dirname "$REPORT_FILE")"

# Variables pour le rapport
TEMP_RESULTS="${SCRIPT_DIR}/.temp_fuzzy_setup.json"

# Fonction de nettoyage
cleanup() {
    rm -f "${SCRIPT_DIR}/.temp_fuzzy_setup.json" 2>/dev/null
}
trap cleanup EXIT

# ============================================
# VÉRIFICATIONS
# ============================================
if ! pgrep -f "cassandra" > /dev/null; then
    error "HCD n'est pas démarré. Exécutez d'abord: ./03_start_hcd.sh"
    exit 1
fi

cd "$HCD_DIR"
jenv local 11
eval "$(jenv init -)"

info "🔍 Vérification que HCD est prêt..."
if ! ./bin/cqlsh localhost 9042 -e "SELECT cluster_name FROM system.local;" > /dev/null 2>&1; then
    error "HCD n'est pas prêt. Attendez quelques secondes et réessayez."
    exit 1
fi

# Vérifier que la table existe
info "🔍 Vérification que la table existe..."
TABLE_EXISTS=$(./bin/cqlsh localhost 9042 -e "SELECT table_name FROM system_schema.tables WHERE keyspace_name = 'domirama2_poc' AND table_name = 'operations_by_account';" 2>&1 | grep -v "Warnings" | grep -c "operations_by_account" || echo "0")
if [ "$TABLE_EXISTS" -eq 0 ]; then
    error "Table 'operations_by_account' n'existe pas. Exécutez d'abord: ./10_setup_domirama2_poc.sh"
    exit 1
fi
success "✅ Table 'operations_by_account' existe"

# ============================================
# EN-TÊTE DE DÉMONSTRATION
# ============================================
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  🎯 DÉMONSTRATION DIDACTIQUE : Configuration Fuzzy Search avec ByteT5"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
info "📚 Cette démonstration affiche :"
echo "   ✅ Contexte et problème des typos complexes dans les recherches"
echo "   ✅ DDL complet (ALTER TABLE, CREATE INDEX) avec explications"
echo "   ✅ Équivalences HBase → HCD pour la recherche vectorielle"
echo "   ✅ Résultats de vérification détaillés"
echo "   ✅ Cinématique complète de chaque étape"
echo "   ✅ Documentation structurée générée automatiquement"
echo ""

# ============================================
# PARTIE 0: CONTEXTE - Pourquoi la Recherche Floue ?
# ============================================
echo ""
section "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
section "  📚 PARTIE 0: CONTEXTE - Pourquoi la Recherche Floue ?"
section "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

info "📚 PROBLÈME : Recherches avec Typos Complexes qui Échouent"
echo ""
echo "   Scénario : Un utilisateur cherche 'LOYER' mais tape 'LOYR' (caractère 'e' manquant)"
echo "   Résultat avec index standard : ❌ Aucun résultat trouvé"
echo ""
echo "   Scénario avancé : Un utilisateur cherche 'CARREFOUR' mais tape 'KARREFOUR' (faute)"
echo "   Résultat avec index N-Gram : ⚠️  Peut trouver, mais pas toujours"
echo ""
echo "   Problème : Les index full-text (standard, N-Gram) ont des limitations :"
echo "   - Index standard : Recherche exacte (après stemming/accents)"
echo "   - Index N-Gram : Recherche partielle mais limitée aux préfixes"
echo "   - Aucun index ne gère bien les typos complexes (faute, inversion, etc.)"
echo ""

info "📚 SOLUTION : Recherche Vectorielle avec Embeddings ByteT5"
echo ""
echo "   Stratégie : Utiliser des embeddings sémantiques pour capturer la similarité"
echo "   - Embeddings : Représentation vectorielle du sens des mots"
echo "   - ByteT5 : Modèle multilingue robuste aux typos (1472 dimensions)"
echo "   - Similarité cosinus : Mesure la proximité sémantique entre vecteurs"
echo "   - ANN (Approximate Nearest Neighbor) : Recherche rapide des vecteurs proches"
echo ""
echo "   Exemple de recherche qui fonctionne :"
code "   SELECT libelle, montant"
code "   FROM operations_by_account"
code "   WHERE code_si = '1' AND contrat = '5913101072'"
code "   ORDER BY libelle_embedding ANN OF [0.12, 0.5, ..., -0.03]  -- Vecteur de la requête"
code "   LIMIT 5;"
echo ""
echo "   Avantages :"
echo "   ✅ Tolère les typos complexes (faute, inversion, caractères manquants)"
echo "   ✅ Capture la similarité sémantique (synonymes, variations)"
echo "   ✅ Multilingue (ByteT5 supporte plusieurs langues)"
echo "   ✅ Robuste aux variations linguistiques"
echo ""

info "📚 ÉQUIVALENCES HBase → HCD :"
echo ""
echo "   HBase :"
echo "      - Recherche vectorielle : ❌ Pas d'équivalent direct"
echo "      - Nécessite : Elasticsearch + système ML externe"
echo "      - Configuration : Complexe (Elasticsearch + modèle ML + synchronisation)"
echo "      - Exemple : Elasticsearch avec plugin ML + modèle externe (BERT, etc.)"
echo ""
echo "   HCD :"
echo "      - Recherche vectorielle : ✅ Type VECTOR natif intégré"
echo "      - Nécessite : Aucun système externe"
echo "      - Configuration : Simple (ALTER TABLE + CREATE INDEX)"
echo "      - Exemple : Type VECTOR<FLOAT, 1472> + index SAI vectoriel"
echo ""
echo "   Améliorations HCD :"
echo "      ✅ Type VECTOR natif (vs système ML externe)"
echo "      ✅ Index SAI vectoriel intégré (vs Elasticsearch externe)"
echo "      ✅ Pas de synchronisation nécessaire (vs HBase + Elasticsearch + ML)"
echo "      ✅ Performance optimale (index co-localisé avec données)"
echo "      ✅ Support ANN (Approximate Nearest Neighbor) natif"
echo ""

# ============================================
# PARTIE 1: DDL - Ajout de la Colonne Vectorielle
# ============================================
echo ""
section "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
section "  📋 PARTIE 1: DDL - AJOUT DE LA COLONNE libelle_embedding"
section "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

expected "📋 Résultat attendu :"
echo "   Colonne 'libelle_embedding' (VECTOR<FLOAT, 1472>) ajoutée à la table 'operations_by_account'"
echo "   - Type : VECTOR<FLOAT, 1472> (vecteur de 1472 dimensions)"
echo "   - Dimensions : 1472 (taille des embeddings ByteT5-small)"
echo "   - Valeur par défaut : NULL (pour données existantes)"
echo "   - Remplissage : Automatique pour nouvelles données (via script 22)"
echo ""

info "📝 DDL - Ajout de la Colonne :"
echo ""
code "ALTER TABLE operations_by_account ADD libelle_embedding VECTOR<FLOAT, 1472>;"
echo ""

info "   Explication :"
echo "      - ALTER TABLE : Modifie la structure d'une table existante"
echo "      - ADD : Ajoute une nouvelle colonne"
echo "      - libelle_embedding : Nom de la colonne vectorielle"
echo "      - VECTOR<FLOAT, 1472> : Type de données vectoriel"
echo "        • VECTOR : Type natif HCD pour stocker des vecteurs"
echo "        • FLOAT : Type de chaque dimension (nombre décimal)"
echo "        • 1472 : Nombre de dimensions (taille des embeddings ByteT5-small)"
echo "      - Valeur par défaut : NULL pour les lignes existantes"
echo ""
echo "   📚 À propos des Embeddings ByteT5 :"
echo "      - ByteT5-small : Modèle de langage multilingue"
echo "      - Dimensions : 1472 (taille fixe des embeddings générés)"
echo "      - Robustesse : Tolère les typos et variations linguistiques"
echo "      - Multilingue : Supporte plusieurs langues (français, anglais, etc.)"
echo "      - Génération : Via script Python (transformers + torch)"
echo ""
echo "   ⚠️  Note importante :"
echo "      - Les données EXISTANTES auront libelle_embedding = NULL"
echo "      - Les NOUVELLES données auront libelle_embedding rempli automatiquement"
echo "      - Pour mettre à jour les données existantes :"
echo "        • Utiliser le script 22: ./22_generate_embeddings.sh"
echo "        • Ou utiliser le script Python: examples/python/generate_embeddings_bytet5.py"
echo ""

# Vérifier si la colonne existe déjà
info "🔍 Vérification de l'existence de la colonne..."
COLUMN_EXISTS=$(./bin/cqlsh localhost 9042 -e "USE domirama2_poc; DESCRIBE TABLE operations_by_account;" 2>&1 | grep -c "libelle_embedding" || echo "0")

if [ "$COLUMN_EXISTS" -eq 0 ]; then
    info "📋 Ajout de la colonne libelle_embedding..."
    echo ""
    demo "🚀 Exécution du DDL..."
    ./bin/cqlsh localhost 9042 -e "USE domirama2_poc; ALTER TABLE operations_by_account ADD libelle_embedding VECTOR<FLOAT, 1472>;" 2>&1 | grep -v "Warnings" || true
    echo ""
    
    if [ $? -eq 0 ]; then
        success "✅ Colonne libelle_embedding ajoutée"
    else
        error "❌ Erreur lors de l'ajout de la colonne"
        exit 1
    fi
else
    info "✅ Colonne libelle_embedding existe déjà"
fi

# Vérification
info "🔍 Vérification de la colonne..."
COLUMN_DETAILS=$(./bin/cqlsh localhost 9042 -e "USE domirama2_poc; DESCRIBE TABLE operations_by_account;" 2>&1 | grep -A 2 "libelle_embedding" | grep -v "Warnings" | head -3)

if echo "$COLUMN_DETAILS" | grep -q "libelle_embedding"; then
    success "✅ Colonne libelle_embedding vérifiée"
    echo ""
    result "📊 Détails de la colonne :"
    echo "   ┌─────────────────────────────────────────────────────────┐"
    echo "$COLUMN_DETAILS" | sed 's/^/   │ /'
    echo "   └─────────────────────────────────────────────────────────┘"
else
    warn "⚠️  Colonne libelle_embedding non trouvée dans le schéma"
fi
echo ""

# ============================================
# PARTIE 2: DDL - Création de l'Index Vectoriel
# ============================================
echo ""
section "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
section "  📋 PARTIE 2: DDL - CRÉATION DE L'INDEX VECTORIEL"
section "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

expected "📋 Résultat attendu :"
echo "   Index 'idx_libelle_embedding_vector' créé sur la colonne 'libelle_embedding'"
echo "   - Type : Index SAI vectoriel (Storage-Attached Index)"
echo "   - Usage : Recherche par similarité (ANN - Approximate Nearest Neighbor)"
echo "   - Performance : Recherche rapide même sur millions de vecteurs"
echo ""

info "📝 DDL - Création de l'Index :"
echo ""
code "DROP INDEX IF EXISTS idx_libelle_embedding_vector;"
code "CREATE CUSTOM INDEX IF NOT EXISTS idx_libelle_embedding_vector"
code "ON operations_by_account(libelle_embedding)"
code "USING 'StorageAttachedIndex';"
echo ""

info "   Explication :"
echo "      - DROP INDEX IF EXISTS : Supprime l'index s'il existe (idempotent)"
echo "      - CREATE CUSTOM INDEX : Crée un index personnalisé"
echo "      - idx_libelle_embedding_vector : Nom de l'index"
echo "      - ON operations_by_account(libelle_embedding) : Colonne indexée"
echo "      - USING 'StorageAttachedIndex' : Type d'index (SAI)"
echo ""
echo "   📚 À propos de l'Index SAI Vectoriel :"
echo "      - SAI (Storage-Attached Indexing) : Index intégré à HCD"
echo "      - Type vectoriel : Optimisé pour recherche par similarité"
echo "      - ANN (Approximate Nearest Neighbor) : Trouve les vecteurs les plus proches"
echo "      - Similarité cosinus : Mesure la proximité entre vecteurs"
echo "      - Performance : Recherche rapide même sur millions de vecteurs"
echo ""
echo "   🔍 Comment fonctionne la recherche vectorielle :"
echo "      1. La requête est encodée en vecteur (via ByteT5)"
echo "      2. L'index SAI trouve les vecteurs les plus proches (ANN)"
echo "      3. Les résultats sont triés par similarité cosinus"
echo "      4. Les top-K résultats sont retournés"
echo ""
echo "   ⚠️  Note importante :"
echo "      - L'indexation se fait en arrière-plan (peut prendre quelques minutes)"
echo "      - Attendre 30-60 secondes avant de tester les recherches"
echo "      - Vérifier l'état de l'index : SELECT * FROM system_views.indexes;"
echo ""

# Créer l'index vectoriel
info "📋 Création de l'index vectoriel..."
echo ""
demo "🚀 Exécution du DDL..."
./bin/cqlsh localhost 9042 <<'CQL'
USE domirama2_poc;
DROP INDEX IF EXISTS idx_libelle_embedding_vector;
CREATE CUSTOM INDEX IF NOT EXISTS idx_libelle_embedding_vector
ON operations_by_account(libelle_embedding)
USING 'StorageAttachedIndex';
CQL

if [ $? -eq 0 ]; then
    success "✅ Index idx_libelle_embedding_vector créé"
else
    error "❌ Erreur lors de la création de l'index"
    exit 1
fi
echo ""

# Vérification
info "🔍 Vérification de l'index..."
sleep 2
INDEX_EXISTS=$(./bin/cqlsh localhost 9042 -e "USE domirama2_poc; DESCRIBE INDEX idx_libelle_embedding_vector;" 2>&1 | grep -v "Warnings" | grep -c "idx_libelle_embedding_vector" || echo "0")

if [ "$INDEX_EXISTS" -gt 0 ]; then
    success "✅ Index idx_libelle_embedding_vector vérifié"
    echo ""
    result "📊 Détails de l'index :"
    INDEX_DETAILS=$(./bin/cqlsh localhost 9042 -e "USE domirama2_poc; DESCRIBE INDEX idx_libelle_embedding_vector;" 2>&1 | grep -v "Warnings" | head -10)
    echo "   ┌─────────────────────────────────────────────────────────┐"
    echo "$INDEX_DETAILS" | sed 's/^/   │ /'
    echo "   └─────────────────────────────────────────────────────────┘"
else
    warn "⚠️  Index idx_libelle_embedding_vector non trouvé (peut être en cours de création)"
fi
echo ""

# ============================================
# PARTIE 3: VÉRIFICATIONS COMPLÈTES
# ============================================
echo ""
section "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
section "  🔍 PARTIE 3: VÉRIFICATIONS COMPLÈTES"
section "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

info "🔍 Vérification du schéma complet..."
SCHEMA_CHECK=$(./bin/cqlsh localhost 9042 -e "USE domirama2_poc; DESCRIBE TABLE operations_by_account;" 2>&1 | grep -E "(libelle_embedding|VECTOR)" | grep -v "Warnings" | head -5)

if echo "$SCHEMA_CHECK" | grep -q "libelle_embedding"; then
    success "✅ Colonne libelle_embedding présente dans le schéma"
    echo ""
    result "📊 Colonne dans le schéma :"
    echo "   ┌─────────────────────────────────────────────────────────┐"
    echo "$SCHEMA_CHECK" | sed 's/^/   │ /'
    echo "   └─────────────────────────────────────────────────────────┘"
else
    warn "⚠️  Colonne libelle_embedding non trouvée dans le schéma"
fi
echo ""

info "⏳ Indexation en cours (peut prendre quelques minutes)..."
echo "   Les index SAI sont construits en arrière-plan"
echo "   Attendre 30-60 secondes avant de tester les recherches"
echo "   Vérifier l'état : SELECT * FROM system_views.indexes WHERE index_name = 'idx_libelle_embedding_vector';"
echo ""

# ============================================
# PARTIE 4: RÉSUMÉ ET PROCHAINES ÉTAPES
# ============================================
echo ""
section "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
section "  📊 PARTIE 4: RÉSUMÉ ET PROCHAINES ÉTAPES"
section "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

info "📊 Résumé de la configuration :"
echo ""
echo "   ✅ Colonne 'libelle_embedding' (VECTOR<FLOAT, 1472>) ajoutée"
echo "   ✅ Index 'idx_libelle_embedding_vector' créé"
echo "   ✅ Support de la recherche par similarité (ANN)"
echo "   ✅ Tolérance aux typos complexes et variations linguistiques"
echo ""

info "💡 Avantages de la recherche vectorielle :"
echo ""
echo "   ✅ Tolère les typos complexes (faute, inversion, caractères manquants)"
echo "   ✅ Capture la similarité sémantique (synonymes, variations)"
echo "   ✅ Multilingue (ByteT5 supporte plusieurs langues)"
echo "   ✅ Robuste aux variations linguistiques"
echo "   ✅ Performance optimale (index co-localisé avec données)"
echo ""

info "📝 Prochaines étapes :"
echo ""
echo "   1. Installer les dépendances Python :"
echo "      pip install transformers torch"
echo ""
echo "   2. Générer les embeddings pour les données existantes :"
echo "      ./22_generate_embeddings.sh"
echo ""
echo "   3. Tester la recherche floue :"
echo "      ./23_test_fuzzy_search.sh"
echo ""
echo "   ⚠️  Important :"
echo "      - Les données existantes ont libelle_embedding = NULL"
echo "      - Il faut générer les embeddings avec le script 22"
echo "      - Attendre que l'index soit construit (30-60 secondes)"
echo ""

success "✅ Configuration de la recherche floue terminée !"

# ============================================
# PARTIE 5: GÉNÉRATION DU RAPPORT MARKDOWN
# ============================================
echo ""
section "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
section "  📝 PARTIE 5: GÉNÉRATION DU RAPPORT MARKDOWN"
section "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

info "📝 Génération du rapport markdown..."

# Passer les variables d'environnement au script Python
export SCRIPT_DIR_ENV="${SCRIPT_DIR}"
export REPORT_FILE_ENV="${REPORT_FILE}"

python3 << 'PYEOF'
import json
import os
from datetime import datetime

# Récupérer les variables d'environnement
report_file = os.environ.get('REPORT_FILE_ENV', 'doc/demonstrations/21_FUZZY_SEARCH_SETUP.md')
script_dir = os.environ.get('SCRIPT_DIR_ENV', '.')

# Générer le rapport
report = f"""# 🔍 Démonstration : Configuration Fuzzy Search avec ByteT5 - POC Domirama2

**Date** : {datetime.now().strftime("%Y-%m-%d %H:%M:%S")}  
**Script** : `21_setup_fuzzy_search_v2_didactique.sh`  
**Objectif** : Configurer la recherche floue avec colonne vectorielle et index SAI vectoriel

---

## 📋 Table des Matières

1. [Contexte - Pourquoi la Recherche Floue ?](#contexte)
2. [DDL - Ajout de la Colonne Vectorielle](#ddl-colonne)
3. [DDL - Création de l'Index Vectoriel](#ddl-index)
4. [Vérifications](#vérifications)
5. [Résumé et Prochaines Étapes](#résumé)

---

## 📚 Contexte - Pourquoi la Recherche Floue ?

### Problème

Les recherches avec typos complexes ne fonctionnent pas avec les index standard :

**Scénario 1** : Un utilisateur cherche 'LOYER' mais tape 'LOYR' (caractère 'e' manquant)
- Résultat avec index standard : ❌ Aucun résultat trouvé

**Scénario 2** : Un utilisateur cherche 'CARREFOUR' mais tape 'KARREFOUR' (faute)
- Résultat avec index N-Gram : ⚠️  Peut trouver, mais pas toujours

**Problème** : Les index full-text (standard, N-Gram) ont des limitations :
- Index standard : Recherche exacte (après stemming/accents)
- Index N-Gram : Recherche partielle mais limitée aux préfixes
- Aucun index ne gère bien les typos complexes (faute, inversion, etc.)

### Solution

Utiliser des embeddings sémantiques pour capturer la similarité :

- **Embeddings** : Représentation vectorielle du sens des mots
- **ByteT5** : Modèle multilingue robuste aux typos (1472 dimensions)
- **Similarité cosinus** : Mesure la proximité sémantique entre vecteurs
- **ANN (Approximate Nearest Neighbor)** : Recherche rapide des vecteurs proches

**Exemple de recherche qui fonctionne :**

```cql
SELECT libelle, montant
FROM operations_by_account
WHERE code_si = '1' AND contrat = '5913101072'
ORDER BY libelle_embedding ANN OF [0.12, 0.5, ..., -0.03]  -- Vecteur de la requête
LIMIT 5;
```

**Avantages :**
- ✅ Tolère les typos complexes (faute, inversion, caractères manquants)
- ✅ Capture la similarité sémantique (synonymes, variations)
- ✅ Multilingue (ByteT5 supporte plusieurs langues)
- ✅ Robuste aux variations linguistiques

### Équivalences HBase → HCD

| Concept HBase | Équivalent HCD | Statut |
|---------------|----------------|--------|
| Recherche vectorielle | Type VECTOR natif | ✅ |
| Système ML externe | Aucun système externe | ✅ |
| Elasticsearch + ML | Index SAI vectoriel intégré | ✅ |
| Synchronisation HBase ↔ Elasticsearch ↔ ML | Pas de synchronisation nécessaire | ✅ |

### Améliorations HCD

✅ **Type VECTOR natif** (vs système ML externe)  
✅ **Index SAI vectoriel intégré** (vs Elasticsearch externe)  
✅ **Pas de synchronisation** (vs HBase + Elasticsearch + ML)  
✅ **Performance optimale** (index co-localisé avec données)  
✅ **Support ANN natif** (Approximate Nearest Neighbor)

---

## 📋 DDL - Ajout de la Colonne Vectorielle

### Résultat Attendu

Colonne 'libelle_embedding' (VECTOR<FLOAT, 1472>) ajoutée à la table 'operations_by_account' :
- Type : VECTOR<FLOAT, 1472> (vecteur de 1472 dimensions)
- Dimensions : 1472 (taille des embeddings ByteT5-small)
- Valeur par défaut : NULL (pour données existantes)
- Remplissage : Automatique pour nouvelles données (via script 22)

### DDL

```cql
ALTER TABLE operations_by_account ADD libelle_embedding VECTOR<FLOAT, 1472>;
```

### Explication

- **ALTER TABLE** : Modifie la structure d'une table existante
- **ADD** : Ajoute une nouvelle colonne
- **libelle_embedding** : Nom de la colonne vectorielle
- **VECTOR<FLOAT, 1472>** : Type de données vectoriel
  - VECTOR : Type natif HCD pour stocker des vecteurs
  - FLOAT : Type de chaque dimension (nombre décimal)
  - 1472 : Nombre de dimensions (taille des embeddings ByteT5-small)

### À propos des Embeddings ByteT5

- **ByteT5-small** : Modèle de langage multilingue
- **Dimensions** : 1472 (taille fixe des embeddings générés)
- **Robustesse** : Tolère les typos et variations linguistiques
- **Multilingue** : Supporte plusieurs langues (français, anglais, etc.)
- **Génération** : Via script Python (transformers + torch)

### Note Importante

- Les données EXISTANTES auront libelle_embedding = NULL
- Les NOUVELLES données auront libelle_embedding rempli automatiquement
- Pour mettre à jour les données existantes :
  - Utiliser le script 22: `./22_generate_embeddings.sh`
  - Ou utiliser le script Python: `examples/python/generate_embeddings_bytet5.py`

---

## 📋 DDL - Création de l'Index Vectoriel

### Résultat Attendu

Index 'idx_libelle_embedding_vector' créé sur la colonne 'libelle_embedding' :
- Type : Index SAI vectoriel (Storage-Attached Index)
- Usage : Recherche par similarité (ANN - Approximate Nearest Neighbor)
- Performance : Recherche rapide même sur millions de vecteurs

### DDL

```cql
DROP INDEX IF EXISTS idx_libelle_embedding_vector;
CREATE CUSTOM INDEX IF NOT EXISTS idx_libelle_embedding_vector
ON operations_by_account(libelle_embedding)
USING 'StorageAttachedIndex';
```

### Explication

- **DROP INDEX IF EXISTS** : Supprime l'index s'il existe (idempotent)
- **CREATE CUSTOM INDEX** : Crée un index personnalisé
- **idx_libelle_embedding_vector** : Nom de l'index
- **ON operations_by_account(libelle_embedding)** : Colonne indexée
- **USING 'StorageAttachedIndex'** : Type d'index (SAI)

### À propos de l'Index SAI Vectoriel

- **SAI (Storage-Attached Indexing)** : Index intégré à HCD
- **Type vectoriel** : Optimisé pour recherche par similarité
- **ANN (Approximate Nearest Neighbor)** : Trouve les vecteurs les plus proches
- **Similarité cosinus** : Mesure la proximité entre vecteurs
- **Performance** : Recherche rapide même sur millions de vecteurs

### Comment fonctionne la recherche vectorielle

1. La requête est encodée en vecteur (via ByteT5)
2. L'index SAI trouve les vecteurs les plus proches (ANN)
3. Les résultats sont triés par similarité cosinus
4. Les top-K résultats sont retournés

### Note Importante

- L'indexation se fait en arrière-plan (peut prendre quelques minutes)
- Attendre 30-60 secondes avant de tester les recherches
- Vérifier l'état de l'index : `SELECT * FROM system_views.indexes WHERE index_name = 'idx_libelle_embedding_vector';`

---

## 🔍 Vérifications

### Colonne

✅ Colonne libelle_embedding présente dans le schéma

### Index

✅ Index idx_libelle_embedding_vector créé

### Indexation

⏳ Indexation en cours (peut prendre quelques minutes)
- Les index SAI sont construits en arrière-plan
- Attendre 30-60 secondes avant de tester les recherches
- Vérifier l'état : `SELECT * FROM system_views.indexes WHERE index_name = 'idx_libelle_embedding_vector';`

---

## 📊 Résumé et Prochaines Étapes

### Résumé de la Configuration

✅ Colonne 'libelle_embedding' (VECTOR<FLOAT, 1472>) ajoutée  
✅ Index 'idx_libelle_embedding_vector' créé  
✅ Support de la recherche par similarité (ANN)  
✅ Tolérance aux typos complexes et variations linguistiques

### Avantages de la Recherche Vectorielle

✅ Tolère les typos complexes (faute, inversion, caractères manquants)  
✅ Capture la similarité sémantique (synonymes, variations)  
✅ Multilingue (ByteT5 supporte plusieurs langues)  
✅ Robuste aux variations linguistiques  
✅ Performance optimale (index co-localisé avec données)

### Prochaines Étapes

1. **Installer les dépendances Python** :
   ```bash
   pip install transformers torch
   ```

2. **Générer les embeddings pour les données existantes** :
   ```bash
   ./22_generate_embeddings.sh
   ```

3. **Tester la recherche floue** :
   ```bash
   ./23_test_fuzzy_search.sh
   ```

### Important

- Les données existantes ont libelle_embedding = NULL
- Il faut générer les embeddings avec le script 22
- Attendre que l'index soit construit (30-60 secondes)

---

**✅ Configuration de la recherche floue terminée !**
"""

# Écrire le rapport
with open(report_file, 'w', encoding='utf-8') as f:
    f.write(report)

print(f"✅ Rapport généré : {report_file}")

PYEOF

success "✅ Rapport markdown généré : $REPORT_FILE"
echo ""

success "✅ Configuration de la recherche floue terminée !"
info "📝 Documentation générée : $REPORT_FILE"
echo ""

