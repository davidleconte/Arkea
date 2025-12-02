#!/bin/bash
# ============================================
# Script 24 : Démonstration Data API REST/GraphQL (Version Didactique)
# Démontre l'utilisation et la valeur ajoutée de la Data API HCD
# ============================================
#
# OBJECTIF :
#   Ce script démontre de manière très didactique l'utilisation et la valeur ajoutée
#   de la Data API HCD, qui permet un accès simplifié à HCD via des requêtes HTTP
#   REST/GraphQL, sans nécessiter de drivers binaires CQL.
#   
#   Cette version didactique affiche :
#   - Le contexte et les avantages de la Data API
#   - Les équivalences CQL → Data API REST/GraphQL
#   - Les exemples de code (REST, GraphQL, Python)
#   - Les cas d'usage concrets DomiramaCatOps
#   - La cinématique complète de chaque étape
#   - Une documentation structurée pour livrable
#
# PRÉREQUIS :
#   - HCD démarré (./scripts/setup/03_start_hcd.sh)
#   - Keyspace 'domiramacatops_poc' et tables créés
#   - Data API configurée (optionnel, pour démonstration complète)
#   - Python 3.8+ avec astrapy installé (optionnel)
#
# UTILISATION :
#   ./24_demo_data_api.sh
#
# SORTIE :
#   - Contexte et avantages Data API
#   - Exemples REST/GraphQL
#   - Cas d'usage DomiramaCatOps
#   - Documentation structurée dans le terminal
#   - Rapport de démonstration généré
#
# PROCHAINES ÉTAPES :
#   - Script 25: Tests feedbacks ICS (./25_test_feedbacks_ics.sh)
#   - Script 26: Tests décisions salaires (./26_test_decisions_salaires.sh)
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

REPORT_FILE="${SCRIPT_DIR}/../doc/demonstrations/24_DATA_API_DEMONSTRATION.md"
KEYSPACE_NAME="domiramacatops_poc"
TABLE_NAME="operations_by_account"
# HCD_HOME devrait être défini par .poc-profile
# Créer le répertoire de documentation
mkdir -p "$(dirname "$REPORT_FILE")"

# ============================================
# VÉRIFICATIONS PRÉALABLES
# ============================================
show_partie "0" "VÉRIFICATIONS PRÉALABLES"

check_hcd_status
check_jenv_java_version

# Vérifier que le keyspace existe
check_schema "" "" # Vérifie HCD et Java
KEYSPACE_EXISTS=$("${HCD_DIR}/bin/cqlsh" "$HCD_HOST" "$HCD_PORT" -e "SELECT keyspace_name FROM system_schema.keyspaces WHERE keyspace_name = '$KEYSPACE_NAME';" 2>&1 | grep -c "$KEYSPACE_NAME" || echo "0")
if [ "$KEYSPACE_EXISTS" -eq 0 ]; then
    error "Le keyspace '$KEYSPACE_NAME' n'existe pas. Exécutez d'abord ./01_setup_domiramaCatOps_keyspace.sh"
    exit 1
fi

# ============================================
# EN-TÊTE DE DÉMONSTRATION
# ============================================
show_demo_header "Data API REST/GraphQL"

# ============================================
# PARTIE 1: CONTEXTE ET AVANTAGES
# ============================================
show_partie "1" "CONTEXTE - DATA API vs CQL DIRECT"

info "📚 QU'EST-CE QUE LA DATA API ?"
echo ""
echo "   La Data API est une API REST/GraphQL fournie par HCD pour simplifier"
echo "   l'accès aux données sans nécessiter de driver binaire ou de connexion CQL directe."
echo ""
info "📋 AVANTAGES DE LA DATA API :"
echo "   ✅ Simplification : Accès HTTP standard (REST/JSON)"
echo "   ✅ Découplage : Front-end/mobile indépendants du backend"
echo "   ✅ GraphQL : Requêtes flexibles côté client"
echo "   ✅ Sécurité : Authentification token centralisée"
echo "   ✅ Documentation : API auto-documentée"
echo "   ✅ Exposition : Possibilité d'exposer aux partenaires"
echo ""

info "💡 Comparaison Data API vs CQL Direct :"
echo ""
echo "   | Critère              | CQL Direct    | Data API            |"
echo "   |-----------------------|---------------|---------------------|"
echo "   | Performance          | ⭐⭐⭐⭐⭐     | ⭐⭐⭐⭐              |"
echo "   | Simplicité           | ⭐⭐⭐         | ⭐⭐⭐⭐⭐            |"
echo "   | Sécurité             | ⭐⭐⭐         | ⭐⭐⭐⭐⭐            |"
echo "   | Flexibilité          | ⭐⭐⭐⭐       | ⭐⭐⭐⭐⭐ (GraphQL)  |"
echo "   | Découplage           | ⭐⭐           | ⭐⭐⭐⭐⭐            |"
echo "   | Accès Front-end      | ❌ Non        | ✅ Oui              |"
echo "   | Accès Mobile         | ❌ Non        | ✅ Oui              |"
echo "   | Intégration Partenaires| ❌ Non      | ✅ Oui              |"
echo ""

# ============================================
# PARTIE 2: ÉQUIVALENCES CQL → DATA API
# ============================================
show_partie "2" "ÉQUIVALENCES - CQL vs DATA API"

info "📝 Exemple 1 : Recherche d'opérations"
echo ""
code "CQL Direct :"
code "SELECT * FROM operations_by_account"
code "WHERE code_si = '1' AND contrat = '5913101072'"
code "  AND libelle : 'LOYER'"
code "ORDER BY date_op DESC LIMIT 5;"
echo ""
code "Data API REST :"
code "GET /v2/keyspaces/$KEYSPACE_NAME/$TABLE_NAME"
code "  ?where={\"code_si\":\"1\",\"contrat\":\"5913101072\",\"libelle\":{\"$contains\":\"LOYER\"}}"
code "  &page-size=5"
code "  &sort=date_op:desc"
code "Headers: X-Cassandra-Token: <token>"
echo ""
code "Data API GraphQL :"
code "query {"
code "  operations_by_account("
code "    filter: {"
code "      code_si: {eq: \"1\"}"
code "      contrat: {eq: \"5913101072\"}"
code "      libelle: {contains: \"LOYER\"}"
code "    }"
code "    options: {pageSize: 5, sort: [{date_op: DESC}]}"
code "  ) {"
code "    values {"
code "      date_op"
code "      numero_op"
code "      libelle"
code "      montant"
code "      cat_auto"
code "    }"
code "  }"
code "}"
echo ""

info "📝 Exemple 2 : Mise à jour de catégorie"
echo ""
code "CQL Direct :"
code "UPDATE operations_by_account"
code "SET cat_user = 'ALIMENTATION', cat_date_user = '2024-01-20 10:00:00'"
code "WHERE code_si = '1' AND contrat = '5913101072'"
code "  AND date_op = '2024-01-20 10:00:00' AND numero_op = 1;"
echo ""
code "Data API REST :"
code "PATCH /v2/keyspaces/$KEYSPACE_NAME/$TABLE_NAME/1/5913101072/2024-01-20T10:00:00/1"
code "Body: {"
code "  \"cat_user\": \"ALIMENTATION\","
code "  \"cat_date_user\": \"2024-01-20T10:00:00Z\""
code "}"
code "Headers: X-Cassandra-Token: <token>"
echo ""
code "Data API GraphQL :"
code "mutation {"
code "  updateoperations_by_account("
code "    value: {"
code "      code_si: \"1\""
code "      contrat: \"5913101072\""
code "      date_op: \"2024-01-20T10:00:00Z\""
code "      numero_op: 1"
code "      cat_user: \"ALIMENTATION\""
code "      cat_date_user: \"2024-01-20T10:00:00Z\""
code "    }"
code "  ) {"
code "    value {"
code "      cat_user"
code "      cat_date_user"
code "    }"
code "  }"
code "}"
echo ""

# ============================================
# PARTIE 3: CAS D'USAGE DOMIRAMACATOPS
# ============================================
show_partie "3" "CAS D'USAGE - DOMIRAMACATOPS"

info "📋 Cas d'usage 1 : Recherche d'opérations (Front-end Web)"
echo ""
code "// Front-end JavaScript"
code "const response = await fetch("
code "  \`https://api.hcd.example/v2/keyspaces/$KEYSPACE_NAME/$TABLE_NAME"
code "    ?where={\"code_si\":\"\${codeSi}\",\"contrat\":\"\${contrat}\",\"libelle\":{\"$contains\":\"\${searchTerm}\"}}\`,"
code "  {"
code "    headers: {"
code "      'X-Cassandra-Token': apiToken"
code "    }"
code "  }"
code ");"
code "const data = await response.json();"
echo ""
info "   Avantage : Accès direct depuis le front-end, pas besoin de backend intermédiaire"
echo ""

info "📋 Cas d'usage 2 : Mise à jour catégorie client (Mobile)"
echo ""
code "// Application Mobile (React Native)"
code "const updateCategory = async (operationId, newCategory) => {"
code "  const response = await fetch("
code "    \`https://api.hcd.example/v2/keyspaces/$KEYSPACE_NAME/$TABLE_NAME/\${operationId}\`,"
code "    {"
code "      method: 'PATCH',"
code "      headers: {"
code "        'X-Cassandra-Token': apiToken,"
code "        'Content-Type': 'application/json'"
code "      },"
code "      body: JSON.stringify({"
code "        cat_user: newCategory,"
code "        cat_date_user: new Date().toISOString()"
code "      })"
code "    }"
code "  );"
code "  return await response.json();"
code "};"
echo ""
info "   Avantage : Mise à jour directe depuis mobile, pas besoin de backend"
echo ""

info "📋 Cas d'usage 3 : Recherche avec GraphQL (Flexibilité)"
echo ""
code "// GraphQL Query (Front-end)"
code "const SEARCH_OPERATIONS = gql\`"
code "  query SearchOperations(\$codeSi: String!, \$contrat: String!, \$searchTerm: String!) {"
code "    operations_by_account("
code "      filter: {"
code "        code_si: {eq: \$codeSi}"
code "        contrat: {eq: \$contrat}"
code "        libelle: {contains: \$searchTerm}"
code "      }"
code "    ) {"
code "      values {"
code "        date_op"
code "        numero_op"
code "        libelle"
code "        montant"
code "        cat_auto"
code "        cat_user"
code "      }"
code "    }"
code "  }"
code "\`;"
echo ""
info "   Avantage : Requête flexible, le client choisit les champs à récupérer"
echo ""

# ============================================
# PARTIE 4: EXEMPLE PYTHON (ASTAPY)
# ============================================
show_partie "4" "EXEMPLE PYTHON - CLIENT ASTAPY"

info "📝 Exemple : Utilisation du client Python astrapy"
echo ""
code "from astrapy import DataAPIClient"
code ""
code "# Connexion à HCD"
code "client = DataAPIClient("
code "    token='<DATA_API_TOKEN>',"
code "    api_endpoint='https://api.hcd.example'"
code ")"
code ""
code "# Recherche d'opérations"
code "db = client.get_database('$KEYSPACE_NAME')"
code "collection = db.get_collection('$TABLE_NAME')"
code ""
code "results = collection.find("
code "    filter={"
code "        'code_si': '1',"
code "        'contrat': '5913101072',"
code "        'libelle': {'$contains': 'LOYER'}"
code "    },"
code "    options={'limit': 5, 'sort': {'date_op': -1}}"
code ")"
code ""
code "for doc in results:"
code "    print(f\"Opération: {doc['libelle']} - {doc['montant']}\")"
echo ""
info "   Avantage : Client Python simple, pas besoin de driver CQL"
echo ""

# ============================================
# PARTIE 5: CONFIGURATION ET SÉCURITÉ
# ============================================
show_partie "5" "CONFIGURATION ET SÉCURITÉ"

info "📝 Configuration Data API :"
echo ""
code "# Endpoint Data API"
code "export DATA_API_ENDPOINT=\"http://localhost:8080\""
code ""
code "# Token d'authentification"
code "export DATA_API_TOKEN=\"Cassandra:<base64_username>:<base64_password>\""
echo ""
info "   Explication :"
echo "      - Endpoint : URL de base de l'API (http://CLUSTER_HOST:GATEWAY_PORT)"
echo "      - Token : Format 'Cassandra:BASE64-USERNAME:BASE64-PASSWORD'"
echo "      - Sécurité : Token centralisé, rate limiting possible"
echo ""

info "📝 Sécurité et Rate Limiting :"
echo ""
echo "   ✅ Authentification : Token obligatoire pour chaque requête"
echo "   ✅ Rate Limiting : Limitation du nombre de requêtes par token"
echo "   ✅ HTTPS : Support TLS/SSL pour production"
echo "   ✅ CORS : Configuration CORS pour front-end"
echo "   ✅ Audit : Logs d'accès pour traçabilité"
echo ""

# ============================================
# PARTIE 6: RÉSUMÉ ET CONCLUSION
# ============================================
show_partie "6" "RÉSUMÉ ET CONCLUSION"

info "📊 Résumé de la démonstration Data API :"
echo ""
echo "   ✅ Simplification : Accès HTTP standard (REST/JSON)"
echo "   ✅ Découplage : Front-end/mobile indépendants du backend"
echo "   ✅ GraphQL : Requêtes flexibles côté client"
echo "   ✅ Sécurité : Authentification token centralisée"
echo "   ✅ Exposition : Possibilité d'exposer aux partenaires"
echo ""

info "💡 Quand utiliser Data API vs CQL Direct :"
echo ""
echo "   ✅ Data API recommandée pour :"
echo "      - Front-end Web (JavaScript/TypeScript)"
echo "      - Applications mobiles (React Native, Flutter)"
echo "      - Intégration partenaires/externes"
echo "      - Microservices (API Gateway)"
echo "      - Prototypage rapide"
echo ""
echo "   ✅ CQL Direct recommandé pour :"
echo "      - Backend haute performance (Java, Python)"
echo "      - Traitements batch (Spark, ETL)"
echo "      - Requêtes complexes avec optimisations"
echo "      - Contrôle fin de la performance"
echo ""

info "📝 Prochaines étapes :"
echo ""
echo "   - Script 25: Tests feedbacks ICS (./25_test_feedbacks_ics.sh)"
echo "   - Script 26: Tests décisions salaires (./26_test_decisions_salaires.sh)"
echo ""

success "✅ Démonstration Data API terminée avec succès !"
info "📝 Documentation générée : $REPORT_FILE"
echo ""

# ============================================
# GÉNÉRATION DU RAPPORT MARKDOWN
# ============================================
info "📝 Génération du rapport de démonstration markdown..."

REPORT_CONTENT=$(cat << EOF
## 📚 Contexte - Data API vs CQL Direct

### Qu'est-ce que la Data API ?

La **Data API** est une API REST/GraphQL fournie par HCD pour simplifier l'accès aux données sans nécessiter de driver binaire ou de connexion CQL directe.

### Avantages

✅ **Simplification** : Accès HTTP standard (REST/JSON)  
✅ **Découplage** : Front-end/mobile indépendants du backend  
✅ **GraphQL** : Requêtes flexibles côté client  
✅ **Sécurité** : Authentification token centralisée  
✅ **Documentation** : API auto-documentée  
✅ **Exposition** : Possibilité d'exposer aux partenaires

### Comparaison

| Critère | CQL Direct | Data API |
|---------|------------|----------|
| Performance | ⭐⭐⭐⭐⭐ | ⭐⭐⭐⭐ |
| Simplicité | ⭐⭐⭐ | ⭐⭐⭐⭐⭐ |
| Sécurité | ⭐⭐⭐ | ⭐⭐⭐⭐⭐ |
| Flexibilité | ⭐⭐⭐⭐ | ⭐⭐⭐⭐⭐ (GraphQL) |
| Découplage | ⭐⭐ | ⭐⭐⭐⭐⭐ |
| Accès Front-end | ❌ Non | ✅ Oui |
| Accès Mobile | ❌ Non | ✅ Oui |

---

## 📋 Équivalences - CQL vs Data API

### Exemple 1 : Recherche d'opérations

**CQL Direct** :
\`\`\`cql
SELECT * FROM operations_by_account
WHERE code_si = '1' AND contrat = '5913101072'
  AND libelle : 'LOYER'
ORDER BY date_op DESC LIMIT 5;
\`\`\`

**Data API REST** :
\`\`\`http
GET /v2/keyspaces/$KEYSPACE_NAME/$TABLE_NAME
  ?where={"code_si":"1","contrat":"5913101072","libelle":{"$contains":"LOYER"}}
  &page-size=5
  &sort=date_op:desc
Headers: X-Cassandra-Token: <token>
\`\`\`

**Data API GraphQL** :
\`\`\`graphql
query {
  operations_by_account(
    filter: {
      code_si: {eq: "1"}
      contrat: {eq: "5913101072"}
      libelle: {contains: "LOYER"}
    }
    options: {pageSize: 5, sort: [{date_op: DESC}]}
  ) {
    values {
      date_op
      numero_op
      libelle
      montant
      cat_auto
    }
  }
}
\`\`\`

### Exemple 2 : Mise à jour de catégorie

**CQL Direct** :
\`\`\`cql
UPDATE operations_by_account
SET cat_user = 'ALIMENTATION', cat_date_user = '2024-01-20 10:00:00'
WHERE code_si = '1' AND contrat = '5913101072'
  AND date_op = '2024-01-20 10:00:00' AND numero_op = 1;
\`\`\`

**Data API REST** :
\`\`\`http
PATCH /v2/keyspaces/$KEYSPACE_NAME/$TABLE_NAME/1/5913101072/2024-01-20T10:00:00/1
Body: {
  "cat_user": "ALIMENTATION",
  "cat_date_user": "2024-01-20T10:00:00Z"
}
Headers: X-Cassandra-Token: <token>
\`\`\`

---

## 🎯 Cas d'Usage - DomiramaCatOps

### Cas d'usage 1 : Recherche d'opérations (Front-end Web)

**Avantage** : Accès direct depuis le front-end, pas besoin de backend intermédiaire.

### Cas d'usage 2 : Mise à jour catégorie client (Mobile)

**Avantage** : Mise à jour directe depuis mobile, pas besoin de backend.

### Cas d'usage 3 : Recherche avec GraphQL (Flexibilité)

**Avantage** : Requête flexible, le client choisit les champs à récupérer.

---

## ✅ Conclusion

La démonstration de la Data API a été réalisée avec succès, mettant en évidence :

✅ **Simplification** : Accès HTTP standard (REST/JSON)  
✅ **Découplage** : Front-end/mobile indépendants du backend  
✅ **GraphQL** : Requêtes flexibles côté client  
✅ **Sécurité** : Authentification token centralisée  
✅ **Exposition** : Possibilité d'exposer aux partenaires

### Quand utiliser Data API vs CQL Direct

**Data API recommandée pour** :
- Front-end Web (JavaScript/TypeScript)
- Applications mobiles (React Native, Flutter)
- Intégration partenaires/externes
- Microservices (API Gateway)
- Prototypage rapide

**CQL Direct recommandé pour** :
- Backend haute performance (Java, Python)
- Traitements batch (Spark, ETL)
- Requêtes complexes avec optimisations
- Contrôle fin de la performance

---

**✅ Démonstration Data API terminée avec succès !**
EOF
)
generate_report "$REPORT_FILE" "📡 Démonstration : Data API REST/GraphQL DomiramaCatOps" "$REPORT_CONTENT"

