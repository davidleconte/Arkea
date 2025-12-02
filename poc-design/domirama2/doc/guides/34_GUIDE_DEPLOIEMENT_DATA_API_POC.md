# 🚀 Guide : Déploiement Data API pour POC Local

**Date** : 2025-11-25  
**Référence** : <https://docs.datastax.com/en/hyper-converged-database/1.2/api-reference/dataapiclient.html>  
**Objectif** : Déployer réellement la Data API pour un POC local HCD

---

## 📋 Prérequis selon la Documentation Officielle

D'après la [documentation Data API HCD](https://docs.datastax.com/en/hyper-converged-database/1.2/api-reference/dataapiclient.html), la Data API nécessite :

1. **Endpoint** : `http://CLUSTER_HOST:GATEWAY_PORT`
   - `CLUSTER_HOST` : IP externe d'un nœud du cluster (via `kubectl get nodes -o wide`)
   - `GATEWAY_PORT` : Port du service API gateway (via `kubectl get svc`)

2. **Token** : `Cassandra:BASE64-USERNAME:BASE64-PASSWORD`

3. **Client** : `astrapy` (Python), `@datastax/astra-db-ts` (TypeScript), ou `astra-db-java` (Java)

**Important** : La documentation suppose un **déploiement Kubernetes** avec services configurés.

---

## ⚠️ Problème pour POC Local

### HCD Local (Standalone)

Notre POC utilise **HCD local** (tarball, single-node) :

- ✅ HCD installé : `binaire/hcd-1.2.3/`
- ✅ Port CQL : `9042` (accessible)
- ❌ **Pas de Kubernetes**
- ❌ **Pas de service Data API**
- ❌ **Pas de GATEWAY_PORT**

**Conséquence** : La Data API n'est **pas disponible** par défaut sur HCD local.

---

## 🎯 Solutions pour POC Local

### Option 1 : Déployer Stargate (Recommandé pour POC)

**Stargate** est le gateway open-source qui expose Cassandra via REST/GraphQL.

**Documentation officielle** : <https://stargate.io/docs/latest/index.html>

#### Installation via Podman

**Référence** : [Installing Stargate - Cassandra 4.0](https://stargate.io/docs/latest/install/cassandra-4.0.html)

**Note** : Ce POC utilise Podman au lieu de Docker.

```bash
# 1. Vérifier que HCD est démarré
nc -z localhost 9042 || echo "❌ HCD non démarré"

# 2. Démarrer Stargate avec Podman
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

# 3. Vérifier que Stargate est démarré
sleep 10
curl http://localhost:8080/v1/status
# Devrait retourner : {"status":"ok"}
```

**Ports Stargate** (selon [Stargate Ports](https://stargate.io/docs/latest/install/stargate-ports.html)) :

- `8080` : REST API v1
- `8081` : REST API v2
- `8082` : GraphQL API

#### Configuration

```bash
# Mettre à jour l'endpoint
export API_ENDPOINT="http://localhost:8080"
export USERNAME="cassandra"
export PASSWORD="cassandra"

# Ou dans .poc-profile
echo 'export API_ENDPOINT="http://localhost:8080"' >> .poc-profile
```

#### Test

```bash
# Test HTTP
curl http://localhost:8080/v1/status

# Test avec client Python
python3 data_api_examples/01_connect_data_api.py
```

---

### Option 2 : HCD en Kubernetes (Production)

Pour un déploiement production-like :

1. **Déployer HCD en Kubernetes** (via Mission Control ou manuellement)
2. **Trouver l'endpoint** :

   ```bash
   # CLUSTER_HOST
   kubectl get nodes -o wide
   # Utiliser EXTERNAL-IP

   # GATEWAY_PORT
   kubectl get svc
   # Trouver le service Data API / Stargate / Gateway
   # Utiliser le NodePort
   ```

3. **Configurer** :

   ```bash
   export API_ENDPOINT="http://EXTERNAL-IP:NODEPORT"
   ```

---

### Option 3 : Utiliser CQL Direct (Actuel - Recommandé pour POC)

**Pour le POC, utiliser directement CQL** :

- ✅ Déjà démontré et fonctionnel
- ✅ Performance optimale
- ✅ Pas de dépendance supplémentaire
- ✅ Conforme aux besoins fonctionnels

**La Data API reste optionnelle** pour :

- Applications mobiles
- Intégration partenaires
- Microservices

---

## 📋 Script de Déploiement Stargate

Un script automatisé est disponible :

```bash
./39_deploy_stargate.sh
```

Ce script :

1. Vérifie que HCD est démarré
2. Vérifie que Podman est disponible
3. Déploie Stargate via Podman
4. Vérifie que l'endpoint est accessible
5. Teste la connexion avec le client Python

---

## 🔍 Vérification Post-Déploiement

### Test 1 : HTTP Status

```bash
curl http://localhost:8080/v1/status
# Attendu : {"status":"ok"} ou HTTP 200
```

### Test 2 : Client Python

```bash
python3 data_api_examples/01_connect_data_api.py
# Attendu : Connexion réussie
```

### Test 3 : Script de Vérification

```bash
./38_verifier_endpoint_data_api.sh
# Devrait maintenant montrer : ✅ Endpoint accessible
```

---

## 📊 Comparaison : Avant vs Après Déploiement

| Élément | Avant (Sans Stargate) | Après (Avec Stargate) |
|---------|----------------------|----------------------|
| **Port 8080** | ❌ Non en écoute | ✅ En écoute |
| **HTTP curl** | ❌ Connection refused | ✅ HTTP 200 |
| **Client Python** | ❌ Erreur "Environments outside of Astra DB" | ✅ Connexion réussie |
| **Tests réels** | ❌ Impossible | ✅ Possibles |

---

## 🎯 Recommandation pour POC

### Pour Démonstration Conceptuelle

**Suffisant** :

- ✅ Configuration documentée
- ✅ Exemples de code créés
- ✅ Valeur ajoutée expliquée
- ✅ Documentation complète

**Pas besoin de Stargate** si :

- On utilise CQL direct (déjà démontré)
- On veut juste montrer la valeur ajoutée
- On n'a pas besoin de tests réels

### Pour Tests Réels

**Nécessaire** :

- ✅ Déployer Stargate (Podman)
- ✅ Configurer l'endpoint
- ✅ Tester avec les exemples

**Utile si** :

- On veut tester réellement la Data API
- On veut démontrer l'accès mobile/front-end
- On veut valider les performances

---

## 📚 Références

### Data API HCD

- **Documentation officielle** : <https://docs.datastax.com/en/hyper-converged-database/1.2/api-reference/dataapiclient.html>
- **Quickstart** : <https://docs.datastax.com/en/hyper-converged-database/1.2/api-reference/quickstart.html>

### Stargate

- **Documentation officielle** : <https://stargate.io/docs/latest/index.html>
- **Installation Cassandra 4.0** : <https://stargate.io/docs/latest/install/cassandra-4.0.html>
- **Ports Stargate** : <https://stargate.io/docs/latest/install/stargate-ports.html>
- **REST API** : <https://stargate.io/docs/latest/develop/rest.html>
- **GraphQL API** : <https://stargate.io/docs/latest/develop/graphql.html>

---

## ✅ Conclusion

**Pour POC Local** :

- **Option A** : Utiliser CQL direct (déjà démontré) ✅
- **Option B** : Déployer Stargate pour tests réels Data API 🟢

**La Data API est configurée et documentée, mais nécessite Stargate pour être réellement accessible.**

---

**✅ Configuration : Complète**  
**⚠️ Déploiement : Optionnel (Stargate requis pour endpoint réel)**
