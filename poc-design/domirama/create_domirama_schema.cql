-- ============================================
-- Schéma CQL pour le POC Domirama
-- Migration de B997X04:domirama (HBase) vers HCD
-- ============================================

-- Créer le keyspace
CREATE KEYSPACE IF NOT EXISTS domirama_poc
WITH REPLICATION = {
  'class': 'SimpleStrategy',
  'replication_factor': 1
};

USE domirama_poc;

-- Table principale : operations_by_account
-- Remplace la table HBase B997X04:domirama
CREATE TABLE IF NOT EXISTS operations_by_account (
    -- Partition Key (regroupe toutes les opérations d'un compte)
    code_si           TEXT,
    contrat           TEXT,
    
    -- Clustering Keys (tri antichronologique)
    op_date           TIMESTAMP,
    op_seq            INT,
    
    -- Identifiant unique
    op_id             TEXT,  -- UUID stocké comme TEXT pour compatibilité Spark
    
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

-- Index SAI Full-Text sur libellé (remplacement de Solr)
-- Syntaxe correcte pour HCD 1.2
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

-- Index SAI sur catégorie automatique (optionnel)
CREATE CUSTOM INDEX IF NOT EXISTS idx_cat_auto 
ON operations_by_account(cat_auto)
USING 'StorageAttachedIndex';

-- Index SAI sur montant (pour range queries)
CREATE CUSTOM INDEX IF NOT EXISTS idx_montant 
ON operations_by_account(montant)
USING 'StorageAttachedIndex';

-- Index SAI sur type d'opération
CREATE CUSTOM INDEX IF NOT EXISTS idx_type_operation 
ON operations_by_account(type_operation)
USING 'StorageAttachedIndex';

-- Vérification
DESCRIBE KEYSPACE domirama_poc;

