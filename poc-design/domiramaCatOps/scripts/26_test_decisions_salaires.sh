#!/bin/bash
set -euo pipefail
# ============================================
# Script 26 : Tests Décisions Salaires (Version Didactique)
# Démontre les fonctionnalités de gestion des décisions salaires
# Équivalent HBase: SALARY_DECISION:{libellé}
# ============================================
#
# OBJECTIF :
#   Ce script démontre de manière très didactique les fonctionnalités de gestion des
#   décisions salaires (méthode de catégorisation sur libellés taggés salaires).
#
#   Cette version didactique affiche :
#   - Les équivalences HBase → HCD détaillées
#   - Les requêtes CQL complètes avant exécution
#   - Les résultats attendus pour chaque requête
#   - Les résultats obtenus avec mesure de performance
#   - Une documentation structurée pour livrable
#
# PRÉREQUIS :
#   - HCD démarré (./scripts/setup/03_start_hcd.sh)
#   - Schéma configuré (./03_setup_meta_categories_tables.sh)
#   - Données chargées (./06_load_meta_categories_data_parquet.sh)
#   - Java 11 configuré via jenv
#
# UTILISATION :
#   ./26_test_decisions_salaires.sh
#
# SORTIE :
#   - Requêtes CQL affichées avec explications
#   - Résultats de chaque requête
#   - Mesures de performance
#   - Documentation structurée générée
#
# PROCHAINES ÉTAPES :
#   - Script 27: Démonstration Kafka Streaming (./27_demo_kafka_streaming.sh)
#
# ============================================

set -euo pipefail

# Source les fonctions utilitaires et le profil d'environnement
source "$(dirname "${BASH_SOURCE[0]}")/../utils/didactique_functions.sh"
source "$(dirname "${BASH_SOURCE[0]}")/../../.poc-profile"

# ============================================
# CONFIGURATION
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

REPORT_FILE="${SCRIPT_DIR}/../doc/demonstrations/26_DECISIONS_SALAIRES_DEMONSTRATION.md"
KEYSPACE_NAME="domiramacatops_poc"
TABLE_NAME="decisions_salaires"
# HCD_HOME devrait être défini par .poc-profile
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
KEYSPACE_EXISTS=$("${HCD_DIR}/bin/cqlsh" "$HCD_HOST" "$HCD_PORT" -e "SELECT keyspace_name FROM system_schema.keyspaces WHERE keyspace_name = '$KEYSPACE_NAME';" 2>&1 | grep -c "$KEYSPACE_NAME" || echo "0")
if [ "$KEYSPACE_EXISTS" -eq 0 ]; then
    error "Le keyspace '$KEYSPACE_NAME' n'existe pas. Exécutez d'abord ./01_setup_domiramaCatOps_keyspace.sh"
    exit 1
fi
TABLE_EXISTS=$("${HCD_DIR}/bin/cqlsh" "$HCD_HOST" "$HCD_PORT" -e "SELECT table_name FROM system_schema.tables WHERE keyspace_name = '$KEYSPACE_NAME' AND table_name = '$TABLE_NAME';" 2>&1 | grep -c "$TABLE_NAME" || echo "0")
if [ "$TABLE_EXISTS" -eq 0 ]; then
    error "La table '$TABLE_NAME' n'existe pas. Exécutez d'abord ./03_setup_meta_categories_tables.sh"
    exit 1
fi

# ============================================
# EN-TÊTE DE DÉMONSTRATION
# ============================================
show_demo_header "Tests Décisions Salaires"

# ============================================
# PARTIE 1: CONTEXTE HBase → HCD
# ============================================
show_partie "1" "CONTEXTE - DÉCISIONS SALAIRES HBase vs HCD"

info "📚 ÉQUIVALENCES HBase → HCD pour les Décisions Salaires :"
echo ""
echo "   HBase                          →  HCD (Cassandra)"
echo "   ──────────────────────────────    ─────────────────────────────"
echo "   SALARY_DECISION:{libellé}      →  decisions_salaires"
echo "   Rowkey simple                   →  PRIMARY KEY (libelle_simplifie)"
echo "   Colonnes dynamiques             →  Colonnes normalisées"
echo ""
info "📋 STRUCTURE DE LA TABLE decisions_salaires :"
echo "   - PRIMARY KEY: libelle_simplifie"
echo "   - Colonnes: methode_utilisee, modele, actif"
echo "   - Métadonnées: created_at, updated_at"
echo "   - Usage: Méthode de catégorisation sur libellés taggés salaires"
echo ""

# ============================================
# PARTIE 2: TEST 1 - Lecture Décision Salaire
# ============================================
show_partie "2" "TEST 1 - LECTURE DÉCISION SALAIRE"

show_test_section "Test 1 : Lecture décision salaire" "Lire la décision salaire pour un libellé spécifique." "Retourne la méthode utilisée, le modèle et le statut actif"

info "📝 Équivalent HBase :"
code "GET 'domirama-meta-categories', 'SALARY_DECISION:SALAIRE'"
echo ""
info "📝 Requête CQL :"
code "SELECT libelle_simplifie, methode_utilisee, modele, actif, created_at, updated_at"
code "FROM $KEYSPACE_NAME.$TABLE_NAME"
code "WHERE libelle_simplifie = 'SALAIRE';"
echo ""
info "   Explication :"
echo "      - PRIMARY KEY: libelle_simplifie (accès direct)"
echo "      - methode_utilisee: Méthode de catégorisation utilisée"
echo "      - modele: Modèle ML utilisé (si applicable)"
echo "      - actif: Statut actif/inactif de la décision"
echo ""

info "🚀 Exécution de la requête..."
execute_cql_query "SELECT libelle_simplifie, methode_utilisee, modele, actif, created_at, updated_at FROM $KEYSPACE_NAME.$TABLE_NAME WHERE libelle_simplifie = 'SALAIRE';" "Lecture décision salaire"

# ============================================
# PARTIE 3: TEST 2 - Insertion Décision Salaire
# ============================================
show_partie "3" "TEST 2 - INSERTION DÉCISION SALAIRE"

show_test_section "Test 2 : Insertion décision salaire" "Insérer une nouvelle décision salaire pour un libellé." "Décision salaire créée avec méthode, modèle et statut actif"

info "📝 Équivalent HBase :"
code "PUT 'domirama-meta-categories', 'SALARY_DECISION:SALAIRE', 'methode', 'ML_MODEL'"
code "PUT 'domirama-meta-categories', 'SALARY_DECISION:SALAIRE', 'modele', 'bert-base'"
code "PUT 'domirama-meta-categories', 'SALARY_DECISION:SALAIRE', 'actif', 'true'"
echo ""
info "📝 Requête CQL :"
code "INSERT INTO $KEYSPACE_NAME.$TABLE_NAME"
code "  (libelle_simplifie, methode_utilisee, modele, actif, created_at, updated_at)"
code "VALUES"
code "  ('SALAIRE', 'ML_MODEL', 'bert-base', true, toTimestamp(now()), toTimestamp(now()));"
echo ""
info "   Explication :"
echo "      - INSERT : Création d'une nouvelle décision"
echo "      - methode_utilisee: 'ML_MODEL' (modèle machine learning)"
echo "      - modele: 'bert-base' (nom du modèle)"
echo "      - actif: true (décision active)"
echo "      - Timestamps: created_at et updated_at"
echo ""

info "🚀 Exécution de l'insertion..."
execute_cql_query "INSERT INTO $KEYSPACE_NAME.$TABLE_NAME (libelle_simplifie, methode_utilisee, modele, actif, created_at, updated_at) VALUES ('SALAIRE', 'ML_MODEL', 'bert-base', true, toTimestamp(now()), toTimestamp(now()));" "Insertion décision salaire"

info "🔍 Vérification de l'insertion..."
execute_cql_query "SELECT libelle_simplifie, methode_utilisee, modele, actif, created_at, updated_at FROM $KEYSPACE_NAME.$TABLE_NAME WHERE libelle_simplifie = 'SALAIRE';" "Vérification décision insérée"

# ============================================
# PARTIE 4: TEST 3 - Mise à Jour Décision Salaire
# ============================================
show_partie "4" "TEST 3 - MISE À JOUR DÉCISION SALAIRE"

show_test_section "Test 3 : Mise à jour décision salaire" "Mettre à jour une décision salaire existante (changement de modèle)." "Décision salaire mise à jour avec nouveau modèle et updated_at"

info "📝 Équivalent HBase :"
code "PUT 'domirama-meta-categories', 'SALARY_DECISION:SALAIRE', 'modele', 'bert-large'"
code "PUT 'domirama-meta-categories', 'SALARY_DECISION:SALAIRE', 'updated_at', '2024-01-20 10:00:00'"
echo ""
info "📝 Requête CQL :"
code "UPDATE $KEYSPACE_NAME.$TABLE_NAME"
code "SET modele = 'bert-large',"
code "    updated_at = toTimestamp(now())"
code "WHERE libelle_simplifie = 'SALAIRE';"
echo ""
info "   Explication :"
echo "      - UPDATE : Mise à jour d'une décision existante"
echo "      - modele: Changement de 'bert-base' à 'bert-large'"
echo "      - updated_at: Mise à jour du timestamp"
echo ""

info "🚀 Exécution de la mise à jour..."
execute_cql_query "UPDATE $KEYSPACE_NAME.$TABLE_NAME SET modele = 'bert-large', updated_at = toTimestamp(now()) WHERE libelle_simplifie = 'SALAIRE';" "Mise à jour décision salaire"

info "🔍 Vérification de la mise à jour..."
execute_cql_query "SELECT libelle_simplifie, methode_utilisee, modele, actif, created_at, updated_at FROM $KEYSPACE_NAME.$TABLE_NAME WHERE libelle_simplifie = 'SALAIRE';" "Vérification décision mise à jour"

# ============================================
# PARTIE 5: TEST 4 - Désactivation Décision Salaire
# ============================================
show_partie "5" "TEST 4 - DÉSACTIVATION DÉCISION SALAIRE"

show_test_section "Test 4 : Désactivation décision salaire" "Désactiver une décision salaire (actif = false)." "Décision salaire désactivée"

info "📝 Équivalent HBase :"
code "PUT 'domirama-meta-categories', 'SALARY_DECISION:SALAIRE', 'actif', 'false'"
echo ""
info "📝 Requête CQL :"
code "UPDATE $KEYSPACE_NAME.$TABLE_NAME"
code "SET actif = false,"
code "    updated_at = toTimestamp(now())"
code "WHERE libelle_simplifie = 'SALAIRE';"
echo ""
info "   Explication :"
echo "      - actif: false (décision désactivée)"
echo "      - updated_at: Mise à jour du timestamp"
echo "      - Usage: Désactiver une décision sans la supprimer"
echo ""

info "🚀 Exécution de la désactivation..."
execute_cql_query "UPDATE $KEYSPACE_NAME.$TABLE_NAME SET actif = false, updated_at = toTimestamp(now()) WHERE libelle_simplifie = 'SALAIRE';" "Désactivation décision salaire"

info "🔍 Vérification de la désactivation..."
execute_cql_query "SELECT libelle_simplifie, methode_utilisee, modele, actif, created_at, updated_at FROM $KEYSPACE_NAME.$TABLE_NAME WHERE libelle_simplifie = 'SALAIRE';" "Vérification décision désactivée"

# ============================================
# PARTIE 6: TEST 5 - Liste Décisions Actives
# ============================================
show_partie "6" "TEST 5 - LISTE DÉCISIONS ACTIVES"

show_test_section "Test 5 : Liste décisions actives" "Lister toutes les décisions salaires actives." "Liste des décisions avec actif = true"

info "📝 Requête CQL :"
code "SELECT libelle_simplifie, methode_utilisee, modele, actif, created_at, updated_at"
code "FROM $KEYSPACE_NAME.$TABLE_NAME"
code "WHERE actif = true ALLOW FILTERING;"
echo ""
info "   Explication :"
echo "      - WHERE actif = true : Filtre sur colonne non-clé"
echo "      - ALLOW FILTERING : Nécessaire pour filtrage sur colonne non-clé"
echo "      - Usage: Lister toutes les décisions actives pour affichage"
echo "      - Note: En production, utiliser un index SAI sur 'actif'"
echo ""

info "🚀 Exécution de la requête..."
execute_cql_query "SELECT libelle_simplifie, methode_utilisee, modele, actif, created_at, updated_at FROM $KEYSPACE_NAME.$TABLE_NAME WHERE actif = true ALLOW FILTERING;" "Liste décisions actives"

info "💡 Optimisation :"
echo "   Pour améliorer les performances, créer un index SAI sur 'actif' :"
code "CREATE CUSTOM INDEX idx_decisions_actif"
code "ON $KEYSPACE_NAME.$TABLE_NAME(actif)"
code "USING 'StorageAttachedIndex';"
echo ""

# ============================================
# PARTIE 7: RÉSUMÉ ET CONCLUSION
# ============================================
show_partie "7" "RÉSUMÉ ET CONCLUSION"

info "📊 Résumé de la démonstration Décisions Salaires :"
echo ""
echo "   ✅ Lecture décision : Requête par PRIMARY KEY (libelle_simplifie)"
echo "   ✅ Insertion décision : Création avec méthode, modèle et statut"
echo "   ✅ Mise à jour décision : Modification de méthode/modèle"
echo "   ✅ Désactivation décision : actif = false (soft delete)"
echo "   ✅ Liste décisions actives : Filtrage sur colonne non-clé"
echo ""

info "💡 Avantages HCD vs HBase pour les Décisions Salaires :"
echo ""
echo "   ✅ Structure normalisée : Table dédiée (vs colonnes dynamiques HBase)"
echo "   ✅ Métadonnées : created_at, updated_at (traçabilité)"
echo "   ✅ Soft delete : actif = false (vs suppression HBase)"
echo "   ✅ Index SAI : Possibilité d'indexer sur 'actif' (performance)"
echo ""

info "📝 Prochaines étapes :"
echo ""
echo "   - Script 27: Démonstration Kafka Streaming (./27_demo_kafka_streaming.sh)"
echo ""

success "✅ Tests Décisions Salaires terminés avec succès !"
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
| SALARY_DECISION:{libellé} | \`decisions_salaires\` | ✅ |
| Rowkey simple | PRIMARY KEY (libelle_simplifie) | ✅ |
| Colonnes dynamiques | Colonnes normalisées | ✅ |

### Structure de la table

- **PRIMARY KEY** : \`libelle_simplifie\`
- **Colonnes** : \`methode_utilisee\`, \`modele\`, \`actif\`
- **Métadonnées** : \`created_at\`, \`updated_at\`
- **Usage** : Méthode de catégorisation sur libellés taggés salaires

---

## 🧪 Tests de Décisions Salaires

### Test 1 : Lecture Décision Salaire

**Équivalent HBase** :
\`\`\`
GET 'domirama-meta-categories', 'SALARY_DECISION:SALAIRE'
\`\`\`

**Requête CQL** :
\`\`\`cql
SELECT libelle_simplifie, methode_utilisee, modele, actif, created_at, updated_at
FROM $KEYSPACE_NAME.$TABLE_NAME
WHERE libelle_simplifie = 'SALAIRE';
\`\`\`
**Résultat** : Retourne la méthode utilisée, le modèle et le statut actif.

### Test 2 : Insertion Décision Salaire

**Équivalent HBase** :
\`\`\`
PUT 'domirama-meta-categories', 'SALARY_DECISION:SALAIRE', 'methode', 'ML_MODEL'
PUT 'domirama-meta-categories', 'SALARY_DECISION:SALAIRE', 'modele', 'bert-base'
PUT 'domirama-meta-categories', 'SALARY_DECISION:SALAIRE', 'actif', 'true'
\`\`\`

**Requête CQL** :
\`\`\`cql
INSERT INTO $KEYSPACE_NAME.$TABLE_NAME
  (libelle_simplifie, methode_utilisee, modele, actif, created_at, updated_at)
VALUES
  ('SALAIRE', 'ML_MODEL', 'bert-base', true, toTimestamp(now()), toTimestamp(now()));
\`\`\`
**Résultat** : Décision salaire créée avec méthode, modèle et statut actif.

### Test 3 : Mise à Jour Décision Salaire

**Équivalent HBase** :
\`\`\`
PUT 'domirama-meta-categories', 'SALARY_DECISION:SALAIRE', 'modele', 'bert-large'
PUT 'domirama-meta-categories', 'SALARY_DECISION:SALAIRE', 'updated_at', '2024-01-20 10:00:00'
\`\`\`

**Requête CQL** :
\`\`\`cql
UPDATE $KEYSPACE_NAME.$TABLE_NAME
SET modele = 'bert-large',
    updated_at = toTimestamp(now())
WHERE libelle_simplifie = 'SALAIRE';
\`\`\`
**Résultat** : Décision salaire mise à jour avec nouveau modèle et updated_at.

### Test 4 : Désactivation Décision Salaire

**Équivalent HBase** :
\`\`\`
PUT 'domirama-meta-categories', 'SALARY_DECISION:SALAIRE', 'actif', 'false'
\`\`\`

**Requête CQL** :
\`\`\`cql
UPDATE $KEYSPACE_NAME.$TABLE_NAME
SET actif = false,
    updated_at = toTimestamp(now())
WHERE libelle_simplifie = 'SALAIRE';
\`\`\`
**Résultat** : Décision salaire désactivée (soft delete).

### Test 5 : Liste Décisions Actives

**Requête CQL** :
\`\`\`cql
SELECT libelle_simplifie, methode_utilisee, modele, actif, created_at, updated_at
FROM $KEYSPACE_NAME.$TABLE_NAME
WHERE actif = true ALLOW FILTERING;
\`\`\`
**Résultat** : Liste des décisions avec actif = true.

**Optimisation** : Créer un index SAI sur 'actif' pour améliorer les performances.

---

## ✅ Conclusion

La démonstration des Décisions Salaires a été réalisée avec succès, mettant en évidence :

✅ **Structure normalisée** : Table dédiée (vs colonnes dynamiques HBase).
✅ **Métadonnées** : created_at, updated_at (traçabilité).
✅ **Soft delete** : actif = false (vs suppression HBase).
✅ **Index SAI** : Possibilité d'indexer sur 'actif' (performance).

---

**✅ Tests Décisions Salaires terminés avec succès !**
EOF
)
generate_report "$REPORT_FILE" "💰 Tests : Décisions Salaires DomiramaCatOps" "$REPORT_CONTENT"
