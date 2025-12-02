# 📚 Enrichissement Documentation : Exemples Concrets et Équivalences HBase → HCD

**Date** : 2025-01-XX  
**Objectif** : Enrichir la documentation des use cases avec des exemples concrets, équivalences HBase → HCD détaillées et diagrammes de flux  
**Format** : Documentation enrichie par use case

---

## 📊 Résumé

Ce document enrichit la documentation existante avec :

- ✅ **Exemples concrets** pour chaque use case
- ✅ **Équivalences HBase → HCD** détaillées avec code
- ✅ **Diagrammes de flux** pour les use cases complexes

---

## 🎯 PARTIE 1 : USE CASES TABLE `domirama` - EXEMPLES CONCRETS

### UC-01 : Catégorisation Automatique (Batch)

#### Contexte HBase

```java
// HBase : Écriture batch avec catégorie automatique
Put put = new Put(Bytes.toBytes("01:5913101072:2024-01-20T10:00:00:1"));
put.addColumn(Bytes.toBytes("category"), Bytes.toBytes("cat_auto"),
              Bytes.toBytes("ALIMENTATION"));
put.addColumn(Bytes.toBytes("category"), Bytes.toBytes("cat_confidence"),
              Bytes.toBytes("0.95"));
table.put(put);
```

#### Équivalent HCD

```cql
-- HCD : Insertion avec catégorie automatique
INSERT INTO operations_by_account (
    code_si, contrat, date_op, numero_op,
    libelle, montant, cat_auto, cat_confidence,
    ingestion_timestamp, ingestion_source, ingestion_batch_id
) VALUES (
    '01', '5913101072', '2024-01-20 10:00:00', 1,
    'CARREFOUR MARKET', 45.50, 'ALIMENTATION', 0.95,
    '2024-01-20 10:00:00', 'batch', 'batch_2024_01_20_001'
);
```

#### Exemple Concret

**Scénario** : Système batch analyse 20 000 opérations quotidiennes et catégorise automatiquement.

**Données d'entrée** :

- Opération : "CARREFOUR MARKET" - 45.50€
- Modèle ML : Score 0.95 → Catégorie "ALIMENTATION"

**Résultat HCD** :

```cql
SELECT code_si, contrat, date_op, libelle, cat_auto, cat_confidence
FROM operations_by_account
WHERE code_si = '01' AND contrat = '5913101072'
  AND date_op >= '2024-01-20' AND date_op < '2024-01-21';

-- Résultat :
-- code_si | contrat     | date_op           | libelle            | cat_auto      | cat_confidence
-- --------+-------------+-------------------+--------------------+---------------+----------------
-- 01      | 5913101072  | 2024-01-20 10:00  | CARREFOUR MARKET   | ALIMENTATION  | 0.95
```

#### Diagramme de Flux

```
┌─────────────────┐
│  Fichier Parquet│
│  (20k opérations)│
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│  Spark Batch    │
│  - Lecture      │
│  - Catégorisation│
│  - Transformation│
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│  HCD Table      │
│  operations_by_ │
│  account        │
│  - cat_auto     │
│  - cat_confidence│
└─────────────────┘
```

---

### UC-02 : Correction Client (Temps Réel)

#### Contexte HBase

```java
// HBase : Correction client via API
Put put = new Put(Bytes.toBytes("01:5913101072:2024-01-20T10:00:00:1"));
put.addColumn(Bytes.toBytes("category"), Bytes.toBytes("cat_user"),
              Bytes.toBytes("RESTAURANT"));
put.addColumn(Bytes.toBytes("category"), Bytes.toBytes("cat_date_user"),
              Bytes.toBytes("2024-01-20T15:30:00"));
table.put(put);
```

#### Équivalent HCD

```cql
-- HCD : Mise à jour client (temps réel)
UPDATE operations_by_account
SET cat_user = 'RESTAURANT',
    cat_date_user = '2024-01-20 15:30:00',
    cat_validee = true,
    ingestion_timestamp = '2024-01-20 15:30:00',
    ingestion_source = 'realtime'
WHERE code_si = '01'
  AND contrat = '5913101072'
  AND date_op = '2024-01-20 10:00:00'
  AND numero_op = 1;
```

#### Exemple Concret

**Scénario** : Client connecté via application mobile corrige une catégorie.

**Données d'entrée** :

- Opération existante : "CARREFOUR MARKET" - Catégorie auto "ALIMENTATION"
- Correction client : "RESTAURANT" (client sait que c'était un restaurant)

**Résultat HCD** :

```cql
SELECT code_si, contrat, date_op, libelle,
       cat_auto, cat_user, cat_date_user, cat_validee
FROM operations_by_account
WHERE code_si = '01' AND contrat = '5913101072'
  AND date_op = '2024-01-20 10:00:00' AND numero_op = 1;

-- Résultat :
-- cat_auto: ALIMENTATION (conservé)
-- cat_user: RESTAURANT (nouveau)
-- cat_date_user: 2024-01-20 15:30:00
-- cat_validee: true
```

#### Diagramme de Flux

```
┌──────────────┐
│  Client App  │
│  (Mobile)    │
└──────┬───────┘
       │ PUT /api/operations/{id}/category
       ▼
┌──────────────┐
│  API Gateway │
│  (REST)      │
└──────┬───────┘
       │
       ▼
┌──────────────┐
│  HCD Update  │
│  - cat_user  │
│  - cat_date  │
│  - cat_validee│
└──────────────┘
```

---

### UC-03 : Stratégie Multi-Version

#### Contexte HBase

```java
// HBase : Écriture batch puis correction client (non-écrasement)
// Batch écrit : cat_auto = "ALIMENTATION"
// Client écrit : cat_user = "RESTAURANT"
// Les deux coexistent dans différentes colonnes
```

#### Équivalent HCD

```cql
-- HCD : Stratégie multi-version native
-- Colonnes séparées : cat_auto (batch) et cat_user (client)
-- Pas d'écrasement, les deux valeurs coexistent

-- Lecture avec priorité client
SELECT
    code_si, contrat, date_op, libelle,
    COALESCE(cat_user, cat_auto) AS categorie_finale,
    CASE
        WHEN cat_user IS NOT NULL THEN 'client'
        ELSE 'batch'
    END AS source_categorie
FROM operations_by_account
WHERE code_si = '01' AND contrat = '5913101072';
```

#### Exemple Concret

**Scénario** : Système batch catégorise, puis client corrige. Les deux valeurs sont conservées.

**État Initial (Batch)** :

- `cat_auto = 'ALIMENTATION'`
- `cat_confidence = 0.95`
- `cat_user = NULL`

**État Après Correction Client** :

- `cat_auto = 'ALIMENTATION'` (conservé)
- `cat_user = 'RESTAURANT'` (ajouté)
- `cat_date_user = '2024-01-20 15:30:00'`
- `cat_validee = true`

**Logique Applicative** :

```python
# Priorité : cat_user > cat_auto
if operation.cat_user:
    categorie_finale = operation.cat_user
    source = "client"
else:
    categorie_finale = operation.cat_auto
    source = "batch"
```

#### Diagramme de Flux

```
┌─────────────┐      ┌─────────────┐
│  Batch Job  │      │  Client App │
└──────┬──────┘      └──────┬──────┘
       │                    │
       ▼                    ▼
┌──────────────────────────────┐
│  HCD operations_by_account   │
│  ┌─────────────┬──────────┐  │
│  │ cat_auto    │ cat_user │  │
│  │ (batch)     │ (client) │  │
│  │ ALIMENTATION│ RESTAURANT│  │
│  └─────────────┴──────────┘  │
└──────────────────────────────┘
       │                    │
       └────────┬───────────┘
                ▼
        ┌───────────────┐
        │  Application  │
        │  COALESCE     │
        │  (cat_user,   │
        │   cat_auto)   │
        └───────────────┘
```

---

### UC-04 : Recherche par Catégorie

#### Contexte HBase

```java
// HBase : Scan avec filtre sur colonne category
Scan scan = new Scan();
Filter filter = new SingleColumnValueFilter(
    Bytes.toBytes("category"),
    Bytes.toBytes("cat_auto"),
    CompareFilter.CompareOp.EQUAL,
    Bytes.toBytes("ALIMENTATION")
);
scan.setFilter(filter);
ResultScanner scanner = table.getScanner(scan);
```

#### Équivalent HCD

```cql
-- HCD : SELECT avec WHERE + Index SAI
SELECT * FROM operations_by_account
WHERE code_si = '01' AND contrat = '5913101072'
  AND cat_auto = 'ALIMENTATION'
  AND date_op >= '2024-01-01'
ORDER BY date_op DESC;
```

#### Exemple Concret

**Scénario** : Client recherche toutes ses opérations catégorisées "ALIMENTATION" en janvier 2024.

**Requête** :

```cql
SELECT date_op, numero_op, libelle, montant, cat_auto, cat_confidence
FROM operations_by_account
WHERE code_si = '01' AND contrat = '5913101072'
  AND cat_auto = 'ALIMENTATION'
  AND date_op >= '2024-01-01' AND date_op < '2024-02-01'
ORDER BY date_op DESC
LIMIT 50;
```

**Résultat** :

```
date_op           | numero_op | libelle            | montant | cat_auto      | cat_confidence
------------------+-----------+--------------------+---------+---------------+----------------
2024-01-20 10:00  | 1         | CARREFOUR MARKET   | 45.50   | ALIMENTATION  | 0.95
2024-01-18 14:30  | 2         | LECLERC           | 120.00  | ALIMENTATION  | 0.92
2024-01-15 09:15  | 3         | SUPER U           | 67.30   | ALIMENTATION  | 0.88
...
```

**Performance** :

- **Avec Index SAI** : ~5ms (index sur `cat_auto`)
- **Sans Index** : ~200ms (scan complet)

---

### UC-05 : Recherche par Libellé (Full-Text, Fuzzy, Hybrid)

#### Contexte HBase

```java
// HBase : Scan avec filtre texte (basique, pas de fuzzy)
Scan scan = new Scan();
Filter filter = new SingleColumnValueFilter(
    Bytes.toBytes("operations"),
    Bytes.toBytes("libelle"),
    CompareFilter.CompareOp.EQUAL,
    Bytes.toBytes("CARREFOUR")
);
scan.setFilter(filter);
```

#### Équivalent HCD - Full-Text Search

```cql
-- HCD : Full-Text Search avec SAI
SELECT * FROM operations_by_account
WHERE code_si = '01' AND contrat = '5913101072'
  AND libelle : 'CARREFOUR'
ORDER BY date_op DESC;
```

#### Équivalent HCD - Fuzzy Search (Vector)

```python
# HCD : Fuzzy Search avec ByteT5 embeddings
from cassandra.cluster import Cluster
from transformers import T5Tokenizer, T5EncoderModel

# Encoder la requête
tokenizer = T5Tokenizer.from_pretrained('google/byt5-base')
model = T5EncoderModel.from_pretrained('google/byt5-base')
query = "CARREFOUR"
query_embedding = encode_text(query, tokenizer, model)

# Recherche vectorielle
query = """
SELECT code_si, contrat, date_op, numero_op, libelle, montant,
       cat_auto, libelle_embedding
FROM operations_by_account
WHERE code_si = '01' AND contrat = '5913101072'
ORDER BY libelle_embedding ANN OF %s LIMIT 10;
"""
session.execute(query, [query_embedding])
```

#### Équivalent HCD - Hybrid Search

```python
# HCD : Hybrid Search (Full-Text + Vector)
# 1. Full-Text Search (précision)
fulltext_results = session.execute("""
    SELECT * FROM operations_by_account
    WHERE code_si = '01' AND contrat = '5913101072'
      AND libelle : 'CARREFOUR'
    LIMIT 10;
""")

# 2. Si pas de résultats, Vector Search (tolérance typos)
if not fulltext_results:
    vector_results = session.execute("""
        SELECT * FROM operations_by_account
        WHERE code_si = '01' AND contrat = '5913101072'
        ORDER BY libelle_embedding ANN OF %s LIMIT 10;
    """, [query_embedding])
```

#### Exemple Concret

**Scénario** : Client recherche "CARREFOUR" avec typo "CARREFOR".

**Full-Text Search** :

- Requête : `libelle : 'CARREFOR'`
- Résultat : ❌ Aucun résultat (pas de tolérance typo)

**Fuzzy Search (Vector)** :

- Requête : Vector search avec embedding "CARREFOR"
- Résultat : ✅ Trouve "CARREFOUR MARKET" (similarité sémantique)

**Hybrid Search** :

- Étape 1 : Full-Text "CARREFOR" → ❌ Aucun résultat
- Étape 2 : Vector Search "CARREFOR" → ✅ Résultats pertinents

---

### UC-06 : Export Incrémental (TIMERANGE)

#### Contexte HBase

```java
// HBase : Export avec TIMERANGE
Scan scan = new Scan();
scan.setTimeRange(
    startTime,  // 2024-01-01 00:00:00
    endTime     // 2024-02-01 00:00:00
);
scan.setBatch(1000);
ResultScanner scanner = table.getScanner(scan);
```

#### Équivalent HCD

```cql
-- HCD : Export avec WHERE sur clustering keys
SELECT * FROM operations_by_account
WHERE date_op >= '2024-01-01' AND date_op < '2024-02-01'
ALLOW FILTERING;
```

#### Exemple Concret avec Spark

```python
# Spark : Export incrémental Parquet
from pyspark.sql import SparkSession

spark = SparkSession.builder \
    .appName("ExportIncremental") \
    .config("spark.cassandra.connection.host", "localhost") \
    .getOrCreate()

# Lecture depuis HCD
df = spark.read \
    .format("org.apache.spark.sql.cassandra") \
    .options(
        keyspace="domiramacatops_poc",
        table="operations_by_account"
    ) \
    .load()

# Filtrage par période
df_filtered = df.filter(
    (df.date_op >= "2024-01-01") &
    (df.date_op < "2024-02-01")
)

# Export Parquet
df_filtered.write \
    .mode("overwrite") \
    .parquet("/data/exports/2024-01")
```

#### Diagramme de Flux

```
┌─────────────────┐
│  HCD Table      │
│  operations_by_ │
│  account        │
└────────┬────────┘
         │ WHERE date_op >= '2024-01-01' AND date_op < '2024-02-01'
         ▼
┌─────────────────┐
│  Spark Read     │
│  - Filtrage     │
│  - Transformation│
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│  Parquet Export │
│  /data/exports/  │
│  2024-01/       │
└─────────────────┘
```

---

### UC-07 : Filtrage Colonnes Dynamiques

#### Contexte HBase

```java
// HBase : Filtrage sur colonnes dynamiques
Scan scan = new Scan();
Filter filter = new SingleColumnValueFilter(
    Bytes.toBytes("meta"),
    Bytes.toBytes("source"),
    CompareFilter.CompareOp.EQUAL,
    Bytes.toBytes("batch")
);
scan.setFilter(filter);
```

#### Équivalent HCD

```cql
-- HCD : Filtrage sur MAP avec CONTAINS
SELECT * FROM operations_by_account
WHERE code_si = '01' AND contrat = '5913101072'
  AND meta_flags CONTAINS KEY 'source'
  AND meta_flags['source'] = 'batch';
```

#### Exemple Concret

**Scénario** : Recherche toutes les opérations importées par batch.

**Requête** :

```cql
SELECT date_op, numero_op, libelle, meta_flags
FROM operations_by_account
WHERE code_si = '01' AND contrat = '5913101072'
  AND meta_flags CONTAINS KEY 'source'
  AND meta_flags['source'] = 'batch'
  AND date_op >= '2024-01-01';
```

**Résultat** :

```
date_op           | numero_op | libelle            | meta_flags
------------------+-----------+--------------------+----------------------------------------
2024-01-20 10:00  | 1         | CARREFOUR MARKET   | {'source': 'batch', 'version': '1.0'}
2024-01-18 14:30  | 2         | LECLERC           | {'source': 'batch', 'version': '1.0'}
```

---

### UC-08 : TTL et Purge Automatique

#### Contexte HBase

```java
// HBase : Configuration TTL
HColumnDescriptor columnFamily = new HColumnDescriptor("category");
columnFamily.setTimeToLive(315619200); // 10 ans en secondes
```

#### Équivalent HCD

```cql
-- HCD : Configuration TTL au niveau table
CREATE TABLE operations_by_account (
    ...
) WITH default_time_to_live = 315360000; -- 10 ans en secondes
```

#### Exemple Concret

**Scénario** : Données expirées après 10 ans, purge automatique.

**Insertion avec TTL personnalisé** :

```cql
INSERT INTO operations_by_account (
    code_si, contrat, date_op, numero_op, libelle
) VALUES (
    '01', '5913101072', '2014-01-20 10:00:00', 1, 'TEST'
) USING TTL 315360000; -- 10 ans
```

**Vérification après expiration** :

```cql
-- Après 10 ans + 1 jour
SELECT * FROM operations_by_account
WHERE code_si = '01' AND contrat = '5913101072'
  AND date_op = '2014-01-20 10:00:00';

-- Résultat : Aucune ligne (données expirées et purgées)
```

---

### UC-09 : BLOOMFILTER Équivalent

#### Contexte HBase

```java
// HBase : Configuration BLOOMFILTER
HColumnDescriptor columnFamily = new HColumnDescriptor("category");
columnFamily.setBloomFilterType(BloomType.ROW);
```

#### Équivalent HCD

```cql
-- HCD : Index SAI (déterministe, pas probabiliste)
CREATE CUSTOM INDEX idx_cat_auto_sai ON operations_by_account (cat_auto)
USING 'org.apache.cassandra.index.sai.StorageAttachedIndex';
```

#### Exemple Concret

**Scénario** : Recherche optimisée avec index SAI.

**Sans Index** :

```cql
-- Scan complet (lent)
SELECT * FROM operations_by_account
WHERE code_si = '01' AND contrat = '5913101072'
  AND cat_auto = 'ALIMENTATION';
-- Temps : ~200ms
```

**Avec Index SAI** :

```cql
-- Index lookup (rapide)
SELECT * FROM operations_by_account
WHERE code_si = '01' AND contrat = '5913101072'
  AND cat_auto = 'ALIMENTATION';
-- Temps : ~5ms (40x plus rapide)
```

**Différence** :

- **HBase BLOOMFILTER** : Probabiliste (peut avoir faux positifs)
- **HCD SAI** : Déterministe (résultats exacts, plus performant)

---

### UC-10 : REPLICATION_SCOPE Équivalent

#### Contexte HBase

```java
// HBase : Configuration REPLICATION_SCOPE
HColumnDescriptor columnFamily = new HColumnDescriptor("category");
columnFamily.setScope(1); // Réplication activée
```

#### Équivalent HCD

```cql
-- HCD : NetworkTopologyStrategy (multi-datacenter)
CREATE KEYSPACE domiramacatops_poc
WITH REPLICATION = {
    'class': 'NetworkTopologyStrategy',
    'datacenter1': 3,
    'datacenter2': 3
};
```

#### Exemple Concret

**Scénario** : Réplication multi-datacenter pour haute disponibilité.

**Configuration Production** :

```cql
-- Datacenter Paris
CREATE KEYSPACE domiramaCatOps_prod
WITH REPLICATION = {
    'class': 'NetworkTopologyStrategy',
    'paris': 3,
    'lyon': 3
};
```

**Écriture** :

```cql
-- Écriture avec consistency LOCAL_QUORUM (datacenter local)
INSERT INTO operations_by_account (...) VALUES (...)
USING CONSISTENCY LOCAL_QUORUM;
```

**Lecture** :

```cql
-- Lecture avec consistency LOCAL_QUORUM
SELECT * FROM operations_by_account
WHERE code_si = '01' AND contrat = '5913101072'
USING CONSISTENCY LOCAL_QUORUM;
```

---

## 🎯 PARTIE 2 : USE CASES TABLE `domirama-meta-categories` - EXEMPLES CONCRETS

### UC-11 : Acceptation Client

#### Contexte HBase

```java
// HBase : Acceptation via PUT
Put put = new Put(Bytes.toBytes("01:5913101072:ALIMENTATION"));
put.addColumn(Bytes.toBytes("acceptation"), Bytes.toBytes("accepte"),
              Bytes.toBytes("true"));
put.addColumn(Bytes.toBytes("acceptation"), Bytes.toBytes("date"),
              Bytes.toBytes("2024-01-20T15:30:00"));
table.put(put);
```

#### Équivalent HCD

```cql
-- HCD : Insertion dans table acceptations
INSERT INTO acceptations (
    code_si, contrat, code_categorie, accepte, date_acceptation
) VALUES (
    '01', '5913101072', 'ALIMENTATION', true, '2024-01-20 15:30:00'
);
```

#### Exemple Concret

**Scénario** : Client accepte la catégorie "ALIMENTATION" pour son compte.

**Requête** :

```cql
INSERT INTO acceptations (
    code_si, contrat, code_categorie, accepte, date_acceptation
) VALUES (
    '01', '5913101072', 'ALIMENTATION', true, '2024-01-20 15:30:00'
);
```

**Vérification** :

```cql
SELECT * FROM acceptations
WHERE code_si = '01' AND contrat = '5913101072'
  AND code_categorie = 'ALIMENTATION';

-- Résultat :
-- code_si | contrat     | code_categorie | accepte | date_acceptation
-- --------+-------------+----------------+---------+------------------
-- 01      | 5913101072  | ALIMENTATION   | true    | 2024-01-20 15:30
```

---

### UC-12 : Opposition Catégorisation

#### Contexte HBase

```java
// HBase : Opposition via PUT
Put put = new Put(Bytes.toBytes("01:5913101072:ALIMENTATION"));
put.addColumn(Bytes.toBytes("opposition"), Bytes.toBytes("oppose"),
              Bytes.toBytes("true"));
put.addColumn(Bytes.toBytes("opposition"), Bytes.toBytes("date"),
              Bytes.toBytes("2024-01-20T15:30:00"));
table.put(put);
```

#### Équivalent HCD

```cql
-- HCD : Insertion dans table oppositions
INSERT INTO oppositions (
    code_si, contrat, code_categorie, oppose, date_opposition
) VALUES (
    '01', '5913101072', 'ALIMENTATION', true, '2024-01-20 15:30:00'
);
```

---

### UC-13 : Historique Opposition (VERSIONS)

#### Contexte HBase

```java
// HBase : VERSIONS => '50' pour historique
HColumnDescriptor columnFamily = new HColumnDescriptor("opposition");
columnFamily.setMaxVersions(50);
```

#### Équivalent HCD

```cql
-- HCD : Table d'historique avec TIMEUUID
CREATE TABLE historique_oppositions (
    code_si TEXT,
    contrat TEXT,
    code_categorie TEXT,
    date_opposition TIMEUUID,  -- Clustering key pour historique
    oppose BOOLEAN,
    PRIMARY KEY ((code_si, contrat, code_categorie), date_opposition)
) WITH CLUSTERING ORDER BY (date_opposition DESC);
```

#### Exemple Concret

**Scénario** : Client oppose puis retire l'opposition plusieurs fois.

**Insertion 1** :

```cql
INSERT INTO historique_oppositions (
    code_si, contrat, code_categorie, date_opposition, oppose
) VALUES (
    '01', '5913101072', 'ALIMENTATION', now(), true
);
```

**Insertion 2 (retrait opposition)** :

```cql
INSERT INTO historique_oppositions (
    code_si, contrat, code_categorie, date_opposition, oppose
) VALUES (
    '01', '5913101072', 'ALIMENTATION', now(), false
);
```

**Lecture historique** :

```cql
SELECT date_opposition, oppose
FROM historique_oppositions
WHERE code_si = '01' AND contrat = '5913101072'
  AND code_categorie = 'ALIMENTATION'
ORDER BY date_opposition DESC;

-- Résultat :
-- date_opposition                    | oppose
-- -----------------------------------+--------
-- 2024-01-20 15:35:00.123456+0000   | false
-- 2024-01-20 15:30:00.123456+0000   | true
```

---

### UC-14 : Feedbacks par Libellé (Compteurs)

#### Contexte HBase

```java
// HBase : INCREMENT atomique
Increment increment = new Increment(Bytes.toBytes("CARREFOUR MARKET"));
increment.addColumn(Bytes.toBytes("feedbacks"), Bytes.toBytes("count"), 1);
table.increment(increment);
```

#### Équivalent HCD

```cql
-- HCD : Type counter
UPDATE feedbacks_libelles
SET count = count + 1
WHERE libelle = 'CARREFOUR MARKET';
```

#### Exemple Concret

**Scénario** : Client valide une catégorie, incrément du compteur de feedback.

**Requête** :

```cql
UPDATE feedbacks_libelles
SET count = count + 1
WHERE libelle = 'CARREFOUR MARKET';
```

**Lecture** :

```cql
SELECT libelle, count
FROM feedbacks_libelles
WHERE libelle = 'CARREFOUR MARKET';

-- Résultat :
-- libelle            | count
-- -------------------+-------
-- CARREFOUR MARKET   | 1250
```

---

### UC-15 : Feedbacks par ICS (Compteurs)

#### Contexte HBase

```java
// HBase : INCREMENT atomique par ICS
Increment increment = new Increment(Bytes.toBytes("ALIMENTATION"));
increment.addColumn(Bytes.toBytes("feedbacks"), Bytes.toBytes("count"), 1);
table.increment(increment);
```

#### Équivalent HCD

```cql
-- HCD : Type counter par code catégorie
UPDATE feedbacks_ics
SET count = count + 1
WHERE code_categorie = 'ALIMENTATION';
```

---

### UC-16 : Règles Personnalisées

#### Contexte HBase

```java
// HBase : Stockage règle personnalisée
Put put = new Put(Bytes.toBytes("01:5913101072"));
put.addColumn(Bytes.toBytes("regles"), Bytes.toBytes("CARREFOUR"),
              Bytes.toBytes("RESTAURANT"));
table.put(put);
```

#### Équivalent HCD

```cql
-- HCD : Table règles personnalisées
INSERT INTO regles_personnalisees (
    code_si, contrat, libelle_pattern, code_categorie
) VALUES (
    '01', '5913101072', 'CARREFOUR%', 'RESTAURANT'
);
```

#### Exemple Concret

**Scénario** : Client crée une règle : "Tous les libellés contenant 'CARREFOUR' → catégorie 'RESTAURANT'".

**Insertion règle** :

```cql
INSERT INTO regles_personnalisees (
    code_si, contrat, libelle_pattern, code_categorie, date_creation
) VALUES (
    '01', '5913101072', 'CARREFOUR%', 'RESTAURANT', '2024-01-20 10:00:00'
);
```

**Application règle (batch)** :

```python
# Spark : Application règles personnalisées
rules = spark.read \
    .format("org.apache.spark.sql.cassandra") \
    .options(keyspace="domiramacatops_poc", table="regles_personnalisees") \
    .load()

operations = spark.read \
    .format("org.apache.spark.sql.cassandra") \
    .options(keyspace="domiramacatops_poc", table="operations_by_account") \
    .load()

# Join et application règles
operations_with_rules = operations.join(
    rules,
    (operations.code_si == rules.code_si) &
    (operations.contrat == rules.contrat) &
    (operations.libelle.like(rules.libelle_pattern)),
    "left"
)

# Mise à jour cat_auto si règle trouvée
operations_updated = operations_with_rules.withColumn(
    "cat_auto",
    when(col("code_categorie").isNotNull(), col("code_categorie"))
    .otherwise(col("cat_auto"))
)
```

---

### UC-17 : Décisions Salaires

#### Contexte HBase

```java
// HBase : Stockage décision salaire
Put put = new Put(Bytes.toBytes("SALARY_DECISION:PAYEMENT SALAIRE"));
put.addColumn(Bytes.toBytes("decision"), Bytes.toBytes("methode"),
              Bytes.toBytes("SALAIRE"));
table.put(put);
```

#### Équivalent HCD

```cql
-- HCD : Table décisions salaires
INSERT INTO decisions_salaires (
    libelle, methode_categorisation, active
) VALUES (
    'PAYEMENT SALAIRE', 'SALAIRE', true
);
```

---

### UC-18 : Application Règles Personnalisées (Batch)

Voir UC-16 pour l'exemple complet avec Spark.

---

### UC-19 : Mise à Jour Feedbacks (Temps Réel)

#### Contexte HBase

```java
// HBase : INCREMENT atomique temps réel
Increment increment = new Increment(Bytes.toBytes("CARREFOUR MARKET"));
increment.addColumn(Bytes.toBytes("feedbacks"), Bytes.toBytes("count"), 1);
table.increment(increment);
```

#### Équivalent HCD

```cql
-- HCD : UPDATE counter temps réel
UPDATE feedbacks_libelles
SET count = count + 1
WHERE libelle = 'CARREFOUR MARKET';
```

---

### UC-20 : Cohérence Multi-Tables

#### Exemple Concret

**Scénario** : Vérifier la cohérence entre `operations_by_account` et `feedbacks_libelles`.

**Requête de vérification** :

```cql
-- Compter opérations avec libellé "CARREFOUR MARKET"
SELECT COUNT(*) as count_operations
FROM operations_by_account
WHERE libelle = 'CARREFOUR MARKET';

-- Compter feedbacks pour "CARREFOUR MARKET"
SELECT count as count_feedbacks
FROM feedbacks_libelles
WHERE libelle = 'CARREFOUR MARKET';

-- Vérification : count_feedbacks <= count_operations
```

---

## 🎯 PARTIE 3 : USE CASES ADDITIONNELS - EXEMPLES CONCRETS

### UC-API-01 : Data API REST/GraphQL

#### Exemple REST

```bash
# GET : Recherche opérations
curl -X GET "https://api.hcd.example/v2/keyspaces/domiramacatops_poc/operations_by_account" \
  -H "X-Cassandra-Token: <token>" \
  -G \
  -d "where={\"code_si\":\"01\",\"contrat\":\"5913101072\",\"libelle\":{\"$contains\":\"CARREFOUR\"}}" \
  -d "page-size=10"
```

#### Exemple GraphQL

```graphql
query {
  operations_by_account(
    filter: {
      code_si: {eq: "01"}
      contrat: {eq: "5913101072"}
      libelle: {contains: "CARREFOUR"}
    }
    options: {pageSize: 10, sort: [{date_op: DESC}]}
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
```

---

### UC-STREAM-01 : Kafka + Spark Streaming

#### Exemple Configuration

```python
# Spark Structured Streaming depuis Kafka
from pyspark.sql import SparkSession
from pyspark.sql.functions import *

spark = SparkSession.builder \
    .appName("KafkaStreaming") \
    .config("spark.cassandra.connection.host", "localhost") \
    .getOrCreate()

# Lecture depuis Kafka
df = spark.readStream \
    .format("kafka") \
    .option("kafka.bootstrap.servers", "localhost:9092") \
    .option("subscribe", "operations-realtime") \
    .load()

# Transformation
df_parsed = df.select(
    from_json(col("value").cast("string"), schema).alias("data")
).select("data.*")

# Écriture vers HCD
query = df_parsed.writeStream \
    .format("org.apache.spark.sql.cassandra") \
    .options(
        keyspace="domiramacatops_poc",
        table="operations_by_account"
    ) \
    .option("checkpointLocation", "/checkpoint/kafka-streaming") \
    .start()
```

---

## ✅ CONCLUSION

**✅ Documentation enrichie avec** :

- ✅ Exemples concrets pour chaque use case
- ✅ Équivalences HBase → HCD détaillées avec code
- ✅ Diagrammes de flux pour use cases complexes

**📚 Références** :

- Voir `02_LISTE_DETAIL_DEMONSTRATIONS.md` pour la liste complète
- Voir `18_INDEX_USE_CASES_SCRIPTS.md` pour la navigation

---

**Date** : 2025-01-XX  
**Version** : 1.0
