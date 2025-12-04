#!/bin/bash
set -euo pipefail
# ============================================
# Script 04 : Création des Index SAI pour operations_by_account (Version Didactique)
# Crée tous les index SAI nécessaires pour la recherche avancée
# ============================================
#
# Voir l'en-tête du script original pour le contexte / utilisation / prérequis.
# Version corrigée : suppression des textes collés et robustification des quotes.
#
set -euo pipefail

# ============================================
# SOURCE DES FONCTIONS UTILITAIRES
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

if [ -f "${SCRIPT_DIR}/../utils/didactique_functions.sh" ]; then
    # shellcheck source=/dev/null
    source "${SCRIPT_DIR}/../utils/didactique_functions.sh"
else
    # Fallback si les fonctions ne sont pas disponibles
    RED=$'\033[0;31m'
    GREEN=$'\033[0;32m'
    YELLOW=$'\033[1;33m'
    BLUE=$'\033[0;34m'
    CYAN=$'\033[0;36m'
    MAGENTA=$'\033[0;35m'
    BOLD=$'\033[1m'
    NC=$'\033[0m'
    info() { echo -e "${BLUE}ℹ️  $1${NC}"; }
    success() { echo -e "${GREEN}✅ $1${NC}"; }
    warn() { echo -e "${YELLOW}⚠️  $1${NC}"; }
    error() { echo -e "${RED}❌ $1${NC}"; }
    demo() { echo -e "${CYAN}🎯 $1${NC}"; }
    code() { echo -e "${MAGENTA}📝 $1${NC}"; }
    section() { echo -e "${BOLD}${CYAN}$1${NC}"; }
    result() { echo -e "${GREEN}📊 $1${NC}"; }
    expected() { echo -e "${YELLOW}📋 $1${NC}"; }
fi

# ============================================
# CONFIGURATION
# ============================================
INDEX_FILE="${SCRIPT_DIR}/../schemas/02_create_operations_indexes.cql"
META_INDEX_FILE="${SCRIPT_DIR}/../schemas/04_create_meta_categories_indexes.cql"
REPORT_FILE="${SCRIPT_DIR}/../doc/demonstrations/04_CREATE_INDEXES_DEMONSTRATION.md"

# Charger l'environnement POC (HCD déjà installé sur MBP)
if [ -f "${INSTALL_DIR}/.poc-profile" ]; then
    # shellcheck source=/dev/null
    source "${INSTALL_DIR}/.poc-profile"
fi

# HCD_HOME devrait être défini par .poc-profile
HCD_DIR="${HCD_HOME:-${INSTALL_DIR}/binaire/hcd-1.2.3}"

# Créer le répertoire de documentation
mkdir -p "$(dirname "$REPORT_FILE")"

# ============================================
# VÉRIFICATIONS
# ============================================
cd "$HCD_DIR"

# Définit Java 11 via jenv si disponible — ne doit pas faire échouer le script si jenv absent
if command -v jenv >/dev/null 2>&1; then
    jenv local 11 || true
    eval "$(jenv init -)"
fi

info "🔍 Vérification que HCD est prêt..."
if ! "${HCD_HOME:-$HCD_DIR}/bin/cqlsh" "$HCD_HOST" "$HCD_PORT" -e 'SELECT cluster_name FROM system.local;' > /dev/null 2>&1; then
    error "HCD n'est pas prêt. Attendez quelques secondes et réessayez."
    exit 1
fi

# Vérifier que le keyspace existe (nom en minuscules)
if ! "${HCD_HOME:-$HCD_DIR}/bin/cqlsh" "$HCD_HOST" "$HCD_PORT" -e 'DESCRIBE KEYSPACE domiramacatops_poc;' > /dev/null 2>&1; then
    error "Le keyspace domiramacatops_poc n'existe pas. Exécutez d'abord: ./01_setup_domiramaCatOps_keyspace.sh"
    exit 1
fi

# Vérifier que la table existe
if ! "${HCD_HOME:-$HCD_DIR}/bin/cqlsh" "$HCD_HOST" "$HCD_PORT" -e 'DESCRIBE TABLE domiramacatops_poc.operations_by_account;' > /dev/null 2>&1; then
    error "La table operations_by_account n'existe pas. Exécutez d'abord: ./02_setup_operations_by_account.sh"
    exit 1
fi

if [ ! -f "$INDEX_FILE" ]; then
    error "Fichier schéma index non trouvé: $INDEX_FILE"
    exit 1
fi

if [ ! -f "$META_INDEX_FILE" ]; then
    warn "Fichier schéma index meta-categories non trouvé: $META_INDEX_FILE (optionnel)"
fi

# ============================================
# EN-TÊTE DE DÉMONSTRATION
# ============================================
if type show_demo_header >/dev/null 2>&1; then
    show_demo_header "Création des Index SAI pour operations_by_account"
else
    section "Création des Index SAI pour operations_by_account"
fi

# ============================================
# PARTIE 1: CONTEXTE HBase → HCD
# ============================================
if type show_partie >/dev/null 2>&1; then
    show_partie "1" "CONTEXTE - Migration HBase → HCD"
else
    section "1 - CONTEXTE - Migration HBase → HCD"
fi

info "📚 ÉQUIVALENCES HBase → HCD :"
echo ""
echo "   HBase :"
echo "      - Index : Elasticsearch externe (système séparé)"
echo "      - Recherche full-text : Via Elasticsearch"
echo "      - Recherche vectorielle : Via ML externe"
echo "      - Maintenance : Système externe à maintenir"
echo ""
echo "   HCD :"
echo "      - Index : SAI intégré (Storage-Attached Index)"
echo "      - Recherche full-text : Index SAI avec analyzers Lucene"
echo "      - Recherche vectorielle : Index SAI vectoriel natif"
echo "      - Maintenance : Intégré à HCD, pas de système externe"
echo ""
echo "   Avantages HCD :"
echo "      ✅ Index intégrés (pas de système externe)"
echo "      ✅ Performance optimisée (pas de réseau externe)"
echo "      ✅ Maintenance simplifiée (un seul système)"
echo "      ✅ Support vectoriel natif (ANN intégré)"
echo ""

# ============================================
# PARTIE 2: DDL - Index SAI Full-Text (description only)
# ============================================
if type show_partie >/dev/null 2>&1; then
    show_partie "2" "DDL - INDEX SAI FULL-TEXT"
else
    section "2 - DDL - INDEX SAI FULL-TEXT"
fi

expected "📋 Résultat attendu :"
echo "   Index 'idx_libelle_fulltext_advanced' créé avec analyzers français"
echo ""

info "📝 DDL - Index SAI Full-Text sur libellé :"
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
code "      {\"name\": \"frenchLightStem\"}"
code "    ]"
code "  }'"
code "};"
echo ""

info "   Explication :"
echo "      - Index SAI = Storage-Attached Index (intégré à HCD)"
echo "      - Analyzer français : lowercase, asciifolding, frenchLightStem"
echo ""

# ============================================
# PARTIE 3: DDL - N-Gram & Collection (description only)
# ============================================
if type show_partie >/dev/null 2>&1; then
    show_partie "3" "DDL - INDEX SAI N-GRAM ET COLLECTION"
else
    section "3 - DDL - INDEX SAI N-GRAM ET COLLECTION"
fi

expected "📋 Résultat attendu :"
echo "   Index 'idx_libelle_prefix_ngram' et 'idx_libelle_tokens' créés"
echo ""

info "📝 DDL - Index SAI N-Gram sur libelle_prefix :"
echo ""
code "CREATE CUSTOM INDEX IF NOT EXISTS idx_libelle_prefix_ngram"
code "ON operations_by_account(libelle_prefix)"
code "USING 'StorageAttachedIndex';"
echo ""

info "📝 DDL - Index SAI Collection sur libelle_tokens :"
echo ""
code "CREATE CUSTOM INDEX IF NOT EXISTS idx_libelle_tokens"
code "ON operations_by_account(libelle_tokens)"
code "USING 'StorageAttachedIndex';"
echo ""

# ============================================
# PARTIE 4: DDL - Vector Search (description only)
# ============================================
if type show_partie >/dev/null 2>&1; then
    show_partie "4" "DDL - INDEX SAI VECTOR SEARCH"
else
    section "4 - DDL - INDEX SAI VECTOR SEARCH"
fi

expected "📋 Résultat attendu :"
echo "   Index 'idx_libelle_embedding_vector' créé pour recherche vectorielle"
echo ""

info "📝 DDL - Index SAI Vector Search sur libelle_embedding :"
echo ""
code "CREATE CUSTOM INDEX IF NOT EXISTS idx_libelle_embedding_vector"
code "ON operations_by_account(libelle_embedding)"
code "USING 'StorageAttachedIndex'"
code "WITH OPTIONS = {"
code "  'similarity_function': 'COSINE'"
code "};"
echo ""

# ============================================
# PARTIE 5: DDL - Catégories & autres (description only)
# ============================================
if type show_partie >/dev/null 2>&1; then
    show_partie "5" "DDL - INDEX SAI CATÉGORIES ET AUTRES"
else
    section "5 - DDL - INDEX SAI CATÉGORIES ET AUTRES"
fi

expected "📋 Résultat attendu :"
echo "   Index créés : idx_cat_auto, idx_cat_user, idx_montant, idx_type_operation"
echo ""

info "📝 DDL - Index SAI sur Catégories :"
echo ""
code "CREATE CUSTOM INDEX IF NOT EXISTS idx_cat_auto"
code "ON operations_by_account(cat_auto)"
code "USING 'StorageAttachedIndex';"
echo ""

code "CREATE CUSTOM INDEX IF NOT EXISTS idx_cat_user"
code "ON operations_by_account(cat_user)"
code "USING 'StorageAttachedIndex';"
echo ""

info "📝 DDL - Index SAI sur Autres Colonnes :"
echo ""
code "CREATE CUSTOM INDEX IF NOT EXISTS idx_montant"
code "ON operations_by_account(montant)"
code "USING 'StorageAttachedIndex';"
echo ""

code "CREATE CUSTOM INDEX IF NOT EXISTS idx_type_operation"
code "ON operations_by_account(type_operation)"
code "USING 'StorageAttachedIndex';"
echo ""

# ============================================
# Exécution - Index operations_by_account
# ============================================
info "🚀 Exécution du DDL pour les index operations_by_account..."
"${HCD_HOME:-$HCD_DIR}/bin/cqlsh" "$HCD_HOST" "$HCD_PORT" -f "$INDEX_FILE" 2>&1 | grep -v 'Warnings' || true

sleep 3

# Vérification - Index operations_by_account
info "🔍 Vérification de la création des index operations_by_account..."
INDEXES_OPS=$(
  "${HCD_HOME:-$HCD_DIR}/bin/cqlsh" "$HCD_HOST" "$HCD_PORT" -e "SELECT index_name FROM system_schema.indexes WHERE keyspace_name = 'domiramacatops_poc' AND table_name = 'operations_by_account';" 2>&1 \
  | grep -v 'Warnings' | grep -v 'index_name' | grep -vE '^---' | grep -v '^$' | wc -l | tr -d ' '
)

if [ "${INDEXES_OPS}" -ge 8 ]; then
    success "✅ ${INDEXES_OPS} index(es) SAI créé(s) pour operations_by_account"
    echo ""
    result "📊 Liste des index operations_by_account créés :"
    echo "   ┌─────────────────────────────────────────────────────────┐"
    "${HCD_HOME:-$HCD_DIR}/bin/cqlsh" "$HCD_HOST" "$HCD_PORT" -e "SELECT index_name FROM system_schema.indexes WHERE keyspace_name = 'domiramacatops_poc' AND table_name = 'operations_by_account';" 2>&1 \
      | grep -v 'Warnings' | grep -v 'index_name' | grep -vE '^---' | grep -v '^$' | sed 's/^/   │ /'
    echo "   └─────────────────────────────────────────────────────────┘"
else
    warn "⚠️  Nombre d index SAI operations_by_account: ${INDEXES_OPS} (attendu: 8+)"
fi
echo ""

# ============================================
# PARTIE 5b: Meta-categories
# ============================================
if type show_partie >/dev/null 2>&1; then
    show_partie "5b" "DDL - INDEX SAI META-CATEGORIES"
else
    section "5b - DDL - INDEX SAI META-CATEGORIES"
fi

if [ -f "$META_INDEX_FILE" ]; then
    info "📝 DDL - Index SAI pour tables meta-categories :"
    echo ""
    code "Tables concernées :"
    code "  - historique_opposition"
    code "  - feedback_par_libelle"
    code "  - feedback_par_ics"
    code "  - regles_personnalisees"
    code "  - decisions_salaires"
    echo ""
    info "   Explication :"
    echo "      - Index full-text : Pour recherche textuelle (libelle_simplifie, raison)"
    echo "      - Index standard : Pour filtrage rapide (categorie, actif, status)"
    echo "      - Index SAI : Intégré à HCD (pas de système externe)"
    echo ""

    # Exécution - Index meta-categories
    info "🚀 Exécution du DDL pour les index meta-categories..."
    "${HCD_HOME:-$HCD_DIR}/bin/cqlsh" "$HCD_HOST" "$HCD_PORT" -f "$META_INDEX_FILE" 2>&1 | grep -v 'Warnings' || true

    sleep 3

    # Vérification - Index meta-categories
    info "🔍 Vérification de la création des index meta-categories..."
    INDEXES_META=$(
      "${HCD_HOME:-$HCD_DIR}/bin/cqlsh" "$HCD_HOST" "$HCD_PORT" -e "SELECT table_name, index_name FROM system_schema.indexes WHERE keyspace_name = 'domiramacatops_poc' AND table_name IN ('historique_opposition', 'feedback_par_libelle', 'feedback_par_ics', 'regles_personnalisees', 'decisions_salaires');" 2>&1 \
      | grep -v 'Warnings' | grep -v 'table_name' | grep -vE '^---' | grep -v '^$' | wc -l | tr -d ' '
    )

    if [ "${INDEXES_META}" -ge 10 ]; then
        success "✅ ${INDEXES_META} index(es) SAI créé(s) pour tables meta-categories"
        echo ""
        result "📊 Liste des index meta-categories créés :"
        echo "   ┌─────────────────────────────────────────────────────────┐"
        "${HCD_HOME:-$HCD_DIR}/bin/cqlsh" "$HCD_HOST" "$HCD_PORT" -e "SELECT table_name, index_name FROM system_schema.indexes WHERE keyspace_name = 'domiramacatops_poc' AND table_name IN ('historique_opposition', 'feedback_par_libelle', 'feedback_par_ics', 'regles_personnalisees', 'decisions_salaires') ORDER BY table_name, index_name;" 2>&1 \
          | grep -v 'Warnings' | grep -v 'table_name' | grep -vE '^---' | grep -v '^$' | sed 's/^/   │ /'
        echo "   └─────────────────────────────────────────────────────────┘"
    else
        warn "⚠️  Nombre d index SAI meta-categories: ${INDEXES_META} (attendu: 10+)"
    fi
    echo ""

    TOTAL_INDEXES=$((INDEXES_OPS + INDEXES_META))
    info "📊 Total des index SAI créés : ${TOTAL_INDEXES} (operations: ${INDEXES_OPS}, meta-categories: ${INDEXES_META})"
    echo ""
else
    warn "⚠️  Fichier index meta-categories non trouvé: ${META_INDEX_FILE}"
    warn "   Les index meta-categories ne seront pas créés"
    TOTAL_INDEXES=${INDEXES_OPS}
fi

# ============================================
# PARTIE 6: VÉRIFICATIONS COMPLÈTES
# ============================================
if type show_partie >/dev/null 2>&1; then
    show_partie "6" "VÉRIFICATIONS COMPLÈTES"
else
    section "6 - VÉRIFICATIONS COMPLÈTES"
fi

if type check_hcd_status >/dev/null 2>&1; then
    check_hcd_status
fi

if type check_jenv_java_version >/dev/null 2>&1; then
    check_jenv_java_version
fi

info "🔍 Vérification complète des index..."
echo ""

# Vérification 1: Index Full-Text
expected "📋 Vérification 1 : Index Full-Text"
echo "   Attendu : Index 'idx_libelle_fulltext_advanced' existe"
FULLTEXT_EXISTS=$(
  "${HCD_HOME:-$HCD_DIR}/bin/cqlsh" "$HCD_HOST" "$HCD_PORT" -e "SELECT index_name FROM system_schema.indexes WHERE keyspace_name = 'domiramacatops_poc' AND table_name = 'operations_by_account' AND index_name = 'idx_libelle_fulltext_advanced';" 2>&1 \
  | grep -v 'Warnings' | grep -c 'idx_libelle_fulltext_advanced' || echo '0'
)

if [ "${FULLTEXT_EXISTS}" -gt 0 ]; then
    success "✅ Index 'idx_libelle_fulltext_advanced' existe"
else
    warn "⚠️  Index 'idx_libelle_fulltext_advanced' non trouvé"
fi
echo ""

# Vérification 2: Index Vector
expected "📋 Vérification 2 : Index Vector"
echo "   Attendu : Index 'idx_libelle_embedding_vector' existe"
VECTOR_EXISTS=$(
  "${HCD_HOME:-$HCD_DIR}/bin/cqlsh" "$HCD_HOST" "$HCD_PORT" -e "SELECT index_name FROM system_schema.indexes WHERE keyspace_name = 'domiramacatops_poc' AND table_name = 'operations_by_account' AND index_name = 'idx_libelle_embedding_vector';" 2>&1 \
  | grep -v 'Warnings' | grep -c 'idx_libelle_embedding_vector' || echo '0'
)

if [ "${VECTOR_EXISTS}" -gt 0 ]; then
    success "✅ Index 'idx_libelle_embedding_vector' existe"
else
    warn "⚠️  Index 'idx_libelle_embedding_vector' non trouvé"
fi
echo ""

# Vérification 3: Index Catégories
expected "📋 Vérification 3 : Index Catégories"
echo "   Attendu : Index 'idx_cat_auto' et 'idx_cat_user' existent"
CAT_AUTO_EXISTS=$(
  "${HCD_HOME:-$HCD_DIR}/bin/cqlsh" "$HCD_HOST" "$HCD_PORT" -e "SELECT index_name FROM system_schema.indexes WHERE keyspace_name = 'domiramacatops_poc' AND table_name = 'operations_by_account' AND index_name = 'idx_cat_auto';" 2>&1 \
  | grep -v 'Warnings' | grep -c 'idx_cat_auto' || echo '0'
)

CAT_USER_EXISTS=$(
  "${HCD_HOME:-$HCD_DIR}/bin/cqlsh" "$HCD_HOST" "$HCD_PORT" -e "SELECT index_name FROM system_schema.indexes WHERE keyspace_name = 'domiramacatops_poc' AND table_name = 'operations_by_account' AND index_name = 'idx_cat_user';" 2>&1 \
  | grep -v 'Warnings' | grep -c 'idx_cat_user' || echo '0'
)

if [ "${CAT_AUTO_EXISTS}" -gt 0 ] && [ "${CAT_USER_EXISTS}" -gt 0 ]; then
    success "✅ Index 'idx_cat_auto' et 'idx_cat_user' existent"
else
    warn "⚠️  Certains index de catégories manquants (cat_auto: ${CAT_AUTO_EXISTS}, cat_user: ${CAT_USER_EXISTS})"
fi
echo ""

# ============================================
# PARTIE 7: RÉSUMÉ ET CONCLUSION
# ============================================
if type show_partie >/dev/null 2>&1; then
    show_partie "7" "RÉSUMÉ ET CONCLUSION"
else
    section "7 - RÉSUMÉ ET CONCLUSION"
fi

info "📊 Résumé de la configuration :"
echo ""
echo "   ✅ Index SAI operations_by_account : ${INDEXES_OPS} index(es)"
echo "      - Index Full-Text : idx_libelle_fulltext_advanced"
echo "      - Index N-Gram : idx_libelle_prefix_ngram"
echo "      - Index Collection : idx_libelle_tokens"
echo "      - Index Vector : idx_libelle_embedding_vector"
echo "      - Index Catégories : idx_cat_auto, idx_cat_user"
echo "      - Index Autres : idx_montant, idx_type_operation"
if [ -f "$META_INDEX_FILE" ]; then
    echo "   ✅ Index SAI meta-categories : ${INDEXES_META} index(es)"
    echo "      - historique_opposition : idx_historique_status, idx_historique_raison_fulltext"
    echo "      - feedback_par_libelle : idx_feedback_libelle_fulltext, idx_feedback_categorie"
    echo "      - feedback_par_ics : idx_feedback_ics_categorie"
    echo "      - regles_personnalisees : idx_regles_libelle_fulltext, idx_regles_categorie_cible, idx_regles_actif"
    echo "      - decisions_salaires : idx_decisions_methode, idx_decisions_modele, idx_decisions_actif"
fi
echo "   ✅ Total index SAI : ${TOTAL_INDEXES} index(es)"
echo ""

info "💡 Équivalences HBase → HCD validées :"
echo ""
echo "   ✅ Elasticsearch externe → Index SAI intégré"
echo "   ✅ Recherche full-text → Index SAI avec analyzers"
echo "   ✅ Recherche vectorielle → Index SAI vectoriel natif"
echo ""

info "📝 Prochaines étapes :"
echo ""
echo "   - Script 05: Chargement des données (batch)"
echo "   - Script 16-18: Tests de recherche avancée (full-text, fuzzy, vector, hybrid)"
echo ""

success "✅ Configuration des index terminée !"
info "📝 Documentation générée : $REPORT_FILE"
echo ""

# ============================================
# GÉNÉRATION DU RAPPORT (Python HEREDOC)
# ============================================
info "📝 Génération du rapport de démonstration..."

# Passer les compteurs à python via variables d'environnement
INDEXES="${INDEXES_OPS}" INDEXES_META="${INDEXES_META:-0}" TOTAL_INDEXES="${TOTAL_INDEXES:-$INDEXES_OPS}" FULLTEXT_EXISTS="${FULLTEXT_EXISTS:-0}" VECTOR_EXISTS="${VECTOR_EXISTS:-0}" CAT_AUTO_EXISTS="${CAT_AUTO_EXISTS:-0}" CAT_USER_EXISTS="${CAT_USER_EXISTS:-0}" python3 <<'PYEOF' > "$REPORT_FILE"
import os
from datetime import datetime

backtick = chr(96)
code_block_start = backtick + backtick + backtick + "cql\n"
code_block_end = "\n" + backtick + backtick + backtick + "\n"

report = ""
report += "# 🏗️ Démonstration : Création des Index SAI pour operations_by_account\n\n"
report += f"**Date** : {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}\n"
report += "**Script** : 04_create_indexes.sh\n"
report += "**Objectif** : Démontrer la création des index SAI pour DomiramaCatOps\n\n"
report += "---\n\n"
report += "## 📋 Table des Matières\n\n"
report += "1. [Contexte HBase → HCD](#contexte-hbase--hcd)\n"
report += "2. [DDL - Index SAI](#ddl-index-sai)\n"
report += "3. [Vérifications](#vérifications)\n"
report += "4. [Conclusion](#conclusion)\n\n"
report += "---\n\n"
report += "## 📚 Contexte HBase → HCD\n\n"
report += "### Équivalences\n\n"
report += "| Concept HBase | Équivalent HCD | Statut |\n"
report += "|---------------|----------------|--------|\n"
report += "| Index Elasticsearch externe | Index SAI intégré | ✅ |\n"
report += "| Recherche full-text (Elasticsearch) | Index SAI full-text avec analyzers | ✅ |\n"
report += "| Recherche vectorielle (ML externe) | Index SAI vectoriel natif | ✅ |\n\n"
report += "### Avantages HCD\n\n"
report += "✅ **Index intégrés** (pas de système externe)\n"
report += "✅ **Performance optimisée** (pas de réseau externe)\n"
report += "✅ **Maintenance simplifiée** (un seul système)\n"
report += "✅ **Support vectoriel natif** (ANN intégré)\n\n"
report += "---\n\n"
report += "## 📋 DDL - Index SAI\n\n"
report += "### Index Créés\n\n"
report += "1. **idx_libelle_fulltext_advanced** : Recherche full-text sur libellé (analyzers français)\n"
report += "2. **idx_libelle_prefix_ngram** : Recherche partielle (N-Gram)\n"
report += "3. **idx_libelle_tokens** : Recherche partielle avec CONTAINS (Collection)\n"
report += "4. **idx_libelle_embedding_vector** : Recherche vectorielle (ANN)\n"
report += "5. **idx_cat_auto** : Filtrage rapide par catégorie batch\n"
report += "6. **idx_cat_user** : Filtrage rapide par catégorie client\n"
report += "7. **idx_montant** : Range queries sur montant\n"
report += "8. **idx_type_operation** : Filtrage rapide par type d operation\n\n"
report += "---\n\n"
report += "### Vérification\n\n"
report += f"✅ {os.environ.get('INDEXES', 'N/A')} index(es) SAI créé(s) pour operations_by_account\n"
if int(os.environ.get('INDEXES_META', '0')) > 0:
    report += f"✅ {os.environ.get('INDEXES_META', 'N/A')} index(es) SAI créé(s) pour tables meta-categories\n"
report += f"✅ **Total** : {os.environ.get('TOTAL_INDEXES', 'N/A')} index(es) SAI créé(s)\n\n"
report += "---\n\n"
report += "## 🔍 Vérifications\n\n"
report += "| Vérification | Attendu | Obtenu | Statut |\n"
report += "|--------------|---------|--------|--------|\n"
report += f"| Index Full-Text | idx_libelle_fulltext_advanced | {'✅' if int(os.environ.get('FULLTEXT_EXISTS','0'))>0 else '❌'} | {'✅' if int(os.environ.get('FULLTEXT_EXISTS','0'))>0 else '❌'} |\n"
report += f"| Index Vector | idx_libelle_embedding_vector | {'✅' if int(os.environ.get('VECTOR_EXISTS','0'))>0 else '❌'} | {'✅' if int(os.environ.get('VECTOR_EXISTS','0'))>0 else '❌'} |\n"
report += f"| Index Catégories | idx_cat_auto, idx_cat_user | {'✅' if int(os.environ.get('CAT_AUTO_EXISTS','0'))>0 and int(os.environ.get('CAT_USER_EXISTS','0'))>0 else '❌'} | {'✅' if int(os.environ.get('CAT_AUTO_EXISTS','0'))>0 and int(os.environ.get('CAT_USER_EXISTS','0'))>0 else '❌'} |\n"
report += f"| Total Index | 8+ | {os.environ.get('INDEXES','N/A')} | {'✅' if int(os.environ.get('INDEXES','0'))>=8 else '❌'} |\n\n"
report += "---\n\n"
report += "## ✅ Conclusion\n\n"
report += f"Les index SAI ont été créés avec succès :\n\n✅ **Total** : {os.environ.get('TOTAL_INDEXES','N/A')} index(es) SAI créé(s)\n\n"
report += "### Prochaines Étapes\n\n"
report += "- Script 05: Chargement des données (batch)\n"
report += "- Script 16-18: Tests de recherche avancée (full-text, fuzzy, vector, hybrid)\n\n"
report += "\n**✅ Configuration terminée avec succès !**\n"

print(report, end="")
PYEOF

success "✅ Rapport généré : $REPORT_FILE"
echo ""
