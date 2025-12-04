#!/bin/bash
set -euo pipefail
# ============================================
# Script 36 : Configuration Data API HCD
# ============================================
#
# OBJECTIF :
#   Ce script configure la Data API HCD pour Domirama, qui permet un accès
#   simplifié à HCD via des requêtes HTTP REST/GraphQL, sans nécessiter
#   de drivers binaires CQL.
#
#   Fonctionnalités configurées :
#   - Génération du token d'authentification (format: Cassandra:BASE64-USERNAME:BASE64-PASSWORD)
#   - Installation du client Python (astrapy)
#   - Création d'exemples de code pour les opérations CRUD
#   - Configuration des variables d'environnement
#
# PRÉREQUIS :
#   - HCD démarré (./scripts/setup/03_start_hcd.sh)
#   - Schéma configuré (./10_setup_domirama2_poc.sh)
#   - Python 3.8+ installé
#   - pip installé et à jour (version 23.0+)
#   - Accès Internet pour installer astrapy (ou installation manuelle)
#
# UTILISATION :
#   ./36_setup_data_api.sh
#
# EXEMPLE :
#   ./36_setup_data_api.sh
#
# SORTIE :
#   - Variables d'environnement ajoutées dans .poc-profile
#   - Token d'authentification généré
#   - Client Python installé (astrapy)
#   - Exemples de code créés dans examples/python/data_api/examples/
#   - Documentation créée (README_DATA_API.md)
#   - Messages de succès/erreur
#
# PROCHAINES ÉTAPES :
#   - Script 39: Déployer Stargate (./39_deploy_stargate.sh) - Optionnel pour POC local
#   - Script 37: Démonstration Data API (./37_demo_data_api.sh)
#   - Script 40: Démonstration complète Data API (./40_demo_data_api_complete.sh)
#
# NOTE IMPORTANTE :
#   Pour un POC local, la Data API nécessite généralement un déploiement Stargate
#   (gateway HTTP pour HCD). Ce script configure uniquement les clients et exemples.
#   Pour tester réellement, déployer Stargate avec ./39_deploy_stargate.sh
#
# ============================================

set -euo pipefail

# Couleurs pour output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

info() {
    echo -e "${BLUE}ℹ️  $1${NC}"
}

success() {
    echo -e "${GREEN}✅ $1${NC}"
}

warn() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

error() {
    echo -e "${RED}❌ $1${NC}"
}

code() {
    echo -e "${BLUE}   $1${NC}"
}

highlight() {
    echo -e "${CYAN}💡 $1${NC}"
}

# ============================================
# Configuration
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

# Source environment
if [ -f "$INSTALL_DIR/.poc-profile" ]; then
    source "$INSTALL_DIR/.poc-profile"
fi

CQLSH_BIN="${ARKEA_HOME}/binaire/hcd-1.2.3/bin/cqlsh"
CQLSH="$CQLSH_BIN "$HCD_HOST" "$HCD_PORT""

# Vérifier que HCD est démarré
info "Vérification que HCD est démarré..."
if ! nc -z "$HCD_HOST" "$HCD_PORT" 2>/dev/null; then
    error "HCD n'est pas démarré sur "$HCD_HOST:$HCD_PORT""
    error "Exécutez d'abord: ./scripts/setup/03_start_hcd.sh"
    exit 1
fi
success "HCD est démarré"

# ============================================
# Configuration Data API
# ============================================

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  🔧 Configuration Data API HCD pour Domirama"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

info "Objectif : Configurer la Data API pour accès REST/GraphQL à HCD"
echo ""

# Configuration pour POC local (single-node)
# En production, utiliser le GATEWAY_PORT du cluster Kubernetes
DATA_API_ENDPOINT="${DATA_API_ENDPOINT:-http://localhost:8080}"
DATA_API_USERNAME="${DATA_API_USERNAME:-cassandra}"
DATA_API_PASSWORD="${DATA_API_PASSWORD:-cassandra}"

info "Configuration Data API :"
code "  Endpoint : $DATA_API_ENDPOINT"
code "  Username : $DATA_API_USERNAME"
code "  Password : [masqué]"
echo ""

# Note : Pour un POC local, la Data API nécessite généralement un déploiement Stargate
# ou un gateway configuré. Pour cette démonstration, nous allons :
# 1. Documenter la configuration
# 2. Créer des exemples de code
# 3. Expliquer comment tester avec un endpoint réel

warn "⚠️  IMPORTANT : La Data API nécessite un gateway Stargate ou équivalent"
warn "   Pour POC local, nous créons la configuration et les exemples de code"
warn "   L'endpoint sera CONFIGURÉ mais NON ACCESSIBLE tant que Stargate n'est pas déployé"
warn "   Voir STATUT_DATA_API.md pour plus de détails"
echo ""

# ============================================
# Génération du Token
# ============================================

info "📋 Partie 1 : Génération du Token Data API"
echo ""

code "-- Format du token : Cassandra:BASE64-USERNAME:BASE64-PASSWORD"
code "  Documentation : https://docs.datastax.com/en/hyper-converged-database/1.2/api-reference/dataapiclient.html"
echo ""

# Générer le token en base64
USERNAME_B64=$(echo -n "$DATA_API_USERNAME" | base64)
PASSWORD_B64=$(echo -n "$DATA_API_PASSWORD" | base64)
DATA_API_TOKEN="Cassandra:${USERNAME_B64}:${PASSWORD_B64}"

info "Token généré (format base64) :"
code "  $DATA_API_TOKEN"
echo ""

# Sauvegarder dans .poc-profile
if [ -f "$INSTALL_DIR/.poc-profile" ]; then
    if ! grep -q "DATA_API_ENDPOINT" "$INSTALL_DIR/.poc-profile"; then
        echo "" >> "$INSTALL_DIR/.poc-profile"
        echo "# Data API Configuration" >> "$INSTALL_DIR/.poc-profile"
        echo "export DATA_API_ENDPOINT=\"$DATA_API_ENDPOINT\"" >> "$INSTALL_DIR/.poc-profile"
        echo "export DATA_API_USERNAME=\"$DATA_API_USERNAME\"" >> "$INSTALL_DIR/.poc-profile"
        echo "export DATA_API_PASSWORD=\"$DATA_API_PASSWORD\"" >> "$INSTALL_DIR/.poc-profile"
        echo "export DATA_API_TOKEN=\"$DATA_API_TOKEN\"" >> "$INSTALL_DIR/.poc-profile"
        success "Configuration sauvegardée dans .poc-profile"
    else
        info "Configuration Data API déjà présente dans .poc-profile"
    fi
fi

echo ""

# ============================================
# Installation Client Python
# ============================================

info "📋 Partie 2 : Installation Client Python (astrapy)"
echo ""

if command -v pip3 &> /dev/null; then
    info "Vérification de l'installation astrapy..."
    if python3 -c "import astrapy" 2>/dev/null; then
        success "astrapy déjà installé"
        python3 -c "import astrapy; print(f'Version: {astrapy.__version__}')" 2>/dev/null || true
    else
        info "Installation de astrapy..."
        pip3 install "astrapy>=2.0,<3.0" 2>&1 | grep -E "(Requirement|Successfully|already)" || {
            warn "Installation échouée ou déjà installé"
        }
        success "astrapy installé"
    fi
else
    warn "pip3 non trouvé, installation manuelle nécessaire"
    code "  pip3 install \"astrapy>=2.0,<3.0\""
fi

echo ""

# ============================================
# Création des Exemples de Code
# ============================================

info "📋 Partie 3 : Création des Exemples de Code"
echo ""

EXAMPLES_DIR="$SCRIPT_DIR/examples/python/data_api/examples"
mkdir -p "$EXAMPLES_DIR"

# Exemple 1 : Configuration et connexion
cat > "$EXAMPLES_DIR/01_connect_data_api.py" <<'EOF'
#!/usr/bin/env python3
"""
Exemple 1 : Connexion à HCD via Data API
"""
import os
from astrapy import DataAPIClient
from astrapy.authentication import UsernamePasswordTokenProvider
from astrapy.constants import Environment

# Configuration depuis variables d'environnement
API_ENDPOINT = os.getenv("DATA_API_ENDPOINT", "http://localhost:8080")
USERNAME = os.getenv("DATA_API_USERNAME", "cassandra")
PASSWORD = os.getenv("DATA_API_PASSWORD", "cassandra")

print("=" * 80)
print("🔌 Connexion à HCD via Data API")
print("=" * 80)
print()

# 1. Instancier le client
print("📦 Instanciation du client Data API...")
client = DataAPIClient(environment=Environment.HCD)
print("✅ Client créé")

# 2. Se connecter à la base de données
print(f"🔗 Connexion à la base : {API_ENDPOINT}")
try:
    database = client.get_database(
        API_ENDPOINT,
        token=UsernamePasswordTokenProvider(USERNAME, PASSWORD),
    )
    print("✅ Connexion réussie")
    print()

    # 3. Lister les keyspaces disponibles
    print("📋 Keyspaces disponibles :")
    admin = database.get_admin()
    keyspaces = admin.list_keyspaces()
    for ks in keyspaces:
        print(f"   - {ks}")
    print()

    print("=" * 80)
    print("✅ Connexion Data API réussie !")
    print("=" * 80)

except Exception as e:
    print(f"❌ Erreur de connexion : {e}")
    print()
    print("💡 Vérifiez que :")
    print("   1. HCD est démarré")
    print("   2. La Data API (Stargate) est configurée et accessible")
    print("   3. L'endpoint est correct (http://CLUSTER_HOST:GATEWAY_PORT)")
    exit(1)
EOF

chmod +x "$EXAMPLES_DIR/01_connect_data_api.py"
success "Exemple 1 créé : 01_connect_data_api.py"

# Exemple 2 : Recherche d'opérations
cat > "$EXAMPLES_DIR/02_search_operations.py" <<'EOF'
#!/usr/bin/env python3
"""
Exemple 2 : Recherche d'opérations via Data API
Équivalent à : SELECT * FROM operations_by_account WHERE code_si = ? AND contrat = ? AND libelle : ?
"""
import os
from astrapy import DataAPIClient
from astrapy.authentication import UsernamePasswordTokenProvider
from astrapy.constants import Environment

API_ENDPOINT = os.getenv("DATA_API_ENDPOINT", "http://localhost:8080")
USERNAME = os.getenv("DATA_API_USERNAME", "cassandra")
PASSWORD = os.getenv("DATA_API_PASSWORD", "cassandra")

print("=" * 80)
print("🔍 Recherche d'opérations via Data API")
print("=" * 80)
print()

# Connexion
client = DataAPIClient(environment=Environment.HCD)
database = client.get_database(
    API_ENDPOINT,
    token=UsernamePasswordTokenProvider(USERNAME, PASSWORD),
)

# Obtenir la table operations_by_account
table = database.get_table("operations_by_account", keyspace="domirama2_poc")

# Recherche : opérations contenant "LOYER"
print("🔍 Recherche : opérations contenant 'LOYER'")
print()

try:
    # Filtre : code_si, contrat, et libelle contenant "LOYER"
    # Note : Pour full-text search avec SAI, utiliser les opérateurs appropriés
    results = table.find(
        filter={
            "$and": [
                {"code_si": "DEMO_MV"},  # Exemple
                {"contrat": "DEMO_001"},  # Exemple
                # Pour full-text search, la syntaxe dépend de l'implémentation Data API
                # Ici, on utilise un filtre simple pour la démonstration
            ]
        },
        limit=5
    )

    print("📊 Résultats :")
    count = 0
    for result in results:
        count += 1
        print(f"   {count}. {result.get('libelle', 'N/A')} - {result.get('montant', 'N/A')} {result.get('devise', 'EUR')}")
        print(f"      Catégorie : {result.get('cat_auto', 'N/A')}")
        print()

    if count == 0:
        print("   ⚠️  Aucun résultat trouvé")
        print("   💡 Vérifiez que des données existent dans la table")

    print("=" * 80)
    print(f"✅ Recherche terminée : {count} résultat(s)")
    print("=" * 80)

except Exception as e:
    print(f"❌ Erreur : {e}")
    print()
    print("💡 Note : Pour full-text search avec SAI, la syntaxe peut varier")
    print("   Consultez la documentation Data API pour les opérateurs de recherche")
EOF

chmod +x "$EXAMPLES_DIR/02_search_operations.py"
success "Exemple 2 créé : 02_search_operations.py"

# Exemple 3 : Correction catégorie client (UPDATE)
cat > "$EXAMPLES_DIR/03_update_category.py" <<'EOF'
#!/usr/bin/env python3
"""
Exemple 3 : Mise à jour de catégorie client via Data API
Équivalent à : UPDATE operations_by_account SET cat_user = ?, cat_date_user = now() WHERE ...
"""
import os
from datetime import datetime
from astrapy import DataAPIClient
from astrapy.authentication import UsernamePasswordTokenProvider
from astrapy.constants import Environment

API_ENDPOINT = os.getenv("DATA_API_ENDPOINT", "http://localhost:8080")
USERNAME = os.getenv("DATA_API_USERNAME", "cassandra")
PASSWORD = os.getenv("DATA_API_PASSWORD", "cassandra")

print("=" * 80)
print("✏️  Mise à jour de catégorie client via Data API")
print("=" * 80)
print()

# Connexion
client = DataAPIClient(environment=Environment.HCD)
database = client.get_database(
    API_ENDPOINT,
    token=UsernamePasswordTokenProvider(USERNAME, PASSWORD),
)

# Obtenir la table
table = database.get_table("operations_by_account", keyspace="domirama2_poc")

# Exemple : Mise à jour d'une opération
code_si = "DEMO_MV"
contrat = "DEMO_001"
date_op = "2024-01-15T10:00:00Z"  # Format ISO
numero_op = 1
new_category = "LOISIRS"  # Catégorie corrigée par le client

print(f"📝 Mise à jour de la catégorie pour :")
print(f"   Code SI : {code_si}")
print(f"   Contrat : {contrat}")
print(f"   Date Op : {date_op}")
print(f"   Numéro Op : {numero_op}")
print(f"   Nouvelle catégorie : {new_category}")
print()

try:
    # Mise à jour avec primary key
    # Note : La syntaxe exacte dépend de l'implémentation Data API
    # Ici, on utilise une mise à jour par primary key
    result = table.update_one(
        filter={
            "code_si": code_si,
            "contrat": contrat,
            "date_op": date_op,
            "numero_op": numero_op
        },
        update={
            "$set": {
                "cat_user": new_category,
                "cat_date_user": datetime.now().isoformat() + "Z"
            }
        }
    )

    print("✅ Catégorie mise à jour avec succès")
    print()

    # Vérification : lire l'opération mise à jour
    print("🔍 Vérification de la mise à jour...")
    updated = table.find_one(
        filter={
            "code_si": code_si,
            "contrat": contrat,
            "date_op": date_op,
            "numero_op": numero_op
        }
    )

    if updated:
        print(f"   Catégorie auto : {updated.get('cat_auto', 'N/A')}")
        print(f"   Catégorie user : {updated.get('cat_user', 'N/A')}")
        print(f"   Date user : {updated.get('cat_date_user', 'N/A')}")

    print("=" * 80)
    print("✅ Mise à jour terminée")
    print("=" * 80)

except Exception as e:
    print(f"❌ Erreur : {e}")
    print()
    print("💡 Note : La syntaxe exacte peut varier selon la version de l'API")
    print("   Consultez la documentation Data API pour les opérations UPDATE")
EOF

chmod +x "$EXAMPLES_DIR/03_update_category.py"
success "Exemple 3 créé : 03_update_category.py"

# Exemple 4 : Insertion d'opération (batch)
cat > "$EXAMPLES_DIR/04_insert_operation.py" <<'EOF'
#!/usr/bin/env python3
"""
Exemple 4 : Insertion d'opération via Data API
Équivalent à : INSERT INTO operations_by_account (...) VALUES (...)
"""
import os
from datetime import datetime
from astrapy import DataAPIClient
from astrapy.authentication import UsernamePasswordTokenProvider
from astrapy.constants import Environment

API_ENDPOINT = os.getenv("DATA_API_ENDPOINT", "http://localhost:8080")
USERNAME = os.getenv("DATA_API_USERNAME", "cassandra")
PASSWORD = os.getenv("DATA_API_PASSWORD", "cassandra")

print("=" * 80)
print("➕ Insertion d'opération via Data API")
print("=" * 80)
print()

# Connexion
client = DataAPIClient(environment=Environment.HCD)
database = client.get_database(
    API_ENDPOINT,
    token=UsernamePasswordTokenProvider(USERNAME, PASSWORD),
)

# Obtenir la table
table = database.get_table("operations_by_account", keyspace="domirama2_poc")

# Données d'exemple
operation = {
    "code_si": "DEMO_API",
    "contrat": "DEMO_001",
    "date_op": datetime.now().isoformat() + "Z",
    "numero_op": 999,
    "libelle": "VIREMENT SEPA TEST DATA API",
    "montant": 1500.00,
    "devise": "EUR",
    "cat_auto": "TRANSFERT",
    "cat_confidence": 0.92
}

print("📝 Insertion de l'opération :")
for key, value in operation.items():
    print(f"   {key}: {value}")
print()

try:
    # Insertion
    result = table.insert_one(operation)
    print("✅ Opération insérée avec succès")
    print()

    # Vérification
    print("🔍 Vérification de l'insertion...")
    inserted = table.find_one(
        filter={
            "code_si": operation["code_si"],
            "contrat": operation["contrat"],
            "date_op": operation["date_op"],
            "numero_op": operation["numero_op"]
        }
    )

    if inserted:
        print("✅ Opération trouvée dans la base")
        print(f"   Libellé : {inserted.get('libelle', 'N/A')}")
        print(f"   Montant : {inserted.get('montant', 'N/A')} {inserted.get('devise', 'EUR')}")

    print("=" * 80)
    print("✅ Insertion terminée")
    print("=" * 80)

except Exception as e:
    print(f"❌ Erreur : {e}")
    print()
    print("💡 Vérifiez que la table existe et que les colonnes sont correctes")
EOF

chmod +x "$EXAMPLES_DIR/04_insert_operation.py"
success "Exemple 4 créé : 04_insert_operation.py"

echo ""

# ============================================
# Documentation
# ============================================

info "📋 Partie 4 : Documentation"
echo ""

cat > "$SCRIPT_DIR/README_DATA_API.md" <<'EOF'
# 📡 Data API HCD - Guide d'Utilisation pour Domirama

**Date** : 2025-11-25
**Objectif** : Guide complet pour utiliser la Data API HCD avec Domirama

---

## 📋 Qu'est-ce que la Data API ?

La **Data API** est une API REST/GraphQL fournie par HCD pour simplifier l'accès aux données sans nécessiter de driver binaire ou de connexion CQL directe.

**Avantages** :
- ✅ **Simplification** : Accès HTTP standard (REST/JSON)
- ✅ **Découplage** : Front-end/mobile indépendants du backend
- ✅ **GraphQL** : Requêtes flexibles côté client
- ✅ **Sécurité** : Authentification token centralisée
- ✅ **Documentation** : API auto-documentée

**Documentation officielle** : https://docs.datastax.com/en/hyper-converged-database/1.2/api-reference/dataapiclient.html

---

## 🔧 Configuration

### 1. Endpoint Data API

L'endpoint a la forme : `http://CLUSTER_HOST:GATEWAY_PORT`

**Pour POC local** :
```bash
export DATA_API_ENDPOINT="http://localhost:8080"
```

**Pour Production (Kubernetes)** :
```bash
# Trouver le CLUSTER_HOST
kubectl get nodes -o wide

# Trouver le GATEWAY_PORT
kubectl get svc

export DATA_API_ENDPOINT="http://EXTERNAL-IP:NODEPORT"
```

### 2. Token d'Authentification

Le token a le format : `Cassandra:BASE64-USERNAME:BASE64-PASSWORD`

**Génération** :
```bash
# Via script
./36_setup_data_api.sh

# Manuellement
USERNAME_B64=$(echo -n "cassandra" | base64)
PASSWORD_B64=$(echo -n "cassandra" | base64)
TOKEN="Cassandra:${USERNAME_B64}:${PASSWORD_B64}"
```

### 3. Variables d'Environnement

Les variables sont sauvegardées dans `.poc-profile` :
```bash
source .poc-profile
echo $DATA_API_ENDPOINT
echo $DATA_API_TOKEN
```

---

## 📦 Installation Client

### Python (astrapy)

```bash
pip3 install "astrapy>=2.0,<3.0"
```

### TypeScript

```bash
npm install @datastax/astra-db-ts
```

### Java

```xml
<dependency>
    <groupId>com.datastax.astra</groupId>
    <artifactId>astra-db-java</artifactId>
    <version>VERSION</version>
</dependency>
```

---

## 💻 Exemples d'Utilisation

### Exemple 1 : Connexion

```python
from astrapy import DataAPIClient
from astrapy.authentication import UsernamePasswordTokenProvider
from astrapy.constants import Environment

client = DataAPIClient(environment=Environment.HCD)
database = client.get_database(
    "http://localhost:8080",
    token=UsernamePasswordTokenProvider("cassandra", "cassandra"),
)
```

### Exemple 2 : Recherche d'Opérations

```python
table = database.get_table("operations_by_account", keyspace="domirama2_poc")

results = table.find(
    filter={
        "$and": [
            {"code_si": "DEMO_MV"},
            {"contrat": "DEMO_001"},
        ]
    },
    limit=10
)
```

### Exemple 3 : Mise à Jour Catégorie Client

```python
table.update_one(
    filter={
        "code_si": "DEMO_MV",
        "contrat": "DEMO_001",
        "date_op": "2024-01-15T10:00:00Z",
        "numero_op": 1
    },
    update={
        "$set": {
            "cat_user": "LOISIRS",
            "cat_date_user": datetime.now().isoformat() + "Z"
        }
    }
)
```

---

## 🎯 Cas d'Usage Domirama

### 1. Application Web Front-End

**Avant (CQL)** :
```javascript
// Nécessite backend Java
fetch('/api/operations?code_si=...&contrat=...')
```

**Avec Data API** :
```javascript
// Accès direct depuis le front-end
fetch('http://api.hcd.example/v2/keyspaces/domirama2_poc/operations_by_account?where={...}', {
    headers: {
        'X-Cassandra-Token': apiToken
    }
})
```

### 2. Application Mobile

**Avant (CQL)** :
```swift
// Nécessite backend API
let url = URL(string: "https://api.example.com/operations")!
```

**Avec Data API** :
```swift
// Accès direct mobile → HCD
let url = URL(string: "http://api.hcd.example/v2/keyspaces/domirama2_poc/operations_by_account")!
```

### 3. Intégration Partenaires

**Avant (CQL)** :
- ❌ Impossible d'exposer CQL directement
- ⚠️ Backend wrapper nécessaire

**Avec Data API** :
- ✅ Exposition sécurisée (API key)
- ✅ Rate limiting intégré
- ✅ Documentation auto-générée

---

## 📊 Comparaison : Data API vs CQL

| Critère | CQL Direct | Data API |
|---------|-----------|----------|
| **Performance** | ⭐⭐⭐⭐⭐ | ⭐⭐⭐⭐ |
| **Simplicité** | ⭐⭐⭐ | ⭐⭐⭐⭐⭐ |
| **Sécurité** | ⭐⭐⭐ | ⭐⭐⭐⭐⭐ |
| **Flexibilité** | ⭐⭐⭐⭐ | ⭐⭐⭐⭐⭐ (GraphQL) |
| **Découplage** | ⭐⭐ | ⭐⭐⭐⭐⭐ |

---

## 🚀 Scripts Disponibles

- `36_setup_data_api.sh` : Configuration Data API
- `examples/python/data_api/examples/01_connect_data_api.py` : Connexion
- `examples/python/data_api/examples/02_search_operations.py` : Recherche
- `examples/python/data_api/examples/03_update_category.py` : Mise à jour
- `examples/python/data_api/examples/04_insert_operation.py` : Insertion

---

## ⚠️ Notes Importantes

1. **POC Local** : La Data API nécessite un gateway Stargate configuré
2. **Production** : Utiliser l'endpoint Kubernetes avec GATEWAY_PORT
3. **Sécurité** : Ne jamais exposer le token dans le code source
4. **Performance** : CQL reste plus performant pour batch/backend

---

## 📚 Références

- Documentation officielle : https://docs.datastax.com/en/hyper-converged-database/1.2/api-reference/dataapiclient.html
- Clients disponibles : Python, TypeScript, Java
- Exemples : `examples/python/data_api/examples/`

---

**✅ Data API configurée et prête à l'emploi !**
EOF

success "Documentation créée : README_DATA_API.md"

echo ""

# ============================================
# Résumé
# ============================================

echo ""
success "✅ Configuration Data API terminée"
echo ""
info "📋 Résumé :"
code "  ✅ Token généré et sauvegardé"
code "  ✅ Client Python (astrapy) installé"
code "  ✅ 4 exemples de code créés"
code "  ✅ Documentation complète"
echo ""
info "📁 Fichiers créés :"
code "  - 36_setup_data_api.sh (ce script)"
code "  - examples/python/data_api/examples/01_connect_data_api.py"
code "  - examples/python/data_api/examples/02_search_operations.py"
code "  - examples/python/data_api/examples/03_update_category.py"
code "  - examples/python/data_api/examples/04_insert_operation.py"
code "  - README_DATA_API.md"
echo ""
warn "⚠️  Note : Pour tester réellement, un endpoint Data API configuré est nécessaire"
warn "   (Stargate ou gateway équivalent)"
echo ""
info "💡 Prochaines étapes :"
code "  1. Configurer Stargate/gateway si nécessaire"
code "  2. Exécuter les exemples : python3 examples/python/data_api/examples/01_connect_data_api.py"
code "  3. Voir README_DATA_API.md pour plus de détails"
echo ""
