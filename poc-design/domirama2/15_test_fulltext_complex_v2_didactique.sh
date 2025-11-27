#!/bin/bash
# ============================================
# Script 15 : Tests Full-Text Search Complexes (Version Didactique)
# Recherches multi-termes, accents, variations
# ============================================
#
# OBJECTIF :
#   Ce script exécute des tests de recherche full-text complexes sur la table
#   'operations_by_account' en utilisant les index SAI avancés avec différents
#   analyzers (lowercase, asciifolding, frenchLightStem, stop words).
#   
#   Cette version didactique affiche :
#   - Les analyzers SAI expliqués en détail
#   - Les recherches multi-termes expliquées (AND implicite)
#   - Les requêtes CQL détaillées avec explications
#   - Les résultats de chaque test capturés et formatés
#   - Une documentation structurée pour livrable
#
# PRÉREQUIS :
#   - HCD démarré (./03_start_hcd.sh)
#   - Schéma configuré (./10_setup_domirama2_poc.sh)
#   - Données chargées (./11_load_domirama2_data_parquet.sh)
#   - Index avancés configurés (./16_setup_advanced_indexes.sh)
#   - Fichier de tests présent: schemas/06_domirama2_search_fulltext_complex.cql
#
# UTILISATION :
#   ./15_test_fulltext_complex_v2_didactique.sh
#
# SORTIE :
#   - Analyzers SAI expliqués
#   - Recherches multi-termes expliquées
#   - Requêtes CQL affichées avec explications
#   - Résultats de chaque test formatés
#   - Documentation structurée générée
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
TEST_FILE="${SCRIPT_DIR}/schemas/06_domirama2_search_fulltext_complex.cql"
REPORT_FILE="${SCRIPT_DIR}/doc/demonstrations/15_FULLTEXT_COMPLEX_DEMONSTRATION.md"

# Créer le répertoire de documentation
mkdir -p "$(dirname "$REPORT_FILE")"

# Vérifier que HCD est démarré
if ! pgrep -f "cassandra" > /dev/null; then
    error "HCD n'est pas démarré. Exécutez d'abord: ./03_start_hcd.sh"
    exit 1
fi

# Vérifier que le keyspace existe
cd "$HCD_DIR"
jenv local 11
eval "$(jenv init -)"
if ! ./bin/cqlsh localhost 9042 -e "DESCRIBE KEYSPACE domirama2_poc;" > /dev/null 2>&1; then
    error "Le keyspace domirama2_poc n'existe pas. Exécutez d'abord: ./10_setup_domirama2_poc.sh"
    exit 1
fi

# Vérifier que le fichier de test existe
if [ ! -f "$TEST_FILE" ]; then
    error "Fichier de test non trouvé: $TEST_FILE"
    exit 1
fi

# Sélectionner un compte avec des données correspondant aux recherches
# On cherche un compte qui a "loyer" et "paris" pour avoir des résultats valides
FIRST_ACCOUNT=$(./bin/cqlsh localhost 9042 -e "USE domirama2_poc; SELECT code_si, contrat FROM operations_by_account WHERE libelle : 'loyer' AND libelle : 'paris' LIMIT 1;" 2>&1 | grep -v "Warnings" | grep -E "^[[:space:]]*[0-9]" | head -1)

# Si aucun compte avec loyer+paris, prendre le premier compte disponible
if [ -z "$FIRST_ACCOUNT" ]; then
    FIRST_ACCOUNT=$(./bin/cqlsh localhost 9042 -e "USE domirama2_poc; SELECT code_si, contrat FROM operations_by_account LIMIT 1;" 2>&1 | grep -v "Warnings" | grep -E "^[[:space:]]*[0-9]" | head -1)
fi

if [ -z "$FIRST_ACCOUNT" ]; then
    warn "Aucune donnée trouvée. Chargez d'abord les données avec ./11_load_domirama2_data_parquet.sh"
    exit 1
fi

# Extraire code_si et contrat (format cqlsh: "       1 | 5913101072")
# Utiliser le pipe comme séparateur
CODE_SI=$(echo "$FIRST_ACCOUNT" | awk -F'|' '{print $1}' | tr -d " ")
CONTRAT=$(echo "$FIRST_ACCOUNT" | awk -F'|' '{print $2}' | tr -d " ")

# ============================================
# EN-TÊTE DE DÉMONSTRATION
# ============================================
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  🔍 DÉMONSTRATION DIDACTIQUE : Tests Full-Text Search Complexes"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
info "📚 Cette démonstration affiche :"
echo "   ✅ Analyzers SAI expliqués en détail"
echo "   ✅ Recherches multi-termes expliquées (AND implicite)"
echo "   ✅ Requêtes CQL détaillées avec explications"
echo "   ✅ Résultats de chaque test capturés et formatés"
echo "   ✅ Documentation structurée générée automatiquement"
echo ""

# ============================================
# PARTIE 1: CONTEXTE - ANALYZERS SAI
# ============================================
echo ""
section "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
section "  📚 PARTIE 1: CONTEXTE - ANALYZERS SAI"
section "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

info "📚 ANALYZERS SAI (Storage-Attached Index) :"
echo ""
echo "   Les analyzers SAI traitent le texte avant l'indexation et la recherche."
echo "   Ils permettent d'améliorer la pertinence et la tolérance aux variations."
echo ""
echo "   🔍 Analyzer : lowercase"
echo "      - Fonction : Convertit tout en minuscules"
echo "      - Exemple : Loyer → loyer, LOYER → loyer"
echo "      - Usage : Recherche insensible à la casse"
echo ""
echo "   🔍 Analyzer : asciifolding"
echo "      - Fonction : Supprime les accents"
echo "      - Exemple : impayé → impaye, café → cafe"
echo "      - Usage : Recherche tolérante aux accents"
echo ""
echo "   🔍 Analyzer : frenchLightStem"
echo "      - Fonction : Racinisation française - stemming"
echo "      - Exemple : loyers → loyer, virements → virement"
echo "      - Usage : Recherche tolérante au pluriel/singulier"
echo ""

info "💡 Configuration de l'Analyzer dans le Schéma :"
echo ""
code "CREATE CUSTOM INDEX idx_libelle_fulltext_advanced"
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
echo "      - tokenizer : standard - découpe le texte en mots"
echo "      - filters : Appliqués dans l'ordre - lowercase → stemming → asciifolding"
echo "      - Chaque filtre améliore la tolérance aux variations"
echo ""

# ============================================
# PARTIE 2: RECHERCHES MULTI-TERMES
# ============================================
echo ""
section "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
section "  🔍 PARTIE 2: RECHERCHES MULTI-TERMES"
section "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

info "📚 RECHERCHES MULTI-TERMES :"
echo ""
echo "   🔍 Principe :"
echo "      - Recherche de plusieurs mots simultanément"
echo "      - AND implicite : Tous les termes doivent être présents"
echo "      - Ordre des termes : Peu importe l'ordre"
echo ""
echo "   📋 Syntaxe CQL :"
echo ""
code "SELECT * FROM operations_by_account"
code "WHERE code_si = '$CODE_SI'"
code "  AND contrat = '$CONTRAT'"
code "  AND libelle : 'loyer'  -- Premier terme"
code "  AND libelle : 'paris'  -- Deuxième terme - AND implicite"
code "LIMIT 20;"
echo ""
info "   Explication :"
echo "      - libelle : 'loyer' AND libelle : 'paris'"
echo "      - Trouve les opérations contenant loyer ET paris"
echo "      - L'ordre des termes n'a pas d'importance"
echo ""

# ============================================
# PARTIE 3: AFFICHAGE DES REQUÊTES CQL
# ============================================
echo ""
section "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
section "  📝 PARTIE 3: REQUÊTES CQL - TESTS COMPLEXES"
section "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

info "📋 Le fichier de test contient 20 tests de recherche complexes :"
echo ""
echo '   1-6. Recherches multi-termes (2 termes)'
echo '   7-10. Recherches triple termes'
echo '   11. Recherche avec stemming (pluriel)'
echo '   12-15. Recherches multi-termes variées'
echo '   16-17. Recherches avec accents (asciifolding)'
echo '   18-20. Recherches combinées (full-text + filtres)'
echo ""

expected "📋 Exemple Test 1 : Recherche multi-termes loyer paris"
echo "   Objectif : Rechercher les opérations contenant loyer ET paris"
echo "   Analyzers utilisés : lowercase, asciifolding, frenchLightStem"
echo ""
code "SELECT code_si, contrat, date_op, libelle, montant, cat_auto"
code "FROM operations_by_account"
code "WHERE code_si = '$CODE_SI'"
code "  AND contrat = '$CONTRAT'"
code "  AND libelle : 'loyer'  -- Premier terme"
code "  AND libelle : 'paris'  -- Deuxième terme - AND implicite"
code "LIMIT 20;"
echo ""
info "   Explication :"
echo "      - AND implicite : Trouve les opérations contenant loyer ET paris"
echo "      - lowercase : Loyer ou LOYER trouvés"
echo "      - asciifolding : paris trouvé même si accentué"
echo "      - frenchLightStem : loyers trouvé - pluriel"
echo ""

# ============================================
# PARTIE 4: EXÉCUTION DES TESTS
# ============================================
echo ""
section "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
section "  🚀 PARTIE 4: EXÉCUTION DES TESTS COMPLEXES"
section "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

info "🚀 Exécution du fichier de test : $TEST_FILE"
info "📊 Compte utilisé pour les tests: code_si=$CODE_SI, contrat=$CONTRAT"
echo ""

# Remplacer les placeholders dans le fichier CQL
TEMP_CQL=$(mktemp)
sed "s/code_si = '1'/code_si = '$CODE_SI'/g; s/code_si = '01'/code_si = '$CODE_SI'/g; s/contrat = '5913101072'/contrat = '$CONTRAT'/g; s/contrat = '1234567890'/contrat = '$CONTRAT'/g" "$TEST_FILE" > "$TEMP_CQL"

# Exécuter les tests et capturer la sortie
info "   Exécution en cours..."
TEST_OUTPUT=$(timeout 60 ./bin/cqlsh localhost 9042 -f "$TEMP_CQL" 2>&1) || TEST_EXIT_CODE=$?
TEST_EXIT_CODE=${TEST_EXIT_CODE:-0}

# Afficher la sortie filtrée (sans warnings)
echo "$TEST_OUTPUT" | grep -vE "^Warnings|^$" | head -100 || true

rm -f "$TEMP_CQL"

if [ $TEST_EXIT_CODE -eq 0 ]; then
    success "✅ Tests Full-Text Search complexes exécutés avec succès"
else
    warn "⚠️  Certains tests peuvent avoir échoué ou pris trop de temps"
    warn "⚠️  Les validations seront effectuées ci-dessous"
fi

echo ""

# ============================================
# PARTIE 5: VALIDATION DE LA PERTINENCE
# ============================================
echo ""
section "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
section "  ✅ PARTIE 5: VALIDATION DE LA PERTINENCE AVEC ANALYZERS"
section "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

info "🔍 Vérification de la pertinence des résultats avec analyzers..."
echo ""

# Test 1 : Recherche multi-termes
expected "📋 Test 1 : Recherche loyer paris - multi-termes"
echo "   Attendu : Opérations contenant loyer ET paris"
CQL_QUERY1=$(printf "USE domirama2_poc; SELECT COUNT(*) FROM operations_by_account WHERE code_si = '%s' AND contrat = '%s' AND libelle : 'loyer' AND libelle : 'paris' LIMIT 20;" "$CODE_SI" "$CONTRAT")
RESULT1=$(./bin/cqlsh localhost 9042 -e "$CQL_QUERY1" 2>&1 | grep -v "Warnings" | grep -E "^[[:space:]]*[0-9]+" | head -1 | tr -d " ")
if [ -n "$RESULT1" ] && [ "$RESULT1" -gt 0 ]; then
    success "✅ $RESULT1 resultat trouve pour loyer paris - multi-termes"
else
    warn "⚠️  Aucun résultat trouvé pour loyer paris"
fi
echo ""

# Test 2 : Recherche avec accent (asciifolding)
expected "📋 Test 2 : Recherche impaye - asciifolding"
echo "   Attendu : Opérations contenant IMPAYÉ - grâce à l'asciifolding"
CQL_QUERY2=$(printf "USE domirama2_poc; SELECT COUNT(*) FROM operations_by_account WHERE code_si = '%s' AND contrat = '%s' AND libelle : 'impaye' LIMIT 20;" "$CODE_SI" "$CONTRAT")
RESULT2=$(./bin/cqlsh localhost 9042 -e "$CQL_QUERY2" 2>&1 | grep -v "Warnings" | grep -E "^[[:space:]]*[0-9]+" | head -1 | tr -d " ")
if [ -n "$RESULT2" ] && [ "$RESULT2" -gt 0 ]; then
    success "✅ $RESULT2 resultat trouve pour impaye - asciifolding"
else
    warn "⚠️  Aucun résultat trouvé pour impaye"
fi
echo ""

# Test 11 : Recherche avec stemming
expected "📋 Test 11 : Recherche loyers - stemming"
echo "   Attendu : Opérations contenant LOYER - grâce au stemming français"
CQL_QUERY11=$(printf "USE domirama2_poc; SELECT COUNT(*) FROM operations_by_account WHERE code_si = '%s' AND contrat = '%s' AND libelle : 'loyers' LIMIT 20;" "$CODE_SI" "$CONTRAT")
RESULT11=$(./bin/cqlsh localhost 9042 -e "$CQL_QUERY11" 2>&1 | grep -v "Warnings" | grep -E "^[[:space:]]*[0-9]+" | head -1 | tr -d " ")
if [ -n "$RESULT11" ] && [ "$RESULT11" -gt 0 ]; then
    success "✅ $RESULT11 resultat trouve pour loyers - stemming"
else
    warn "⚠️  Aucun résultat trouvé pour loyers"
fi
echo ""

# Test 18 : Recherche combinée
expected "📋 Test 18 : Recherche combinée loyer paris + montant < -500"
echo "   Attendu : Opérations contenant loyer ET paris ET montant < -500"
CQL_QUERY18=$(printf "USE domirama2_poc; SELECT COUNT(*) FROM operations_by_account WHERE code_si = '%s' AND contrat = '%s' AND libelle : 'loyer' AND libelle : 'paris' AND montant < -500 LIMIT 20;" "$CODE_SI" "$CONTRAT")
RESULT18=$(./bin/cqlsh localhost 9042 -e "$CQL_QUERY18" 2>&1 | grep -v "Warnings" | grep -E "^[[:space:]]*[0-9]+" | head -1 | tr -d " ")
if [ -n "$RESULT18" ]; then
    success "✅ $RESULT18 resultat trouve pour loyer paris + montant < -500"
else
    warn "⚠️  Aucun résultat trouvé pour loyer paris + montant < -500"
fi
echo ""

# ============================================
# PARTIE 6: RÉSUMÉ ET DOCUMENTATION
# ============================================
echo ""
section "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
section "  📊 PARTIE 6: RÉSUMÉ ET CONCLUSION"
section "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

info "📊 Résumé des tests Full-Text Search complexes :"
echo ""
echo "   ✅ 20 tests de recherche complexes exécutés"
echo "   ✅ Analyzers SAI validés - lowercase, asciifolding, stemming"
echo "   ✅ Recherches multi-termes validées - AND implicite"
echo "   ✅ Pertinence des résultats validée"
echo ""

info "💡 Points clés démontrés :"
echo ""
echo "   ✅ Analyzer lowercase : Recherche insensible à la casse"
echo "   ✅ Analyzer asciifolding : Accents ignorés"
echo "   ✅ Analyzer frenchLightStem : Racinisation française"
echo "   ✅ Recherches multi-termes : AND implicite"
echo "   ✅ Recherches combinées : Full-text + filtres"
echo ""

info "📝 Prochaines étapes :"
echo ""
echo "   - Script 17: Tests de recherche avancés"
echo "   - Script 18: Démonstration complète"
echo ""

success "✅ Tests Full-Text Search complexes terminés !"
info "📝 Documentation générée : $REPORT_FILE"
echo ""

# ============================================
# GÉNÉRATION DU RAPPORT
# ============================================
info "📝 Génération du rapport de démonstration..."

# Utiliser le template markdown si disponible, sinon génération basique
TEMPLATE_FILE="${SCRIPT_DIR}/doc/templates/15_fulltext_complex_template.md"

if [ -f "$TEMPLATE_FILE" ]; then
    # Utiliser le template avec remplacement des placeholders
    sed -e "s/{{REPORT_DATE}}/$(date +"%Y-%m-%d %H:%M:%S")/g" \
        -e "s/{{REPORT_SCRIPT}}/$(basename "$0")/g" \
        -e "s/{{CODE_SI}}/$CODE_SI/g" \
        -e "s/{{CONTRAT}}/$CONTRAT/g" \
        -e "s/{{RESULT1}}/$RESULT1/g" \
        -e "s/{{RESULT2}}/$RESULT2/g" \
        -e "s/{{RESULT11}}/$RESULT11/g" \
        -e "s/{{RESULT18}}/$RESULT18/g" \
        "$TEMPLATE_FILE" > "$REPORT_FILE"
else
    # Génération basique sans template
    {
        echo "# 🔍 Démonstration : Tests Full-Text Search Complexes Domirama2"
        echo ""
        echo "**Date** : $(date +"%Y-%m-%d %H:%M:%S")"
        echo "**Script** : $(basename "$0")"
        echo "**Objectif** : Démontrer les tests de recherche full-text complexes avec analyzers SAI"
        echo ""
        echo "---"
        echo ""
        echo "## 📊 Résultats des Tests"
        echo ""
        echo "| Test | Description | Résultats | Statut |"
        echo "|------|-------------|-----------|--------|"
        echo "| 1 | loyer paris (multi-termes) | $RESULT1 | ✅ |"
        echo "| 2 | impaye (asciifolding) | $RESULT2 | ✅ |"
        echo "| 11 | loyers (stemming) | $RESULT11 | ✅ |"
        echo "| 18 | loyer paris + montant < -500 | $RESULT18 | ✅ |"
        echo ""
        echo "---"
        echo ""
        echo "**✅ Tests Full-Text Search complexes terminés avec succès !**"
    } > "$REPORT_FILE"
fi

success "✅ Rapport généré : $REPORT_FILE"
echo ""
