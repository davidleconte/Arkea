# 📊 Guide de Comparaison Détaillée des POCs - ARKEA

**Date** : 2025-12-02  
**Objectif** : Comparaison technique détaillée entre BIC, domirama2, et domiramaCatOps  
**Version** : 1.0.0

---

## 📋 Vue d'Ensemble

Ce guide compare en détail les **3 POCs** du projet ARKEA pour la migration HBase → HCD :

1. **BIC** (Base d'Interaction Client)
2. **domirama2** (Domirama v2)
3. **domiramaCatOps** (Domirama Catégorisation des Opérations)

---

## 🔍 Comparaison Technique

### Architecture et Schéma

| Aspect | BIC | domirama2 | domiramaCatOps |
|--------|-----|-----------|----------------|
| **Keyspace** | `bic_poc` | `domirama2_poc` | `domiramacatops_poc` |
| **Tables principales** | `interactions_by_client` | `operations_by_account` | `operations_by_account` + 7 tables meta |
| **Clustering key** | `timeuuid` | `date_op`, `numero_op` | `date_op`, `numero_op` |
| **Colonnes dynamiques** | ✅ MAP | ❌ | ❌ |
| **Format COBOL** | ❌ | ✅ BLOB | ❌ |
| **TTL** | 2 ans | ❌ | 10 ans |

### Format de Données

| Aspect | BIC | domirama2 | domiramaCatOps |
|--------|-----|-----------|----------------|
| **Format source** | JSON (Kafka) + Parquet | Parquet | Parquet |
| **Ingestion temps réel** | ✅ Kafka (Spark Streaming) | ❌ | ❌ |
| **Ingestion batch** | ✅ Parquet | ✅ Parquet | ✅ Parquet |
| **Export batch** | ✅ HDFS/ORC | ✅ Parquet | ❌ |
| **Export incrémental** | ❌ | ✅ Fenêtre glissante | ❌ |

### Recherche et Indexation

| Aspect | BIC | domirama2 | domiramaCatOps |
|--------|-----|-----------|----------------|
| **Full-text search** | ✅ SAI + Lucene | ✅ SAI + Lucene | ✅ SAI + Lucene |
| **Vector search** | ❌ | ✅ ByteT5, e5-large | ✅ ByteT5, e5-large, invoice |
| **Hybrid search** | ❌ | ✅ Full-text + Vector | ✅ Full-text + Vector |
| **Fuzzy search** | ❌ | ✅ | ✅ |
| **N-gram search** | ❌ | ✅ | ✅ |
| **Analyzers Lucene** | ✅ | ✅ | ✅ |

### Fonctionnalités Métier

| Aspect | BIC | domirama2 | domiramaCatOps |
|--------|-----|-----------|----------------|
| **Catégorisation auto** | ❌ | ❌ | ✅ |
| **Corrections client** | ❌ | ✅ Multi-version | ✅ Multi-version |
| **Compteurs atomiques** | ❌ | ❌ | ✅ COUNTER |
| **Règles personnalisées** | ❌ | ❌ | ✅ |
| **Historique oppositions** | ❌ | ❌ | ✅ |
| **Feedbacks** | ❌ | ❌ | ✅ |

### Intégration et API

| Aspect | BIC | domirama2 | domiramaCatOps |
|--------|-----|-----------|----------------|
| **Data API** | ❌ | ✅ REST/GraphQL | ❌ |
| **Kafka ingestion** | ✅ | ❌ | ❌ |
| **Backend API** | ✅ (lecture) | ✅ | ❌ |

### Performance et Scalabilité

| Aspect | BIC | domirama2 | domiramaCatOps |
|--------|-----|-----------|----------------|
| **Pagination** | ✅ Cursor-based | ✅ Cursor-based | ✅ Cursor-based |
| **Export optimisé** | ✅ ORC | ✅ Parquet | ❌ |
| **Fenêtre glissante** | ❌ | ✅ | ❌ |
| **Bloom filter** | ❌ | ✅ Équivalent | ❌ |

---

## 📊 Matrice de Fonctionnalités

### Recherche

| Fonctionnalité | BIC | domirama2 | domiramaCatOps |
|----------------|-----|-----------|----------------|
| Full-text simple | ✅ | ✅ | ✅ |
| Full-text avec analyzers | ✅ | ✅ | ✅ |
| Vector (ByteT5) | ❌ | ✅ | ✅ |
| Vector (e5-large) | ❌ | ✅ | ✅ |
| Vector (invoice) | ❌ | ❌ | ✅ |
| Hybrid (full-text + vector) | ❌ | ✅ | ✅ |
| Fuzzy | ❌ | ✅ | ✅ |
| N-gram | ❌ | ✅ | ✅ |

### Ingestion

| Fonctionnalité | BIC | domirama2 | domiramaCatOps |
|----------------|-----|-----------|----------------|
| Batch Parquet | ✅ | ✅ | ✅ |
| Kafka temps réel | ✅ | ❌ | ❌ |
| Multi-version | ❌ | ✅ | ✅ |
| Bulk load | ✅ | ✅ | ✅ |

### Export

| Fonctionnalité | BIC | domirama2 | domiramaCatOps |
|----------------|-----|-----------|----------------|
| Export Parquet | ❌ | ✅ | ❌ |
| Export ORC/HDFS | ✅ | ❌ | ❌ |
| Export incrémental | ❌ | ✅ | ❌ |
| Fenêtre glissante | ❌ | ✅ | ❌ |
| STARTROW/STOPROW | ❌ | ✅ | ❌ |

### Gestion des Données

| Fonctionnalité | BIC | domirama2 | domiramaCatOps |
|----------------|-----|-----------|----------------|
| TTL automatique | ✅ (2 ans) | ❌ | ✅ (10 ans) |
| Colonnes dynamiques | ✅ MAP | ❌ | ❌ |
| Format COBOL | ❌ | ✅ BLOB | ❌ |
| Catégorisation | ❌ | ❌ | ✅ |
| Compteurs atomiques | ❌ | ❌ | ✅ |

---

## 🎯 Cas d'Usage par POC

### BIC

1. **Timeline conseiller** : 2 ans d'historique des interactions
2. **Ingestion Kafka** : Événements `bic-event` en streaming
3. **Export batch** : Export `bic-unload` vers HDFS/ORC
4. **Filtrage** : Par canal, type d'interaction, résultat
5. **Recherche full-text** : Sur les contenus d'interaction

### domirama2

1. **Stockage opérations** : Table `operations_by_account`
2. **Recherche avancée** : Full-text, vector, hybrid
3. **Export incrémental** : Fenêtre glissante avec équivalences HBase
4. **Data API** : REST/GraphQL pour intégration
5. **Multi-version** : Batch vs client (pas d'écrasement)

### domiramaCatOps

1. **Catégorisation auto** : Colonnes `cat_auto`, `cat_confidence`
2. **Corrections client** : Colonnes `cat_user`, `cat_date_user`
3. **7 tables meta** : Acceptation, opposition, règles, feedbacks
4. **Compteurs atomiques** : Feedbacks par libellé et ICS
5. **Recherche avancée** : Full-text, vector (3 modèles), hybrid

---

## 🔧 Différences Techniques Détaillées

### Schéma de Données

#### BIC

```cql
CREATE TABLE bic.interactions_by_client (
    client_id TEXT,
    interaction_time TIMEUUID,
    canal TEXT,
    type_interaction TEXT,
    contenu TEXT,
    metadata MAP<TEXT, TEXT>,
    PRIMARY KEY (client_id, interaction_time)
) WITH TTL = 63072000; -- 2 ans
```

#### domirama2

```cql
CREATE TABLE domirama2_poc.operations_by_account (
    compte TEXT,
    date_op DATE,
    numero_op INT,
    libelle TEXT,
    montant DECIMAL,
    operation_data BLOB, -- Format COBOL
    PRIMARY KEY (compte, date_op, numero_op)
);
```

#### domiramaCatOps

```cql
CREATE TABLE domiramacatops_poc.operations_by_account (
    compte TEXT,
    date_op DATE,
    numero_op INT,
    cat_auto TEXT, -- Catégorisation automatique
    cat_confidence DECIMAL,
    cat_user TEXT, -- Correction client
    cat_date_user TIMESTAMP,
    PRIMARY KEY (compte, date_op, numero_op)
);
```

### Index SAI

#### BIC

```cql
CREATE CUSTOM INDEX idx_contenu_fulltext ON bic.interactions_by_client (contenu)
USING 'org.apache.cassandra.index.sai.StorageAttachedIndex'
WITH OPTIONS = {
    'index_analyzer': '{
        "tokenizer": "standard",
        "filters": ["lowercase", "asciifolding", "frenchLightStem"]
    }'
};
```

#### domirama2

```cql
-- Full-text
CREATE CUSTOM INDEX idx_libelle_fulltext ON domirama2_poc.operations_by_account (libelle)
USING 'org.apache.cassandra.index.sai.StorageAttachedIndex'
WITH OPTIONS = {
    'index_analyzer': '{
        "tokenizer": "standard",
        "filters": ["lowercase", "asciifolding", "frenchLightStem"]
    }'
};

-- Vector
CREATE CUSTOM INDEX idx_libelle_vector ON domirama2_poc.operations_by_account (libelle_embedding)
USING 'org.apache.cassandra.index.sai.StorageAttachedIndex'
WITH OPTIONS = {'index_mode': 'vector', 'dimensions': 768};
```

#### domiramaCatOps

```cql
-- Full-text (identique domirama2)
-- Vector (3 modèles : ByteT5, e5-large, invoice)
CREATE CUSTOM INDEX idx_libelle_vector_byteT5 ON domiramacatops_poc.operations_by_account (libelle_embedding_byteT5)
USING 'org.apache.cassandra.index.sai.StorageAttachedIndex'
WITH OPTIONS = {'index_mode': 'vector', 'dimensions': 768};
```

---

## 📈 Recommandations

### Pour la Recherche Avancée

**Choisir** : **domirama2** ou **domiramaCatOps**

- Full-text avec analyzers Lucene
- Vector search (ByteT5, e5-large)
- Hybrid search (full-text + vector)
- Fuzzy et N-gram

### Pour l'Ingestion Temps Réel

**Choisir** : **BIC**

- Ingestion Kafka avec Spark Streaming
- Topic `bic-event`
- Traitement en temps réel

### Pour la Catégorisation

**Choisir** : **domiramaCatOps**

- Catégorisation automatique
- Corrections client
- 7 tables meta-categories
- Compteurs atomiques

### Pour l'Export Batch

**Choisir** : **BIC** (ORC/HDFS) ou **domirama2** (Parquet)

- BIC : Export ORC vers HDFS
- domirama2 : Export Parquet incrémental (fenêtre glissante)

### Pour l'Intégration API

**Choisir** : **domirama2**

- Data API REST/GraphQL
- Stargate
- Intégration facile

---

## 🔄 Migration entre POCs

### De domirama2 vers domiramaCatOps

**Similaire** : Structure de base identique (`operations_by_account`)

**Différences** :
- Ajout colonnes catégorisation
- Ajout 7 tables meta-categories
- Ajout compteurs atomiques

**Migration** : Relativement simple (ajout de colonnes et tables)

### De BIC vers domirama2

**Différent** : Structure complètement différente

**Migration** : Complexe (redesign du schéma)

---

## 📚 Documentation Complémentaire

- **GUIDE_CHOIX_POC.md** : Guide de choix selon les besoins
- **poc-design/bic/README.md** : Documentation complète BIC
- **poc-design/domirama2/README.md** : Documentation complète domirama2
- **poc-design/domiramaCatOps/README.md** : Documentation complète domiramaCatOps

---

**Pour plus d'informations, voir** :
- `docs/GUIDE_CHOIX_POC.md` - Guide de choix
- `poc-design/*/README.md` - Documentation de chaque POC

