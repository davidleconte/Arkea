# 📊 Analyse POC : Migration HBase → HCD - Projet Catégorisation des Opérations

**Date** : 2024-11-27  
**Projet** : Catégorisation des Opérations (DomiramaCatOps)  
**Tables HBase Sources** : 
  - `B997X04:domirama` (Column Family `category`)
  - `B997X04:domirama-meta-categories`
**Objectif** : Déterminer le POC à faire pour démontrer que la migration de HBase vers DataStax HCD est possible  
**Méthodologie** : Même approche que Domirama2  
**Format** : Rapport McKinsey MECE (Mutuellement Exclusif, Collectivement Exhaustif)  
**Keyspace HCD** : `domiramacatops_poc` (nouveau keyspace dédié)  
**Format Source** : Parquet uniquement (pas de SequenceFile)  
**Recherche Avancée** : ✅ **Inclut toutes les fonctionnalités Domirama2** (Full-Text, Vector, Hybrid, Fuzzy, N-Gram)

---

## 📑 Table des Matières

1. [Sources Analysées](#-sources-analysées)
2. [PARTIE 1 : ANALYSE DE L'EXISTANT HBase](#-partie-1--analyse-de-lexistant-hbase)
3. [PARTIE 2 : BESOINS À DÉMONTRER (MECE)](#-partie-2--besoins-à-démontrer-mece)
4. [PARTIE 3 : PLAN D'ACTION POC](#-partie-3--plan-daction-poc)
5. [PARTIE 4 : IMPLICATIONS ET DÉFIS](#-partie-4--implications-et-défis)
6. [PARTIE 5 : CRITÈRES DE SUCCÈS](#-partie-5--critères-de-succès)
7. [CONCLUSION](#-conclusion)

---

## 📚 Sources Analysées

### Inputs-Clients

1. **"Etat de l'art HBase chez Arkéa.pdf"**
   - Section "2. Catégorisation des Opérations"
   - Description complète de la table `B997X04:domirama` (Column Family `category`)
   - Configuration HBase détaillée
   - Patterns d'accès (écriture, lecture)
   - Fonctionnalités spécifiques utilisées

2. **groupe_2025-11-25-110250.zip**
   - Archives des projets catégorisation :
     - `domirama-category-main.tar.gz`
     - `categorizationjar-master.tar.gz`
     - `categorizationapi-main.tar.gz`
   - Code source des applications existantes
   - Schémas de référence

### Inputs-IBM

1. **PROPOSITION_MECE_MIGRATION_HBASE_HCD.md**
   - Section "Refonte de domirama-meta-categories sous IBM HCD"
   - Proposition technique pour la table `domirama-meta-categories`
   - Recommandations pour la Column Family `category` dans `domirama`
   - Schémas CQL recommandés
   - Indexation SAI
   - Data API

---

## 🎯 PARTIE 1 : ANALYSE DE L'EXISTANT HBase

### 1.1 Description Générale

**Projet** : Catégorisation des Opérations  
**Objectif** : Extension du projet Domirama pour enrichir les opérations d'un système de catégorisation automatique et personnalisable par les clients.

**Architecture HBase** :
- Ajout d'une Column Family à la table `domirama` existante
- Partage du même design de clé que Domirama
- **Deux tables HBase distinctes** :
  - `B997X04:domirama` (Column Family `category`) : Opérations avec catégorisation
  - `B997X04:domirama-meta-categories` : Métadonnées et configurations (7 "KeySpaces" logiques)

**Architecture HCD Cible** :
- **Nouveau keyspace dédié** : `domiramacatops_poc` (pas d'extension de `domirama2_poc`)
- **8 tables HCD** :
  - 1 table pour `operations_by_account` (depuis `domirama.category`)
  - 7 tables pour les métadonnées (explosion de `domirama-meta-categories`)

**Repos Git** :
- `https://gitlark.s.arkea.com/edd_technique_outil_plateforme/7x09/categorizationjar`
- `https://gitlark.s.arkea.com/edd_technique_outul_plateforme/7x09/domirama-category`
- `https://gitlark.s.arkea.com/edd_technique_outul_plateforme/7x09/categorizationapi`

---

### 1.2 Configuration HBase - Table `B997X04:domirama` (CF `category`)

#### Schéma HBase

```hbase
Table: 'B997X04:domirama'
Column Family: 'category'
  BLOOMFILTER => 'ROWCOL'
  TTL => '315619200 SECONDS (3653 DAYS)'  # ≈ 10 ans
  REPLICATION_SCOPE => '1'
```

#### Caractéristiques Clés

| Caractéristique | Valeur HBase | Description |
|----------------|--------------|-------------|
| **Table** | `B997X04:domirama` | Table existante Domirama |
| **Column Family** | `category` | Nouvelle CF ajoutée pour catégorisation |
| **BLOOMFILTER** | `ROWCOL` | Filtrage sur RowKey + Column Qualifier |
| **TTL** | `315619200` secondes (3653 jours ≈ 10 ans) | Purge automatique après 10 ans |
| **REPLICATION_SCOPE** | `1` | Réplication vers autres clusters |

---

### 1.3 Key Design

**Structure de la RowKey** :
- **Même structure que Domirama** :
  - `code SI` (entité organisationnelle)
  - `numéro de contrat` (identification du compte)
  - `binaire combinant numéro d'opération + date` pour ordre antichronologique

**Objectif** :
- Une ligne par opération
- Toutes les opérations d'un même compte sont contiguës
- Tri antichronologique (plus récent en premier)

---

### 1.4 Format de Stockage

**Données Thrift encodées en Binaire** :
- Données Thrift encodées en Binaire dans une colonne
- Colonnes dynamiques calquées sur certaines propriétés du POJO Thrift
- Permet d'ajouter des filtres sur les valeurs de ces colonnes dans les Scan
- Optimisation avec le BLOOMFILTER

**Structure** :
- **Colonne principale** : Données Thrift complètes (format binaire)
- **Colonnes dynamiques** : Propriétés extraites du POJO Thrift pour filtrage
  - Exemples : `cat_auto`, `cat_user`, `cat_date_user`, `cat_validee`, etc.

**Avantages** :
- Stockage compact (Thrift binaire)
- Filtrage efficace (colonnes dynamiques + BLOOMFILTER)
- Flexibilité (colonnes dynamiques sans modification de schéma)

---

### 1.5 Opérations d'Écriture

#### 1.5.1 Écriture Batch (MapReduce bulkLoad)

**Processus** :
1. Préparation des données issues du moteur de catégorisation
2. Écriture HBase dans un programme MapReduce en bulkLoad
3. Passage des opérations directement par API HBase dans la phase reduce

**Caractéristiques** :
- **Format source** : SequenceFile (probablement)
- **Volume** : Traitement batch de toutes les opérations
- **Performance** : BulkLoad pour éviter surcharge API temps réel

**Données écrites** :
- Catégorie automatique (`cat_auto`)
- Score de confiance (`cat_confidence`)
- Timestamp constant (pour ne pas écraser les corrections client)

#### 1.5.2 Écriture Temps Réel (API Client)

**Processus** :
- Écriture par l'API pour permettre au client de corriger les résultats du moteur de catégorisation
- PUT avec `current_Timestamp` (timestamp réel de l'action client)

**Données écrites** :
- Catégorie modifiée par client (`cat_user`)
- Date de modification (`cat_date_user`)
- Validation (`cat_validee`)

**Stratégie Multi-Version** :
- Le batch écrit toujours sur le même timestamp
- Le client écrit sur le timestamp réel de son action
- **Résultat** : Pas d'écrasement en cas de rejeu du batch
- L'application priorise `cat_user` si non nul, sinon `cat_auto`

---

### 1.6 Opérations de Lecture

#### 1.6.1 Lecture Temps Réel (API)

**Processus** :
- Lecture Temps réel par l'API à l'aide de SCAN + value filter
- Recherche des opérations d'un compte avec filtres sur catégories

**Patterns** :
- SCAN sur la partition (code_si + contrat)
- Filtres sur colonnes dynamiques (cat_auto, cat_user, etc.)
- Value filters pour filtrer côté serveur

**Cas d'usage** :
- Affichage des opérations catégorisées pour un client
- Recherche par catégorie
- Filtrage par période

#### 1.6.2 Lecture Batch (Unload Incrémental)

**Processus** :
- Lecture batch pour des unload incrémentaux sur HDFS au format ORC
- FullScan + STARTROW + STOPROW + TIMERANGE pour une fenêtre glissante
- Ciblage plus précis des données à redescendre

**Patterns** :
- **FullScan** : Parcours complet de la table
- **STARTROW/STOPROW** : Délimitation par RowKey
- **TIMERANGE** : Fenêtre glissante temporelle

**Cas d'usage** :
- Export incrémental vers HDFS
- Alimentation de systèmes d'analyse
- Backup/Archive

---

### 1.7 Fonctionnalités HBase Spécifiques Utilisées

#### 1.7.1 TTL (Time To Live)

**Configuration** :
- TTL : `315619200` secondes (3653 jours ≈ 10 ans)

**Usage** :
- Purge automatique des données anciennes
- Pas d'intervention manuelle nécessaire

#### 1.7.2 Temporalité des Cellules (Versions)

**Stratégie** :
- Le batch écrit toujours sur le même timestamp
- Le client écrit sur le timestamp réel de son action
- **Résultat** : Pas d'écrasement en cas de rejeu du batch

**Implémentation** :
- Utilisation des versions HBase pour distinguer batch vs client
- L'application lit la version la plus récente pour chaque source

#### 1.7.3 BLOOMFILTER

**Configuration** :
- `BLOOMFILTER => 'ROWCOL'`

**Usage** :
- Optimisation des lectures
- Filtrage sur RowKey + Column Qualifier
- Réduction des I/O inutiles

#### 1.7.4 REPLICATION_SCOPE

**Configuration** :
- `REPLICATION_SCOPE => '1'`

**Usage** :
- Réplication vers autres clusters
- Haute disponibilité
- Disaster recovery

#### 1.7.5 Colonnes Dynamiques

**Usage** :
- Colonnes calquées sur propriétés du POJO Thrift
- Permet filtres sur valeurs dans les Scan
- Pas de modification de schéma nécessaire

---

## 🎯 PARTIE 2 : BESOINS À DÉMONTRER (MECE)

### 2.1 Dimension 1 : Configuration et Schéma

#### 2.1.1 Keyspace et Table

**À démontrer** :
- ✅ Création du keyspace `domiramacatops_poc`
- ✅ Création de la table `operations_by_account` (ou réutilisation de `domirama2_poc.operations_by_account`)
- ✅ Ajout des colonnes de catégorisation à la table existante

**Implique** :
- Schéma CQL avec colonnes de catégorisation
- Stratégie de réplication (SimpleStrategy pour POC, NetworkTopologyStrategy pour production)
- Documentation du schéma

#### 2.1.2 Key Design

**À démontrer** :
- ✅ Partition Key : `(code_si, contrat)` (identique à Domirama2)
- ✅ Clustering Keys : `(date_op DESC, numero_op ASC)` (ordre antichronologique)
- ✅ Conformité avec la structure HBase existante

**Implique** :
- Validation que la structure de clé permet les mêmes patterns d'accès
- Démonstration de l'ordre antichronologique
- Tests de performance sur les accès par partition

#### 2.1.3 Colonnes de Catégorisation

**À démontrer** :
- ✅ Colonnes pour catégorie automatique (`cat_auto`, `cat_confidence`)
- ✅ Colonnes pour catégorie utilisateur (`cat_user`, `cat_date_user`, `cat_validee`)
- ✅ Colonne pour données Thrift binaires (`operation_data BLOB`)
- ✅ Colonnes dynamiques (`meta_flags MAP<TEXT, TEXT>`)

**Implique** :
- Schéma CQL complet avec toutes les colonnes
- Documentation de chaque colonne
- Exemples de données

---

### 2.2 Dimension 2 : Format de Stockage

#### 2.2.1 Données Thrift Binaires

**À démontrer** :
- ✅ Stockage des données Thrift encodées en binaire dans une colonne BLOB
- ✅ Préservation de l'intégrité des données lors de la migration
- ✅ Capacité de décodage des données Thrift depuis le BLOB

**Implique** :
- Colonne `operation_data BLOB` dans le schéma
- Scripts de migration HBase → HCD (conversion Thrift binaire)
- Tests de validation (encodage/décodage)

#### 2.2.2 Colonnes Dynamiques

**À démontrer** :
- ✅ Utilisation de `MAP<TEXT, TEXT>` pour colonnes dynamiques
- ✅ Filtrage sur les valeurs des colonnes dynamiques
- ✅ Indexation SAI sur les colonnes dynamiques si nécessaire

**Implique** :
- Schéma avec `meta_flags MAP<TEXT, TEXT>`
- Index SAI sur les clés du MAP si besoin
- Démonstration de filtrage avec `CONTAINS`

---

### 2.3 Dimension 3 : Opérations d'Écriture

#### 2.3.1 Écriture Batch (MapReduce bulkLoad → Spark)

**À démontrer** :
- ✅ Migration de MapReduce bulkLoad vers Spark
- ✅ Chargement batch de données depuis Parquet/SequenceFile
- ✅ Écriture en masse dans HCD via Spark Cassandra Connector
- ✅ Préservation du timestamp constant pour le batch

**Implique** :
- Script Spark pour ingestion batch
- Conversion SequenceFile → Parquet (si nécessaire)
- Utilisation de `spark-cassandra-connector`
- Gestion des timestamps (batch écrit avec timestamp constant)

#### 2.3.2 Écriture Temps Réel (API PUT → Data API / CQL)

**À démontrer** :
- ✅ Écriture via Data API (REST/GraphQL) pour corrections client
- ✅ Écriture via CQL direct (driver Java/Python)
- ✅ Utilisation de timestamp réel pour les corrections client
- ✅ Stratégie multi-version (pas d'écrasement batch → client)

**Implique** :
- Configuration Data API (Stargate)
- Scripts de démonstration (PUT via Data API)
- Scripts de démonstration (UPDATE via CQL)
- Tests de non-écrasement (batch puis client)

---

### 2.4 Dimension 4 : Opérations de Lecture

#### 2.4.1 Lecture Temps Réel (SCAN + value filter → SELECT + SAI)

**À démontrer** :
- ✅ Remplacement de SCAN + value filter par SELECT + WHERE + SAI
- ✅ Recherche par catégorie (cat_auto, cat_user)
- ✅ Filtrage sur colonnes dynamiques
- ✅ Performance équivalente ou meilleure

**Implique** :
- Index SAI sur colonnes de catégorisation
- Requêtes CQL avec WHERE
- Tests de performance (latence, débit)
- Comparaison avec HBase (si possible)

#### 2.4.2 Lecture Batch (FullScan + STARTROW/STOPROW + TIMERANGE)

**À démontrer** :
- ✅ Export incrémental avec fenêtre glissante (TIMERANGE)
- ✅ Export avec délimitation par clé (STARTROW/STOPROW équivalent)
- ✅ Export au format Parquet (remplacement ORC)
- ✅ Performance et scalabilité

**Implique** :
- Scripts Spark pour export incrémental
- Utilisation de WHERE sur clustering keys (date_op, numero_op)
- Export Parquet avec partitionnement
- Tests de performance sur gros volumes

---

### 2.5 Dimension 5 : Fonctionnalités Spécifiques

#### 2.5.1 TTL (Time To Live)

**À démontrer** :
- ✅ Configuration TTL au niveau table (`default_time_to_live`)
- ✅ Purge automatique après 10 ans (315619200 secondes)
- ✅ Validation que les données expirent correctement

**Implique** :
- Schéma CQL avec `default_time_to_live = 315619200`
- Tests de validation (insertion puis vérification expiration)
- Documentation du comportement

#### 2.5.2 Temporalité des Cellules (Multi-Version)

**À démontrer** :
- ✅ Stratégie multi-version pour distinguer batch vs client
- ✅ Colonnes séparées (`cat_auto` vs `cat_user`)
- ✅ Logique applicative de priorisation (cat_user > cat_auto)
- ✅ Non-écrasement en cas de rejeu batch

**Implique** :
- Schéma avec colonnes séparées
- Scripts de démonstration (batch puis client)
- Tests de non-écrasement
- Documentation de la logique applicative

#### 2.5.3 BLOOMFILTER Équivalent

**À démontrer** :
- ✅ Équivalent BLOOMFILTER avec index SAI
- ✅ Performance équivalente ou meilleure
- ✅ Réduction des I/O inutiles

**Implique** :
- Index SAI sur colonnes clés
- Tests de performance
- Comparaison avec HBase (si possible)
- Documentation de l'équivalence

#### 2.5.4 REPLICATION_SCOPE Équivalent

**À démontrer** :
- ✅ Réplication multi-cluster avec NetworkTopologyStrategy
- ✅ Configuration de réplication par datacenter
- ✅ Tests de réplication

**Implique** :
- Configuration NetworkTopologyStrategy
- Tests de réplication (si environnement multi-cluster disponible)
- Documentation de la configuration

---

### 2.6 Dimension 6 : Recherche et Indexation

#### 2.6.1 Recherche par Catégorie

**À démontrer** :
- ✅ Recherche par catégorie automatique (`cat_auto`)
- ✅ Recherche par catégorie utilisateur (`cat_user`)
- ✅ Recherche combinée (cat_auto OU cat_user)
- ✅ Performance avec index SAI

**Implique** :
- Index SAI sur `cat_auto` et `cat_user`
- Requêtes CQL avec WHERE
- Tests de performance

#### 2.6.2 Recherche Full-Text (si applicable)

**À démontrer** :
- ✅ Recherche full-text sur libellé d'opération (si colonne `libelle` présente)
- ✅ Utilisation d'analyzers Lucene (frenchLightStem, asciifolding)
- ✅ Recherche multi-terme
- ✅ Performance avec index SAI full-text

**Implique** :
- Index SAI full-text sur `libelle` (si présent)
- Configuration d'analyzers
- Tests de recherche

---

### 2.7 Dimension 7 : Migration et Intégration

#### 2.7.1 Migration des Données

**À démontrer** :
- ✅ Extraction des données depuis HBase
- ✅ Conversion Thrift binaire → BLOB
- ✅ Migration vers HCD (Spark ou DSBulk)
- ✅ Validation de l'intégrité des données

**Implique** :
- Scripts d'extraction HBase
- Scripts de conversion
- Scripts de chargement HCD
- Tests de validation (comptage, échantillonnage)

#### 2.7.2 Intégration avec Applications Existantes

**À démontrer** :
- ✅ Compatibilité avec l'API existante (categorizationapi)
- ✅ Migration progressive (dual-write possible)
- ✅ Tests de régression

**Implique** :
- Analyse de l'API existante
- Adapter l'API pour HCD (Data API ou driver)
- Tests de compatibilité

---

## 🎯 PARTIE 3 : PLAN D'ACTION POC

### 3.1 Structure du POC

**Dossier** : `poc-design/domiramaCatOps/`

**Organisation** :
```
domiramaCatOps/
├── doc/
│   ├── templates/          # Templates pour scripts didactiques
│   ├── demonstrations/     # Rapports auto-générés
│   └── *.md                # Documentation principale
├── schemas/
│   └── *.cql              # Schémas CQL (numérotés par ordre d'exécution)
├── scripts/
│   └── *.sh               # Scripts shell (numérotés par ordre d'exécution)
└── data/                   # Données de test Parquet (si nécessaire)
```

**Méthodologie** :
- Même approche que Domirama2
- Scripts numérotés par ordre d'exécution
- Versions didactiques avec génération automatique de rapports .md
- Templates réutilisables
- **Format source** : Parquet uniquement (pas de SequenceFile)

---

### 3.2 Scripts à Créer (Ordre d'Exécution)

#### Phase 1 : Setup et Configuration

1. **`01_setup_domiramaCatOps_keyspace.sh`**
   - Création du keyspace `domiramacatops_poc` (nouveau keyspace dédié)
   - Configuration de la stratégie de réplication
   - Documentation complète

2. **`02_setup_operations_by_account.sh`**
   - Création de la table `operations_by_account` avec colonnes de catégorisation
   - Configuration TTL
   - Documentation

3. **`03_setup_meta_categories_tables.sh`**
   - Création des 7 tables pour `domirama-meta-categories`
   - Tables : acceptation_client, opposition_categorisation, historique_opposition, feedback_par_libelle, feedback_par_ics, regles_personnalisees, decisions_salaires
   - Documentation

4. **`04_create_indexes.sh`**
   - Création des index SAI sur colonnes de catégorisation
   - Index full-text si applicable
   - Index sur tables meta-categories si nécessaire
   - Documentation

#### Phase 2 : Ingestion

5. **`05_load_operations_data_parquet.sh`**
   - Chargement batch de données depuis Parquet (format source unique)
   - Simulation MapReduce → Spark
   - Utilisation de timestamp constant pour batch
   - Chargement dans `operations_by_account`

6. **`06_load_meta_categories_data_parquet.sh`**
   - Chargement batch des métadonnées depuis Parquet
   - Chargement dans les 7 tables meta-categories
   - Format Parquet uniquement

7. **`07_load_category_data_realtime.sh`**
   - Chargement temps réel (corrections client)
   - Utilisation de timestamp réel
   - Tests de non-écrasement
   - Vérification acceptation/opposition avant catégorisation

#### Phase 3 : Lecture et Recherche

8. **`08_test_category_search.sh`**
   - Recherche par catégorie (cat_auto, cat_user)
   - Tests de performance
   - Comparaison avec HBase (si possible)

9. **`09_test_acceptation_opposition.sh`**
   - Tests acceptation client
   - Tests opposition catégorisation
   - Impact sur catégorisation

10. **`10_test_regles_personnalisees.sh`**
    - Tests règles personnalisées
    - Application des règles sur catégorisation
    - Tests de priorité

11. **`11_test_feedbacks_counters.sh`**
    - Tests compteurs atomiques (feedback_par_libelle, feedback_par_ics)
    - Tests INCREMENT équivalent
    - Tests de cohérence

12. **`12_test_historique_opposition.sh`**
    - Tests historique opposition (remplace VERSIONS => '50')
    - Tests de traçabilité

13. **`13_test_dynamic_columns.sh`**
    - Filtrage sur colonnes dynamiques (meta_flags)
    - Tests avec CONTAINS

14. **`14_test_incremental_export.sh`**
    - Export incrémental avec fenêtre glissante
    - Export Parquet
    - Tests de performance

15. **`15_test_coherence_multi_tables.sh`**
    - Tests de cohérence entre les 8 tables
    - Validation des contraintes métier

#### Phase 4 : Fonctionnalités Spécifiques

16. **`16_demo_ttl.sh`**
    - Démonstration TTL
    - Tests de purge automatique

17. **`17_demo_multi_version.sh`**
    - Démonstration stratégie multi-version
    - Tests de non-écrasement (batch → client)

18. **`18_demo_bloomfilter_equivalent.sh`**
    - Démonstration équivalent BLOOMFILTER
    - Tests de performance avec index SAI

19. **`19_demo_replication_scope.sh`**
    - Démonstration réplication (si environnement disponible)
    - Configuration NetworkTopologyStrategy

#### Phase 5 : Migration

20. **`20_migrate_hbase_to_hcd.sh`**
    - Extraction HBase (2 tables)
    - Conversion Thrift binaire → BLOB
    - Migration vers HCD (8 tables)
    - Validation

21. **`21_validate_migration.sh`**
    - Validation complète de la migration
    - Tests de cohérence
    - Tests de performance

---

### 3.3 Schémas CQL à Créer

1. **`01_create_domiramaCatOps_keyspace.cql`**
   - Création du keyspace `domiramacatops_poc`
   - Configuration de réplication

2. **`02_create_operations_by_account.cql`**
   - Table `operations_by_account` avec colonnes de catégorisation
   - TTL configuration

3. **`03_create_meta_categories_tables.cql`**
   - 7 tables pour `domirama-meta-categories` :
     - acceptation_client
     - opposition_categorisation
     - historique_opposition
     - feedback_par_libelle (compteurs)
     - feedback_par_ics (compteurs)
     - regles_personnalisees
     - decisions_salaires

4. **`04_create_indexes.cql`**
   - Index SAI sur cat_auto, cat_user
   - Index full-text si applicable
   - Index sur tables meta-categories si nécessaire

---

### 3.4 Documentation à Créer

1. **`01_README.md`**
   - Vue d'ensemble du POC
   - Objectifs
   - Structure
   - Guide d'exécution

2. **`02_GAPS_ANALYSIS.md`**
   - Analyse des gaps fonctionnels
   - Comparaison HBase vs HCD
   - Statut de chaque fonctionnalité

3. **`03_DEMONSTRATION_COMPLETE.md`**
   - Documentation complète de toutes les démonstrations
   - Résultats
   - Validations

---

## 🎯 PARTIE 4 : IMPLICATIONS ET DÉFIS

### 4.1 Implications Techniques

#### 4.1.1 Schéma de Données

**Défi** :
- Création d'un nouveau keyspace dédié
- Explosion de `domirama-meta-categories` en 7 tables
- Relations entre les 8 tables HCD

**Décision POC** :
- **Nouveau keyspace** : `domiramacatops_poc` (dédié, pas d'extension de `domirama2_poc`)
- **8 tables HCD** :
  - 1 table `operations_by_account` (depuis `domirama.category`)
  - 7 tables pour métadonnées (explosion de `domirama-meta-categories`)
- **Séparation claire** des responsabilités (bonnes pratiques CQL)

#### 4.1.2 Migration Thrift Binaire

**Défi** :
- Conversion des données Thrift binaires depuis HBase
- Préservation de l'intégrité
- Format source : Parquet uniquement (pas de SequenceFile)

**Solution** :
- Extraction directe du BLOB depuis HBase
- Conversion en Parquet (colonne Binary pour BLOB)
- Chargement depuis Parquet dans HCD
- Stockage dans `operation_data BLOB` sans conversion
- Décodage côté application si nécessaire

#### 4.1.3 Stratégie Multi-Version

**Défi** :
- HBase utilise les versions de cellules
- HCD n'a pas de versions automatiques

**Solution** :
- Colonnes séparées (`cat_auto` vs `cat_user`)
- Logique applicative de priorisation
- Timestamps explicites (`cat_date_user`)

---

### 4.2 Implications Fonctionnelles

#### 4.2.1 Compatibilité API

**Défi** :
- L'API existante (`categorizationapi`) utilise l'API HBase
- Migration vers Data API ou driver CQL

**Solution** :
- Adapter l'API pour utiliser Data API (REST/GraphQL)
- Ou utiliser driver Java/Python CQL
- Tests de régression

#### 4.2.2 Performance

**Défi** :
- Garantir des performances équivalentes ou meilleures
- Notamment pour les SCAN + value filter

**Solution** :
- Index SAI optimisés
- Tests de performance
- Benchmarking

---

### 4.3 Implications Opérationnelles

#### 4.3.1 Migration Progressive

**Défi** :
- Migration sans interruption de service
- Dual-write possible ?

**Solution** :
- Phase 1 : Dual-write (HBase + HCD)
- Phase 2 : Lecture HCD uniquement
- Phase 3 : Arrêt écriture HBase

#### 4.3.2 Formation Équipes

**Défi** :
- Formation des équipes sur HCD/CQL
- Migration des compétences HBase → HCD

**Solution** :
- Documentation complète
- Scripts didactiques
- Sessions de formation

---

## 🎯 PARTIE 5 : CRITÈRES DE SUCCÈS

### 5.1 Critères Fonctionnels

- ✅ **100% des fonctionnalités HBase couvertes** :
  - TTL automatique
  - Temporalité (multi-version)
  - BLOOMFILTER équivalent
  - REPLICATION_SCOPE équivalent
  - Colonnes dynamiques
  - Écriture batch (Spark)
  - Écriture temps réel (Data API/CQL)
  - Lecture temps réel (SELECT + SAI)
  - Lecture batch (export incrémental)

### 5.2 Critères de Performance

- ✅ **Performance équivalente ou meilleure** :
  - Latence lecture < 10ms (p95)
  - Débit écriture batch > 10K ops/s
  - Export incrémental < 1h pour 1M lignes

### 5.3 Critères de Qualité

- ✅ **Documentation complète** :
  - Schémas CQL documentés
  - Scripts commentés
  - Rapports de démonstration
  - Guide de migration

- ✅ **Tests validés** :
  - Tests fonctionnels
  - Tests de performance
  - Tests de non-régression

---

## 📋 CONCLUSION

Ce document définit le périmètre complet du POC pour la migration de la table `B997X04:domirama` (Column Family `category`) de HBase vers DataStax HCD.

**Prochaines étapes** :
1. Création de la structure du dossier `domiramaCatOps`
2. Création des schémas CQL
3. Création des scripts de démonstration
4. Exécution et validation du POC
5. Documentation des résultats

**Méthodologie** : Même approche que Domirama2, avec scripts didactiques et génération automatique de rapports.

---

**Date de création** : 2024-11-27  
**Auteur** : Analyse basée sur inputs-clients et inputs-ibm  
**Version** : 1.0

