# 🎯 Valeur Ajoutée de la Data API pour Domirama

**Date** : 2025-11-25
**Table** : Domirama (operations_by_account)
**Objectif** : Analyser la valeur ajoutée concrète de la Data API vs CQL direct

---

## 📋 Contexte : Architecture Domirama Actuelle

### Architecture HBase Actuelle

**Composants** :

- **Backend Java** : API HBase (clients Java)
- **Front-end Web** : Application client bancaire
- **Mobile** : Applications mobiles (iOS/Android)
- **Batch** : MapReduce/PIG pour ingestion

**Patterns d'Accès** :

- **Temps réel** : API Java → HBase (SCAN, MultiGet)
- **Recherche** : SCAN complet → Index Solr in-memory → MultiGet
- **Correction client** : PUT avec timestamp

### Architecture HCD Proposée (POC Domirama2)

**Composants** :

- **Backend Java** : Drivers Cassandra (CQL)
- **Front-end Web** : Application client bancaire
- **Mobile** : Applications mobiles (iOS/Android)
- **Batch** : Spark pour ingestion

**Patterns d'Accès** :

- **Temps réel** : Drivers Cassandra → HCD (SELECT + SAI)
- **Recherche** : SELECT avec SAI (pas de scan complet)
- **Correction client** : UPDATE avec cat_user

---

## 🔍 Analyse : Data API vs CQL Direct

### 1. Cas d'Usage : Application Web Front-End

#### Scénario Actuel (CQL Direct)

**Architecture** :

```
Front-end Web → Backend Java → Driver Cassandra → HCD
```

**Avantages** :

- ✅ Performance optimale (connexion directe)
- ✅ Contrôle total (requêtes optimisées)
- ✅ Pas de couche intermédiaire

**Inconvénients** :

- ⚠️ Backend Java nécessaire (couplage)
- ⚠️ Gestion des connexions (pooling)
- ⚠️ Maintenance du code driver

#### Scénario avec Data API

**Architecture** :

```
Front-end Web → Data API (REST/GraphQL) → HCD
```

**Avantages** :

- ✅ **Simplification** : Pas de backend Java intermédiaire
- ✅ **Découplage** : Front-end indépendant du backend
- ✅ **Standard HTTP** : Facile à intégrer (fetch, axios)
- ✅ **GraphQL** : Requêtes flexibles côté client
- ✅ **Sécurité** : Authentification token centralisée

**Inconvénients** :

- ⚠️ Latence légèrement supérieure (HTTP vs binaire)
- ⚠️ Moins de contrôle sur les requêtes

**Valeur Ajoutée** : 🟢 **Moyenne à Élevée**

- Simplification architecture
- Découplage front-end/back-end
- Développement front-end plus rapide

---

### 2. Cas d'Usage : Applications Mobiles (iOS/Android)

#### Scénario Actuel (CQL Direct)

**Architecture** :

```
Mobile App → Backend API → Driver Cassandra → HCD
```

**Problèmes** :

- ⚠️ Backend API nécessaire (couche intermédiaire)
- ⚠️ Gestion des versions API
- ⚠️ Latence réseau (mobile → backend → HCD)

#### Scénario avec Data API

**Architecture** :

```
Mobile App → Data API (REST) → HCD
```

**Avantages** :

- ✅ **Accès direct** : Mobile → HCD (sans backend)
- ✅ **REST standard** : Facile à intégrer (URLSession, Retrofit)
- ✅ **GraphQL** : Requêtes adaptées au mobile (seulement les champs nécessaires)
- ✅ **Cache** : Gestion cache HTTP native
- ✅ **Offline** : Stratégies de cache/offline plus simples

**Valeur Ajoutée** : 🟢 **Élevée**

- Simplification architecture mobile
- Réduction latence (moins de sauts)
- Développement mobile plus rapide

---

### 3. Cas d'Usage : Microservices / API Gateway

#### Scénario Actuel (CQL Direct)

**Architecture** :

```
Microservice → Driver Cassandra → HCD
```

**Problèmes** :

- ⚠️ Chaque microservice doit gérer le driver
- ⚠️ Pooling de connexions par service
- ⚠️ Configuration distribuée

#### Scénario avec Data API

**Architecture** :

```
Microservice → Data API (REST) → HCD
```

**Avantages** :

- ✅ **Unification** : Point d'entrée unique
- ✅ **API Gateway** : Routage, rate limiting, monitoring
- ✅ **Découplage** : Microservices indépendants du driver
- ✅ **Monitoring** : Métriques centralisées
- ✅ **Sécurité** : Authentification centralisée

**Valeur Ajoutée** : 🟢 **Élevée**

- Architecture microservices simplifiée
- Gestion centralisée
- Monitoring unifié

---

### 4. Cas d'Usage : Intégration Partenaires / Externes

#### Scénario Actuel (CQL Direct)

**Problèmes** :

- ❌ **Sécurité** : Impossible d'exposer CQL directement
- ❌ **Backend nécessaire** : API wrapper obligatoire
- ❌ **Complexité** : Gestion authentification, rate limiting

#### Scénario avec Data API

**Avantages** :

- ✅ **Sécurité** : Authentification token (API key)
- ✅ **Rate limiting** : Contrôle d'accès intégré
- ✅ **Documentation** : API auto-documentée (OpenAPI/Swagger)
- ✅ **Versioning** : Gestion versions API
- ✅ **Monitoring** : Traçabilité des accès

**Valeur Ajoutée** : 🟢 **Très Élevée**

- Exposition sécurisée possible
- Pas besoin de backend wrapper
- Intégration partenaires facilitée

---

### 5. Cas d'Usage : Développement Rapide / Prototypage

#### Scénario Actuel (CQL Direct)

**Problèmes** :

- ⚠️ Nécessite driver et configuration
- ⚠️ Courbe d'apprentissage CQL
- ⚠️ Setup complexe

#### Scénario avec Data API

**Avantages** :

- ✅ **Rapidité** : Requêtes HTTP simples (curl, Postman)
- ✅ **Prototypage** : Développement front-end sans backend
- ✅ **Tests** : Tests d'intégration simplifiés
- ✅ **Documentation** : Auto-générée (GraphQL schema)

**Valeur Ajoutée** : 🟢 **Moyenne**

- Accélération développement
- Prototypage facilité
- Tests simplifiés

---

### 6. Cas d'Usage : GraphQL pour Requêtes Flexibles

#### Scénario Actuel (CQL Direct)

**Problèmes** :

- ⚠️ Requêtes CQL fixes (backend)
- ⚠️ Over-fetching (toutes les colonnes)
- ⚠️ Under-fetching (plusieurs requêtes nécessaires)

#### Scénario avec Data API (GraphQL)

**Avantages** :

- ✅ **Flexibilité** : Client demande exactement ce qu'il veut
- ✅ **Efficacité** : Pas d'over-fetching
- ✅ **Agrégation** : Requêtes combinées (opérations + catégories)
- ✅ **Évolution** : Ajout de champs sans casser les clients

**Exemple GraphQL** :

```graphql
query {
  operations(
    code_si: "01"
    contrat: "1234567890"
    date_op: {gte: "2024-01-01", lte: "2024-12-31"}
    libelle: "loyer"
  ) {
    date_op
    numero_op
    libelle
    montant
    cat_auto
    cat_user
    cat_confidence
  }
}
```

**Valeur Ajoutée** : 🟢 **Élevée**

- Requêtes optimisées côté client
- Évolution API sans breaking changes
- Expérience développeur améliorée

---

## 📊 Tableau Comparatif : Valeur Ajoutée par Cas d'Usage

| Cas d'Usage | CQL Direct | Data API | Valeur Ajoutée | Priorité |
|-------------|------------|----------|----------------|----------|
| **Application Web** | ✅ Performance | ✅ Simplification | 🟢 Moyenne-Élevée | 🟡 Optionnel |
| **Applications Mobiles** | ⚠️ Backend nécessaire | ✅ Accès direct | 🟢 **Élevée** | 🟢 **Recommandé** |
| **Microservices** | ⚠️ Gestion distribuée | ✅ Unification | 🟢 **Élevée** | 🟢 **Recommandé** |
| **Intégration Partenaires** | ❌ Impossible | ✅ Sécurisé | 🟢 **Très Élevée** | 🔴 **Critique** |
| **Prototypage** | ⚠️ Complexe | ✅ Rapide | 🟢 Moyenne | 🟡 Optionnel |
| **GraphQL** | ❌ Non disponible | ✅ Disponible | 🟢 **Élevée** | 🟢 **Recommandé** |

---

## 🎯 Recommandations par Scénario

### Scénario 1 : Architecture Monolithique (Backend Java)

**Recommandation** : ⚠️ **Data API non nécessaire**

**Justification** :

- Backend Java déjà en place
- Performance CQL optimale
- Pas de besoin d'exposition externe

**Action** : Conserver CQL direct

---

### Scénario 2 : Architecture Microservices

**Recommandation** : ✅ **Data API recommandée**

**Justification** :

- Unification des accès
- Découplage des services
- Monitoring centralisé

**Action** : Implémenter Data API comme point d'entrée unique

---

### Scénario 3 : Applications Mobiles

**Recommandation** : ✅ **Data API fortement recommandée**

**Justification** :

- Accès direct mobile → HCD
- Réduction latence
- GraphQL pour requêtes optimisées

**Action** : Utiliser Data API REST/GraphQL pour mobile

---

### Scénario 4 : Intégration Partenaires / Externes

**Recommandation** : 🔴 **Data API critique**

**Justification** :

- Sécurité (API key)
- Rate limiting
- Documentation auto-générée

**Action** : Data API obligatoire pour exposition externe

---

### Scénario 5 : Architecture Hybride

**Recommandation** : ✅ **Data API + CQL (complémentaires)**

**Justification** :

- CQL pour backend haute performance
- Data API pour front-end/mobile/externe

**Action** : Utiliser les deux selon le cas d'usage

---

## 💡 Cas d'Usage Concrets Domirama

### 1. Recherche d'Opérations (Front-end Web)

**Avec CQL Direct** :

```java
// Backend Java
String query = "SELECT * FROM operations_by_account " +
               "WHERE code_si = ? AND contrat = ? " +
               "AND libelle : ?";
PreparedStatement stmt = session.prepare(query);
ResultSet rs = session.execute(stmt.bind(codeSi, contrat, searchTerm));
```

**Avec Data API (REST)** :

```javascript
// Front-end JavaScript
const response = await fetch(
  `https://api.hcd.example/v2/keyspaces/domirama2_poc/operations_by_account?where={"code_si":"${codeSi}","contrat":"${contrat}","libelle":{"$contains":"${searchTerm}"}}`,
  {
    headers: {
      'X-Cassandra-Token': apiToken
    }
  }
);
```

**Avec Data API (GraphQL)** :

```graphql
query SearchOperations($codeSi: String!, $contrat: String!, $searchTerm: String!) {
  operations_by_account(
    filter: {
      code_si: {eq: $codeSi}
      contrat: {eq: $contrat}
      libelle: {contains: $searchTerm}
    }
  ) {
    values {
      date_op
      numero_op
      libelle
      montant
      cat_auto
      cat_user
    }
  }
}
```

**Valeur Ajoutée** : 🟢 **Moyenne**

- Front-end peut accéder directement
- Pas besoin de backend Java
- GraphQL plus flexible

---

### 2. Correction Catégorie Client (Mobile)

**Avec CQL Direct** :

```java
// Backend Java nécessaire
String update = "UPDATE operations_by_account " +
                "SET cat_user = ?, cat_date_user = now() " +
                "WHERE code_si = ? AND contrat = ? " +
                "AND date_op = ? AND numero_op = ?";
PreparedStatement stmt = session.prepare(update);
session.execute(stmt.bind(catUser, codeSi, contrat, dateOp, numeroOp));
```

**Avec Data API (REST)** :

```swift
// iOS Swift
let url = URL(string: "https://api.hcd.example/v2/keyspaces/domirama2_poc/operations_by_account/\(operationId)")!
var request = URLRequest(url: url)
request.httpMethod = "PATCH"
request.setValue(apiToken, forHTTPHeaderField: "X-Cassandra-Token")
request.setValue("application/json", forHTTPHeaderField: "Content-Type")

let body = [
    "cat_user": newCategory,
    "cat_date_user": ISO8601DateFormatter().string(from: Date())
]
request.httpBody = try JSONSerialization.data(withJSONObject: body)

let task = URLSession.shared.dataTask(with: request) { data, response, error in
    // Handle response
}
task.resume()
```

**Valeur Ajoutée** : 🟢 **Élevée**

- Mobile peut mettre à jour directement
- Pas besoin de backend API
- Code plus simple

---

### 3. Export Données Partenaire (Externe)

**Avec CQL Direct** :

- ❌ Impossible d'exposer CQL directement
- ⚠️ Backend wrapper nécessaire
- ⚠️ Gestion sécurité complexe

**Avec Data API (REST)** :

```python
# Partenaire externe
import requests

headers = {
    'X-Cassandra-Token': partner_api_key,
    'Content-Type': 'application/json'
}

response = requests.get(
    'https://api.hcd.example/v2/keyspaces/domirama2_poc/operations_by_account',
    params={
        'where': '{"code_si":"01","date_op":{"$gte":"2024-01-01"}}',
        'page-size': 100
    },
    headers=headers
)

operations = response.json()['data']
```

**Valeur Ajoutée** : 🟢 **Très Élevée**

- Exposition sécurisée possible
- Pas de backend wrapper
- Rate limiting intégré

---

## 📊 Synthèse : Valeur Ajoutée Globale

### Pour Domirama Spécifiquement

**Valeur Ajoutée** : 🟢 **Moyenne à Élevée**

**Justification** :

- ✅ Applications mobiles : **Élevée** (accès direct)
- ✅ Microservices : **Élevée** (unification)
- ✅ Intégration partenaires : **Très Élevée** (sécurité)
- ⚠️ Application web : **Moyenne** (simplification)
- ⚠️ Backend batch : **Faible** (CQL plus performant)

### Recommandation Globale

**Pour POC** : 🟡 **Optionnel**

- CQL suffit pour démonstration
- Data API peut être ajoutée si besoin

**Pour Production** : 🟢 **Recommandé** (selon architecture)

- **Obligatoire** si : Intégration partenaires, applications mobiles
- **Recommandé** si : Architecture microservices, GraphQL souhaité
- **Optionnel** si : Architecture monolithique, backend Java uniquement

---

## 🎯 Plan d'Action : Implémentation Data API

### Phase 1 : Évaluation (POC)

**Objectif** : Déterminer si Data API apporte une valeur

**Actions** :

1. ✅ Documenter les cas d'usage (ce document)
2. ⚠️ Tester Data API avec un cas d'usage simple
3. ⚠️ Comparer performance Data API vs CQL

**Délai** : 1-2 jours

---

### Phase 2 : Démonstration (Optionnel)

**Objectif** : Démontrer Data API pour un cas d'usage concret

**Actions** :

1. ⚠️ Setup Data API HCD
2. ⚠️ Créer exemple REST (recherche opérations)
3. ⚠️ Créer exemple GraphQL (requête flexible)
4. ⚠️ Documenter dans POC

**Délai** : 2-3 jours

---

### Phase 3 : Production (Si Justifié)

**Objectif** : Implémenter Data API en production

**Actions** :

1. ⚠️ Configuration Data API HCD
2. ⚠️ Authentification (API keys)
3. ⚠️ Rate limiting
4. ⚠️ Monitoring
5. ⚠️ Documentation API

**Délai** : 1-2 semaines

---

## 📝 Conclusion

### Valeur Ajoutée Data API pour Domirama

**Score Global** : 🟢 **7/10** (Moyenne à Élevée)

**Détail par Cas d'Usage** :

- Applications mobiles : **9/10** (Élevée)
- Microservices : **8/10** (Élevée)
- Intégration partenaires : **10/10** (Très Élevée)
- Application web : **6/10** (Moyenne)
- Backend batch : **3/10** (Faible)

### Recommandation Finale

**Pour POC** : ⚠️ **Optionnel**

- Focus sur fonctionnalités core (CQL)
- Data API peut être ajoutée si besoin spécifique

**Pour Production** : 🟢 **Recommandé** (selon architecture)

- **Critique** si intégration partenaires ou applications mobiles
- **Recommandé** si architecture microservices
- **Optionnel** si architecture monolithique backend Java

---

**✅ La Data API apporte une valeur significative pour les cas d'usage modernes (mobile, microservices, partenaires), mais reste optionnelle pour les architectures traditionnelles (backend Java monolithique).**
