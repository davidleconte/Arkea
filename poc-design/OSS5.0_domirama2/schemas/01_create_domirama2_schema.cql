-- ============================================
-- Fichier : 01_create_domirama2_schema.cql
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
--   - Équivalent HBase : Table 'domirama' dans namespace 'B997X04' avec Column Family 'operations'
--   - Différences :
--     * Schéma fixe (vs schéma flexible HBase)
--     * Clés de clustering pour partitionnement (vs RowKey HBase)
--     * Colonnes typées (vs colonnes dynamiques HBase)
--   - Améliorations :
--     * Index SAI intégrés (vs Elasticsearch externe)
--     * Support vectoriel natif (vs nécessite ML externe)
--     * Stratégie multi-version native (vs logique applicative HBase)
--
-- PRÉREQUIS :
--   - HCD 1.2.3 démarré et accessible sur localhost:9042
--   - Aucun fichier à exécuter avant (c'est le premier fichier)
--
-- UTILISATION :
--   cqlsh localhost 9042 -f 01_create_domirama2_schema.cql
--   ou via script shell : ./10_setup_domirama2_poc.sh
--
-- EXEMPLE :
--   cqlsh localhost 9042 -f schemas/01_create_domirama2_schema.cql
--
-- SORTIE :
--   - Keyspace 'domirama2_poc' créé
--   - Table 'operations_by_account' créée avec toutes les colonnes
--   - Index SAI de base créés (idx_libelle_fulltext, idx_cat_auto, idx_cat_user, etc.)
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
WITH REPLICATION = {
  'class': 'SimpleStrategy',
  'replication_factor': 1
};

USE domirama2_poc;

-- ============================================
-- SECTION 2 : Création de la Table
-- ============================================
-- Table principale pour stocker les opérations bancaires
-- Équivalent HBase : Table 'domirama' dans namespace 'B997X04' avec RowKey = code_si:contrat:date_op:numero_op
-- Clés de partition : code_si, contrat (déterminent la partition HCD)
-- Clés de clustering : date_op, numero_op (trient les données dans la partition)
-- Conforme à la proposition IBM avec toutes les colonnes nécessaires
-- ============================================
CREATE TABLE IF NOT EXISTS operations_by_account (
    -- ============================================
    -- Clés de Partition (équivalent partie fixe du RowKey HBase)
    -- ============================================
    -- Ces colonnes déterminent dans quelle partition HCD les données sont stockées
    -- Équivalent HBase : Première partie du RowKey (code_si:contrat)
    code_si           TEXT,  -- Code système source (ex: "DEMO_OFFICIAL", "01")
    contrat           TEXT,  -- Numéro de compte/contrat (ex: "1234567890")

    -- ============================================
    -- Clés de Clustering (équivalent partie variable du RowKey HBase)
    -- ============================================
    -- Ces colonnes trient les données dans la partition (tri antichronologique)
    -- Équivalent HBase : Deuxième partie du RowKey (date_op:numero_op)
    -- Aligné avec IBM : date_op au lieu de op_date, numero_op au lieu de op_seq
    date_op           TIMESTAMP,  -- Date de l'opération (tri chronologique DESC)
    numero_op         INT,        -- Numéro séquentiel de l'opération (tri par ordre ASC)

    -- ============================================
    -- Identifiant Unique
    -- ============================================
    op_id             TEXT,  -- UUID de l'opération (généré par Spark, stocké comme TEXT pour compatibilité)

    -- ============================================
    -- Données Décodées du COBOL (colonnes normalisées)
    -- ============================================
    -- Équivalent HBase : Colonnes dans CF 'operations' avec données décodées
    libelle           TEXT,        -- Libellé de l'opération (recherche full-text)
    montant           DECIMAL,     -- Montant de l'opération
    devise            TEXT,         -- Devise (EUR, USD, etc.)
    date_valeur       TIMESTAMP,   -- Date de valeur de l'opération
    type_operation    TEXT,        -- Type d'opération (VIREMENT, PRELEVEMENT, etc.)
    sens_operation    TEXT,        -- Sens de l'opération (DEBIT ou CREDIT)

    -- ============================================
    -- Données Brutes COBOL (format BLOB conforme IBM)
    -- ============================================
    -- Équivalent HBase : Colonne dans CF 'cobol' avec format BLOB
    -- Format : Enregistrement COBOL encodé (conforme proposition IBM)
    operation_data    BLOB,        -- Données COBOL brutes (format BLOB)
    cobol_data_base64 TEXT,        -- Optionnel : données COBOL en base64 (pour compatibilité)
    copy_type         TEXT,        -- Type de copy COBOL (si plusieurs copies)

    -- ============================================
    -- Métadonnées (équivalent CF 'meta' HBase)
    -- ============================================
    -- Équivalent HBase : Colonnes dynamiques dans CF 'meta'
    -- Format MAP : Permet stockage flexible de métadonnées (équivalent colonnes dynamiques HBase)
    meta_flags        MAP<TEXT, TEXT>,  -- Métadonnées diverses (flags, tags, etc.)

    -- ============================================
    -- Colonnes de Catégorisation (Stratégie Multi-Version)
    -- ============================================
    -- IMPORTANT : Stratégie Multi-Version conforme IBM
    --   - Le BATCH écrit UNIQUEMENT cat_auto et cat_confidence
    --   - Le CLIENT écrit dans cat_user, cat_date_user, cat_validee
    --   - L'APPLICATION priorise cat_user si non nul, sinon cat_auto
    --   - Cette séparation garantit qu'aucune correction client ne sera perdue
    -- Équivalent HBase : Colonnes dans CF 'categorisation' avec logique applicative
    cat_auto          TEXT,        -- Catégorie automatique (batch) - Écrit UNIQUEMENT par le batch
    cat_confidence    DECIMAL,     -- Score de confiance du moteur (0.0 à 1.0) - NOUVEAU
    cat_user          TEXT,        -- Catégorie modifiée par client - Écrit UNIQUEMENT par l'API client
    cat_date_user     TIMESTAMP,   -- Date de modification par client - NOUVEAU
    cat_validee       BOOLEAN,     -- Acceptation par client - NOUVEAU (sans accent pour CQL)

    -- ============================================
    -- Clé Primaire Composite
    -- ============================================
    -- Format : ((partition_keys), clustering_keys)
    -- Équivalent HBase : RowKey = code_si:contrat:date_op:numero_op
    PRIMARY KEY ((code_si, contrat), date_op, numero_op)
) WITH CLUSTERING ORDER BY (date_op DESC, numero_op ASC)  -- Tri antichronologique
  AND default_time_to_live = 315360000;  -- TTL 10 ans (en secondes) - Équivalent TTL HBase

-- ============================================
-- SECTION 3 : Index SAI de Base
-- ============================================
-- Index SAI (Storage-Attached Index) pour recherche full-text
-- Équivalent HBase : Index Elasticsearch (dans l'architecture existante)
-- Avantages : Index intégré, pas de système externe nécessaire
-- ============================================

-- Index SAI Full-Text sur libellé (remplacement de Solr/Elasticsearch)
-- Conforme IBM avec analyzer français (lowercase, asciifolding, frenchLightStem)
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

-- Index SAI sur catégorie automatique (pour filtrage rapide)
-- Permet de filtrer rapidement par catégorie batch
CREATE CUSTOM INDEX IF NOT EXISTS idx_cat_auto
ON operations_by_account(cat_auto)
USING 'StorageAttachedIndex';

-- Index SAI sur catégorie client (pour filtrage rapide)
-- Permet de trouver rapidement les opérations corrigées par le client
CREATE CUSTOM INDEX IF NOT EXISTS idx_cat_user
ON operations_by_account(cat_user)
USING 'StorageAttachedIndex';

-- Index SAI sur montant (pour range queries)
-- Permet des requêtes de plage sur les montants (ex: montant < -500)
CREATE CUSTOM INDEX IF NOT EXISTS idx_montant
ON operations_by_account(montant)
USING 'StorageAttachedIndex';

-- Index SAI sur type d'opération (pour filtrage rapide)
-- Permet de filtrer rapidement par type d'opération
CREATE CUSTOM INDEX IF NOT EXISTS idx_type_operation
ON operations_by_account(type_operation)
USING 'StorageAttachedIndex';

-- ============================================
-- VÉRIFICATION
-- ============================================
-- Vérifier que le keyspace et la table ont été créés correctement
-- ============================================
DESCRIBE KEYSPACE domirama2_poc;
