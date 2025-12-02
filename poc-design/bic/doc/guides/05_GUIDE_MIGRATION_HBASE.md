# 📖 Guide : Migration HBase → HCD pour BIC

**Date** : 2025-12-01  
**Version** : 1.0.0  
**Objectif** : Guide complet de migration de HBase vers HCD pour le use case BIC

---

## 📋 Table des Matières

- [Vue d'Ensemble](#vue-densemble)
- [Équivalences HBase → HCD](#équivalences-hbase--hcd)
- [Patterns de Migration](#patterns-de-migration)
- [Exemples de Code](#exemples-de-code)
- [Checklist de Migration](#checklist-de-migration)

---

## 🎯 Vue d'Ensemble

Ce guide documente toutes les équivalences entre HBase et HCD pour le use case BIC (Base d'Interaction Client), permettant de migrer progressivement les composants existants.

### Contexte HBase

**Table HBase** : `B993O02:bi-client`  
**Clé de ligne** : `code_efs + numero_client + date (yyyyMMdd) + cd_canal + idt_tech`

**Column Families** :

- `A`, `C`, `E`, `M` : Attributs extraits de l'événement
- `VERSIONS=2` : Pour certaines CF (conservation dernière modification)

**Format de stockage** :

- JSON dans une colonne principale
- Colonnes dynamiques "normalisées" extraites du JSON
- Permet filtres via SCAN + Bloomfilter (ROWCOL)

### Contexte HCD

**Table HCD** : `bic_poc.interactions_by_client`

**Clé Primaire** :

- Partition Key : `(code_efs, numero_client)`
- Clustering Key : `(date_interaction, canal, type_interaction, idt_tech)`
- Clustering Order : `DESC` (plus récent en premier)

**Colonnes** :

- `json_data` (text) : Données JSON complètes
- `colonnes_dynamiques` (map<text, text>) : Colonnes dynamiques
- `default_time_to_live = 63072000` : TTL 2 ans

---

## 🔄 Équivalences HBase → HCD

### 1. Écriture Batch (BulkLoad)

#### HBase

```java
// HBase BulkLoad
Configuration conf = HBaseConfiguration.create();
Job job = Job.getInstance(conf, "BICBulkLoad");
job.setJarByClass(BICBulkLoad.class);
job.setMapperClass(BICMapper.class);
job.setReducerClass(BICReducer.class);
job.setOutputFormatClass(HFileOutputFormat.class);
HFileOutputFormat.configureIncrementalLoad(job, table);
```

**Processus** :

1. Génération des HFiles via MapReduce
2. Chargement des HFiles dans HBase (bulkLoad)
3. Compaction des HFiles

#### HCD (Spark)

```scala
// HCD Spark Batch Write
val spark = SparkSession.builder()
  .appName("BICLoaderBatch")
  .config("spark.cassandra.connection.host", "localhost")
  .config("spark.cassandra.connection.port", "9042")
  .getOrCreate()

val interactions = spark.read.parquet("data/interactions.parquet")
interactions.write
  .format("org.apache.spark.sql.cassandra")
  .options(Map("keyspace" -> "bic_poc", "table" -> "interactions_by_client"))
  .mode("append")
  .save()
```

**Avantages** :

- ✅ Plus simple : Pas besoin de générer HFiles
- ✅ Plus rapide : Écriture directe via connecteur
- ✅ Plus flexible : Support de multiples formats (Parquet, JSON, CSV)

---

### 2. Lecture Batch (STARTROW/STOPROW/TIMERANGE)

#### HBase

```java
// HBase SCAN avec STARTROW/STOPROW/TIMERANGE
Scan scan = new Scan();
scan.setStartRow(Bytes.toBytes("EFS001_CLIENT123_20240101"));
scan.setStopRow(Bytes.toBytes("EFS001_CLIENT123_20241231"));
scan.setTimeRange(startTimestamp, endTimestamp);
ResultScanner scanner = table.getScanner(scan);
```

**Équivalent HBase** :

- `STARTROW/STOPROW` : Filtrage par plage de clés de ligne
- `TIMERANGE` : Filtrage par plage temporelle

#### HCD (CQL)

```cql
-- HCD : Filtrage par client et période
SELECT * FROM bic_poc.interactions_by_client
WHERE code_efs = 'EFS001'
  AND numero_client = 'CLIENT123'
  AND date_interaction >= '2024-01-01 00:00:00+0000'
  AND date_interaction < '2024-12-31 23:59:59+0000';
```

**Équivalent HCD** :

- `STARTROW/STOPROW` → `WHERE code_efs = ? AND numero_client = ? AND date_interaction >= ? AND < ?`
- `TIMERANGE` → `WHERE date_interaction >= ? AND < ?`

**Avantages** :

- ✅ Syntaxe SQL standard (CQL)
- ✅ Plus lisible et maintenable
- ✅ Performance optimale avec partition key

---

### 3. Lecture Temps Réel (SCAN + Value Filter)

#### HBase

```java
// HBase SCAN avec filtre valeur
Scan scan = new Scan();
SingleColumnValueFilter filter = new SingleColumnValueFilter(
    Bytes.toBytes("A"),
    Bytes.toBytes("canal"),
    CompareOperator.EQUAL,
    Bytes.toBytes("email")
);
scan.setFilter(filter);
ResultScanner scanner = table.getScanner(scan);
```

**Équivalent HBase** :

- `SCAN + value filter` : Filtrage par valeur de colonne

#### HCD (CQL avec Index SAI)

```cql
-- HCD : Filtrage par canal (index SAI)
SELECT * FROM bic_poc.interactions_by_client
WHERE code_efs = 'EFS001'
  AND numero_client = 'CLIENT123'
  AND canal = 'email';
```

**Index SAI requis** :

```cql
CREATE CUSTOM INDEX idx_interactions_canal ON bic_poc.interactions_by_client (canal)
USING 'StorageAttachedIndex';
```

**Avantages** :

- ✅ Index SAI plus performant que scan global
- ✅ Syntaxe SQL standard
- ✅ Support de filtres multiples simultanés

---

### 4. Colonnes Dynamiques

#### HBase

```java
// HBase : Colonnes dynamiques
Put put = new Put(rowKey);
put.addColumn(Bytes.toBytes("A"), Bytes.toBytes("categorie"), Bytes.toBytes("premium"));
put.addColumn(Bytes.toBytes("A"), Bytes.toBytes("duree_secondes"), Bytes.toBytes("120"));
table.put(put);
```

**Équivalent HBase** :

- Colonnes dynamiques : Ajout de colonnes à la volée
- Pas de schéma fixe

#### HCD (MAP)

```cql
-- HCD : Colonnes dynamiques (MAP)
CREATE TABLE bic_poc.interactions_by_client (
    ...
    colonnes_dynamiques map<text, text>,
    ...
);

-- Insertion
INSERT INTO bic_poc.interactions_by_client (..., colonnes_dynamiques)
VALUES (..., {'categorie': 'premium', 'duree_secondes': '120'});
```

**Avantages** :

- ✅ Type MAP natif Cassandra
- ✅ Plus structuré que colonnes dynamiques HBase
- ✅ Requêtes efficaces sur les clés/valeurs du MAP

---

### 5. TTL (Time-To-Live)

#### HBase

```java
// HBase : TTL par cellule
Put put = new Put(rowKey);
put.addColumn(Bytes.toBytes("A"), Bytes.toBytes("data"), Bytes.toBytes("value"));
put.setTTL(63072000L); // 2 ans en millisecondes
table.put(put);
```

**Équivalent HBase** :

- TTL par cellule ou par famille de colonnes

#### HCD (default_time_to_live)

```cql
-- HCD : TTL au niveau table
CREATE TABLE bic_poc.interactions_by_client (
    ...
) WITH default_time_to_live = 63072000; -- 2 ans en secondes
```

**Avantages** :

- ✅ TTL automatique pour toutes les lignes
- ✅ Plus simple à gérer
- ✅ Pas besoin de définir TTL à chaque insertion

---

### 6. Recherche Full-Text

#### HBase

```java
// HBase : Recherche full-text (scan complet + filtres)
Scan scan = new Scan();
FilterList filters = new FilterList();
filters.addFilter(new SingleColumnValueFilter(...));
filters.addFilter(new ValueFilter(CompareOperator.EQUAL, new SubstringComparator("reclamation")));
scan.setFilter(filters);
ResultScanner scanner = table.getScanner(scan); // Scan complet = lent
```

**Équivalent HBase** :

- Scan complet de la table (lent)
- Filtres sur valeurs

#### HCD (SAI Full-Text avec Lucene)

```cql
-- HCD : Index SAI Full-Text avec analyseurs Lucene
CREATE CUSTOM INDEX idx_interactions_json_data_fulltext ON bic_poc.interactions_by_client (json_data)
USING 'StorageAttachedIndex'
WITH OPTIONS = {
    'index_analyzer': '{
        "tokenizer": {"name": "standard"},
        "filters": [
            {"name": "lowercase"},
            {"name": "asciifolding"},
            {"name": "frenchLightStem"}
        ]
    }'
};

-- Recherche
SELECT * FROM bic_poc.interactions_by_client
WHERE code_efs = 'EFS001'
  AND numero_client = 'CLIENT123'
  AND json_data : 'reclamation';
```

**Avantages** :

- ✅ Index SAI performant (pas de scan complet)
- ✅ Analyseurs linguistiques (français, stemming)
- ✅ Recherche par préfixe, racine, fuzzy

---

## 📝 Patterns de Migration

### Pattern 1 : Migration Progressive

1. **Phase 1** : Créer le schéma HCD en parallèle de HBase
2. **Phase 2** : Ingestion double (HBase + HCD) pour validation
3. **Phase 3** : Migration des lectures progressivement
4. **Phase 4** : Arrêt de l'écriture HBase, uniquement HCD

### Pattern 2 : Migration par Composant

1. **Composant Batch** : Migrer `bic-batch-main.tar.gz` → Spark batch write
2. **Composant Temps Réel** : Migrer `bic-event` Kafka → Spark Streaming
3. **Composant Export** : Migrer `bic-unload-main.tar.gz` → Spark export ORC
4. **Composant API** : Migrer API HBase → Data API REST/GraphQL

---

## 💻 Exemples de Code

### Exemple 1 : Migration BulkLoad → Spark Batch

**Avant (HBase)** :

```java
// MapReduce BulkLoad
Job job = Job.getInstance(conf, "BICBulkLoad");
HFileOutputFormat.configureIncrementalLoad(job, table);
```

**Après (HCD)** :

```scala
// Spark Batch Write
val interactions = spark.read.parquet("data/interactions.parquet")
interactions.write
  .format("org.apache.spark.sql.cassandra")
  .options(Map("keyspace" -> "bic_poc", "table" -> "interactions_by_client"))
  .mode("append")
  .save()
```

### Exemple 2 : Migration SCAN → SELECT

**Avant (HBase)** :

```java
Scan scan = new Scan();
scan.setStartRow(Bytes.toBytes("EFS001_CLIENT123_20240101"));
scan.setStopRow(Bytes.toBytes("EFS001_CLIENT123_20241231"));
ResultScanner scanner = table.getScanner(scan);
```

**Après (HCD)** :

```cql
SELECT * FROM bic_poc.interactions_by_client
WHERE code_efs = 'EFS001'
  AND numero_client = 'CLIENT123'
  AND date_interaction >= '2024-01-01 00:00:00+0000'
  AND date_interaction < '2024-12-31 23:59:59+0000';
```

### Exemple 3 : Migration Filtres → Index SAI

**Avant (HBase)** :

```java
SingleColumnValueFilter filter = new SingleColumnValueFilter(
    Bytes.toBytes("A"),
    Bytes.toBytes("canal"),
    CompareOperator.EQUAL,
    Bytes.toBytes("email")
);
scan.setFilter(filter);
```

**Après (HCD)** :

```cql
-- Index SAI
CREATE CUSTOM INDEX idx_interactions_canal ON bic_poc.interactions_by_client (canal)
USING 'StorageAttachedIndex';

-- Requête
SELECT * FROM bic_poc.interactions_by_client
WHERE code_efs = 'EFS001'
  AND numero_client = 'CLIENT123'
  AND canal = 'email';
```

---

## ✅ Checklist de Migration

### Phase 1 : Préparation

- [ ] Analyser le schéma HBase existant
- [ ] Identifier toutes les requêtes HBase utilisées
- [ ] Créer le schéma HCD équivalent
- [ ] Créer les index SAI nécessaires
- [ ] Valider le schéma avec données de test

### Phase 2 : Migration des Écritures

- [ ] Migrer bulkLoad → Spark batch write
- [ ] Migrer écritures temps réel → Spark Streaming
- [ ] Valider l'intégrité des données (HBase vs HCD)
- [ ] Comparer les performances

### Phase 3 : Migration des Lectures

- [ ] Migrer SCAN → SELECT CQL
- [ ] Migrer filtres → Index SAI
- [ ] Migrer recherche full-text → SAI Lucene
- [ ] Valider les résultats (HBase vs HCD)

### Phase 4 : Migration des Exports

- [ ] Migrer export batch → Spark export ORC
- [ ] Valider l'équivalence STARTROW/STOPROW/TIMERANGE
- [ ] Comparer les performances d'export

### Phase 5 : Validation et Production

- [ ] Tests de charge et performance
- [ ] Validation de la cohérence des données
- [ ] Migration progressive en production
- [ ] Monitoring et alertes

---

## 📚 Ressources

- **Scripts de démonstration** : `scripts/08_load_interactions_batch.sh`, `scripts/14_test_export_batch.sh`
- **Documentation HCD** : [DataStax Documentation](https://docs.datastax.com/)
- **Guide SAI** : `doc/design/03_METHODOLOGIE_VALIDATION.md`

---

**Date** : 2025-12-01  
**Version** : 1.0.0
