# 📊 Résumé Exécutif : POC DomiramaCatOps

**Date** : 2024-11-27
**Projet** : Catégorisation des Opérations
**Table HBase** : `B997X04:domirama` (Column Family `category`)
**Objectif** : Déterminer le POC à faire pour démontrer la migration HBase → HCD

---

## 🎯 Objectif Principal

Démontrer que la migration de la table `B997X04:domirama` (Column Family `category`) de HBase vers DataStax HCD est **techniquement faisable** et **fonctionnellement équivalente**, en suivant la même méthodologie que le POC Domirama2.

---

## 📋 Périmètre du POC

### Table Cible

**HBase** :

- Table : `B997X04:domirama`
- Column Family : `category`
- Configuration :
  - BLOOMFILTER : `ROWCOL`
  - TTL : `315619200` secondes (≈ 10 ans)
  - REPLICATION_SCOPE : `1`

**HCD** :

- Keyspace : `domiramacatops_poc`
- Table : `operations_by_account` (extension de Domirama2 ou table séparée)
- Colonnes de catégorisation : `cat_auto`, `cat_confidence`, `cat_user`, `cat_date_user`, `cat_validee`

---

## 🔍 Ce qu'il faut Démontrer (MECE)

### 1. Configuration et Schéma ✅

- Keyspace et table créés
- Colonnes de catégorisation ajoutées
- Key design conforme (code_si + contrat, date_op DESC, numero_op ASC)
- TTL configuré (10 ans)

### 2. Format de Stockage ✅

- Données Thrift binaires stockées en BLOB
- Colonnes dynamiques avec MAP<TEXT, TEXT>
- Filtrage sur colonnes dynamiques

### 3. Opérations d'Écriture ✅

- **Batch** : Spark (remplacement MapReduce bulkLoad)
  - Timestamp constant pour batch
- **Temps réel** : Data API / CQL (remplacement API PUT)
  - Timestamp réel pour client
  - Stratégie multi-version (pas d'écrasement)

### 4. Opérations de Lecture ✅

- **Temps réel** : SELECT + SAI (remplacement SCAN + value filter)
  - Recherche par catégorie
  - Filtrage sur colonnes dynamiques
- **Batch** : Export incrémental Parquet (remplacement ORC)
  - Fenêtre glissante (TIMERANGE)
  - Délimitation par clé (STARTROW/STOPROW équivalent)

### 5. Fonctionnalités Spécifiques ✅

- **TTL** : Purge automatique après 10 ans
- **Temporalité** : Multi-version (colonnes séparées batch/client)
- **BLOOMFILTER** : Équivalent avec index SAI
- **REPLICATION_SCOPE** : NetworkTopologyStrategy

---

## 📊 Plan d'Action

### Phase 1 : Setup (2 scripts)

1. `01_setup_domiramacatops_poc.sh` : Création keyspace/table
2. `02_create_category_indexes.sh` : Création index SAI

### Phase 2 : Ingestion (2 scripts)

3. `03_load_category_data_batch.sh` : Chargement batch (Spark)
4. `04_load_category_data_realtime.sh` : Chargement temps réel (Data API/CQL)

### Phase 3 : Lecture (3 scripts)

5. `05_test_category_search.sh` : Recherche par catégorie
6. `06_test_dynamic_columns.sh` : Filtrage colonnes dynamiques
7. `07_test_incremental_export.sh` : Export incrémental Parquet

### Phase 4 : Fonctionnalités (4 scripts)

8. `08_demo_ttl.sh` : Démonstration TTL
9. `09_demo_multi_version.sh` : Démonstration multi-version
10. `10_demo_bloomfilter_equivalent.sh` : Équivalent BLOOMFILTER
11. `11_demo_replication_scope.sh` : Réplication

### Phase 5 : Migration (1 script)

12. `12_migrate_hbase_to_hcd.sh` : Migration complète

**Total** : **12 scripts** à créer et exécuter

---

## 🎯 Critères de Succès

### Fonctionnels

- ✅ 100% des fonctionnalités HBase couvertes
- ✅ Toutes les opérations (écriture/lecture) fonctionnelles
- ✅ Performance équivalente ou meilleure

### Techniques

- ✅ Schémas CQL documentés
- ✅ Scripts commentés et didactiques
- ✅ Rapports de démonstration auto-générés

### Qualité

- ✅ Tests validés
- ✅ Documentation complète
- ✅ Guide de migration

---

## ⚠️ Défis Identifiés

### Techniques

1. **Intégration avec Domirama2** :
   - Choix : Extension de table ou table séparée ?
   - **Décision POC** : Extension (simplicité)

2. **Migration Thrift Binaire** :
   - Préservation de l'intégrité
   - **Solution** : Extraction directe BLOB

3. **Stratégie Multi-Version** :
   - HBase utilise versions de cellules
   - HCD n'a pas de versions automatiques
   - **Solution** : Colonnes séparées + logique applicative

### Fonctionnels

1. **Compatibilité API** :
   - Migration de l'API HBase vers Data API / CQL
   - **Solution** : Adapter l'API existante

2. **Performance** :
   - Garantir performances équivalentes
   - **Solution** : Index SAI optimisés + benchmarking

---

## 📈 Statut Actuel

**Phase** : 📝 **Analyse et Planification**

- ✅ Analyse MECE complète
- ✅ Structure du projet créée
- ✅ Plan d'action défini
- ⏳ Schémas CQL à créer
- ⏳ Scripts à créer
- ⏳ Exécution et validation

---

## 🔗 Références

- **Domirama2** : POC de référence (même méthodologie)
- **Inputs-Clients** : "Etat de l'art HBase chez Arkéa.pdf"
- **Inputs-IBM** : PROPOSITION_MECE_MIGRATION_HBASE_HCD.md

---

**Date** : 2024-11-27
**Version** : 1.0
