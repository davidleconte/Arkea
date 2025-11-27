# 📊 POC Domirama - Migration HBase → HCD

**Date** : 2025-11-25  
**Table HBase** : `B997X04:domirama`  
**Objectif** : Démontrer la migration vers HCD avec remplacement de Solr par SAI

---

## 📁 Contenu du Répertoire

### Schéma et Configuration

- **`create_domirama_schema.cql`** : Schéma CQL complet avec index SAI
  - Keyspace : `domirama_poc`
  - Table : `operations_by_account`
  - Index SAI : Full-text sur libellé, catégorie, montant
  - TTL : 10 ans (315360000 secondes)

- **`07_setup_domirama_poc.sh`** : Script de configuration automatique
  - Crée le keyspace et la table
  - Crée les index SAI
  - Vérifie la configuration

### Données et Code

- **`data/operations_sample.csv`** : Données de test réalistes
  - 14 opérations de test
  - Format : code_si, contrat, date, libellé, montant, etc.

- **`domirama_loader_csv.scala`** : Code Spark pour ingestion CSV → HCD
  - Remplace : PIG → MapReduce → HBase
  - Utilise : Spark → Spark Cassandra Connector → HCD

- **`domirama_search_test.cql`** : Tests de recherche full-text avec SAI
  - 10 scénarios de test
  - Recherche simple, combinée, avec filtres
  - Remplacement de Solr par SAI

---

## 📚 Documentation

- **`FLUX_COMPLET_POC.md`** : Documentation complète du flux d'exécution avec comparaison HBase vs HCD
- **`ORDRE_EXECUTION.md`** : Guide d'exécution séquentielle des scripts

---

## 🚀 Utilisation

### Ordre d'Exécution des Scripts

Les scripts sont numérotés dans l'ordre d'exécution :

1. **`07_setup_domirama_poc.sh`** : Configuration du schéma HCD
   ```bash
   cd /Users/david.leconte/Documents/Arkea
   ./poc-design/domirama/07_setup_domirama_poc.sh
   ```

2. **`08_load_domirama_data.sh`** : Chargement des données CSV dans HCD
   ```bash
   cd /Users/david.leconte/Documents/Arkea
   ./poc-design/domirama/08_load_domirama_data.sh
   ```

3. **`09_test_domirama_search.sh`** : Tests de recherche full-text avec SAI
   ```bash
   cd /Users/david.leconte/Documents/Arkea
   ./poc-design/domirama/09_test_domirama_search.sh
   ```

### Fichiers de Support

- **`create_domirama_schema.cql`** : Schéma CQL (utilisé par script 07)
- **`domirama_loader_csv.scala`** : Code Spark (utilisé par script 08)
- **`domirama_search_test.cql`** : Tests CQL (utilisé par script 09)
- **`data/operations_sample.csv`** : Données de test

---

## 📊 Schéma de Données

### Table `operations_by_account`

**Partition Key** : `(code_si, contrat)`
- Toutes les opérations d'un compte sont sur la même partition
- Distribution uniforme sur le cluster

**Clustering Keys** : `(op_date DESC, op_seq ASC)`
- Tri antichronologique : opérations récentes en premier
- `op_seq` garantit l'unicité

**Colonnes principales** :
- `libelle` : Libellé de l'opération (indexé SAI full-text)
- `montant` : Montant (indexé SAI pour range queries)
- `cat_auto` : Catégorie automatique (indexé SAI)
- `cobol_data_base64` : Données COBOL brutes (si nécessaire)

**TTL** : 10 ans (315360000 secondes)

---

## 🔍 Indexation SAI

### Index Full-Text sur Libellé

```cql
CREATE CUSTOM INDEX idx_libelle_fulltext 
ON operations_by_account(libelle)
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
- ✅ Index persistant (pas de reconstruction à chaque connexion)
- ✅ Recherche distribuée sur le cluster
- ✅ Pas de scan complet nécessaire
- ✅ Mise à jour en temps réel

### Requête Full-Text

```cql
SELECT * FROM domirama_poc.operations_by_account
WHERE code_si = '01' 
  AND contrat = '1234567890'
  AND libelle : 'loyer';
```

---

## 📝 Comparaison HBase vs HCD

| Aspect | HBase | HCD |
|--------|-------|-----|
| **Recherche** | SCAN → Solr in-memory → MultiGet | Requête CQL directe avec SAI |
| **Index** | Solr temporaire (reconstruit à chaque connexion) | SAI persistant (mis à jour automatiquement) |
| **Performance login** | Coûteux (scan 10 ans) | Rapide (requête ciblée) |
| **Ingestion** | PIG → MapReduce → HBase | Spark → HCD |
| **TTL** | ✅ Supporté | ✅ Supporté (identique) |

---

## 🎯 Objectifs du POC

✅ **Migration du schéma** HBase → HCD  
✅ **Remplacement Solr par SAI** pour la recherche full-text  
✅ **Conservation du TTL** pour la purge automatique  
✅ **Simplification de l'ingestion** : PIG/MapReduce → Spark  
✅ **Amélioration des performances** : Pas de scan complet au login  
✅ **Décodage des données COBOL** : Normalisation en colonnes typées

---

## 📚 Documentation

- **Approche détaillée** : `docs/POC_TABLE_DOMIRAMA.md`
- **Documentation HCD** : `docs/REFERENCE_HCD_DOCUMENTATION.md`
- **Proposition IBM** : `inputs-ibm/PROPOSITION_MECE_MIGRATION_HBASE_HCD.md`

---

**POC Domirama prêt à être exécuté !** ✅

