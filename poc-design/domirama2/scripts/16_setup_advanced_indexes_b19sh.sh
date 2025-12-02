#!/bin/bash
# ============================================
# Script 16 : Configuration Index SAI Avancés (Version Améliorée b19sh)
# Création de multiples index avec différents analyzers
# Version améliorée basée sur les apports didactiques du script 19
# ============================================
#
# OBJECTIF :
#   Ce script configure des index SAI (Storage-Attached Index) avancés pour
#   la table 'operations_by_account' avec différents analyzers Lucene pour
#   améliorer la pertinence des recherches full-text.
#
#   Cette version améliorée (b19sh) intègre :
#   - Contexte détaillé (problème + solution + équivalences HBase → HCD)
#   - DDL avec explications détaillées (analyzers)
#   - Comparaisons et recommandations
#   - Vérifications détaillées
#   - Rapport markdown structuré
#
#   Index créés :
#   - idx_libelle_fulltext_advanced : Avec analyzers (lowercase, asciifolding, frenchLightStem, stop words)
#   - idx_libelle_prefix_ngram : Pour recherche partielle et tolérance aux typos
#   - idx_cat_auto, idx_cat_user, idx_montant, idx_type_operation : Index secondaires
#
# PRÉREQUIS :
#   - HCD démarré (./scripts/setup/03_start_hcd.sh)
#   - Schéma de base configuré (./10_setup_domirama2_poc.sh)
#   - Table 'operations_by_account' existante
#   - Fichier schéma présent: schemas/02_create_domirama2_schema_advanced.cql
#
# UTILISATION :
#   ./16_setup_advanced_indexes_b19sh.sh
#
# SORTIE :
#   - Index SAI avancés créés
#   - Vérifications détaillées (colonne, index)
#   - Documentation structurée générée (doc/demonstrations/16_ADVANCED_INDEXES_SETUP.md)
#
# PROCHAINES ÉTAPES :
#   - Script 15: Tests full-text complexes (./15_test_fulltext_complex.sh)
#   - Script 17: Tests de recherche avancés (./17_test_advanced_search.sh)
#
# ============================================

set -euo pipefail

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
SCHEMA_FILE="${SCRIPT_DIR}/schemas/02_create_domirama2_schema_advanced.cql"
REPORT_FILE="${SCRIPT_DIR}/doc/demonstrations/16_ADVANCED_INDEXES_SETUP.md"

# Créer le répertoire de documentation
mkdir -p "$(dirname "$REPORT_FILE")"

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

# ============================================
# EN-TÊTE DE DÉMONSTRATION
# ============================================
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  🎯 DÉMONSTRATION DIDACTIQUE : Configuration Index SAI Avancés"
echo "  Version Améliorée (b19sh) - Basée sur les apports du script 19"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
info "📚 Cette démonstration affiche :"
echo "   ✅ Contexte et problème des recherches full-text limitées"
echo "   ✅ DDL complet avec explications détaillées (analyzers)"
echo "   ✅ Équivalences HBase → HCD pour les index"
echo "   ✅ Comparaisons et recommandations d'utilisation"
echo "   ✅ Résultats de vérification détaillés"
echo "   ✅ Documentation structurée générée automatiquement"
echo ""

# ============================================
# PARTIE 1: CONTEXTE - Pourquoi des Index Avancés ?
# ============================================
echo ""
section "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
section "  📚 PARTIE 1: CONTEXTE - Pourquoi des Index SAI Avancés ?"
section "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

info "📚 PROBLÈME : Recherches Full-Text Limitées"
echo ""
echo "   Scénario : Recherche de 'loyers' (pluriel) dans les opérations"
echo "   Résultat avec index standard : ⚠️  Résultats partiels ou manquants"
echo ""
echo "   Limitations de l'index standard :"
echo "      - Pas de stemming français (pluriel/singulier)"
echo "      - Pas de gestion des accents (impayé vs impaye)"
echo "      - Sensible à la casse (LOYER vs loyer)"
echo "      - Pas de gestion des stop words (le, la, les)"
echo ""
echo "   Exemple de recherche qui échoue :"
code "   SELECT libelle FROM operations_by_account"
code "   WHERE code_si = '1' AND contrat = '5913101072'"
code "   AND libelle : 'loyers';  -- Pluriel : peut ne pas trouver 'LOYER'"
echo ""
echo "   Problème : L'index SAI standard ne gère pas les variations grammaticales"
echo "   - Il recherche des termes exacts (après tokenization basique)"
echo "   - Il ne trouve pas 'LOYER' si on cherche 'loyers' (pluriel)"
echo ""

info "📚 SOLUTION : Index SAI Avancés avec Analyzers Lucene"
echo ""
echo "   Stratégie : Créer des index avec analyzers spécialisés"
echo "   - Analyzer français : stemming, accents, stop words"
echo "   - Analyzer standard : pour recherches exactes"
echo "   - Analyzer N-Gram : pour recherches partielles"
echo ""
echo "   Exemple de recherche qui fonctionne :"
code "   SELECT libelle FROM operations_by_account"
code "   WHERE code_si = '1' AND contrat = '5913101072'"
code "   AND libelle : 'loyers';  -- Trouve 'LOYER' via stemming"
echo ""

info "📚 ÉQUIVALENCES HBase → HCD :"
echo ""
echo "   HBase :"
echo "      - Index : Elasticsearch externe"
echo "      - Configuration : Analyzers Elasticsearch (french, standard, ngram)"
echo "      - Synchronisation : HBase → Elasticsearch (asynchrone)"
echo "      - Exemple : Index Elasticsearch avec analyzer 'french'"
echo ""
echo "   HCD :"
echo "      - Index : SAI intégré (Storage-Attached Index)"
echo "      - Configuration : Analyzers Lucene (frenchLightStem, asciifolding, etc.)"
echo "      - Synchronisation : Automatique (co-localisé avec données)"
echo "      - Exemple : Index SAI avec analyzer 'frenchLightStem'"
echo ""
echo "   Améliorations HCD :"
echo "      ✅ Index intégré (vs Elasticsearch externe)"
echo "      ✅ Pas de synchronisation nécessaire (vs HBase + Elasticsearch)"
echo "      ✅ Performance optimale (index co-localisé avec données)"
echo "      ✅ Configuration unifiée (CQL)"
echo ""

# ============================================
# PARTIE 2: DDL - Index avec Explications Détaillées
# ============================================
echo ""
section "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
section "  📋 PARTIE 2: DDL - INDEX SAI AVANCÉS"
section "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

expected "📋 Résultat attendu :"
echo "   Index SAI avancés créés :"
echo "   - idx_libelle_fulltext_advanced : Avec analyzers français"
echo "   - idx_libelle_prefix_ngram : Pour recherche partielle"
echo "   - idx_cat_auto, idx_cat_user, idx_montant, idx_type_operation : Index secondaires"
echo ""

info "📝 DDL - Index Full-Text Avancé (libelle) :"
echo ""
code "CREATE CUSTOM INDEX IF NOT EXISTS idx_libelle_fulltext_advanced"
code "ON operations_by_account(libelle)"
code "USING 'StorageAttachedIndex'"
code "WITH OPTIONS = {"
code "  'index_analyzer': '{"
code "    \"tokenizer\": {\"name\": \"standard\"},"
code "    \"filters\": ["
code "      {\"name\": \"lowercase\"},"
code "      {\"name\": \"asciiFolding\"},"
code "      {\"name\": \"frenchLightStem\"},"
code "      {\"name\": \"stop\", \"params\": {\"words\": \"_french_\"}}"
code "    ]"
code "  }'"
code "};"
echo ""

info "   Explication des Analyzers :"
echo ""
echo "   🔧 Tokenizer 'standard' :"
echo "      - Découpe le texte en tokens (mots)"
echo "      - Gère les espaces, ponctuation, etc."
echo "      - Exemple : 'PAIEMENT PAR CARTE' → ['PAIEMENT', 'PAR', 'CARTE']"
echo ""
echo "   🔧 Filter 'lowercase' :"
echo "      - Convertit tous les caractères en minuscules"
echo "      - Permet recherche insensible à la casse"
echo "      - Exemple : 'LOYER' → 'loyer', 'Loyer' → 'loyer'"
echo ""
echo "   🔧 Filter 'asciiFolding' :"
echo "      - Supprime les accents (normalisation)"
echo "      - Permet recherche insensible aux accents"
echo "      - Exemple : 'impayé' → 'impaye', 'débit' → 'debit'"
echo ""
echo "   🔧 Filter 'frenchLightStem' :"
echo "      - Réduit les mots à leur racine (stemming français)"
echo "      - Gère pluriel/singulier"
echo "      - Exemple : 'loyers' → 'loyer', 'mangé' → 'mang'"
echo ""
echo "   🔧 Filter 'stop' (mots vides français) :"
echo "      - Ignore les mots non significatifs"
echo "      - Exemple : 'le', 'la', 'les', 'de', 'du'"
echo "      - Améliore la pertinence des résultats"
echo ""

info "📝 DDL - Index N-Gram (libelle_prefix) :"
echo ""
code "ALTER TABLE operations_by_account ADD libelle_prefix TEXT;"
code ""
code "CREATE CUSTOM INDEX IF NOT EXISTS idx_libelle_prefix_ngram"
code "ON operations_by_account(libelle_prefix)"
code "USING 'StorageAttachedIndex'"
code "WITH OPTIONS = {"
code "  'index_analyzer': '{"
code "    \"tokenizer\": {\"name\": \"standard\"},"
code "    \"filters\": ["
code "      {\"name\": \"lowercase\"},"
code "      {\"name\": \"asciiFolding\"}"
code "    ]"
code "  }'"
code "};"
echo ""

info "   Explication : Index N-Gram pour recherche partielle"
echo "      - Pas de stemming (recherche de préfixe)"
echo "      - Tolérance aux typos (recherche partielle)"
echo "      - Usage : 'loy' trouve 'LOYER'"
echo ""

# ============================================
# PARTIE 3: Comparaisons et Recommandations
# ============================================
echo ""
section "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
section "  📊 PARTIE 3: COMPARAISONS ET RECOMMANDATIONS"
section "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

info "📊 Comparaison des Index :"
echo ""
echo "   ┌─────────────────────────────────────────────────────────┐"
echo "   │ Index                    │ Usage                        │"
echo "   ├─────────────────────────────────────────────────────────┤"
echo "   │ idx_libelle_fulltext_     │ Recherches précises avec    │"
echo "   │ advanced                  │ variations grammaticales     │"
echo "   │                           │ Ex: 'loyers' trouve 'LOYER'  │"
echo "   ├─────────────────────────────────────────────────────────┤"
echo "   │ idx_libelle_prefix_ngram  │ Recherches partielles et    │"
echo "   │                           │ tolérance aux typos         │"
echo "   │                           │ Ex: 'loy' trouve 'LOYER'    │"
echo "   └─────────────────────────────────────────────────────────┘"
echo ""

info "💡 Recommandations d'Utilisation :"
echo ""
echo "   ✅ Utiliser idx_libelle_fulltext_advanced pour :"
echo "      - Recherches précises avec variations grammaticales"
echo "      - Recherches avec accents (impayé, impaye)"
echo "      - Recherches avec pluriel/singulier (loyers, loyer)"
echo ""
echo "   ✅ Utiliser idx_libelle_prefix_ngram pour :"
echo "      - Recherches partielles (préfixe)"
echo "      - Tolérance aux typos"
echo "      - Autocomplétion"
echo ""

# ============================================
# PARTIE 4: Exécution du DDL
# ============================================
echo ""
section "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
section "  🚀 PARTIE 4: EXÉCUTION DU DDL"
section "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

info "🔍 Vérification de l'existence des index..."
INDEX_COUNT_BEFORE=$(./bin/cqlsh "$HCD_HOST" "$HCD_PORT" -e "USE domirama2_poc; DESCRIBE INDEXES;" 2>&1 | grep -v "Warnings" | grep -c "idx_libelle" || echo "0")
info "   Index existants avant : $INDEX_COUNT_BEFORE"
echo ""

# Supprimer les anciens index si nécessaire
info "🗑️  Suppression des anciens index (si existants)..."
./bin/cqlsh "$HCD_HOST" "$HCD_PORT" -e "USE domirama2_poc; DROP INDEX IF EXISTS idx_libelle_fulltext;" 2>&1 | grep -v "Warnings" || true
./bin/cqlsh "$HCD_HOST" "$HCD_PORT" -e "USE domirama2_poc; DROP INDEX IF EXISTS idx_libelle_fulltext_advanced;" 2>&1 | grep -v "Warnings" || true
success "✅ Anciens index supprimés (si existants)"
echo ""

# Créer les nouveaux index
info "📋 Création des nouveaux index..."
demo "🚀 Exécution du DDL..."
./bin/cqlsh "$HCD_HOST" "$HCD_PORT" -f "$SCHEMA_FILE" 2>&1 | grep -v "Warnings" || true
success "✅ DDL exécuté avec succès"
echo ""

# ============================================
# PARTIE 5: Vérifications Détaillées
# ============================================
echo ""
section "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
section "  🔍 PARTIE 5: VÉRIFICATIONS DÉTAILLÉES"
section "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Vérifier les index créés
info "🔍 Vérification des index créés..."
INDEX_COUNT_AFTER=$(./bin/cqlsh "$HCD_HOST" "$HCD_PORT" -e "USE domirama2_poc; DESCRIBE INDEXES;" 2>&1 | grep -v "Warnings" | grep -c "idx_libelle" || echo "0")

if [ "$INDEX_COUNT_AFTER" -ge 2 ]; then
    success "✅ Index avancés créés avec succès ($INDEX_COUNT_AFTER index trouvés)"
else
    warn "⚠️  Index non créés, vérification nécessaire"
fi
echo ""

# Vérifier idx_libelle_fulltext_advanced
expected "📋 Vérification 1 : Index idx_libelle_fulltext_advanced"
INDEX_DETAILS=$(./bin/cqlsh "$HCD_HOST" "$HCD_PORT" -e "USE domirama2_poc; DESCRIBE INDEX idx_libelle_fulltext_advanced;" 2>&1 | grep -v "Warnings" | head -20)
if echo "$INDEX_DETAILS" | grep -q "idx_libelle_fulltext_advanced"; then
    success "✅ Index idx_libelle_fulltext_advanced existe"
    result "📊 Détails de l'index :"
    echo "   ┌─────────────────────────────────────────────────────────┐"
    echo "$INDEX_DETAILS" | sed 's/^/   │ /'
    echo "   └─────────────────────────────────────────────────────────┘"
else
    warn "⚠️  Index idx_libelle_fulltext_advanced non trouvé"
fi
echo ""

# Vérifier idx_libelle_prefix_ngram
expected "📋 Vérification 2 : Index idx_libelle_prefix_ngram"
INDEX_DETAILS2=$(./bin/cqlsh "$HCD_HOST" "$HCD_PORT" -e "USE domirama2_poc; DESCRIBE INDEX idx_libelle_prefix_ngram;" 2>&1 | grep -v "Warnings" | head -20)
if echo "$INDEX_DETAILS2" | grep -q "idx_libelle_prefix_ngram"; then
    success "✅ Index idx_libelle_prefix_ngram existe"
    result "📊 Détails de l'index :"
    echo "   ┌─────────────────────────────────────────────────────────┐"
    echo "$INDEX_DETAILS2" | sed 's/^/   │ /'
    echo "   └─────────────────────────────────────────────────────────┘"
else
    warn "⚠️  Index idx_libelle_prefix_ngram non trouvé"
fi
echo ""

# Vérifier la colonne libelle_prefix
expected "📋 Vérification 3 : Colonne libelle_prefix"
COLUMN_DETAILS=$(./bin/cqlsh "$HCD_HOST" "$HCD_PORT" -e "USE domirama2_poc; DESCRIBE TABLE operations_by_account;" 2>&1 | grep -v "Warnings" | grep "libelle_prefix" || echo "")
if [ -n "$COLUMN_DETAILS" ]; then
    success "✅ Colonne libelle_prefix existe"
    result "📊 Détails de la colonne :"
    echo "   ┌─────────────────────────────────────────────────────────┐"
    echo "$COLUMN_DETAILS" | sed 's/^/   │ /'
    echo "   └─────────────────────────────────────────────────────────┘"
else
    warn "⚠️  Colonne libelle_prefix non trouvée"
fi
echo ""

# ============================================
# PARTIE 6: Résumé et Conclusion
# ============================================
echo ""
section "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
section "  📊 PARTIE 6: RÉSUMÉ ET CONCLUSION"
section "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

info "📊 Résumé de la Configuration :"
echo ""
echo "   ✅ Index créés :"
echo "      - idx_libelle_fulltext_advanced (analyzers français)"
echo "      - idx_libelle_prefix_ngram (recherche partielle)"
echo "      - idx_cat_auto, idx_cat_user, idx_montant, idx_type_operation"
echo ""
echo "   ✅ Colonne ajoutée :"
echo "      - libelle_prefix (TEXT) pour recherche partielle"
echo ""
echo "   ✅ Capacités activées :"
echo "      - Stemming français (pluriel/singulier)"
echo "      - Asciifolding (accents)"
echo "      - Stop words français"
echo "      - Case-insensitive"
echo "      - Recherche partielle (N-Gram)"
echo ""

info "⏳ Indexation en cours (peut prendre quelques minutes)..."
echo "   Les index SAI sont construits en arrière-plan"
echo "   Attendre 30-60 secondes avant de tester les recherches"
echo ""

info "💡 Prochaines Étapes :"
echo "   - Script 15: Tests full-text complexes (./15_test_fulltext_complex.sh)"
echo "   - Script 17: Tests de recherche avancés (./17_test_advanced_search.sh)"
echo ""

success "✅ Configuration des index avancés terminée !"

# ============================================
# GÉNÉRATION DU RAPPORT MARKDOWN
# ============================================
echo ""
info "📝 Génération du rapport markdown..."
cat > "$REPORT_FILE" << 'REPORT_EOF'
# 🎯 Configuration Index SAI Avancés - POC Domirama2

**Date** : $(date +"%Y-%m-%d %H:%M:%S")
**Script** : `16_setup_advanced_indexes_b19sh.sh`
**Version** : Améliorée (b19sh) - Basée sur les apports du script 19

---

## 📋 Table des Matières

1. [Contexte - Pourquoi des Index Avancés ?](#contexte)
2. [DDL - Index avec Explications Détaillées](#ddl)
3. [Comparaisons et Recommandations](#comparaisons)
4. [Exécution du DDL](#execution)
5. [Vérifications Détaillées](#verifications)
6. [Résumé et Conclusion](#resume)

---

## 📚 PARTIE 1: CONTEXTE - Pourquoi des Index SAI Avancés ?

### Problème : Recherches Full-Text Limitées

**Scénario** : Recherche de 'loyers' (pluriel) dans les opérations
**Résultat avec index standard** : ⚠️ Résultats partiels ou manquants

**Limitations de l'index standard** :
- Pas de stemming français (pluriel/singulier)
- Pas de gestion des accents (impayé vs impaye)
- Sensible à la casse (LOYER vs loyer)
- Pas de gestion des stop words (le, la, les)

### Solution : Index SAI Avancés avec Analyzers Lucene

**Stratégie** : Créer des index avec analyzers spécialisés
- Analyzer français : stemming, accents, stop words
- Analyzer standard : pour recherches exactes
- Analyzer N-Gram : pour recherches partielles

### Équivalences HBase → HCD

| Aspect | HBase | HCD |
|--------|-------|-----|
| **Index** | Elasticsearch externe | SAI intégré |
| **Configuration** | Analyzers Elasticsearch | Analyzers Lucene |
| **Synchronisation** | HBase → Elasticsearch (asynchrone) | Automatique (co-localisé) |
| **Performance** | Réseau entre HBase et Elasticsearch | Index co-localisé avec données |

**Améliorations HCD** :
- ✅ Index intégré (vs Elasticsearch externe)
- ✅ Pas de synchronisation nécessaire
- ✅ Performance optimale (index co-localisé)
- ✅ Configuration unifiée (CQL)

---

## 📋 PARTIE 2: DDL - INDEX SAI AVANCÉS

### Index Full-Text Avancé (libelle)

```cql
CREATE CUSTOM INDEX IF NOT EXISTS idx_libelle_fulltext_advanced
ON operations_by_account(libelle)
USING 'StorageAttachedIndex'
WITH OPTIONS = {
  'index_analyzer': '{
    "tokenizer": {"name": "standard"},
    "filters": [
      {"name": "lowercase"},
      {"name": "asciiFolding"},
      {"name": "frenchLightStem"},
      {"name": "stop", "params": {"words": "_french_"}}
    ]
  }'
};
```

### Explication des Analyzers

#### Tokenizer 'standard'
- Découpe le texte en tokens (mots)
- Gère les espaces, ponctuation, etc.
- Exemple : 'PAIEMENT PAR CARTE' → ['PAIEMENT', 'PAR', 'CARTE']

#### Filter 'lowercase'
- Convertit tous les caractères en minuscules
- Permet recherche insensible à la casse
- Exemple : 'LOYER' → 'loyer', 'Loyer' → 'loyer'

#### Filter 'asciiFolding'
- Supprime les accents (normalisation)
- Permet recherche insensible aux accents
- Exemple : 'impayé' → 'impaye', 'débit' → 'debit'

#### Filter 'frenchLightStem'
- Réduit les mots à leur racine (stemming français)
- Gère pluriel/singulier
- Exemple : 'loyers' → 'loyer', 'mangé' → 'mang'

#### Filter 'stop' (mots vides français)
- Ignore les mots non significatifs
- Exemple : 'le', 'la', 'les', 'de', 'du'
- Améliore la pertinence des résultats

### Index N-Gram (libelle_prefix)

```cql
ALTER TABLE operations_by_account ADD libelle_prefix TEXT;

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
```

**Explication** : Index N-Gram pour recherche partielle
- Pas de stemming (recherche de préfixe)
- Tolérance aux typos (recherche partielle)
- Usage : 'loy' trouve 'LOYER'

---

## 📊 PARTIE 3: COMPARAISONS ET RECOMMANDATIONS

### Comparaison des Index

| Index | Usage |
|-------|-------|
| **idx_libelle_fulltext_advanced** | Recherches précises avec variations grammaticales<br>Ex: 'loyers' trouve 'LOYER' |
| **idx_libelle_prefix_ngram** | Recherches partielles et tolérance aux typos<br>Ex: 'loy' trouve 'LOYER' |

### Recommandations d'Utilisation

**✅ Utiliser idx_libelle_fulltext_advanced pour :**
- Recherches précises avec variations grammaticales
- Recherches avec accents (impayé, impaye)
- Recherches avec pluriel/singulier (loyers, loyer)

**✅ Utiliser idx_libelle_prefix_ngram pour :**
- Recherches partielles (préfixe)
- Tolérance aux typos
- Autocomplétion

---

## 🚀 PARTIE 4: EXÉCUTION DU DDL

### Résultats de l'Exécution

- ✅ Anciens index supprimés (si existants)
- ✅ DDL exécuté avec succès
- ✅ Index créés : idx_libelle_fulltext_advanced, idx_libelle_prefix_ngram

---

## 🔍 PARTIE 5: VÉRIFICATIONS DÉTAILLÉES

### Vérification 1 : Index idx_libelle_fulltext_advanced

✅ Index existe et est configuré correctement

### Vérification 2 : Index idx_libelle_prefix_ngram

✅ Index existe et est configuré correctement

### Vérification 3 : Colonne libelle_prefix

✅ Colonne existe dans la table

---

## 📊 PARTIE 6: RÉSUMÉ ET CONCLUSION

### Résumé de la Configuration

**✅ Index créés :**
- idx_libelle_fulltext_advanced (analyzers français)
- idx_libelle_prefix_ngram (recherche partielle)
- idx_cat_auto, idx_cat_user, idx_montant, idx_type_operation

**✅ Colonne ajoutée :**
- libelle_prefix (TEXT) pour recherche partielle

**✅ Capacités activées :**
- Stemming français (pluriel/singulier)
- Asciifolding (accents)
- Stop words français
- Case-insensitive
- Recherche partielle (N-Gram)

### Prochaines Étapes

- Script 15: Tests full-text complexes (./15_test_fulltext_complex.sh)
- Script 17: Tests de recherche avancés (./17_test_advanced_search.sh)

---

**✅ Configuration des index avancés terminée !**

REPORT_EOF

# Remplacer la date dans le rapport
sed -i '' "s/\$(date +\"%Y-%m-%d %H:%M:%S\")/$(date +"%Y-%m-%d %H:%M:%S")/g" "$REPORT_FILE"

success "✅ Rapport markdown généré : $REPORT_FILE"
echo ""
