# 📊 Data Model Complet : DomiramaCatOps - Analyse MECE

**Date** : 2024-11-27
**Projet** : Catégorisation des Opérations
**Objectif** : Étude précise et détaillée du data model HCD pour les deux tables HBase
**Format** : MECE (Mutuellement Exclusif, Collectivement Exhaustif)

---

## 🎯 Vue d'Ensemble

### Tables HBase Sources

1. **`B997X04:domirama`** (Column Family `category`)
   - Opérations avec catégorisation
   - Une ligne par opération
   - Key design : code_si + contrat + date_op + numero_op

2. **`B997X04:domirama-meta-categories`**
   - Métadonnées et configurations de catégorisation
   - 7 "KeySpaces" logiques dans une table physique
   - Compteurs, règles, historiques

### Keyspace HCD Cible

**Keyspace** : `domiramacatops_poc` (dédié, nouveau keyspace)

**Justification** :

- Séparation claire des responsabilités
- Pas de couplage avec `domirama2_poc`
- Conformité aux bonnes pratiques HCD (un keyspace par domaine métier)

---

## 📋 PARTIE 1 : TABLE `domirama` (CF `category`) → HCD

### 1.1 Table HCD : `operations_by_account`

**Source HBase** : `B997X04:domirama` (Column Family `category`)

**Schéma CQL** :

```cql
CREATE TABLE domiramacatops_poc.operations_by_account (
    -- Partition Key (regroupe toutes les opérations d'un compte)
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
    operation_data    BLOB,        -- Données Thrift encodées en binaire

    -- Colonnes dynamiques
    meta_flags        MAP<TEXT, TEXT>,

    -- ============================================
    -- Colonnes de Recherche Avancée (Conforme Domirama2)
    -- ============================================
    -- Ces colonnes permettent les recherches avancées : full-text, vector, hybrid, fuzzy
    -- Conforme aux fonctionnalités validées dans domirama2
    libelle_prefix    TEXT,        -- Préfixe pour recherche partielle (N-Gram)
    libelle_tokens    SET<TEXT>,   -- Tokens/N-Grams pour recherche partielle avec CONTAINS
    libelle_embedding VECTOR<FLOAT, 1472>,  -- Embeddings ByteT5 pour recherche vectorielle

    -- Colonnes de Catégorisation (Stratégie Multi-Version)
    cat_auto          TEXT,        -- Catégorie automatique (batch)
    cat_confidence    DECIMAL,     -- Score de confiance (0.0 à 1.0)
    cat_user          TEXT,        -- Catégorie modifiée par client
    cat_date_user     TIMESTAMP,   -- Date de modification par client
    cat_validee       BOOLEAN,     -- Validation par client

    PRIMARY KEY ((code_si, contrat), date_op, numero_op)
) WITH CLUSTERING ORDER BY (date_op DESC, numero_op ASC)
  AND default_time_to_live = 315619200;  -- TTL 10 ans
```

**Caractéristiques** :

- ✅ Key design conforme HBase
- ✅ Colonnes de catégorisation (cat_auto, cat_user, etc.)
- ✅ Données Thrift binaires (BLOB)
- ✅ Colonnes dynamiques (MAP)
- ✅ TTL 10 ans

**Index SAI** (Conforme Domirama2 - Recherche Avancée) :

- **Full-Text Avancé** : `idx_libelle_fulltext_advanced` sur `libelle` (analyzers : lowercase, asciifolding, frenchLightStem)
- **N-Gram** : `idx_libelle_prefix_ngram` sur `libelle_prefix` (recherche partielle)
- **Collection** : `idx_libelle_tokens` sur `libelle_tokens` (recherche partielle avec CONTAINS)
- **Vector Search** : `idx_libelle_embedding_vector` sur `libelle_embedding` (fuzzy search avec ByteT5)
- **Catégories** : `idx_cat_auto` et `idx_cat_user` (recherche par catégorie)
- **Autres** : `idx_montant`, `idx_type_operation` (filtrage rapide)

---

## 📋 PARTIE 2 : TABLE `domirama-meta-categories` → HCD

### 2.1 Explosion en 7 Tables HCD

**Source HBase** : `B997X04:domirama-meta-categories` (1 table avec 7 "KeySpaces" logiques)

**HCD** : 7 tables distinctes (bonnes pratiques CQL)

---

### 2.2 Table 1 : `acceptation_client`

**Source HBase** : `ACCEPT:{code_efs}:{no_contrat}:{no_pse}`

**Schéma CQL** :

```cql
CREATE TABLE domiramacatops_poc.acceptation_client (
    code_efs      TEXT,
    no_contrat    TEXT,
    no_pse        TEXT,
    accepted_at   TIMESTAMP,
    accepted      BOOLEAN,

    PRIMARY KEY ((code_efs, no_contrat, no_pse))
);
```

**Usage** : Acceptation de l'affichage/catégorisation par le client

---

### 2.3 Table 2 : `opposition_categorisation`

**Source HBase** : `OPPOSITION:{code_efs}:{no_pse}`

**Schéma CQL** :

```cql
CREATE TABLE domiramacatops_poc.opposition_categorisation (
    code_efs      TEXT,
    no_pse        TEXT,
    opposed       BOOLEAN,
    opposed_at    TIMESTAMP,

    PRIMARY KEY ((code_efs, no_pse))
);
```

**Usage** : Opposition à la catégorisation automatique

---

### 2.4 Table 3 : `historique_opposition`

**Source HBase** : `HISTO_OPPOSITION:{code_efs}:{no_pse}:{timestamp}` (VERSIONS => '50')

**Schéma CQL** :

```cql
CREATE TABLE domiramacatops_poc.historique_opposition (
    code_efs      TEXT,
    no_pse        TEXT,
    horodate      TIMEUUID,  -- Clustering key pour ordre chronologique
    status         TEXT,      -- 'opposé' ou 'autorisé'
    timestamp      TIMESTAMP,
    raison         TEXT,      -- Raison du changement (optionnel)

    PRIMARY KEY ((code_efs, no_pse), horodate)
) WITH CLUSTERING ORDER BY (horodate DESC);
```

**Usage** : Historique des changements d'opposition (remplace VERSIONS => '50')

---

### 2.5 Table 4 : `feedback_par_libelle`

**Source HBase** : `ANALYZE_LABEL:{type_op}:{sens_op}:{libellé}` (compteurs dynamiques)

**Schéma CQL** :

```cql
CREATE TABLE domiramacatops_poc.feedback_par_libelle (
    type_operation     TEXT,
    sens_operation     TEXT,
    libelle_simplifie  TEXT,
    categorie          TEXT,      -- Clustering key (remplace colonnes dynamiques)
    count_engine       COUNTER,   -- Compteur moteur
    count_client       COUNTER,   -- Compteur client

    PRIMARY KEY ((type_operation, sens_operation, libelle_simplifie), categorie)
);
```

**Usage** : Feedbacks moteur/clients par libellé (compteurs atomiques)

**Note** : Table de compteurs (toutes les colonnes non-clé sont de type `counter`)

**Index SAI Recommandés** :

- `idx_feedback_libelle_fulltext` : Index SAI full-text sur `libelle_simplifie` (recherche partielle)
- `idx_feedback_categorie` : Index SAI standard sur `categorie` (filtrage rapide)

---

### 2.6 Table 5 : `feedback_par_ics`

**Source HBase** : `ICS_DECISION:{type_op}:{sens_op}:{no_ICS}` (compteurs dynamiques)

**Schéma CQL** :

```cql
CREATE TABLE domiramacatops_poc.feedback_par_ics (
    type_operation     TEXT,
    sens_operation     TEXT,
    code_ics           TEXT,
    categorie          TEXT,      -- Clustering key
    count_engine       COUNTER,
    count_client       COUNTER,

    PRIMARY KEY ((type_operation, sens_operation, code_ics), categorie)
);
```

**Usage** : Feedbacks moteur/clients par code ICS

**Index SAI Recommandés** :

- `idx_feedback_ics_categorie` : Index SAI standard sur `categorie` (filtrage rapide)

---

### 2.7 Table 6 : `regles_personnalisees`

**Source HBase** : `CUSTOM_RULE:{code_efs}:{type_op}:{sens_op}:{libellé}`

**Schéma CQL** :

```cql
CREATE TABLE domiramacatops_poc.regles_personnalisees (
    code_efs          TEXT,
    type_operation    TEXT,
    sens_operation    TEXT,
    libelle_simplifie TEXT,
    categorie_cible    TEXT,
    actif             BOOLEAN,
    priorite          INT,
    created_at        TIMESTAMP,
    updated_at        TIMESTAMP,

    PRIMARY KEY ((code_efs), type_operation, sens_operation, libelle_simplifie)
);
```

**Usage** : Règles de catégorisation personnalisées par client

**Index SAI Recommandés** :

- `idx_regles_libelle_fulltext` : Index SAI full-text sur `libelle_simplifie` (recherche partielle)
- `idx_regles_categorie_cible` : Index SAI standard sur `categorie_cible` (filtrage rapide)
- `idx_regles_actif` : Index SAI standard sur `actif` (filtrage règles actives)

---

### 2.8 Table 7 : `decisions_salaires`

**Source HBase** : `SALARY_DECISION:{libellé}`

**Schéma CQL** :

```cql
CREATE TABLE domiramacatops_poc.decisions_salaires (
    libelle_simplifie  TEXT,
    methode_utilisee    TEXT,
    modele             TEXT,
    actif              BOOLEAN,
    created_at         TIMESTAMP,
    updated_at         TIMESTAMP,

    PRIMARY KEY (libelle_simplifie)
);
```

**Usage** : Méthode de catégorisation sur libellés taggés salaires

**Index SAI Recommandés** :

- `idx_decisions_methode` : Index SAI standard sur `methode_utilisee` (filtrage rapide)
- `idx_decisions_modele` : Index SAI standard sur `modele` (filtrage rapide)
- `idx_decisions_actif` : Index SAI standard sur `actif` (filtrage décisions actives)

---

## 🔗 PARTIE 3 : RELATIONS ENTRE LES TABLES

### 3.1 Relations Fonctionnelles

#### 3.1.1 Catégorisation des Opérations

**Flux** :

1. **Batch** écrit dans `operations_by_account.cat_auto` (catégorie automatique)
2. **Client** peut corriger dans `operations_by_account.cat_user`
3. **Feedback** mis à jour dans `feedback_par_libelle` (compteurs)
4. **Règles** dans `regles_personnalisees` peuvent surcharger la catégorisation

#### 3.1.2 Contrôle d'Accès

**Flux** :

1. Vérification `acceptation_client` avant affichage
2. Vérification `opposition_categorisation` avant catégorisation
3. Historique dans `historique_opposition`

#### 3.1.3 Feedbacks

**Flux** :

1. Chaque catégorisation → incrément compteur dans `feedback_par_libelle` ou `feedback_par_ics`
2. `count_engine` incrémenté par batch
3. `count_client` incrémenté par correction client

---

## 📊 PARTIE 4 : IMPACTS DE LA DEUXIÈME TABLE SUR LE POC

### 4.1 Impacts sur `operations_by_account`

#### 4.1.1 Vérification Acceptation/Opposition

**Avant catégorisation** :

- Vérifier `acceptation_client` (si accepté)
- Vérifier `opposition_categorisation` (si non opposé)

**Impact POC** :

- Scripts de démonstration doivent inclure ces vérifications
- Tests de non-catégorisation si opposition

#### 4.1.2 Application des Règles Personnalisées

**Avant catégorisation automatique** :

- Vérifier `regles_personnalisees` pour le client/libellé
- Appliquer la règle si existe

**Impact POC** :

- Démonstration de l'application des règles
- Tests de priorité (règle > catégorisation automatique)

#### 4.1.3 Mise à Jour des Feedbacks

**Après catégorisation** :

- Incrémenter `feedback_par_libelle.count_engine` (batch)
- Incrémenter `feedback_par_libelle.count_client` (correction client)

**Impact POC** :

- Démonstration des compteurs atomiques
- Tests de cohérence (opération → feedback)

---

### 4.2 Impacts sur les Scripts de Démonstration

#### 4.2.1 Scripts à Ajouter/Modifier

**Nouveaux scripts** :

- `13_setup_meta_categories_tables.sh` : Création des 7 tables
- `14_load_meta_categories_data.sh` : Chargement des données
- `15_test_acceptation_opposition.sh` : Tests acceptation/opposition
- `16_test_regles_personnalisees.sh` : Tests règles personnalisées
- `17_test_feedbacks_counters.sh` : Tests compteurs atomiques
- `18_test_historique_opposition.sh` : Tests historique

**Scripts à modifier** :

- `03_load_category_data_batch.sh` : Ajouter mise à jour feedbacks
- `04_load_category_data_realtime.sh` : Ajouter vérification acceptation/opposition
- `05_test_category_search.sh` : Ajouter tests avec règles personnalisées

---

### 4.3 Impacts sur le Data Model

#### 4.3.1 Cohérence des Données

**Contraintes à respecter** :

- Si `opposition_categorisation.opposed = true` → pas de catégorisation
- Si `regles_personnalisees` existe → utiliser `categorie_cible`
- Chaque catégorisation → mettre à jour feedbacks

**Impact POC** :

- Tests de cohérence multi-tables
- Validation des contraintes métier

---

## 📋 PARTIE 5 : DONNÉES SOURCE - PARQUET UNIQUEMENT

### 5.1 Format Source

**Spécification** : Données source en **Parquet uniquement** (pas de SequenceFile)

**Implications** :

- Pas de conversion SequenceFile → Parquet
- Scripts Spark lisent directement Parquet
- Structure Parquet doit correspondre au schéma HCD

### 5.2 Structure Parquet Attendue

#### 5.2.1 Pour `operations_by_account`

**Colonnes Parquet** :

- `code_si`, `contrat`, `date_op`, `numero_op`
- `libelle`, `montant`, `devise`, `type_operation`, `sens_operation`
- `operation_data` (BLOB → Binary dans Parquet)
- `cat_auto`, `cat_confidence`, `cat_user`, `cat_date_user`, `cat_validee`
- `meta_flags` (MAP → Struct dans Parquet)

#### 5.2.2 Pour les Tables Meta-Categories

**Parquet séparés par table** :

- `acceptation_client.parquet`
- `opposition_categorisation.parquet`
- `historique_opposition.parquet`
- `feedback_par_libelle.parquet`
- `feedback_par_ics.parquet`
- `regles_personnalisees.parquet`
- `decisions_salaires.parquet`

---

## 🎯 PARTIE 6 : RÉSUMÉ DU DATA MODEL HCD

### 6.1 Keyspace

**Nom** : `domiramacatops_poc`

**Stratégie de réplication** :

- POC : `SimpleStrategy` (replication_factor: 1)
- Production : `NetworkTopologyStrategy` (par datacenter)

### 6.2 Tables (8 tables au total)

1. **`operations_by_account`** : Opérations avec catégorisation
2. **`acceptation_client`** : Acceptations clients
3. **`opposition_categorisation`** : Oppositions
4. **`historique_opposition`** : Historique oppositions
5. **`feedback_par_libelle`** : Feedbacks par libellé (compteurs)
6. **`feedback_par_ics`** : Feedbacks par ICS (compteurs)
7. **`regles_personnalisees`** : Règles personnalisées
8. **`decisions_salaires`** : Décisions salaires

### 6.3 Index SAI (Recherche Avancée - Conforme Domirama2)

**Sur `operations_by_account`** :

**Recherche Full-Text** :

- `idx_libelle_fulltext_advanced` : Analyzers français (lowercase, asciifolding, frenchLightStem)

**Recherche Partielle** :

- `idx_libelle_prefix_ngram` : N-Gram sur `libelle_prefix`
- `idx_libelle_tokens` : Collection sur `libelle_tokens` (CONTAINS)

**Recherche Vectorielle** :

- `idx_libelle_embedding_vector` : ANN sur `libelle_embedding` (ByteT5)

**Recherche Catégories** :

- `idx_cat_auto` : Recherche par catégorie automatique
- `idx_cat_user` : Recherche par catégorie client

**Filtrage** :

- `idx_montant` : Filtrage par montant
- `idx_type_operation` : Filtrage par type d'opération

**Sur autres tables** :

**`historique_opposition`** :

- `idx_historique_status` : Index SAI standard sur `status` (recherche par statut)
- `idx_historique_raison_fulltext` : Index SAI full-text sur `raison` (recherche dans raisons - si nécessaire)

**`feedback_par_libelle`** :

- `idx_feedback_libelle_fulltext` : Index SAI full-text sur `libelle_simplifie` (recherche partielle)
- `idx_feedback_categorie` : Index SAI standard sur `categorie` (filtrage rapide)

**`feedback_par_ics`** :

- `idx_feedback_ics_categorie` : Index SAI standard sur `categorie` (filtrage rapide)

**`regles_personnalisees`** :

- `idx_regles_libelle_fulltext` : Index SAI full-text sur `libelle_simplifie` (recherche partielle)
- `idx_regles_categorie_cible` : Index SAI standard sur `categorie_cible` (filtrage rapide)
- `idx_regles_actif` : Index SAI standard sur `actif` (filtrage règles actives)

**`decisions_salaires`** :

- `idx_decisions_methode` : Index SAI standard sur `methode_utilisee` (filtrage rapide)
- `idx_decisions_modele` : Index SAI standard sur `modele` (filtrage rapide)
- `idx_decisions_actif` : Index SAI standard sur `actif` (filtrage décisions actives)

---

## 📋 PARTIE 7 : PLAN D'ACTION MISE À JOUR (Avec Recherche Avancée)

### 7.1 Scripts à Créer (Total : 24 scripts - Enrichi avec Recherche Avancée)

#### Phase 1 : Setup (3 scripts)

1. `01_setup_domiramaCatOps_keyspace.sh` : Création keyspace
2. `02_setup_operations_by_account.sh` : Création table operations
3. `03_setup_meta_categories_tables.sh` : Création 7 tables meta-categories

#### Phase 2 : Ingestion (3 scripts)

4. `04_load_operations_data_parquet.sh` : Chargement operations (Parquet)
5. `05_load_meta_categories_data_parquet.sh` : Chargement meta-categories (Parquet)
6. `06_load_category_data_realtime.sh` : Chargement temps réel

#### Phase 3 : Tests Fonctionnels (8 scripts)

7. `07_test_category_search.sh` : Recherche par catégorie
8. `08_test_acceptation_opposition.sh` : Tests acceptation/opposition
9. `09_test_regles_personnalisees.sh` : Tests règles personnalisées
10. `10_test_feedbacks_counters.sh` : Tests compteurs atomiques
11. `11_test_historique_opposition.sh` : Tests historique
12. `12_test_dynamic_columns.sh` : Tests colonnes dynamiques
13. `13_test_incremental_export.sh` : Export incrémental
14. `14_test_coherence_multi_tables.sh` : Tests cohérence multi-tables

#### Phase 3b : Recherche Avancée (4 scripts - NOUVEAU - Conforme Domirama2)

15. `15_generate_embeddings.sh` : Génération embeddings ByteT5
16. `16_test_fuzzy_search.sh` : Tests fuzzy search
17. `17_demonstration_fuzzy_search.sh` : Démonstration fuzzy search
18. `18_test_hybrid_search.sh` : Tests hybrid search

#### Phase 4 : Fonctionnalités Spécifiques (4 scripts)

19. `19_demo_ttl.sh` : Démonstration TTL
20. `20_demo_multi_version.sh` : Démonstration multi-version
21. `21_demo_bloomfilter_equivalent.sh` : BLOOMFILTER équivalent
22. `22_demo_replication_scope.sh` : Réplication

#### Phase 5 : Migration (2 scripts)

23. `23_migrate_hbase_to_hcd.sh` : Migration complète
24. `24_validate_migration.sh` : Validation migration

---

## 🎯 CONCLUSION

Ce data model HCD :

- ✅ **Sépare clairement** les responsabilités (8 tables)
- ✅ **Respecte les bonnes pratiques** CQL (schémas fixes, pas de colonnes dynamiques)
- ✅ **Gère les compteurs** avec type `counter` natif
- ✅ **Remplace VERSIONS** par tables d'historique
- ✅ **Utilise Parquet** comme format source unique
- ✅ **Maintient la cohérence** entre les tables

**Prochaines étapes** :

1. Créer les schémas CQL complets
2. Créer les scripts de démonstration
3. Exécuter et valider le POC

---

**Date** : 2024-11-27
**Version** : 1.0
