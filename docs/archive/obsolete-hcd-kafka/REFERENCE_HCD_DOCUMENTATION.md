# 📚 Référence Documentation Officielle IBM/DataStax HCD 1.2

**Date** : 2025-11-25
**Version HCD** : 1.2
**Source** : Documentation officielle DataStax/IBM

---

## 📋 Vue d'Ensemble

Ce document consolide les concepts clés de la documentation officielle IBM/DataStax HCD 1.2 pour référence rapide dans le contexte du POC de migration HBase → HCD.

**Documentation officielle** : [https://docs.datastax.com/en/hyper-converged-database/1.2/](https://docs.datastax.com/en/hyper-converged-database/1.2/get-started/hcd-introduction.html)

---

## 🎯 Introduction à HCD

### Qu'est-ce que HCD ?

**Hyper-Converged Database (HCD)** est une base de données auto-gérée construite sur **Apache Cassandra®**, une base de données NoSQL distribuée open-source. HCD permet de gérer l'infrastructure hyper-convergée (HCI) dans une plateforme unifiée pour les charges de travail de données, IA et analytiques.

**Caractéristiques principales** :

- **Self-managed** : Gestion autonome de la base de données
- **Built on Cassandra** : Basé sur Apache Cassandra
- **HCI support** : Support de l'infrastructure hyper-convergée
- **Unified platform** : Plateforme unifiée pour données, IA et analytics
- **Vector search** : Recherche vectorielle native
- **Real-time processing** : Traitement en temps réel

**Référence** : [Intro to HCD](https://docs.datastax.com/en/hyper-converged-database/1.2/get-started/hcd-introduction.html)

### Cas d'Usage

**Vector search applications** :

- Generative AI (GenAI)
- Semantic search
- Geospatial search
- RAG (Retrieval-Augmented Generation) applications
- AI assistants / chatbots
- Document Q&A
- Sentiment analysis
- Personalization

**Schema-driven applications** :

- E-commerce
- Financial services
- IoT
- Applications nécessitant un schéma défini

---

## 🔍 Storage-Attached Indexing (SAI)

### Qu'est-ce que SAI ?

**Storage-Attached Indexing (SAI)** est un moteur d'indexation distribué profondément intégré à Cassandra/HCD qui offre des fonctionnalités d'indexation avancées.

**Avantages** :

- Indexation secondaire efficace
- Recherche full-text avec analyseurs Lucene
- Indexation vectorielle pour recherche par similarité
- Indexation numérique avec range queries
- Support des collections (maps, sets, lists)
- Performance optimisée (moins d'I/O, latence réduite)
- Intégration au cycle de vie des données (compactions, TTL)

**Référence** : [SAI Quickstart](https://docs.datastax.com/en/hyper-converged-database/1.2/tutorials/sai-quickstart.html)

### Types d'Index SAI

1. **Index d'égalité** : `WHERE column = value`
2. **Index de range** : `WHERE column > value` (numériques, dates)
3. **Index textuel** : `WHERE column : 'term'` (full-text search)
4. **Index vectoriel** : `ORDER BY vector_column ANN OF [...]` (similarity search)

### Création d'Index SAI

```cql
-- Index simple
CREATE CUSTOM INDEX idx_name ON keyspace.table(column)
USING 'StorageAttachedIndex';

-- Index avec options
CREATE CUSTOM INDEX idx_name ON keyspace.table(column)
USING 'StorageAttachedIndex'
WITH OPTIONS = {
  'case_sensitive': 'false',
  'normalize': 'true'
};
```

---

## 📝 CQL Analyzers (Recherche Full-Text)

### Analyseurs Lucene

HCD supporte les **analyseurs Lucene** pour la recherche full-text avec tokenisation, normalisation et stemming.

**Fonctionnalités** :

- Tokenisation standard
- Filtres de langue (français, anglais, etc.)
- Normalisation Unicode
- Stemming (racinisation)
- Stop words
- Case-insensitive search

**Référence** : [Use Analyzers with CQL](https://docs.datastax.com/en/hyper-converged-database/1.2/tutorials/use-analyzers-with-cql.html)

### Exemple d'Index avec Analyzer

```cql
CREATE CUSTOM INDEX idx_libelle ON domirama.operations(libelle)
USING 'org.apache.cassandra.index.sai.StorageAttachedIndex'
WITH OPTIONS = {
  'index_analyzer': '{
    "tokenizer": {"name": "standard"},
    "filters": [
      {"name": "lowercase"},
      {"name": "french"}
    ]
  }'
};
```

### Requête Full-Text

```cql
-- Recherche par terme (opérateur :)
SELECT * FROM domirama.operations
WHERE code_si = '01' AND contrat = '12345'
  AND libelle : 'loyer';

-- Recherche combinée (AND)
SELECT * FROM domirama.operations
WHERE code_si = '01' AND contrat = '12345'
  AND libelle : 'loyer' AND libelle : 'janvier';
```

---

## 🧮 Vector Search (Recherche Vectorielle)

### Qu'est-ce que Vector Search ?

La **recherche vectorielle** permet de stocker et rechercher des **embeddings** (vecteurs numériques) pour la recherche par similarité sémantique.

**Cas d'usage** :

- RAG (Retrieval-Augmented Generation)
- Semantic search
- Similarity matching
- AI applications

**Référence** : [Vector Search with CQL](https://docs.datastax.com/en/hyper-converged-database/1.2/tutorials/vector-search-with-cql.html)

### Type VECTOR

```cql
-- Créer une table avec colonne vectorielle
CREATE TABLE documents (
    id UUID PRIMARY KEY,
    content TEXT,
    embedding VECTOR<FLOAT, 128>
);

-- Créer un index vectoriel
CREATE CUSTOM INDEX idx_embedding ON documents(embedding)
USING 'StorageAttachedIndex';
```

### Requête Vectorielle (ANN)

```cql
-- Recherche par similarité (Approximate Nearest Neighbor)
SELECT id, content
FROM documents
ORDER BY embedding ANN OF [0.1, 0.2, ..., 0.9]
LIMIT 10;

-- Combinaison vector + filtre textuel
SELECT id, content
FROM documents
WHERE content : 'terme'
ORDER BY embedding ANN OF [...]
LIMIT 10;
```

### Algorithme ANN

HCD utilise **JVector** (Approximate Nearest Neighbor) basé sur **DiskANN** pour des recherches rapides et scalables sur de grandes collections de vecteurs.

---

## 🔌 Data API

### Qu'est-ce que la Data API ?

La **Data API** est une API moderne (REST/GraphQL) pour accéder à HCD sans nécessiter de driver binaire ou de connexion CQL directe. Elle s'appuie sur **Stargate**.

**Avantages** :

- Accès HTTP/HTTPS simple
- REST et GraphQL supportés
- Authentification par token
- Typage fort (GraphQL)
- Sécurité intégrée

**Référence** : [Data API Client](https://docs.datastax.com/en/hyper-converged-database/1.2/api-reference/dataapiclient.html)

### Endpoints REST

```bash
# GET - Récupérer des données
GET /api/rest/v2/keyspaces/{keyspace}/{table}?where={...}

# POST - Insérer des données
POST /api/rest/v2/keyspaces/{keyspace}/{table}
Content-Type: application/json
{
  "column1": "value1",
  "column2": "value2"
}

# PUT - Mettre à jour
PUT /api/rest/v2/keyspaces/{keyspace}/{table}/{primary_key}
```

### GraphQL

```graphql
query {
  operations(
    filter: {code_si: {eq: "01"}, contrat: {eq: "12345"}}
    options: {limit: 10}
  ) {
    values {
      code_si
      contrat
      libelle
      montant
    }
  }
}
```

### Clients Disponibles

- **Python** : `astra-db-python` (adapté HCD)
- **Java** : `astra-db-java` (adapté HCD)
- **TypeScript/Node.js** : `@datastax/astra-db-ts`
- **REST/GraphQL** : Endpoints HTTP directs

---

## 💾 CQL (Cassandra Query Language)

### Connexion avec cqlsh

```bash
# Connexion locale
cqlsh localhost 9042

# Connexion avec authentification
cqlsh -u username -p password localhost 9042

# Exécuter un fichier CQL
cqlsh -f schema.cql localhost 9042
```

**Référence** : [Connect with cqlsh](https://docs.datastax.com/en/hyper-converged-database/1.2/manage/operations/connect-with-cqlsh.html)

### Structure CQL

**Référence complète** : [CQL Reference](https://docs.datastax.com/en/cql/hcd/index.html)

**Concepts clés** :

- Keyspaces (équivalent databases)
- Tables avec Primary Key (partition + clustering)
- Types de données (text, int, decimal, timestamp, blob, vector, etc.)
- Collections (map, set, list)
- TTL (Time-To-Live)
- Counters
- Lightweight Transactions (LWT)

---

## 📊 Data Modeling

### Méthodologie

**Référence** : [Data Modeling Methodology](https://docs.datastax.com/en/cql/hcd/data-modeling/methodology.html)

**Étapes** :

1. **Conceptual Data Model** : Identifier les entités et relations
2. **Application Workflow** : Définir les requêtes (queries)
3. **Logical Data Model** : Créer les tables pour chaque query
4. **Physical Data Model** : Optimiser (partition keys, clustering keys, indexes)

**Principe clé** : **One table per query pattern** (une table par pattern de requête)

### Bonnes Pratiques

**Référence** : [Data Modeling Best Practices](https://docs.datastax.com/en/cql/hcd/data-modeling/best-practices.html)

**Règles importantes** :

1. **Partition Key** : Choisir pour distribuer les données uniformément
2. **Clustering Key** : Pour trier les données dans une partition
3. **Éviter les partitions trop grandes** : Limiter à ~100 MB par partition
4. **Éviter les hotspots** : Distribuer la charge uniformément
5. **Dénormalisation** : Accepter la duplication pour performance
6. **Indexation SAI** : Utiliser pour les requêtes secondaires
7. **TTL** : Gérer le cycle de vie des données

### Exemple : Modèle Domirama

```cql
-- Table optimisée pour lecture par compte
CREATE TABLE domirama.operations_by_account (
    code_si TEXT,
    contrat TEXT,
    op_date TIMESTAMP,
    op_seq INT,
    libelle TEXT,
    montant DECIMAL,
    PRIMARY KEY ((code_si, contrat), op_date, op_seq)
) WITH CLUSTERING ORDER BY (op_date DESC, op_seq ASC)
  AND default_time_to_live = 315360000; -- 10 ans
```

---

## 🔄 Chargement de Données

### Méthodes de Chargement

1. **Data API** : Via REST/GraphQL (petits volumes, temps réel)
2. **DataStax Bulk Loader (DSBulk)** : Pour chargements massifs
3. **Spark Cassandra Connector** : Pour transformations ETL
4. **CQL INSERT** : Via drivers ou cqlsh

**Référence** : [Load data](https://docs.datastax.com/en/hyper-converged-database/1.2/get-started/hcd-introduction.html#load-data)

### DSBulk

```bash
# Charger depuis CSV
dsbulk load -url data.csv \
  -k keyspace -t table \
  -h localhost -p 9042

# Exporter vers CSV
dsbulk unload -url output.csv \
  -k keyspace -t table \
  -h localhost -p 9042
```

---

## 🔗 Intégrations

### Spark

**Spark Cassandra Connector** permet de lire/écrire dans HCD depuis Spark.

```scala
val df = spark.read
  .format("org.apache.spark.sql.cassandra")
  .options(Map(
    "keyspace" -> "domirama",
    "table" -> "operations"
  ))
  .load()

df.write
  .format("org.apache.spark.sql.cassandra")
  .options(Map(
    "keyspace" -> "domirama",
    "table" -> "operations"
  ))
  .save()
```

### Kafka

**DataStax Kafka Connector** pour ingestion temps réel depuis Kafka vers HCD.

---

## 🛠️ Mission Control

**Mission Control** est un service cloud-based qui fournit une console de gestion unifiée pour les clusters HCD.

**Fonctionnalités** :

- Déploiement de clusters
- Monitoring
- Patching
- Gestion centralisée

**Référence** : [Mission Control](https://docs.datastax.com/en/hyper-converged-database/1.2/get-started/hcd-introduction.html#mission-control-for-cluster-management)

---

## 📚 Références Complètes

### Documentation Principale

1. **Introduction** : [Intro to HCD](https://docs.datastax.com/en/hyper-converged-database/1.2/get-started/hcd-introduction.html)
2. **SAI Quickstart** : [SAI Quickstart](https://docs.datastax.com/en/hyper-converged-database/1.2/tutorials/sai-quickstart.html)
3. **Vector Search** : [Vector Search with CQL](https://docs.datastax.com/en/hyper-converged-database/1.2/tutorials/vector-search-with-cql.html)
4. **Analyzers** : [Use Analyzers with CQL](https://docs.datastax.com/en/hyper-converged-database/1.2/tutorials/use-analyzers-with-cql.html)
5. **Data API** : [Data API Client](https://docs.datastax.com/en/hyper-converged-database/1.2/api-reference/dataapiclient.html)
6. **CQL Reference** : [CQL Reference](https://docs.datastax.com/en/cql/hcd/index.html)
7. **Data Modeling** : [Methodology](https://docs.datastax.com/en/cql/hcd/data-modeling/methodology.html) | [Best Practices](https://docs.datastax.com/en/cql/hcd/data-modeling/best-practices.html)
8. **cqlsh** : [Connect with cqlsh](https://docs.datastax.com/en/hyper-converged-database/1.2/manage/operations/connect-with-cqlsh.html)

### Concepts Clés pour le POC

**Migration HBase → HCD** :

- ✅ TTL natif (remplace TTL HBase)
- ✅ SAI (remplace Solr/Elasticsearch)
- ✅ Vector search (nouveau, pour IA)
- ✅ Data API (simplifie l'accès applicatif)
- ✅ Spark Connector (remplace MapReduce)
- ✅ Kafka Connector (ingestion temps réel)

**Schémas de données** :

- Partition key = distribution des données
- Clustering key = tri dans la partition
- SAI = indexation secondaire
- TTL = purge automatique

**Performance** :

- Lectures par partition key = très rapides
- SAI = recherche full-text native
- Vector search = recherche sémantique
- Data API = latence similaire aux drivers

---

## 🎯 Points Clés pour le POC

### 1. Remplacement Solr par SAI

**HBase actuel** : Scan complet → Index Solr en mémoire
**HCD proposé** : Requête CQL avec index SAI → Résultats directs

### 2. Recherche Full-Text

**HCD** : Index SAI avec analyseurs Lucene
**Syntaxe** : `WHERE libelle : 'terme'`
**Avantage** : Index persistant, pas de reconstruction à chaque connexion

### 3. Recherche Vectorielle (Optionnel)

**HCD** : Support embeddings pour recherche sémantique
**Syntaxe** : `ORDER BY embedding ANN OF [...]`
**Usage** : RAG, recherche intelligente

### 4. Data API

**HCD** : API REST/GraphQL pour accès simplifié
**Avantage** : Pas besoin de driver binaire, accès HTTP simple

### 5. Migration des Données

**Outils** :

- Spark Cassandra Connector (ETL)
- DSBulk (chargement massif)
- Data API (petits volumes)

---

**Document de référence créé pour le POC !** ✅
