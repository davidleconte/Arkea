# 🏗️ Guide de Configuration - DomiramaCatOps

**Date** : 2025-12-01  
**Objectif** : Guide complet pour configurer le schéma HCD pour DomiramaCatOps  
**Prérequis** : HCD 1.2.3 installé et démarré

---

## 📋 Table des Matières

1. [Prérequis](#prérequis)
2. [Configuration du Keyspace](#configuration-du-keyspace)
3. [Configuration de la Table Principale](#configuration-de-la-table-principale)
4. [Configuration des Tables Meta-Categories](#configuration-des-tables-meta-categories)
5. [Configuration des Index SAI](#configuration-des-index-sai)
6. [Vérifications](#vérifications)
7. [Prochaines Étapes](#prochaines-étapes)

---

## 🔧 Prérequis

### Logiciels Requis

- ✅ **HCD 1.2.3** : Installé et démarré
- ✅ **Java 11** : Configuré via jenv
- ✅ **Python 3.8+** : Pour les scripts de démonstration
- ✅ **Spark 3.5.1** : Pour le chargement batch (optionnel)

### Vérifications

```bash
# Vérifier que HCD est démarré
./scripts/setup/03_start_hcd.sh

# Vérifier l'accès HCD
cd binaire/hcd-1.2.3
./bin/cqlsh "$HCD_HOST" "$HCD_PORT" -e "SELECT cluster_name FROM system.local;"
```

---

## 📦 Configuration du Keyspace

### Script : `01_setup_domiramaCatOps_keyspace.sh`

**Objectif** : Créer le keyspace `domiramacatops_poc`

**Exécution** :
```bash
cd scripts
./01_setup_domiramaCatOps_keyspace.sh
```

**DDL Exécuté** :
```cql
CREATE KEYSPACE IF NOT EXISTS domiramacatops_poc
WITH REPLICATION = {
  'class': 'SimpleStrategy',
  'replication_factor': 1
};
```

**Explication** :
- **Keyspace** : `domiramacatops_poc` (nouveau keyspace dédié)
- **SimpleStrategy** : Pour POC local (1 nœud)
- **NetworkTopologyStrategy** : Pour production (multi-datacenter)

**Rapport généré** : `doc/demonstrations/01_SETUP_KEYSPACE_DEMONSTRATION.md`

---

## 📊 Configuration de la Table Principale

### Script : `02_setup_operations_by_account.sh`

**Objectif** : Créer la table `operations_by_account` avec toutes les colonnes nécessaires

**Exécution** :
```bash
./02_setup_operations_by_account.sh
```

**Structure de la Table** :

```cql
CREATE TABLE IF NOT EXISTS operations_by_account (
    -- Partition Keys
    code_si           TEXT,
    contrat           TEXT,
    
    -- Clustering Keys
    date_op           TIMESTAMP,
    numero_op         INT,
    
    -- Colonnes principales
    libelle           TEXT,
    montant           DECIMAL,
    type_operation    TEXT,
    operation_data    BLOB,
    
    -- Colonnes de recherche avancée
    libelle_prefix    TEXT,
    libelle_tokens    SET<TEXT>,
    libelle_embedding VECTOR<FLOAT, 1472>,
    
    -- Colonnes de catégorisation
    cat_auto          TEXT,
    cat_confidence    DECIMAL,
    cat_user          TEXT,
    cat_date_user     TIMESTAMP,
    cat_validee       BOOLEAN,
    
    PRIMARY KEY ((code_si, contrat), date_op, numero_op)
) WITH CLUSTERING ORDER BY (date_op DESC, numero_op ASC)
  AND default_time_to_live = 315619200;
```

**Colonnes Clés** :

| Colonne | Type | Description |
|---------|------|-------------|
| `code_si`, `contrat` | TEXT | Partition Keys (équivalent RowKey HBase) |
| `date_op`, `numero_op` | TIMESTAMP, INT | Clustering Keys (tri antichronologique) |
| `cat_auto` | TEXT | Catégorie automatique (batch uniquement) |
| `cat_user` | TEXT | Catégorie modifiée par client |
| `libelle_embedding` | VECTOR<FLOAT, 1472> | Embeddings ByteT5 pour recherche vectorielle |

**Rapport généré** : `doc/demonstrations/02_SETUP_OPERATIONS_DEMONSTRATION.md`

---

## 🏷️ Configuration des Tables Meta-Categories

### Script : `03_setup_meta_categories_tables.sh`

**Objectif** : Créer les 7 tables meta-categories (explosion du schéma HBase)

**Exécution** :
```bash
./03_setup_meta_categories_tables.sh
```

**Tables Créées** :

1. **`acceptation_client`** : Acceptation des catégorisations
2. **`opposition_categorisation`** : Oppositions aux catégorisations
3. **`historique_opposition`** : Historique des oppositions
4. **`feedback_par_libelle`** : Feedbacks par libellé (COUNTER)
5. **`feedback_par_ics`** : Feedbacks par ICS (COUNTER)
6. **`regles_personnalisees`** : Règles personnalisées de catégorisation
7. **`decisions_salaires`** : Décisions salaires (cas spécifique)

**Exemple - Table `feedback_par_libelle`** :

```cql
CREATE TABLE IF NOT EXISTS feedback_par_libelle (
    libelle_normalise TEXT,
    cat_auto          TEXT,
    count_engine      COUNTER,
    count_user        COUNTER,
    PRIMARY KEY (libelle_normalise, cat_auto)
);
```

**Rapport généré** : `doc/demonstrations/03_SETUP_META_CATEGORIES_DEMONSTRATION.md`

---

## 🔍 Configuration des Index SAI

### Script : `04_create_indexes.sh`

**Objectif** : Créer tous les index SAI pour la recherche avancée

**Exécution** :
```bash
./04_create_indexes.sh
```

**Index Créés** :

1. **`idx_libelle_fulltext`** : Recherche full-text sur libellé
   ```cql
   CREATE CUSTOM INDEX IF NOT EXISTS idx_libelle_fulltext
   ON operations_by_account(libelle)
   USING 'StorageAttachedIndex'
   WITH OPTIONS = {
     'index_analyzer': '{
       "tokenizer": {"name": "standard"},
       "filters": [
         {"name": "lowercase"},
         {"name": "frenchLightStem"},
         {"name": "asciiFolding"}
       ]
     }'
   };
   ```

2. **`idx_cat_auto`** : Filtrage rapide par catégorie batch
3. **`idx_cat_user`** : Filtrage rapide par catégorie client
4. **`idx_montant`** : Range queries sur montant
5. **`idx_type_operation`** : Filtrage rapide par type d'opération
6. **`idx_libelle_embedding_vector`** : Recherche vectorielle (ANN)

**Rapport généré** : `doc/demonstrations/04_CREATE_INDEXES_DEMONSTRATION.md`

---

## ✅ Vérifications

### Vérification 1 : Keyspace

```bash
cd binaire/hcd-1.2.3
./bin/cqlsh "$HCD_HOST" "$HCD_PORT" -e "SELECT keyspace_name FROM system_schema.keyspaces WHERE keyspace_name = 'domiramacatops_poc';"
```

**Attendu** : `domiramacatops_poc`

### Vérification 2 : Table Principale

```bash
./bin/cqlsh "$HCD_HOST" "$HCD_PORT" -e "DESCRIBE TABLE domiramacatops_poc.operations_by_account;"
```

**Attendu** : Table avec toutes les colonnes (cat_auto, cat_user, libelle_embedding, etc.)

### Vérification 3 : Tables Meta-Categories

```bash
./bin/cqlsh "$HCD_HOST" "$HCD_PORT" -e "SELECT table_name FROM system_schema.tables WHERE keyspace_name = 'domiramacatops_poc' AND table_name LIKE '%feedback%' OR table_name LIKE '%regle%';"
```

**Attendu** : 7 tables meta-categories

### Vérification 4 : Index SAI

```bash
./bin/cqlsh "$HCD_HOST" "$HCD_PORT" -e "SELECT index_name FROM system_schema.indexes WHERE keyspace_name = 'domiramacatops_poc';"
```

**Attendu** : Au moins 6 index SAI

---

## 🚀 Prochaines Étapes

Une fois la configuration terminée :

1. **Générer les données** :
   ```bash
   ./04_generate_operations_parquet.sh
   ```

2. **Charger les données** :
   ```bash
   ./05_load_operations_data_parquet.sh
   ```

3. **Générer les embeddings** :
   ```bash
   ./05_generate_libelle_embedding.sh
   ```

4. **Consulter le guide d'ingestion** :
   - [Guide d'Ingestion](03_GUIDE_INGESTION.md)

---

## 📚 Ressources

- **Scripts** : Tous les scripts sont dans `scripts/`
- **Schémas CQL** : Disponibles dans `schemas/`
- **Démonstrations** : Rapports auto-générés dans `doc/demonstrations/`
- **Documentation** : [INDEX.md](../INDEX.md)

---

**Date de création** : 2025-12-01  
**Dernière mise à jour** : 2025-12-01

