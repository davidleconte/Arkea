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

**Documentation officielle** :

- Quickstart : <https://docs.datastax.com/en/hyper-converged-database/1.2/api-reference/quickstart.html>
- Reference : <https://docs.datastax.com/en/hyper-converged-database/1.2/api-reference/dataapiclient.html>

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
- `data_api_examples/01_connect_data_api.py` : Connexion
- `data_api_examples/02_search_operations.py` : Recherche
- `data_api_examples/03_update_category.py` : Mise à jour
- `data_api_examples/04_insert_operation.py` : Insertion

---

## ⚠️ Notes Importantes

1. **POC Local** : La Data API nécessite un gateway Stargate configuré
2. **Production** : Utiliser l'endpoint Kubernetes avec GATEWAY_PORT
3. **Sécurité** : Ne jamais exposer le token dans le code source
4. **Performance** : CQL reste plus performant pour batch/backend

---

## 📚 Références

- Documentation officielle : <https://docs.datastax.com/en/hyper-converged-database/1.2/api-reference/dataapiclient.html>
- Clients disponibles : Python, TypeScript, Java
- Exemples : `data_api_examples/`

---

**✅ Data API configurée et prête à l'emploi !**
