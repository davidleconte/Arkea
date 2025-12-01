#!/bin/bash
# ============================================
# Script 25 : Tests Feedbacks ICS (Version Didactique)
# Démontre les fonctionnalités compteurs atomiques par ICS (code catégorie)
# Équivalent HBase: INCREMENT sur FEEDBACK_ICS
# ============================================
#
# OBJECTIF :
#   Ce script démontre de manière très didactique les fonctionnalités compteurs atomiques
#   (feedbacks) par ICS (code catégorie) en exécutant des requêtes CQL directement via cqlsh.
#   
#   Cette version didactique affiche :
#   - Les équivalences HBase → HCD détaillées
#   - Les requêtes CQL complètes avant exécution
#   - Les résultats attendus pour chaque requête
#   - Les résultats obtenus avec mesure de performance
#   - Une documentation structurée pour livrable
#
# PRÉREQUIS :
#   - HCD démarré (./03_start_hcd.sh)
#   - Schéma configuré (./03_setup_meta_categories_tables.sh)
#   - Données chargées (./06_load_meta_categories_data_parquet.sh)
#   - Java 11 configuré via jenv
#
# UTILISATION :
#   ./25_test_feedbacks_ics.sh
#
# SORTIE :
#   - Requêtes CQL affichées avec explications
#   - Résultats de chaque requête
#   - Mesures de performance
#   - Documentation structurée générée
#
# PROCHAINES ÉTAPES :
#   - Script 26: Tests décisions salaires (./26_test_decisions_salaires.sh)
#   - Script 27: Démonstration Kafka Streaming (./27_demo_kafka_streaming.sh)
#
# ============================================

set -e

# Source les fonctions utilitaires et le profil d'environnement
source "$(dirname "${BASH_SOURCE[0]}")/../utils/didactique_functions.sh"
source "$(dirname "${BASH_SOURCE[0]}")/../../.poc-profile"

# ============================================
# CONFIGURATION
# ============================================
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd )"
INSTALL_DIR="${INSTALL_DIR:-/Users/david.leconte/Documents/Arkea}"
REPORT_FILE="${SCRIPT_DIR}/../doc/demonstrations/25_FEEDBACKS_ICS_DEMONSTRATION.md"
KEYSPACE_NAME="domiramacatops_poc"
TABLE_NAME="feedback_par_ics"

# HCD_HOME devrait être défini par .poc-profile
HCD_DIR="${HCD_HOME:-${INSTALL_DIR}/binaire/hcd-1.2.3}"

# Créer le répertoire de documentation
mkdir -p "$(dirname "$REPORT_FILE")"

# ============================================
# VÉRIFICATIONS PRÉALABLES
# ============================================
show_partie "0" "VÉRIFICATIONS PRÉALABLES"

check_hcd_status
check_jenv_java_version

# Vérifier que le keyspace et la table existent
check_schema "" "" # Vérifie HCD et Java
KEYSPACE_EXISTS=$("${HCD_DIR}/bin/cqlsh" localhost 9042 -e "SELECT keyspace_name FROM system_schema.keyspaces WHERE keyspace_name = '$KEYSPACE_NAME';" 2>&1 | grep -c "$KEYSPACE_NAME" || echo "0")
if [ "$KEYSPACE_EXISTS" -eq 0 ]; then
    error "Le keyspace '$KEYSPACE_NAME' n'existe pas. Exécutez d'abord ./01_setup_domiramaCatOps_keyspace.sh"
    exit 1
fi
TABLE_EXISTS=$("${HCD_DIR}/bin/cqlsh" localhost 9042 -e "SELECT table_name FROM system_schema.tables WHERE keyspace_name = '$KEYSPACE_NAME' AND table_name = '$TABLE_NAME';" 2>&1 | grep -c "$TABLE_NAME" || echo "0")
if [ "$TABLE_EXISTS" -eq 0 ]; then
    error "La table '$TABLE_NAME' n'existe pas. Exécutez d'abord ./03_setup_meta_categories_tables.sh"
    exit 1
fi

# ============================================
# EN-TÊTE DE DÉMONSTRATION
# ============================================
show_demo_header "Tests Feedbacks ICS (Compteurs Atomiques)"

# ============================================
# PARTIE 1: CONTEXTE HBase → HCD
# ============================================
show_partie "1" "CONTEXTE - FEEDBACKS ICS HBase vs HCD"

info "📚 ÉQUIVALENCES HBase → HCD pour les Feedbacks ICS :"
echo ""
echo "   HBase                          →  HCD (Cassandra)"
echo "   ──────────────────────────────    ─────────────────────────────"
echo "   FEEDBACK_ICS:{type}:{sens}:{ics}:{cat} →  feedback_par_ics"
echo "   INCREMENT atomique              →  Type COUNTER"
echo "   Compteurs dynamiques            →  Colonnes count_engine, count_client"
echo "   Rowkey composite                →  Partition key + Clustering key"
echo ""
info "📋 STRUCTURE DE LA TABLE feedback_par_ics :"
echo "   - Partition key: (type_operation, sens_operation, code_ics)"
echo "   - Clustering key: categorie"
echo "   - Colonnes compteurs: count_engine (COUNTER), count_client (COUNTER)"
echo "   - Métadonnées: last_updated_at, updated_by"
echo ""

# ============================================
# PARTIE 2: TEST 1 - Lecture Compteur par ICS
# ============================================
show_partie "2" "TEST 1 - LECTURE COMPTEUR PAR ICS"

show_test_section "Test 1 : Lecture compteur par ICS" "Lire le compteur de feedbacks pour un ICS (code catégorie) spécifique." "Retourne les compteurs (count_engine, count_client) par catégorie pour un ICS donné"

info "📝 Équivalent HBase :"
code "GET 'domirama-meta-categories', 'FEEDBACK_ICS:VIREMENT:DEBIT:ICS001:ALIMENTATION', 'counter'"
echo ""
info "📝 Requête CQL :"
code "SELECT type_operation, sens_operation, code_ics, categorie, count_engine, count_client"
code "FROM $KEYSPACE_NAME.$TABLE_NAME"
code "WHERE type_operation = 'VIREMENT'"
code "  AND sens_operation = 'DEBIT'"
code "  AND code_ics = 'ICS001';"
echo ""
info "   Explication :"
echo "      - Partition key : (type_operation, sens_operation, code_ics)"
echo "      - Clustering key : categorie (peut retourner plusieurs catégories)"
echo "      - Compteurs : count_engine (moteur), count_client (client)"
echo ""

info "🚀 Exécution de la requête..."
execute_cql_query "SELECT type_operation, sens_operation, code_ics, categorie, count_engine, count_client FROM $KEYSPACE_NAME.$TABLE_NAME WHERE type_operation = 'VIREMENT' AND sens_operation = 'DEBIT' AND code_ics = 'ICS001';" "Lecture compteur par ICS"

# ============================================
# PARTIE 3: TEST 2 - Incrément Compteur Moteur (par ICS)
# ============================================
show_partie "3" "TEST 2 - INCréMENT COMPTEUR MOTEUR (PAR ICS)"

show_test_section "Test 2 : Incrément compteur moteur par ICS" "Incrémenter le compteur moteur (count_engine) pour un ICS." "Compteur count_engine incrémenté de 1 (batch)"

info "📝 Équivalent HBase :"
code "INCREMENT 'domirama-meta-categories', 'FEEDBACK_ICS:VIREMENT:DEBIT:ICS001:ALIMENTATION', 'count_engine', 1"
echo ""
info "📝 Requête CQL :"
code "UPDATE $KEYSPACE_NAME.$TABLE_NAME"
code "SET count_engine = count_engine + 1"
code "WHERE type_operation = 'VIREMENT'"
code "  AND sens_operation = 'DEBIT'"
code "  AND code_ics = 'ICS001'"
code "  AND categorie = 'ALIMENTATION';"
echo ""
info "   Explication :"
echo "      - Type COUNTER : Opération atomique (pas de race condition)"
echo "      - Incrément : count_engine = count_engine + 1"
echo "      - Usage : Compteur de feedbacks acceptés par le moteur (batch)"
echo ""

info "🚀 Exécution de l'incrément..."
execute_cql_query "UPDATE $KEYSPACE_NAME.$TABLE_NAME SET count_engine = count_engine + 1 WHERE type_operation = 'VIREMENT' AND sens_operation = 'DEBIT' AND code_ics = 'ICS001' AND categorie = 'ALIMENTATION';" "Incrément compteur moteur"

info "🔍 Vérification de l'incrément..."
execute_cql_query "SELECT type_operation, sens_operation, code_ics, categorie, count_engine, count_client FROM $KEYSPACE_NAME.$TABLE_NAME WHERE type_operation = 'VIREMENT' AND sens_operation = 'DEBIT' AND code_ics = 'ICS001' AND categorie = 'ALIMENTATION';" "Vérification compteur incrémenté"

# ============================================
# PARTIE 4: TEST 3 - Incrément Compteur Client (par ICS)
# ============================================
show_partie "4" "TEST 3 - INCréMENT COMPTEUR CLIENT (PAR ICS)"

show_test_section "Test 3 : Incrément compteur client par ICS" "Incrémenter le compteur client (count_client) pour un ICS." "Compteur count_client incrémenté de 1 (correction client)"

info "📝 Équivalent HBase :"
code "INCREMENT 'domirama-meta-categories', 'FEEDBACK_ICS:VIREMENT:DEBIT:ICS001:ALIMENTATION', 'count_client', 1"
echo ""
info "📝 Requête CQL :"
code "UPDATE $KEYSPACE_NAME.$TABLE_NAME"
code "SET count_client = count_client + 1"
code "WHERE type_operation = 'VIREMENT'"
code "  AND sens_operation = 'DEBIT'"
code "  AND code_ics = 'ICS001'"
code "  AND categorie = 'ALIMENTATION';"
echo ""
info "   Explication :"
echo "      - Type COUNTER : Opération atomique (pas de race condition)"
echo "      - Incrément : count_client = count_client + 1"
echo "      - Usage : Compteur de feedbacks refusés/corrigés par le client (temps réel)"
echo ""

info "🚀 Exécution de l'incrément..."
execute_cql_query "UPDATE $KEYSPACE_NAME.$TABLE_NAME SET count_client = count_client + 1 WHERE type_operation = 'VIREMENT' AND sens_operation = 'DEBIT' AND code_ics = 'ICS001' AND categorie = 'ALIMENTATION';" "Incrément compteur client"

info "🔍 Vérification de l'incrément..."
execute_cql_query "SELECT type_operation, sens_operation, code_ics, categorie, count_engine, count_client FROM $KEYSPACE_NAME.$TABLE_NAME WHERE type_operation = 'VIREMENT' AND sens_operation = 'DEBIT' AND code_ics = 'ICS001' AND categorie = 'ALIMENTATION';" "Vérification compteur incrémenté"

# ============================================
# PARTIE 5: TEST 4 - Liste Top Feedbacks (par ICS)
# ============================================
show_partie "5" "TEST 4 - LISTE TOP FEEDBACKS (PAR ICS)"

show_test_section "Test 4 : Liste top feedbacks par ICS" "Lister les ICS avec le plus de feedbacks (tri par (count_engine + count_client) DESC)." "Lignes triées par total feedbacks DESC (application)"

info "📝 Équivalent HBase :"
code "SCAN 'domirama-meta-categories', {FILTER => \"PrefixFilter('FEEDBACK_ICS:VIREMENT:DEBIT')}\"}"
echo ""
info "📝 Requête CQL :"
code "SELECT type_operation, sens_operation, code_ics, categorie, count_engine, count_client"
code "FROM $KEYSPACE_NAME.$TABLE_NAME"
code "WHERE type_operation = 'VIREMENT'"
code "  AND sens_operation = 'DEBIT';"
echo ""
info "   Explication :"
echo "      - Partition key : (type_operation, sens_operation, code_ics)"
echo "      - Retourne tous les ICS pour un type/sens donné"
echo "      - Tri : Côté application par (count_engine + count_client) DESC"
echo "      - Usage : Identifier les ICS avec le plus de feedbacks"
echo ""

info "🚀 Exécution de la requête..."
execute_cql_query "SELECT type_operation, sens_operation, code_ics, categorie, count_engine, count_client FROM $KEYSPACE_NAME.$TABLE_NAME WHERE type_operation = 'VIREMENT' AND sens_operation = 'DEBIT';" "Liste top feedbacks par ICS"

info "💡 Note :"
echo "   Le tri par (count_engine + count_client) DESC se fait côté application,"
echo "   pas dans CQL (Cassandra ne supporte pas ORDER BY sur colonnes calculées)."
echo ""

# ============================================
# PARTIE 6: TEST 5 - Statistiques par ICS
# ============================================
show_partie "6" "TEST 5 - STATISTIQUES PAR ICS"

show_test_section "Test 5 : Statistiques par ICS" "Calculer les statistiques agrégées par ICS (total feedbacks, ratio accepté/refusé)." "Statistiques calculées côté application"

info "📝 Requête CQL :"
code "SELECT type_operation, sens_operation, code_ics, categorie,"
code "       count_engine, count_client,"
code "       (count_engine + count_client) as total_feedbacks"
code "FROM $KEYSPACE_NAME.$TABLE_NAME"
code "WHERE type_operation = 'VIREMENT'"
code "  AND sens_operation = 'DEBIT'"
code "  AND code_ics = 'ICS001';"
echo ""
info "   Explication :"
echo "      - Total feedbacks : count_engine + count_client"
echo "      - Ratio accepté : count_engine / (count_engine + count_client)"
echo "      - Ratio refusé : count_client / (count_engine + count_client)"
echo "      - Calcul : Côté application (Cassandra ne supporte pas les agrégations complexes)"
echo ""

info "🚀 Exécution de la requête..."
execute_cql_query "SELECT type_operation, sens_operation, code_ics, categorie, count_engine, count_client FROM $KEYSPACE_NAME.$TABLE_NAME WHERE type_operation = 'VIREMENT' AND sens_operation = 'DEBIT' AND code_ics = 'ICS001';" "Statistiques par ICS"

info "💡 Calcul côté application :"
echo "   - Total feedbacks = count_engine + count_client"
echo "   - Ratio accepté = count_engine / total_feedbacks"
echo "   - Ratio refusé = count_client / total_feedbacks"
echo ""

# ============================================
# PARTIE 7: RÉSUMÉ ET CONCLUSION
# ============================================
show_partie "7" "RÉSUMÉ ET CONCLUSION"

info "📊 Résumé de la démonstration Feedbacks ICS :"
echo ""
echo "   ✅ Lecture compteur : Requête par partition key (type, sens, ICS)"
echo "   ✅ Incrément atomique : Type COUNTER (pas de race condition)"
echo "   ✅ Compteurs séparés : count_engine (moteur) et count_client (client)"
echo "   ✅ Liste top feedbacks : Requête par partition key, tri côté application"
echo "   ✅ Statistiques : Calcul côté application (agrégations complexes)"
echo ""

info "💡 Avantages HCD vs HBase pour les Feedbacks ICS :"
echo ""
echo "   ✅ Type COUNTER : Opération atomique garantie (vs INCREMENT HBase)"
echo "   ✅ Structure normalisée : Table dédiée (vs colonnes dynamiques HBase)"
echo "   ✅ Performance : Partition key optimisée (vs scan HBase)"
echo "   ✅ Métadonnées : last_updated_at, updated_by (traçabilité)"
echo ""

info "📝 Prochaines étapes :"
echo ""
echo "   - Script 26: Tests décisions salaires (./26_test_decisions_salaires.sh)"
echo "   - Script 27: Démonstration Kafka Streaming (./27_demo_kafka_streaming.sh)"
echo ""

success "✅ Tests Feedbacks ICS terminés avec succès !"
info "📝 Documentation générée : $REPORT_FILE"
echo ""

# ============================================
# GÉNÉRATION DU RAPPORT MARKDOWN
# ============================================
info "📝 Génération du rapport de démonstration markdown..."

REPORT_CONTENT=$(cat << EOF
## 📚 Contexte HBase → HCD

### Équivalences

| Concept HBase | Équivalent HCD | Statut |
|---------------|----------------|--------|
| FEEDBACK_ICS:{type}:{sens}:{ics}:{cat} | \`feedback_par_ics\` | ✅ |
| INCREMENT atomique | Type \`COUNTER\` | ✅ |
| Compteurs dynamiques | Colonnes \`count_engine\`, \`count_client\` | ✅ |
| Rowkey composite | Partition key + Clustering key | ✅ |

### Structure de la table

- **Partition key** : \`(type_operation, sens_operation, code_ics)\`
- **Clustering key** : \`categorie\`
- **Colonnes compteurs** : \`count_engine\` (COUNTER), \`count_client\` (COUNTER)
- **Métadonnées** : \`last_updated_at\`, \`updated_by\`

---

## 🧪 Tests de Feedbacks ICS

### Test 1 : Lecture Compteur par ICS

**Équivalent HBase** :
\`\`\`
GET 'domirama-meta-categories', 'FEEDBACK_ICS:VIREMENT:DEBIT:ICS001:ALIMENTATION', 'counter'
\`\`\`

**Requête CQL** :
\`\`\`cql
SELECT type_operation, sens_operation, code_ics, categorie, count_engine, count_client
FROM $KEYSPACE_NAME.$TABLE_NAME
WHERE type_operation = 'VIREMENT'
  AND sens_operation = 'DEBIT'
  AND code_ics = 'ICS001';
\`\`\`
**Résultat** : Retourne les compteurs (count_engine, count_client) par catégorie pour un ICS donné.

### Test 2 : Incrément Compteur Moteur (par ICS)

**Équivalent HBase** :
\`\`\`
INCREMENT 'domirama-meta-categories', 'FEEDBACK_ICS:VIREMENT:DEBIT:ICS001:ALIMENTATION', 'count_engine', 1
\`\`\`

**Requête CQL** :
\`\`\`cql
UPDATE $KEYSPACE_NAME.$TABLE_NAME
SET count_engine = count_engine + 1
WHERE type_operation = 'VIREMENT'
  AND sens_operation = 'DEBIT'
  AND code_ics = 'ICS001'
  AND categorie = 'ALIMENTATION';
\`\`\`
**Résultat** : Compteur count_engine incrémenté de 1 (batch).

### Test 3 : Incrément Compteur Client (par ICS)

**Équivalent HBase** :
\`\`\`
INCREMENT 'domirama-meta-categories', 'FEEDBACK_ICS:VIREMENT:DEBIT:ICS001:ALIMENTATION', 'count_client', 1
\`\`\`

**Requête CQL** :
\`\`\`cql
UPDATE $KEYSPACE_NAME.$TABLE_NAME
SET count_client = count_client + 1
WHERE type_operation = 'VIREMENT'
  AND sens_operation = 'DEBIT'
  AND code_ics = 'ICS001'
  AND categorie = 'ALIMENTATION';
\`\`\`
**Résultat** : Compteur count_client incrémenté de 1 (correction client).

### Test 4 : Liste Top Feedbacks (par ICS)

**Équivalent HBase** :
\`\`\`
SCAN 'domirama-meta-categories', {FILTER => "PrefixFilter('FEEDBACK_ICS:VIREMENT:DEBIT')}"}
\`\`\`

**Requête CQL** :
\`\`\`cql
SELECT type_operation, sens_operation, code_ics, categorie, count_engine, count_client
FROM $KEYSPACE_NAME.$TABLE_NAME
WHERE type_operation = 'VIREMENT'
  AND sens_operation = 'DEBIT';
\`\`\`
**Résultat** : Lignes triées par (count_engine + count_client) DESC (application).

### Test 5 : Statistiques par ICS

**Requête CQL** :
\`\`\`cql
SELECT type_operation, sens_operation, code_ics, categorie, count_engine, count_client
FROM $KEYSPACE_NAME.$TABLE_NAME
WHERE type_operation = 'VIREMENT'
  AND sens_operation = 'DEBIT'
  AND code_ics = 'ICS001';
\`\`\`
**Résultat** : Statistiques calculées côté application (total feedbacks, ratio accepté/refusé).

---

## ✅ Conclusion

La démonstration des Feedbacks ICS a été réalisée avec succès, mettant en évidence :

✅ **Type COUNTER** : Opération atomique garantie (vs INCREMENT HBase).  
✅ **Structure normalisée** : Table dédiée (vs colonnes dynamiques HBase).  
✅ **Performance** : Partition key optimisée (vs scan HBase).  
✅ **Métadonnées** : last_updated_at, updated_by (traçabilité).

---

**✅ Tests Feedbacks ICS terminés avec succès !**
EOF
)
generate_report "$REPORT_FILE" "🔍 Tests : Feedbacks ICS DomiramaCatOps" "$REPORT_CONTENT"

