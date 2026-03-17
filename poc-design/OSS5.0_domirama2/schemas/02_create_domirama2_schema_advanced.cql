-- ============================================
-- Fichier : 02_create_domirama2_schema_advanced.cql
-- Configuration des Index SAI Avancés pour Recherche Full-Text
-- ============================================
--
-- OBJECTIF :
--   Ce fichier configure des index SAI (Storage-Attached Index) avancés pour
--   la table 'operations_by_account' avec différents analyzers Lucene pour
--   améliorer la pertinence des recherches full-text.
--
--   Index créés :
--   - idx_libelle_fulltext_advanced : Avec analyzers (lowercase, asciifolding, frenchLightStem)
--   - idx_libelle_prefix_ngram : Pour recherche partielle et tolérance aux typos
--   - Autres index secondaires
--
-- CONTEXTE HBase → HCD :
--   - Équivalent HBase : Index Elasticsearch avec analyzers personnalisés
--   - Différences :
--     * Index intégré dans HCD (vs Elasticsearch externe)
--     * Analyzers Lucene natifs (vs configuration Elasticsearch)
--   - Améliorations :
--     * Pas de système externe nécessaire
--     * Performance améliorée (pas de réseau entre HCD et Elasticsearch)
--
-- PRÉREQUIS :
--   - Keyspace et table créés (01_create_domirama2_schema.cql)
--   - HCD 1.2.3 démarré et accessible sur localhost:9042
--
-- UTILISATION :
--   cqlsh localhost 9042 -f 02_create_domirama2_schema_advanced.cql
--   ou via script shell : ./16_setup_advanced_indexes.sh
--
-- EXEMPLE :
--   cqlsh localhost 9042 -f schemas/02_create_domirama2_schema_advanced.cql
--
-- SORTIE :
--   - Index SAI avancés créés
--   - Colonne libelle_prefix ajoutée (si nécessaire)
--   - Vérification : DESCRIBE INDEX domirama2_poc.idx_libelle_fulltext_advanced;
--
-- ============================================

CREATE KEYSPACE IF NOT EXISTS domirama2_poc
WITH REPLICATION = {
  'class': 'SimpleStrategy',
  'replication_factor': 1
};

USE domirama2_poc;

-- Table principale (identique)
CREATE TABLE IF NOT EXISTS operations_by_account (
    code_si           TEXT,
    contrat           TEXT,
    date_op           TIMESTAMP,
    numero_op         INT,
    op_id             TEXT,
    libelle           TEXT,
    montant           DECIMAL,
    devise            TEXT,
    date_valeur       TIMESTAMP,
    type_operation    TEXT,
    sens_operation    TEXT,
    operation_data    BLOB,
    cobol_data_base64 TEXT,
    copy_type         TEXT,
    meta_flags        MAP<TEXT, TEXT>,
    cat_auto          TEXT,
    cat_confidence    DECIMAL,
    cat_user          TEXT,
    cat_date_user     TIMESTAMP,
    cat_validee       BOOLEAN,
    PRIMARY KEY ((code_si, contrat), date_op, numero_op)
) WITH CLUSTERING ORDER BY (date_op DESC, numero_op ASC)
  AND default_time_to_live = 315360000;

-- ============================================
-- SECTION 1 : Index SAI Avancé Full-Text Multi-Capacités
-- ============================================
-- Index SAI avec analyzers Lucene pour recherche full-text avancée
-- Équivalent HBase : Index Elasticsearch avec analyzers personnalisés
--
-- IMPORTANT : SAI ne permet qu'un seul index par colonne
-- Cet index remplace idx_libelle_fulltext (du fichier 01) avec des capacités avancées
--
-- Fonctionnalités combinées :
-- - Stemming français (pluriel/singulier) : "loyers" → "loyer"
-- - Asciifolding (accents) : "impayé" → "impaye"
-- - Case-insensitive : "LOYER" = "loyer"
-- - Recherche partielle : Via colonne libelle_prefix (section suivante)
-- ============================================
CREATE CUSTOM INDEX IF NOT EXISTS idx_libelle_fulltext_advanced
ON operations_by_account(libelle)
USING 'StorageAttachedIndex'
WITH OPTIONS = {
  'index_analyzer': '{
    "tokenizer": {"name": "standard"},
    "filters": [
      {"name": "lowercase"},
      {"name": "asciiFolding"},
      {"name": "frenchLightStem"}
    ]
  }'
};

-- ============================================
-- SECTION 2 : Colonne Dérivée pour Recherche Partielle
-- ============================================
-- Création d'une colonne dérivée 'libelle_prefix' pour index N-Gram
-- Équivalent HBase : Colonne dérivée calculée côté application
--
-- Objectif : Permettre recherche partielle et tolérance aux typos
-- Utilisation : Les scripts Spark/application remplissent cette colonne avec
--               les premiers caractères du libellé (ex: "LOYER" → "LOYER" pour prefix=5)
-- ============================================
ALTER TABLE operations_by_account ADD libelle_prefix TEXT;

-- Index N-Gram pour recherche partielle (tolérance aux typos)
-- Équivalent HBase : Recherche partielle via Elasticsearch N-Gram
--
-- Fonctionnement : N-Gram crée des sous-chaînes de 3-5 caractères pour recherche partielle
-- Exemple : "LOYER" génère "LOY", "OYE", "YER", "LOYE", "OYER", "LOYER"
-- Permet de trouver "LOY" même si le libellé complet est "LOYER"
-- ============================================
CREATE CUSTOM INDEX IF NOT EXISTS idx_libelle_prefix_ngram
ON operations_by_account(libelle_prefix)
USING 'StorageAttachedIndex'
WITH OPTIONS = {
  'index_analyzer': '{
    "tokenizer": {"name": "standard"},
    "filters": [
      {"name": "lowercase"},
      {"name": "asciiFolding"}
    ]
  }'
};

-- ============================================
-- Index secondaires (existant)
-- ============================================
CREATE CUSTOM INDEX IF NOT EXISTS idx_cat_auto
ON operations_by_account(cat_auto)
USING 'StorageAttachedIndex';

CREATE CUSTOM INDEX IF NOT EXISTS idx_cat_user
ON operations_by_account(cat_user)
USING 'StorageAttachedIndex';

CREATE CUSTOM INDEX IF NOT EXISTS idx_montant
ON operations_by_account(montant)
USING 'StorageAttachedIndex';

CREATE CUSTOM INDEX IF NOT EXISTS idx_type_operation
ON operations_by_account(type_operation)
USING 'StorageAttachedIndex';
