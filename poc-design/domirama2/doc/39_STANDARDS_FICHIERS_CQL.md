# 📋 Standards et Bonnes Pratiques : Fichiers CQL

**Date** : 2025-11-25  
**Objectif** : Définir les standards de documentation pour tous les fichiers CQL du POC Domirama2

---

## 🎯 Objectifs

1. **Compréhensibilité** : Un développeur externe doit pouvoir comprendre chaque fichier CQL sans connaissance préalable du POC
2. **Contexte** : Expliquer le contexte HBase → HCD et les équivalences
3. **Documentation inline** : Commentaires détaillés dans chaque fichier

---

## ✅ Structure Standard d'un Fichier CQL

### 1. En-tête du Fichier

**Format standard** :
```cql
-- ============================================
-- Fichier : XX_nom_fichier.cql
-- Description courte et claire (1-2 lignes)
-- ============================================
--
-- OBJECTIF :
--   Description détaillée de ce que fait ce fichier (3-5 lignes)
--   Expliquer le contexte et pourquoi ce fichier est nécessaire
--   Mentionner les fonctionnalités principales
--
-- CONTEXTE HBase → HCD :
--   - Équivalent HBase : [fonctionnalité HBase équivalente]
--   - Différences/Améliorations : [ce qui est différent ou mieux]
--
-- PRÉREQUIS :
--   - Liste des prérequis (keyspace créé, table existante, etc.)
--   - Fichiers à exécuter avant celui-ci
--
-- UTILISATION :
--   cqlsh -f XX_nom_fichier.cql
--   ou via script shell : ./XX_nom_script.sh
--
-- EXEMPLE :
--   cqlsh localhost 9042 -f XX_nom_fichier.cql
--
-- SORTIE :
--   - Ce que le fichier produit (keyspace, table, index, etc.)
--   - Vérifications à effectuer après exécution
--
-- ============================================
```

---

### 2. Commentaires Inline

**Pour chaque section importante** :
```cql
-- ============================================
-- SECTION : Nom de la Section
-- ============================================
-- Description de ce que fait cette section
-- Explication des choix techniques
-- Équivalents HBase si applicable
-- ============================================
```

**Pour chaque commande importante** :
```cql
-- Création du keyspace avec réplication
-- Équivalent HBase : Namespace
-- Différence : Réplication configurée au niveau keyspace (vs table HBase)
CREATE KEYSPACE IF NOT EXISTS domirama2_poc
WITH replication = {
    'class': 'SimpleStrategy',
    'replication_factor': 1
};
```

**Pour chaque colonne importante** :
```cql
-- Colonne de catégorisation automatique (batch)
-- Équivalent HBase : Colonne dans CF 'categorisation'
-- Stratégie multi-version : Batch écrit UNIQUEMENT cat_auto (ne touche JAMAIS cat_user)
cat_auto TEXT,
```

---

### 3. Explications Techniques

**Pour les index SAI** :
```cql
-- Index SAI (Storage-Attached Index) pour recherche full-text
-- Équivalent HBase : Index Elasticsearch (dans l'architecture existante)
-- Avantages : Index intégré, pas de système externe nécessaire
-- Analyzers : lowercase, asciifolding, frenchLightStem, stop words
CREATE CUSTOM INDEX IF NOT EXISTS idx_libelle_fulltext_advanced
ON domirama2_poc.operations_by_account (libelle)
USING 'org.apache.cassandra.index.sai.StorageAttachedIndex'
WITH OPTIONS = {
    'analyzer_class': 'org.apache.lucene.analysis.standard.StandardAnalyzer',
    'analyzer': '{
        "tokenizer": {"name": "standard"},
        "filters": [
            {"name": "lowercase"},
            {"name": "asciifolding"},
            {"name": "frenchLightStem"},
            {"name": "stop", "params": {"words": "_french_"}}
        ]
    }'
};
```

**Pour les types de données** :
```cql
-- Colonne vectorielle pour recherche floue (fuzzy search)
-- Type : VECTOR<FLOAT, 1472> (1472 dimensions pour ByteT5)
-- Équivalent HBase : Pas d'équivalent direct (nécessite Elasticsearch + ML)
-- Avantage : Recherche par similarité sémantique intégrée
libelle_embedding VECTOR<FLOAT, 1472>,
```

---

## 📋 Checklist de Documentation

Pour chaque fichier CQL, vérifier :

- [ ] **En-tête complet** : OBJECTIF, CONTEXTE HBase → HCD, PRÉREQUIS, UTILISATION, EXEMPLE, SORTIE
- [ ] **Commentaires inline** : Chaque section importante commentée
- [ ] **Explications techniques** : Choix techniques expliqués
- [ ] **Équivalents HBase** : Mentionnés quand applicable
- [ ] **Exemples d'utilisation** : Si le fichier contient des requêtes de test
- [ ] **Notes importantes** : Stratégies multi-version, contraintes, etc.

---

## 🎯 Niveau de Documentation Requis

### Pour un Développeur Externe

Un développeur externe doit pouvoir :
1. **Comprendre l'objectif** : Lire l'en-tête et savoir ce que fait le fichier
2. **Comprendre le contexte** : Savoir comment cela s'inscrit dans la migration HBase → HCD
3. **Comprendre les équivalences** : Savoir ce qui correspond à HBase
4. **Exécuter le fichier** : Comprendre comment l'utiliser
5. **Comprendre les résultats** : Savoir ce qui est créé/modifié

---

## 📝 Exemple de Fichier CQL Bien Documenté

```cql
-- ============================================
-- Fichier : 01_schemas/01_create_domirama2_schema.cql
-- Création du schéma de base pour le POC Domirama2
-- ============================================
--
-- OBJECTIF :
--   Ce fichier crée le keyspace 'domirama2_poc' et la table 'operations_by_account'
--   avec toutes les colonnes nécessaires pour la catégorisation des opérations.
--   Il implémente la stratégie multi-version (batch vs client) conforme à la
--   proposition IBM pour garantir qu'aucune correction client ne soit perdue.
--
-- CONTEXTE HBase → HCD :
--   - Équivalent HBase : Table 'domirama' avec Column Family 'operations'
--   - Différences :
--     * Schéma fixe (vs schéma flexible HBase)
--     * Clés de clustering pour partitionnement (vs RowKey HBase)
--     * Colonnes typées (vs colonnes dynamiques HBase)
--   - Améliorations :
--     * Index SAI intégrés (vs Elasticsearch externe)
--     * Support vectoriel natif (vs nécessite ML externe)
--
-- PRÉREQUIS :
--   - HCD 1.2.3 démarré et accessible sur localhost:9042
--   - Aucun fichier à exécuter avant (c'est le premier fichier)
--
-- UTILISATION :
--   cqlsh localhost 9042 -f 01_schemas/01_create_domirama2_schema.cql
--   ou via script shell : ./10_setup_domirama10_setup_domirama2_poc.sh
--
-- EXEMPLE :
--   cqlsh localhost 9042 -f schemas/01_create_domirama2_schema.cql
--
-- SORTIE :
--   - Keyspace 'domirama2_poc' créé
--   - Table 'operations_by_account' créée avec toutes les colonnes
--   - Index SAI de base créés
--   - Vérification : DESCRIBE KEYSPACE domirama2_poc;
--
-- ============================================

-- ============================================
-- SECTION 1 : Création du Keyspace
-- ============================================
-- Le keyspace est l'équivalent d'un namespace HBase
-- Réplication : SimpleStrategy avec replication_factor=1 (POC local)
-- En production : NetworkTopologyStrategy avec réplication par datacenter
-- ============================================

CREATE KEYSPACE IF NOT EXISTS domirama2_poc
WITH replication = {
    'class': 'SimpleStrategy',
    'replication_factor': 1
};

-- ============================================
-- SECTION 2 : Création de la Table
-- ============================================
-- Table principale pour stocker les opérations bancaires
-- Équivalent HBase : Table 'domirama' avec RowKey = code_si:contrat:date_op:numero_op
-- Clés de partition : code_si, contrat (déterminent la partition)
-- Clés de clustering : date_op, numero_op (trient les données dans la partition)
-- ============================================

CREATE TABLE IF NOT EXISTS domirama2_poc.operations_by_account (
    -- Clés de partition (équivalent partie fixe du RowKey HBase)
    code_si TEXT,           -- Code système source (ex: "DEMO_OFFICIAL")
    contrat TEXT,           -- Numéro de compte/contrat
    
    -- Clés de clustering (équivalent partie variable du RowKey HBase)
    date_op TIMESTAMP,      -- Date de l'opération (tri chronologique)
    numero_op INT,          -- Numéro séquentiel de l'opération (tri par ordre)
    
    -- Identifiant unique de l'opération
    op_id TEXT,             -- UUID de l'opération (généré par Spark)
    
    -- Données de l'opération
    libelle TEXT,           -- Libellé de l'opération (recherche full-text)
    montant DECIMAL,        -- Montant de l'opération
    devise TEXT,            -- Devise (EUR, USD, etc.)
    
    -- Métadonnées
    type_operation TEXT,    -- Type d'opération (DEBIT, CREDIT, etc.)
    sens_operation TEXT,    -- Sens de l'opération
    
    -- Données COBOL (format BLOB conforme IBM)
    -- Équivalent HBase : Colonne dans CF 'cobol' avec format BLOB
    operation_data BLOB,    -- Données COBOL brutes (format BLOB)
    
    -- Colonnes de catégorisation (stratégie multi-version)
    -- IMPORTANT : Batch écrit UNIQUEMENT cat_auto et cat_confidence
    -- IMPORTANT : Client écrit dans cat_user, cat_date_user, cat_validee
    -- Cette séparation garantit qu'aucune correction client ne sera perdue
    cat_auto TEXT,          -- Catégorie automatique (batch)
    cat_confidence DECIMAL, -- Confiance de la catégorisation (0.0 à 1.0)
    cat_user TEXT,          -- Catégorie client (correction manuelle)
    cat_date_user TIMESTAMP, -- Date de la correction client
    cat_validee BOOLEAN,    -- Indicateur de validation client
    
    -- Clé primaire composite
    PRIMARY KEY ((code_si, contrat), date_op, numero_op)
) WITH CLUSTERING ORDER BY (date_op DESC, numero_op DESC);

-- ============================================
-- SECTION 3 : Index SAI de Base
-- ============================================
-- Index SAI (Storage-Attached Index) pour recherche full-text
-- Équivalent HBase : Index Elasticsearch (dans l'architecture existante)
-- Avantages : Index intégré, pas de système externe nécessaire
-- ============================================

-- Index sur le libellé pour recherche full-text
CREATE CUSTOM INDEX IF NOT EXISTS idx_libelle_fulltext
ON domirama2_poc.operations_by_account (libelle)
USING 'org.apache.cassandra.index.sai.StorageAttachedIndex';

-- Index sur la catégorie automatique pour filtrage
CREATE CUSTOM INDEX IF NOT EXISTS idx_cat_auto
ON domirama2_poc.operations_by_account (cat_auto)
USING 'org.apache.cassandra.index.sai.StorageAttachedIndex';

-- ============================================
-- FIN DU FICHIER
-- ============================================
```

---

## ✅ Conformité Actuelle

### Fichiers CQL à Améliorer

- ⚠️ `01_schemas/01_create_domirama2_schema.cql` : En-tête minimal, commentaires inline insuffisants
- ⚠️ `02_create_domirama2_schema_advanced.cql` : Documentation basique
- ⚠️ `03_create_domirama2_schema_fuzzy.cql` : Documentation basique
- ⚠️ `04_schemas/04_domirama2_search_test.cql` : Commentaires de requêtes insuffisants
- ⚠️ `05_domirama2_search_advanced.cql` : Documentation basique
- ⚠️ `06_domirama2_search_fulltext_complex.cql` : Documentation basique
- ⚠️ `07_domirama2_search_fuzzy.cql` : Documentation basique
- ⚠️ `08_schemas/08_domirama2_api_correction_client.cql` : Documentation basique

---

## 🎯 Plan d'Action

1. **Améliorer tous les fichiers CQL** : Ajouter en-têtes complets et commentaires inline
2. **Expliquer les équivalences HBase** : Mentionner les équivalents HBase pour chaque concept
3. **Documenter les choix techniques** : Expliquer pourquoi certaines options sont choisies
4. **Ajouter des exemples** : Si applicable, ajouter des exemples d'utilisation

---

**✅ Standards définis pour une documentation complète et compréhensible des fichiers CQL !**




