# 🎯 POC - Table Domirama : Approche Détaillée

**Date** : 2025-11-25  
**Table HBase** : `B997X04:domirama`  
**Objectif POC** : Démontrer la migration vers HCD avec remplacement de Solr par SAI

---

## 📊 Analyse de l'Existant HBase

### Structure Actuelle

**Table HBase** :
- **Namespace** : `B997X04`
- **Table** : `domirama`
- **Column Families** :
  - `data` : Données métier (BLOOMFILTER => 'NONE', REPLICATION_SCOPE => '1')
  - `meta` : Métadonnées (BLOOMFILTER => 'NONE', VERSIONS => '2', REPLICATION_SCOPE => '1')

### Key Design HBase

**Clé composite** :
```
RowKey = code_SI + numéro_contrat + binaire(numéro_opération + date)
```

**Composants** :
- `code_SI` : Code de l'entité organisationnelle (ex: "01")
- `numéro_contrat` : Identification du compte client (ex: "1234567890")
- `binaire` : Combinaison numéro d'opération + date pour tri antichronologique

**Objectif** : Toutes les opérations d'un même compte sont contiguës et triées du plus récent au plus ancien.

### Format de Stockage

**Données COBOL encodées Base64** :
- Chaque opération est stockée avec un `column qualifier` par type de copy
- Plusieurs copies peuvent exister pour une même opération (différentes vues/segments du record COBOL)
- Format compact mais nécessite décodage pour utilisation

### Opérations HBase

**Écriture** :
1. Préparation des données issues de la tenue de solde en **PIG**
2. Écriture HBase dans un programme **MapReduce**
3. Passage des opérations directement par **API HBase** dans la phase reduce

**Lecture** :
1. **SCAN** sur l'historique du client lors de sa connexion
2. Construction d'un **index Solr in-memory** pour la recherche
3. **MultiGet** des clés ramenées par l'index Solr pour affichage

**Problème actuel** : Le SCAN complet des 10 ans d'historique à chaque connexion est coûteux.

### Fonctionnalités HBase Utilisées

✅ **TTL** : Purge automatique des données anciennes  
❌ **Temporalité des cellules** : Non utilisée  
✅ **Bloom filters** : Sur les Column Families  
✅ **Versions** : 2 versions pour la CF `meta`

### Remarques Importantes

- **Réplica Elasticsearch** : Disponible avec 13 mois de profondeur pour transactionAPI
- **Projet TAILS** : Refonte à l'étude
- **Opportunité** : Les capacités de search full-text de DataStax (SAI) pourraient être un plus

---

## 🎯 Objectifs du POC Domirama

### Objectifs Principaux

1. ✅ **Démontrer la migration du schéma** HBase → HCD
2. ✅ **Remplacer Solr par SAI** pour la recherche full-text
3. ✅ **Conserver le TTL** pour la purge automatique
4. ✅ **Simplifier l'ingestion** : PIG/MapReduce → Spark
5. ✅ **Améliorer les performances** : Pas de scan complet au login
6. ✅ **Décoder les données COBOL** : Normaliser en colonnes typées

### Objectifs Secondaires

- Démontrer la recherche vectorielle (optionnel, pour futur)
- Tester la Data API pour l'exposition
- Valider les performances avec données réalistes

---

## 📐 Schéma CQL Proposé pour HCD

### Table Principale : `operations_by_account`

```cql
CREATE KEYSPACE IF NOT EXISTS domirama_poc
WITH REPLICATION = {
  'class': 'SimpleStrategy',
  'replication_factor': 1
};

CREATE TABLE domirama_poc.operations_by_account (
    -- Partition Key (regroupe toutes les opérations d'un compte)
    code_si           TEXT,
    contrat           TEXT,
    
    -- Clustering Keys (tri antichronologique)
    op_date           TIMESTAMP,
    op_seq            INT,
    
    -- Identifiant unique
    op_id             UUID,
    
    -- Données décodées du COBOL (colonnes normalisées)
    libelle           TEXT,
    montant           DECIMAL,
    devise            TEXT,
    date_valeur       TIMESTAMP,
    type_operation    TEXT,
    sens_operation    TEXT,  -- DEBIT ou CREDIT
    
    -- Données brutes COBOL (si nécessaire pour compatibilité)
    cobol_data_base64 TEXT,  -- Données COBOL encodées Base64
    copy_type         TEXT,   -- Type de copy (si plusieurs copies)
    
    -- Métadonnées (ancienne CF 'meta')
    meta_flags        MAP<TEXT, TEXT>,  -- Métadonnées diverses
    
    -- Catégorisation (intégration future)
    cat_auto          TEXT,   -- Catégorie automatique
    cat_user          TEXT,   -- Catégorie modifiée par client
    
    PRIMARY KEY ((code_si, contrat), op_date, op_seq)
) WITH CLUSTERING ORDER BY (op_date DESC, op_seq ASC)
  AND default_time_to_live = 315360000;  -- TTL 10 ans (en secondes)
```

### Justification du Schéma

**Partition Key** : `(code_si, contrat)`
- ✅ Toutes les opérations d'un compte sont sur la même partition
- ✅ Distribution uniforme sur le cluster
- ✅ Lecture efficace de l'historique complet d'un client

**Clustering Keys** : `(op_date, op_seq)`
- ✅ Tri antichronologique (DESC) : opérations récentes en premier
- ✅ `op_seq` garantit l'unicité si plusieurs opérations à la même date
- ✅ Permet des requêtes par plage de dates efficaces

**Colonnes normalisées** :
- ✅ `libelle`, `montant`, `devise` : Champs fréquemment utilisés, indexables
- ✅ `cobol_data_base64` : Conservation des données brutes si nécessaire
- ✅ `meta_flags` : MAP pour métadonnées flexibles (remplace CF 'meta')

**TTL** :
- ✅ `default_time_to_live = 315360000` (10 ans) : Purge automatique comme HBase

---

## 🔍 Indexation SAI (Remplacement de Solr)

### Index Full-Text sur Libellé

```cql
-- Index SAI avec analyzer Lucene pour recherche full-text
CREATE CUSTOM INDEX idx_libelle_fulltext 
ON domirama_poc.operations_by_account(libelle)
USING 'org.apache.cassandra.index.sai.StorageAttachedIndex'
WITH OPTIONS = {
  'index_analyzer': '{
    "tokenizer": {"name": "standard"},
    "filters": [
      {"name": "lowercase"},
      {"name": "french"},
      {"name": "asciifolding"}
    ]
  }'
};
```

**Avantages vs Solr** :
- ✅ Index **persistant** (pas de reconstruction à chaque connexion)
- ✅ Recherche **distribuée** sur le cluster
- ✅ **Pas de scan complet** nécessaire au login
- ✅ **Mise à jour en temps réel** lors des écritures

### Index sur Catégorie (Optionnel)

```cql
-- Index pour filtrage par catégorie
CREATE CUSTOM INDEX idx_cat_auto 
ON domirama_poc.operations_by_account(cat_auto)
USING 'StorageAttachedIndex';
```

### Index sur Montant (Optionnel)

```cql
-- Index pour recherche par montant (range queries)
CREATE CUSTOM INDEX idx_montant 
ON domirama_poc.operations_by_account(montant)
USING 'StorageAttachedIndex';
```

### Requêtes Full-Text avec SAI

```cql
-- Recherche simple par terme (remplace Solr)
SELECT * FROM domirama_poc.operations_by_account
WHERE code_si = '01' 
  AND contrat = '1234567890'
  AND libelle : 'loyer';

-- Recherche combinée (AND)
SELECT * FROM domirama_poc.operations_by_account
WHERE code_si = '01' 
  AND contrat = '1234567890'
  AND libelle : 'loyer' 
  AND libelle : 'janvier';

-- Recherche avec filtre par montant
SELECT * FROM domirama_poc.operations_by_account
WHERE code_si = '01' 
  AND contrat = '1234567890'
  AND libelle : 'loyer'
  AND montant > 500;
```

**Comparaison avec HBase** :
- ❌ **HBase** : SCAN complet → Index Solr en mémoire → MultiGet
- ✅ **HCD** : Requête CQL directe avec index SAI → Résultats immédiats

---

## 🔄 Migration des Données

### Stratégie de Migration

**Phase 1 : Extraction HBase**
- Utiliser **Spark** pour lire HBase via Hadoop InputFormat
- Parser la rowkey binaire pour extraire code_SI, contrat, op_date, op_seq
- Décoder les données COBOL Base64

**Phase 2 : Transformation**
- Normaliser les données COBOL en colonnes typées
- Extraire libelle, montant, devise, etc.
- Conserver les données brutes en Base64 si nécessaire

**Phase 3 : Chargement HCD**
- Utiliser **Spark Cassandra Connector** pour écriture parallèle
- Ou **DSBulk** pour chargement massif

### Code Spark pour Migration

```scala
import org.apache.spark.sql.{SparkSession, DataFrame}
import com.datastax.spark.connector._

object DomiramaMigrationSpark {
  
  def main(args: Array[String]): Unit = {
    val spark = SparkSession.builder()
      .appName("DomiramaHBaseToHCD")
      .master("local[*]")
      .config("spark.cassandra.connection.host", "localhost")
      .config("spark.cassandra.connection.port", "9042")
      .getOrCreate()
    
    import spark.implicits._
    
    // 1. Lire depuis HBase
    val hbaseDF = spark.read
      .format("org.apache.hadoop.hbase.spark")
      .option("hbase.table.name", "B997X04:domirama")
      .option("hbase.columns.mapping", 
        "code_si:key, data:libelle, data:montant, data:devise")
      .load()
    
    // 2. Transformer (parser rowkey, décoder COBOL)
    val transformedDF = hbaseDF.map { row =>
      val rowkey = row.getAs[Array[Byte]]("code_si")
      // Parser rowkey binaire...
      // Décoder COBOL Base64...
      // Créer Operation...
    }
    
    // 3. Écrire dans HCD
    transformedDF.write
      .format("org.apache.spark.sql.cassandra")
      .options(Map(
        "keyspace" -> "domirama_poc",
        "table" -> "operations_by_account"
      ))
      .mode("append")
      .save()
    
    spark.stop()
  }
}
```

---

## 📝 Code POC : Ingestion Spark → HCD

### POC1 : CSV → Spark → HCD (Sans jars client)

**Objectif** : Démontrer le pipeline complet avec données simulées

**Fichier CSV de test** :
```csv
code_si,contrat,date_iso,seq,libelle,montant,devise
01,1234567890,2024-01-05T10:15:00Z,1,LOYER JANVIER,-800.00,EUR
01,1234567890,2024-02-05T10:15:00Z,2,LOYER FEVRIER,-800.00,EUR
01,1234567890,2024-03-05T10:15:00Z,3,LOYER MARS,-800.00,EUR
```

**Code Spark** :
```scala
// Voir: inputs-ibm/PROPOSITION_MECE_MIGRATION_HBASE_HCD.md (lignes 1126-1193)
// DomiramaSparkLoaderCsv.scala
```

### POC2 : SequenceFile → Spark → HCD (Avec jars client)

**Objectif** : Utiliser les vrais décoders Arkéa (Y7XDOMIOperationDecoder)

**Code Spark** :
```scala
// Voir: inputs-ibm/PROPOSITION_MECE_MIGRATION_HBASE_HCD.md (lignes 1405-1523)
// DomiramaSparkLoaderSeq.scala
```

---

## 🔍 Code POC : Recherche Full-Text avec SAI

### Remplacement de Solr par SAI

**Ancien workflow HBase** :
```scala
// 1. SCAN complet (coûteux)
val scan = new Scan()
scan.setStartRow(...)
scan.setStopRow(...)
val scanner = table.getScanner(scan)

// 2. Construire index Solr en mémoire
val solrIndex = buildSolrIndex(scanner)

// 3. Rechercher dans Solr
val results = solrIndex.search("loyer")

// 4. MultiGet des clés
val gets = results.map(key => new Get(key))
val operations = table.get(gets)
```

**Nouveau workflow HCD** :
```scala
// 1. Requête CQL directe avec index SAI (efficace)
val query = s"""
  SELECT * FROM domirama_poc.operations_by_account
  WHERE code_si = ? AND contrat = ?
    AND libelle : ?
"""
val prepared = session.prepare(query)
val results = session.execute(prepared.bind("01", "1234567890", "loyer"))

// 2. Résultats directement utilisables (pas de MultiGet)
results.all().forEach { row =>
  val libelle = row.getString("libelle")
  val montant = row.getDecimal("montant")
  // ...
}
```

**Avantages** :
- ✅ **Pas de scan complet** : Index SAI localise directement les partitions
- ✅ **Pas d'index en mémoire** : Index persistant dans HCD
- ✅ **Temps de réponse constant** : Pas de délai de construction d'index
- ✅ **Mise à jour temps réel** : Index mis à jour automatiquement

---

## 🧪 Scénarios de Test POC

### Test 1 : Ingestion de Données

**Objectif** : Valider l'écriture dans HCD

```bash
# 1. Créer le schéma
cqlsh -f create_domirama_schema.cql localhost 9042

# 2. Lancer l'ingestion Spark
spark-submit \
  --class com.arkea.domirama.loader.DomiramaSparkLoaderCsv \
  --packages com.datastax.spark:spark-cassandra-connector_2.12:3.5.0 \
  domirama-spark-poc.jar \
  data/operations.csv

# 3. Vérifier dans HCD
cqlsh localhost 9042
USE domirama_poc;
SELECT COUNT(*) FROM operations_by_account;
SELECT * FROM operations_by_account WHERE code_si='01' AND contrat='1234567890' LIMIT 10;
```

### Test 2 : Recherche Full-Text

**Objectif** : Valider la recherche avec SAI (remplacement Solr)

```bash
# 1. Créer l'index SAI
cqlsh localhost 9042
USE domirama_poc;
CREATE CUSTOM INDEX idx_libelle_fulltext 
ON operations_by_account(libelle)
USING 'org.apache.cassandra.index.sai.StorageAttachedIndex'
WITH OPTIONS = {
  'index_analyzer': '{
    "tokenizer": {"name": "standard"},
    "filters": [{"name": "lowercase"}, {"name": "french"}]
  }'
};

# 2. Tester la recherche
SELECT * FROM operations_by_account
WHERE code_si = '01' 
  AND contrat = '1234567890'
  AND libelle : 'loyer';
```

### Test 3 : Performance (Comparaison HBase vs HCD)

**Objectif** : Mesurer l'amélioration de performance

**Métriques à comparer** :
- ⏱️ **Temps de connexion client** : HBase (scan + Solr) vs HCD (requête directe)
- ⏱️ **Temps de recherche** : HBase (Solr in-memory) vs HCD (SAI)
- 📊 **Charge système** : CPU, mémoire, I/O
- 🔢 **Latence** : P50, P95, P99

**Script de test** :
```scala
// Test de performance
val startTime = System.currentTimeMillis()
val results = session.execute(query)
val duration = System.currentTimeMillis() - startTime
println(s"Recherche terminée en ${duration}ms")
```

### Test 4 : TTL et Purge Automatique

**Objectif** : Valider la purge automatique après 10 ans

```cql
-- Insérer une opération avec TTL explicite (pour test)
INSERT INTO operations_by_account 
(code_si, contrat, op_date, op_seq, libelle, montant)
VALUES ('01', '1234567890', '2014-01-01', 1, 'TEST OLD', 100.00)
USING TTL 60;  -- Expire dans 60 secondes (pour test rapide)

-- Attendre 60 secondes...

-- Vérifier que l'opération a expiré
SELECT * FROM operations_by_account 
WHERE code_si = '01' AND contrat = '1234567890';
-- Résultat : aucune ligne (purge automatique)
```

---

## 📊 Données de Test Réalistes

### Structure des Données Simulées

**Basé sur l'analyse des inputs-clients** :
- Code SI : "01" (entité principale)
- Contrats : Numéros de compte réalistes (10 chiffres)
- Opérations : Types variés (loyers, salaires, achats, virements)
- Dates : Sur 10 ans (2014-2024)
- Libellés : Format réaliste (ex: "LOYER JANVIER", "CB CARREFOUR", etc.)

### Génération de Données

```scala
object GenerateDomiramaTestData {
  
  def generateOperations(count: Int): List[Operation] = {
    val operations = List(
      "LOYER JANVIER", "LOYER FEVRIER", "LOYER MARS",
      "SALAIRE", "CB CARREFOUR", "CB AMAZON",
      "VIREMENT SEPA", "PRELEVEMENT EDF", "CHEQUE"
    )
    
    (1 to count).map { i =>
      val date = LocalDate.now().minusMonths(i % 120)
      Operation(
        codeSi = "01",
        contrat = s"${1000000000L + (i % 1000)}",
        opDate = Timestamp.valueOf(date.atStartOfDay()),
        opSeq = i,
        libelle = operations(i % operations.length),
        montant = BigDecimal(-50.0 - (i % 1000)),
        devise = "EUR"
      )
    }.toList
  }
}
```

---

## 🎯 Résultats Attendus du POC

### Fonctionnalités Démontrées

1. ✅ **Migration du schéma** : HBase → HCD réussie
2. ✅ **Ingestion Spark** : CSV/SequenceFile → HCD fonctionnel
3. ✅ **Recherche full-text** : SAI remplace Solr avec succès
4. ✅ **Performance améliorée** : Pas de scan complet au login
5. ✅ **TTL fonctionnel** : Purge automatique validée

### Métriques de Succès

- ⏱️ **Temps de recherche** : < 100ms (vs plusieurs secondes avec Solr)
- 📊 **Charge système** : Réduction de 70% au login
- ✅ **Fonctionnalités** : 100% des fonctionnalités HBase reproduites
- 🚀 **Scalabilité** : Test avec 1M+ opérations

---

## 📝 Prochaines Étapes

### Après Validation du POC

1. **POC Catégorisation** : Intégrer la catégorisation des opérations
2. **POC Vector Search** : Tester la recherche vectorielle (optionnel)
3. **POC Data API** : Exposer via REST/GraphQL
4. **POC Performance** : Tests de charge avec données production-like

---

## 📁 Fichiers du POC

### Schéma et Configuration

- **`create_domirama_schema.cql`** : Schéma CQL complet avec index SAI
- **`07_setup_domirama_poc.sh`** : Script de configuration automatique

### Données et Code

- **`data/operations_sample.csv`** : Données de test réalistes (14 opérations)
- **`domirama_loader_csv.scala`** : Code Spark pour ingestion CSV → HCD
- **`domirama_search_test.cql`** : Tests de recherche full-text avec SAI

### Utilisation

```bash
# 1. Configurer le schéma
./07_setup_domirama_poc.sh

# 2. Charger les données
spark-submit \
  --class DomiramaLoaderCsv \
  --packages com.datastax.spark:spark-cassandra-connector_2.12:3.5.0 \
  domirama_loader_csv.scala \
  data/operations_sample.csv

# 3. Tester la recherche
cqlsh localhost 9042 -f domirama_search_test.cql
```

---

## 🔗 Références

- **Documentation HCD** : `docs/REFERENCE_HCD_DOCUMENTATION.md`
- **Proposition IBM** : `inputs-ibm/PROPOSITION_MECE_MIGRATION_HBASE_HCD.md`
- **Analyse HBase** : `docs/ANALYSE_ETAT_ART_HBASE.md`
- **Code POC** : Voir section POC dans la proposition IBM

---

**Approche détaillée pour le POC Domirama complétée !** ✅

