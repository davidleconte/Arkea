-- ============================================
-- Fichier : 01_create_domiramaCatOps_schema.cql
-- Création du keyspace et de la table operations_by_account
-- ============================================
--
-- OBJECTIF :
--   Ce fichier crée le keyspace 'domiramacatops_poc' et la table 'operations_by_account'
--   avec toutes les colonnes nécessaires pour la catégorisation des opérations.
--   Il implémente la stratégie multi-version (batch vs client) conforme à la
--   proposition IBM pour garantir qu'aucune correction client ne soit perdue.
--
-- CONTEXTE HBase → HCD :
--   - Équivalent HBase : Table 'domirama' dans namespace 'B997X04' avec Column Family 'category'
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
--   cqlsh localhost 9042 -f 01_create_domiramaCatOps_schema.cql
--   ou via script shell : ./01_setup_domiramaCatOps_keyspace.sh
--
-- ============================================

-- ============================================
-- SECTION 1 : Création du Keyspace
-- ============================================
-- Le keyspace est l'équivalent d'un namespace HBase
-- Réplication : SimpleStrategy avec replication_factor=1 (POC local)
-- En production : NetworkTopologyStrategy avec réplication par datacenter
-- ============================================

CREATE KEYSPACE IF NOT EXISTS domiramacatops_poc
WITH REPLICATION = {
  'class': 'SimpleStrategy',
  'replication_factor': 1
};

USE domiramacatops_poc;

-- ============================================
-- SECTION 2 : Création de la Table operations_by_account
-- ============================================
-- Table principale pour stocker les opérations bancaires avec catégorisation
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
    code_si           TEXT,  -- Code système source (ex: "01", "02")
    contrat           TEXT,  -- Numéro de compte/contrat (ex: "1234567890")
    
    -- ============================================
    -- Clés de Clustering (équivalent partie variable du RowKey HBase)
    -- ============================================
    -- Ces colonnes trient les données dans la partition (tri antichronologique)
    -- Équivalent HBase : Deuxième partie du RowKey (date_op:numero_op)
    date_op           TIMESTAMP,  -- Date de l'opération (tri chronologique DESC)
    numero_op         INT,        -- Numéro séquentiel de l'opération (tri par ordre ASC)
    
    -- ============================================
    -- Données de l'Opération
    -- ============================================
    -- Équivalent HBase : Colonnes dans CF 'operations' avec données décodées
    libelle           TEXT,        -- Libellé de l'opération (recherche full-text)
    montant           DECIMAL,     -- Montant de l'opération
    devise            TEXT,        -- Devise (EUR, USD, etc.)
    date_valeur       TIMESTAMP,   -- Date de valeur de l'opération
    type_operation    TEXT,        -- Type d'opération (VIREMENT, PRELEVEMENT, CB, etc.)
    sens_operation    TEXT,        -- Sens de l'opération (DEBIT ou CREDIT)
    
    -- ============================================
    -- Données Thrift Binaires
    -- ============================================
    -- Équivalent HBase : Colonne dans CF 'category' avec données Thrift encodées en binaire
    -- Format : Données Thrift encodées en binaire (préservation de l'intégrité)
    operation_data    BLOB,        -- Données Thrift encodées en binaire
    
    -- ============================================
    -- Colonnes Dynamiques
    -- ============================================
    -- Équivalent HBase : Colonnes dynamiques dans CF 'meta'
    -- Format MAP : Permet stockage flexible de métadonnées (équivalent colonnes dynamiques HBase)
    meta_flags        MAP<TEXT, TEXT>,  -- Métadonnées diverses (flags, tags, etc.)
    
    -- ============================================
    -- Colonnes de Recherche Avancée (Conforme Domirama2)
    -- ============================================
    -- Ces colonnes permettent les recherches avancées : full-text, vector, hybrid, fuzzy
    -- Conforme aux fonctionnalités validées dans domirama2
    libelle_prefix    TEXT,        -- Préfixe pour recherche partielle (N-Gram)
    libelle_tokens    SET<TEXT>,   -- Tokens/N-Grams pour recherche partielle avec CONTAINS
    libelle_embedding VECTOR<FLOAT, 1472>,  -- Embeddings ByteT5 pour recherche vectorielle
    
    -- ============================================
    -- Colonnes de Catégorisation (Stratégie Multi-Version)
    -- ============================================
    -- IMPORTANT : Stratégie Multi-Version conforme IBM
    --   - Le BATCH écrit UNIQUEMENT cat_auto et cat_confidence
    --   - Le CLIENT écrit dans cat_user, cat_date_user, cat_validee
    --   - L'APPLICATION priorise cat_user si non nul, sinon cat_auto
    --   - Cette séparation garantit qu'aucune correction client ne sera perdue
    -- Équivalent HBase : Colonnes dans CF 'category' avec logique applicative
    cat_auto          TEXT,        -- Catégorie automatique (batch) - Écrit UNIQUEMENT par le batch
    cat_confidence    DECIMAL,     -- Score de confiance du moteur (0.0 à 1.0)
    cat_user          TEXT,        -- Catégorie modifiée par client - Écrit UNIQUEMENT par l'API client
    cat_date_user     TIMESTAMP,   -- Date de modification par client
    cat_validee       BOOLEAN,     -- Acceptation par client
    
    -- ============================================
    -- Métadonnées d'Ingestion
    -- ============================================
    -- Ces colonnes permettent de tracer l'origine et le moment d'ingestion des données
    -- Utiles pour : traçabilité, audit, reprise après crash, debugging
    ingestion_timestamp TIMESTAMP,  -- Timestamp d'ingestion (temps réel ou batch)
    ingestion_source    TEXT,       -- Source d'ingestion ('batch_parquet', 'kafka_corrections', 'kafka_categories', etc.)
    ingestion_batch_id   BIGINT,     -- ID du micro-batch Spark (pour traçabilité et reprise)
    
    -- ============================================
    -- Clé Primaire Composite
    -- ============================================
    -- Format : ((partition_keys), clustering_keys)
    -- Équivalent HBase : RowKey = code_si:contrat:date_op:numero_op
    PRIMARY KEY ((code_si, contrat), date_op, numero_op)
) WITH CLUSTERING ORDER BY (date_op DESC, numero_op ASC)  -- Tri antichronologique
  AND default_time_to_live = 315619200;  -- TTL 10 ans (en secondes) - Équivalent TTL HBase

-- ============================================
-- VÉRIFICATION
-- ============================================
-- Vérifier que le keyspace et la table ont été créés correctement
-- ============================================
DESCRIBE KEYSPACE domiramacatops_poc;

