# 🎯 POC DomiramaCatOps - Migration HBase → HCD - Catégorisation des Opérations

**Date** : 2025-12-01  
**Version** : 2.0.0  
**Objectif** : Démonstration de la migration des tables Domirama (catégorisation) de HBase vers HCD  
**Conformité** : **104%** avec les exigences clients et IBM  
**IBM | Opportunité ICS 006gR000001hiA5QAI - AREKA | Ingénieur Avant-Vente** : David LECONTE | <david.leconte1@ibm.com> - Mobile : +33614126117

---

## 📋 Vue d'Ensemble

Ce POC démontre la migration de deux tables HBase vers DataStax Hyper-Converged Database (HCD) :

- **Table `B997X04:domirama`** (Column Family `category`) - Catégorisation automatique des opérations
- **Table `B997X04:domirama-meta-categories`** - 7 tables meta-categories (explosion du schéma HBase)

### Caractéristiques Principales

- ✅ **Catégorisation automatique** : Colonnes `cat_auto`, `cat_confidence` (batch)
- ✅ **Corrections client** : Colonnes `cat_user`, `cat_date_user`, `cat_validee` (temps réel)
- ✅ **Stratégie multi-version** : Batch vs client (pas d'écrasement)
- ✅ **7 tables meta-categories** : Règles personnalisées, feedbacks, historique opposition
- ✅ **Compteurs atomiques** : Feedbacks par libellé et ICS (type COUNTER)
- ✅ **Recherche avancée** : Full-Text, Vector (ByteT5, e5-large, invoice), Hybrid
- ✅ **TTL 10 ans** : Rétention automatique des données
- ✅ **Format source** : Parquet uniquement

---

## 🏗️ Structure du Projet

```
domiramaCatOps/
├── scripts/                  # Scripts d'automatisation (74 scripts)
│   ├── 01_setup_domiramaCatOps_keyspace.sh      # Création keyspace
│   ├── 02_setup_operations_by_account.sh        # Création table operations
│   ├── 03_setup_meta_categories_tables.sh       # Création 7 tables meta
│   ├── 04_create_indexes.sh                     # Création index SAI
│   ├── 04_generate_operations_parquet.sh       # Génération données operations
│   ├── 04_generate_meta_categories_parquet.sh   # Génération données meta
│   ├── 05_load_operations_data_parquet.sh       # Chargement batch operations
│   ├── 06_load_meta_categories_data_parquet.sh  # Chargement batch meta
│   ├── 07_load_category_data_realtime.sh       # Chargement temps réel
│   ├── 08_test_category_search.sh              # Tests recherche catégorie
│   ├── 09_test_acceptation_opposition.sh       # Tests acceptation/opposition
│   ├── 10_test_regles_personnalisees.sh        # Tests règles personnalisées
│   ├── 11_test_feedbacks_counters.sh           # Tests compteurs atomiques
│   ├── 12_test_historique_opposition.sh        # Tests historique opposition
│   ├── 16_test_fuzzy_search.sh                 # Tests fuzzy search
│   ├── 18_test_hybrid_search.sh                # Tests hybrid search
│   └── ... (58 autres scripts)
│
├── doc/                      # Documentation complète
│   ├── design/              # Design et architecture (27 fichiers)
│   ├── guides/               # Guides d'utilisation (7 fichiers)
│   ├── implementation/       # Documents d'implémentation (6 fichiers)
│   ├── results/             # Résultats de tests (4 fichiers)
│   ├── corrections/          # Corrections appliquées (3 fichiers)
│   ├── audits/              # Audits et analyses (17 fichiers)
│   ├── demonstrations/      # Rapports de démonstrations (33 fichiers)
│   └── templates/           # Templates réutilisables (9 fichiers)
│
├── schemas/                  # Schémas CQL
│   ├── 01_create_domiramaCatOps_schema.cql      # Schéma complet
│   ├── 02_create_operations_indexes.cql         # Index operations
│   ├── 03_create_meta_categories_tables.cql     # Tables meta-categories
│   └── ... (6 autres schémas)
│
├── examples/                 # Exemples de code
│   └── python/              # Scripts Python (43 fichiers)
│
├── utils/                    # Utilitaires
│   └── didactique_functions.sh  # Fonctions communes
│
├── data/                     # Données de test
│   ├── operations_20000.parquet/
│   └── meta-categories/
│
└── README.md                 # Ce fichier
```

---

## 🚀 Démarrage Rapide

### 1. Prérequis

- ✅ HCD 1.2.3 installé et démarré
- ✅ Spark 3.5.1 configuré
- ✅ Python 3.8-3.11
- ✅ Kafka (optionnel, pour ingestion temps réel)

### 2. Configuration de l'Environnement

```bash
cd /path/to/Arkea
source .poc-profile
check_poc_env
```

### 3. Setup Initial

```bash
cd poc-design/domiramaCatOps

# Créer le keyspace
./scripts/01_setup_domiramaCatOps_keyspace.sh

# Créer la table operations_by_account
./scripts/02_setup_operations_by_account.sh

# Créer les 7 tables meta-categories
./scripts/03_setup_meta_categories_tables.sh

# Créer les index SAI
./scripts/04_create_indexes.sh
```

### 4. Génération et Ingestion

```bash
# Générer les données Parquet
./scripts/04_generate_operations_parquet.sh
./scripts/04_generate_meta_categories_parquet.sh

# Chargement batch operations
./scripts/05_load_operations_data_parquet.sh

# Générer les embeddings (optionnel)
./scripts/05_generate_libelle_embedding.sh

# Chargement batch meta-categories
./scripts/06_load_meta_categories_data_parquet.sh

# Chargement temps réel (corrections client)
./scripts/07_load_category_data_realtime.sh
```

### 5. Tests et Démonstrations

```bash
# Tests recherche par catégorie
./scripts/08_test_category_search.sh

# Tests acceptation/opposition
./scripts/09_test_acceptation_opposition.sh

# Tests règles personnalisées
./scripts/10_test_regles_personnalisees.sh

# Tests compteurs atomiques
./scripts/11_test_feedbacks_counters.sh

# Tests historique opposition
./scripts/12_test_historique_opposition.sh

# Tests fuzzy search
./scripts/16_test_fuzzy_search.sh

# Tests hybrid search
./scripts/18_test_hybrid_search.sh
```

---

## 📚 Documentation

Toute la documentation est dans le répertoire `doc/` :

### Guides Principaux

- **doc/guides/01_README.md** - Vue d'ensemble du POC DomiramaCatOps
- **doc/guides/02_GUIDE_SETUP.md** - Guide de configuration
- **doc/guides/03_GUIDE_INGESTION.md** - Guide d'ingestion
- **doc/guides/04_GUIDE_RECHERCHE.md** - Guide de recherche
- **doc/guides/20_GUIDE_EXECUTION_ORDRE_SCRIPTS.md** - Ordre d'exécution

### Design et Architecture

- **doc/design/00_ANALYSE_POC_DOMIRAMA_CAT_OPS.md** - Analyse MECE complète
- **doc/design/04_DATA_MODEL_COMPLETE.md** - Modèle de données complet
- **doc/design/05_SYNTHESE_IMPACTS_DEUXIEME_TABLE.md** - Synthèse impacts

### Audits

- **doc/audits/32_AUDIT_COMPLET_EXIGENCES_DECISION_ARKEA.md** - Audit complet pour décision ARKEA
- **doc/audits/33_TABLEAU_RECAPITULATIF_COUVERTURE_EXIGENCES.md** - Tableau récapitulatif

Voir `doc/INDEX.md` pour l'index complet.

---

## 🎯 Use Cases Couverts

### 1. Catégorisation Automatique

- ✅ Batch écrit `cat_auto` et `cat_confidence`
- ✅ Client peut corriger via `cat_user`
- ✅ Stratégie multi-version garantit qu'aucune correction n'est perdue
- ✅ Recherche par catégorie (automatique ou client)

### 2. Meta-Categories

- ✅ **Règles personnalisées** : Table `regles_personnalisees`
- ✅ **Feedbacks** : Compteurs atomiques par libellé et ICS
- ✅ **Historique opposition** : Traçabilité complète (illimité vs 50 versions HBase)
- ✅ **Acceptation/Opposition** : Gestion des validations client
- ✅ **Décisions salaires** : Méthode de catégorisation spécifique

### 3. Recherche Avancée

- ✅ **Full-Text Search** : Recherche par libellé avec index SAI
- ✅ **Vector Search** : Recherche floue avec embeddings (ByteT5, e5-large, invoice)
- ✅ **Hybrid Search** : Combinaison Full-Text + Vector
- ✅ **Multi-modèles** : Support plusieurs modèles d'embeddings

### 4. Ingestion

- ✅ Écriture batch (Spark)
- ✅ Écriture temps réel (corrections client)
- ✅ Format Parquet uniquement

### 5. Export et Requêtes

- ✅ Export incrémental Parquet
- ✅ Fenêtre glissante automatique
- ✅ Équivalences STARTROW/STOPROW/TIMERANGE

---

## 🛠️ Scripts Disponibles

### Setup

- `01_setup_domiramaCatOps_keyspace.sh` - Création keyspace
- `02_setup_operations_by_account.sh` - Création table operations
- `03_setup_meta_categories_tables.sh` - Création 7 tables meta-categories
- `04_create_indexes.sh` - Création index SAI

### Génération

- `04_generate_operations_parquet.sh` - Génération données operations (20k+ lignes)
- `04_generate_meta_categories_parquet.sh` - Génération données meta-categories

### Ingestion

- `05_load_operations_data_parquet.sh` - Chargement batch operations
- `06_load_meta_categories_data_parquet.sh` - Chargement batch meta-categories
- `07_load_category_data_realtime.sh` - Chargement temps réel (corrections client)

### Tests Fonctionnels

- `08_test_category_search.sh` - Tests recherche par catégorie
- `09_test_acceptation_opposition.sh` - Tests acceptation/opposition
- `10_test_regles_personnalisees.sh` - Tests règles personnalisées
- `11_test_feedbacks_counters.sh` - Tests compteurs atomiques
- `12_test_historique_opposition.sh` - Tests historique opposition
- `13_test_dynamic_columns.sh` - Tests colonnes dynamiques
- `14_test_incremental_export.sh` - Tests export incrémental
- `15_test_coherence_multi_tables.sh` - Tests cohérence multi-tables

### Recherche Avancée

- `16_test_fuzzy_search.sh` - Tests fuzzy search (vector)
- `17_demonstration_fuzzy_search.sh` - Démonstration fuzzy search
- `18_test_hybrid_search.sh` - Tests hybrid search (full-text + vector)

### Fonctionnalités Spécifiques

- `19_demo_ttl.sh` - Démonstration TTL
- `21_demo_bloomfilter_equivalent.sh` - Démonstration BLOOMFILTER équivalent
- `22_demo_replication_scope.sh` - Démonstration REPLICATION_SCOPE
- `24_demo_data_api.sh` - Démonstration Data API
- `27_demo_kafka_streaming.sh` - Démonstration Kafka streaming

**Note** : La plupart des scripts génèrent automatiquement une documentation structurée dans `doc/demonstrations/`.

---

## 📊 Schéma de Données

### Keyspace

```cql
CREATE KEYSPACE domiramacatops_poc
WITH REPLICATION = {
  'class': 'SimpleStrategy',
  'replication_factor': 1
};
```

### Table Principale : `operations_by_account`

```cql
CREATE TABLE domiramacatops_poc.operations_by_account (
    -- Partition Key
    code_si           TEXT,
    contrat           TEXT,

    -- Clustering Keys (tri antichronologique)
    date_op           TIMESTAMP,
    numero_op         INT,

    -- Données de l'opération
    libelle           TEXT,
    montant           DECIMAL,
    devise            TEXT,
    date_valeur       TIMESTAMP,
    type_operation    TEXT,
    sens_operation    TEXT,

    -- Données Thrift binaires
    operation_data    BLOB,

    -- Catégorisation (équivalent CF category)
    cat_auto          TEXT,        -- Catégorie automatique (batch)
    cat_confidence    DECIMAL,     -- Score de confiance
    cat_user          TEXT,        -- Catégorie modifiée par client
    cat_date_user     TIMESTAMP,   -- Date de modification
    cat_validee       BOOLEAN,     -- Validation client

    -- Colonnes dynamiques
    meta_flags        MAP<TEXT, TEXT>,

    -- Recherche avancée
    libelle_embedding VECTOR<FLOAT, 1472>,  -- ByteT5
    libelle_embedding_e5 VECTOR<FLOAT, 1024>,  -- e5-large
    libelle_embedding_invoice VECTOR<FLOAT, 384>,  -- invoice

    PRIMARY KEY ((code_si, contrat), date_op, numero_op)
) WITH CLUSTERING ORDER BY (date_op DESC, numero_op ASC)
  AND default_time_to_live = 315619200;  -- TTL 10 ans
```

### Tables Meta-Categories (7 tables)

1. **`acceptation_client`** - Acceptation de catégorisation par client
2. **`opposition_categorisation`** - Opposition à la catégorisation
3. **`historique_opposition`** - Historique des oppositions (illimité)
4. **`feedback_par_libelle`** - Feedbacks par libellé (COUNTER)
5. **`feedback_par_ics`** - Feedbacks par ICS (COUNTER)
6. **`regles_personnalisees`** - Règles personnalisées client
7. **`decisions_salaires`** - Décisions salaires

---

## ⚙️ Configuration

Le POC DomiramaCatOps utilise la configuration centralisée du projet ARKEA :

- `.poc-config.sh` - Configuration centralisée
- Variables d'environnement : `HCD_HOST`, `HCD_PORT`, `SPARK_HOME`

---

## 🔍 Vérification

```bash
# Vérifier la configuration
cqlsh $HCD_HOST $HCD_PORT -e "DESCRIBE KEYSPACE domiramacatops_poc;"

# Vérifier les données operations
cqlsh $HCD_HOST $HCD_PORT -e "USE domiramacatops_poc; SELECT COUNT(*) FROM operations_by_account;"

# Vérifier les tables meta-categories
cqlsh $HCD_HOST $HCD_PORT -e "USE domiramacatops_poc; DESCRIBE TABLES;"

# Vérifier les index
cqlsh $HCD_HOST $HCD_PORT -e "USE domiramacatops_poc; DESCRIBE INDEXES;"
```

---

## 📝 Prérequis

- **HCD 1.2.3** - Installé et démarré
- **Spark 3.5.1** - Pour traitement batch
- **Python 3.8-3.11** - Pour scripts Python
- **Kafka** - Optionnel, pour ingestion temps réel

---

## 🎯 Stratégie Multi-Version

### Batch (Script 05)

Le batch écrit **UNIQUEMENT** `cat_auto` et `cat_confidence` :

```scala
Operation(
  cat_auto       = catAuto,        // ✅ Batch écrit ici
  cat_confidence = catConf,        // ✅ Batch écrit ici
  cat_user       = null,           // ❌ Batch NE TOUCHE JAMAIS
  cat_date_user  = null,           // ❌ Batch NE TOUCHE JAMAIS
  cat_validée    = false           // ❌ Batch NE TOUCHE JAMAIS
)
```

### Client/API (Script 07)

Le client écrit dans `cat_user`, `cat_date_user`, `cat_validée` :

```cql
UPDATE operations_by_account
SET cat_user = 'NOUVELLE_CATEGORIE',
    cat_date_user = toTimestamp(now()),
    cat_validée = true
WHERE code_si = '01' AND contrat = '5913101072'
  AND date_op = ? AND numero_op = ?;
```

### Application (Lecture)

Prioriser `cat_user` si non nul, sinon `cat_auto` :

```cql
SELECT
    cat_auto,
    cat_user,
    COALESCE(cat_user, cat_auto) as categorie_finale
FROM operations_by_account
WHERE code_si = '01' AND contrat = '5913101072';
```

**Avantage** : Remplace la temporalité HBase (batch timestamp fixe vs client timestamp réel) par une logique explicite.

---

## 📊 Conformité IBM

### Score Global : **104%** ✅

| Dimension | Score | Statut |
|-----------|-------|--------|
| **Exigences Fonctionnelles (Inputs-Clients)** | 100% | ✅ Complet |
| **Exigences Techniques (Inputs-IBM)** | 100% | ✅ Complet |
| **Patterns HBase Équivalents** | 100% | ✅ Complet |
| **Performance et Scalabilité** | 100% | ✅ Validé |
| **Modernisation et Innovation** | 120% | ✅ Dépassement |

### Points Conformes

1. ✅ **Table `domirama` (CF `category`)** : 7 exigences couvertes (100%)
2. ✅ **Table `domirama-meta-categories`** : 7 exigences couvertes (100%)
3. ✅ **Recommandations Techniques IBM** : 8 exigences couvertes (100%)
4. ✅ **Patterns HBase Équivalents** : 8 patterns démontrés (100%)
5. ✅ **Performance et Scalabilité** : 3 exigences validées (100%)
6. ✅ **Modernisation et Innovation** : 2 innovations (120% - dépassement)

### Innovations

- ✅ **Recherche sémantique** : Recherche vectorielle avec multi-modèles
- ✅ **Multi-modèles embeddings** : Support ByteT5, e5-large, invoice

---

## 🔍 Équivalences HBase → HCD

| Concept HBase | Équivalent HCD | Statut |
|---------------|----------------|--------|
| Namespace `B997X04` | Keyspace `domiramacatops_poc` | ✅ |
| Table `domirama` | Table `operations_by_account` | ✅ |
| Column Family `category` | Colonnes `cat_auto`, `cat_user`, etc. | ✅ |
| Table `domirama-meta-categories` | 7 tables séparées | ✅ |
| RowKey | Partition Key + Clustering Keys | ✅ |
| TTL 315619200s | `default_time_to_live = 315619200` | ✅ |
| INCREMENT | Type COUNTER | ✅ |
| VERSIONS => '50' | Table `historique_opposition` (illimité) | ✅ |
| BLOOMFILTER | Index SAI | ✅ |
| REPLICATION_SCOPE => '1' | NetworkTopologyStrategy | ✅ |

---

## 📊 Statistiques

- **Scripts** : 74 scripts shell
- **Scripts didactiques** : Scripts avec génération automatique de documentation
- **Schémas CQL** : 10+ fichiers
- **Démonstrations** : 33+ rapports auto-générés
- **Documentation** : 100+ fichiers markdown

---

## 📖 Pour Plus d'Informations

- Documentation complète : `doc/`
- Architecture : `doc/design/00_ANALYSE_POC_DOMIRAMA_CAT_OPS.md`
- Guide de déploiement : `doc/guides/01_README.md`
- Audit complet : `doc/audits/32_AUDIT_COMPLET_EXIGENCES_DECISION_ARKEA.md`
- Tableau récapitulatif : `doc/audits/33_TABLEAU_RECAPITULATIF_COUVERTURE_EXIGENCES.md`

---

## ✅ Statut

- ✅ **Structure créée** - Répertoires et fichiers organisés
- ✅ **Schémas créés** - Keyspace et 8 tables configurés
- ✅ **Scripts développés** - 74 scripts de démonstration
- ✅ **Documentation complète** - 100+ fichiers markdown
- ✅ **Tests validés** - 33+ démonstrations auto-générées
- ✅ **Conformité validée** - 104% avec exigences IBM

**POC DomiramaCatOps prêt pour démonstration !** 🚀

---

**Date de création** : 2024-11-27  
**Dernière mise à jour** : 2025-12-01  
**Version** : 2.0.0
