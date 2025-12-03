-- ============================================
-- Fichier : 02_create_operations_indexes.cql
-- Création des index SAI pour la table operations_by_account
-- ============================================
--
-- OBJECTIF :
--   Ce fichier crée tous les index SAI (Storage-Attached Index) nécessaires
--   pour la table 'operations_by_account' afin d'optimiser les recherches.
--
-- CONTEXTE HBase → HCD :
--   - Équivalent HBase : Index Elasticsearch (système externe)
--   - Avantage HCD : Index intégrés, pas de système externe nécessaire
--   - Performance : Recherche optimisée directement dans HCD
--
-- PRÉREQUIS :
--   - Keyspace 'domiramacatops_poc' doit exister
--   - Table 'operations_by_account' doit exister
--   - HCD 1.2.3 démarré et accessible sur localhost:9042
--
-- UTILISATION :
--   cqlsh localhost 9042 -f 02_create_operations_indexes.cql
--   ou via script shell : ./04_create_indexes.sh
--
-- ============================================

USE domiramacatops_poc;

-- ============================================
-- SECTION 1 : Index SAI Full-Text sur libellé
-- ============================================
-- Index full-text avec analyzers français pour recherche avancée
-- Équivalent HBase : Index Elasticsearch avec analyzers français
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
-- SECTION 2 : Index SAI N-Gram sur libelle_prefix
-- ============================================
-- Index N-Gram pour recherche partielle (autocomplétion)
-- Permet recherche avec CONTAINS sur préfixes
-- ============================================

CREATE CUSTOM INDEX IF NOT EXISTS idx_libelle_prefix_ngram
ON operations_by_account(libelle_prefix)
USING 'StorageAttachedIndex';

-- ============================================
-- SECTION 3 : Index SAI Collection sur libelle_tokens
-- ============================================
-- Index sur collection SET<TEXT> pour recherche partielle avec CONTAINS
-- Permet recherche de tokens/N-Grams dans le SET
-- ============================================

CREATE CUSTOM INDEX IF NOT EXISTS idx_libelle_tokens
ON operations_by_account(libelle_tokens)
USING 'StorageAttachedIndex';

-- ============================================
-- SECTION 4 : Index SAI Vector Search sur libelle_embedding
-- ============================================
-- Index vectoriel pour recherche sémantique (ANN - Approximate Nearest Neighbor)
-- Utilise les embeddings ByteT5 (1472 dimensions)
-- Permet fuzzy search et recherche sémantique
-- ============================================

CREATE CUSTOM INDEX IF NOT EXISTS idx_libelle_embedding_vector
ON operations_by_account(libelle_embedding)
USING 'StorageAttachedIndex'
WITH OPTIONS = {
  'similarity_function': 'COSINE'
};

-- ============================================
-- SECTION 5 : Index SAI sur Catégories
-- ============================================
-- Index pour filtrage rapide par catégorie
-- ============================================

-- Index sur catégorie automatique (batch)
CREATE CUSTOM INDEX IF NOT EXISTS idx_cat_auto
ON operations_by_account(cat_auto)
USING 'StorageAttachedIndex';

-- Index sur catégorie utilisateur (client)
CREATE CUSTOM INDEX IF NOT EXISTS idx_cat_user
ON operations_by_account(cat_user)
USING 'StorageAttachedIndex';

-- ============================================
-- SECTION 6 : Index SAI sur Autres Colonnes
-- ============================================
-- Index pour filtrage rapide sur montant et type d'opération
-- ============================================

-- Index sur montant (pour range queries)
CREATE CUSTOM INDEX IF NOT EXISTS idx_montant
ON operations_by_account(montant)
USING 'StorageAttachedIndex';

-- Index sur type d'opération (pour filtrage rapide)
CREATE CUSTOM INDEX IF NOT EXISTS idx_type_operation
ON operations_by_account(type_operation)
USING 'StorageAttachedIndex';

-- ============================================
-- VÉRIFICATION
-- ============================================
-- Vérifier que tous les index ont été créés correctement
-- ============================================
SELECT index_name FROM system_schema.indexes
WHERE keyspace_name = 'domiramacatops_poc'
  AND table_name = 'operations_by_account';
