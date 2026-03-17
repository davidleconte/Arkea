# 🌟 Stargate - Gateway Data API pour HCD

**Date** : 2025-11-25
**Référence** : <https://stargate.io/docs/latest/index.html>
**Objectif** : Documentation complète pour déployer et utiliser Stargate avec HCD local

---

## 📋 Qu'est-ce que Stargate ?

**Stargate** est un gateway open-source qui expose Apache Cassandra via des APIs modernes :

- ✅ **REST API** (v1 et v2)
- ✅ **GraphQL API** (CQL-first et Schema-first)
- ✅ **Document API** (MongoDB-like)
- ✅ **gRPC API**

**Pourquoi Stargate pour HCD ?**

- La **Data API HCD** nécessite un gateway pour être accessible
- Stargate est le gateway recommandé pour HCD/Cassandra
- Permet d'exposer HCD via HTTP/REST/GraphQL sans driver binaire

---

## 🔧 Installation

### Prérequis

- ✅ HCD démarré sur `localhost:9042`
- ✅ Podman installé et fonctionnel
- ✅ Ports disponibles : `8080`, `8081`, `8082`

### Déploiement Automatique

**Script disponible** :

```bash
./39_deploy_stargate.sh
```

Ce script :

1. Vérifie les prérequis (Podman, HCD)
2. Télécharge l'image Stargate
3. Déploie le conteneur avec la bonne configuration
4. Vérifie que l'endpoint est accessible
5. Configure les variables d'environnement

### Déploiement Manuel

**Référence** : [Installing Stargate - Cassandra 4.0](https://stargate.io/docs/latest/install/cassandra-4.0.html)

```bash
podman run -d \
  --name stargate \
  -p 8080:8080 \
  -p 8081:8081 \
  -p 8082:8082 \
  -e CLUSTER_NAME=local \
  -e CLUSTER_VERSION=4.0 \
  -e DEVELOPER_MODE=true \
  -e CLUSTER_SEED=localhost:9042 \
  -e DSE=1 \
  stargateio/stargate-4.0:v1.0.84
```

**Variables d'environnement** :

- `CLUSTER_NAME` : Nom du cluster (arbitraire pour POC)
- `CLUSTER_VERSION` : Version Cassandra (4.0 pour HCD 1.2.3)
- `DEVELOPER_MODE` : Mode développement (simplifie la configuration)
- `CLUSTER_SEED` : Adresse du nœud Cassandra (localhost:9042)
- `DSE=1` : Indique que c'est DSE/HCD (pas Cassandra vanilla)

---

## 🔌 Ports Stargate

**Référence** : [Stargate Ports](https://stargate.io/docs/latest/install/stargate-ports.html)

| Port | Service | Description |
|------|---------|-------------|
| `8080` | REST API v1 | API REST version 1 (legacy) |
| `8081` | REST API v2 | API REST version 2 (recommandée) |
| `8082` | GraphQL API | API GraphQL |
| `8090` | Health Check | Endpoint de santé (optionnel) |

**Pour Data API HCD** : Utiliser le port `8080` ou `8081` selon la version de l'API.

---

## ✅ Vérification

### Test 1 : Health Check

```bash
curl http://localhost:8080/v1/status
# Attendu : {"status":"ok"} ou HTTP 200
```

### Test 2 : REST API v2

```bash
curl http://localhost:8081/v2/schemas/keyspaces
# Attendu : Liste des keyspaces (JSON)
```

### Test 3 : GraphQL

```bash
curl -X POST http://localhost:8082/graphql \
  -H "Content-Type: application/json" \
  -d '{"query": "{ keyspaces { name } }"}'
# Attendu : Liste des keyspaces (GraphQL)
```

### Test 4 : Client Python (Data API)

```bash
python3 data_api_examples/01_connect_data_api.py
# Attendu : Connexion réussie
```

---

## 🔐 Authentification

**Par défaut** (DEVELOPER_MODE=true) :

- ✅ Pas d'authentification requise
- ⚠️ **Non sécurisé** - Pour POC uniquement

**Pour Production** :

- Configurer l'authentification via tokens
- Voir : [Securing Stargate](https://stargate.io/docs/latest/secure/authentication.html)

---

## 📊 Utilisation avec Data API HCD

### Configuration

```bash
# Endpoint Data API
export API_ENDPOINT="http://localhost:8080"
export USERNAME="cassandra"
export PASSWORD="cassandra"
```

### Client Python

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

---

## 🛠️ Gestion

### Voir les Logs

```bash
podman logs stargate
podman logs -f stargate  # Suivre en temps réel
```

### Arrêter Stargate

```bash
podman stop stargate
```

### Démarrer Stargate

```bash
podman start stargate
```

### Supprimer Stargate

```bash
podman stop stargate
podman rm stargate
```

### Redémarrer Stargate

```bash
podman restart stargate
```

---

## 🔍 Dépannage

### Problème : Stargate ne démarre pas

**Vérifications** :

1. HCD est démarré : `nc -z localhost 9042`
2. Podman fonctionne : `podman info`
3. Ports disponibles : `lsof -i :8080`

**Logs** :

```bash
podman logs stargate
```

### Problème : Erreur de connexion au cluster

**Vérifications** :

1. `CLUSTER_SEED` correct : `localhost:9042`
2. HCD accessible depuis Podman : `podman exec stargate ping localhost`
3. Version Cassandra correcte : `CLUSTER_VERSION=4.0`

### Problème : Client Python échoue

**Vérifications** :

1. Endpoint accessible : `curl http://localhost:8080/v1/status`
2. Variables d'environnement : `echo $API_ENDPOINT`
3. Client installé : `pip3 list | grep astrapy`

---

## 📚 Documentation Complète

### Stargate

- **Documentation principale** : <https://stargate.io/docs/latest/index.html>
- **Installation** : <https://stargate.io/docs/latest/install/cassandra-4.0.html>
- **REST API** : <https://stargate.io/docs/latest/develop/rest.html>
- **GraphQL API** : <https://stargate.io/docs/latest/develop/graphql.html>
- **Sécurité** : <https://stargate.io/docs/latest/secure/authentication.html>

### Data API HCD

- **Documentation** : <https://docs.datastax.com/en/hyper-converged-database/1.2/api-reference/dataapiclient.html>
- **Quickstart** : <https://docs.datastax.com/en/hyper-converged-database/1.2/api-reference/quickstart.html>

---

## 🎯 Recommandations

### Pour POC

**Option A : Sans Stargate** ✅

- Utiliser CQL direct (déjà démontré)
- Performance optimale
- Pas de dépendance supplémentaire

**Option B : Avec Stargate** 🟢

- Tester réellement la Data API
- Démonstrer l'accès REST/GraphQL
- Valider les performances

### Pour Production

**Obligatoire** : Stargate ou gateway équivalent

- Déployé via Kubernetes
- Configuration sécurisée (authentification)
- Monitoring et logging

---

## ✅ Checklist

- [ ] Podman installé et fonctionnel
- [ ] HCD démarré sur `localhost:9042`
- [ ] Ports `8080`, `8081`, `8082` disponibles
- [ ] Stargate déployé (via script ou manuellement)
- [ ] Endpoint accessible (`curl http://localhost:8080/v1/status`)
- [ ] Variables d'environnement configurées
- [ ] Client Python testé
- [ ] Documentation consultée

---

**✅ Stargate est le gateway recommandé pour exposer HCD via Data API**
