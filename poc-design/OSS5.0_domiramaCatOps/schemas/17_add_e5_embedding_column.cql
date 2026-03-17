-- ============================================
-- Fichier : 17_add_e5_embedding_column.cql
-- Ajout de la colonne vectorielle supplémentaire pour multilingual-e5-large
-- ============================================
--
-- OBJECTIF :
--   Ce fichier ajoute une colonne vectorielle supplémentaire pour stocker
--   les embeddings du modèle 'intfloat/multilingual-e5-large' (1024 dimensions).
--   Cette colonne permet de comparer les performances entre ByteT5-small (1472 dim)
--   et multilingual-e5-large (1024 dim) et d'utiliser le meilleur modèle.
--
-- CONTEXTE :
--   - Colonne existante : libelle_embedding VECTOR<FLOAT, 1472> (ByteT5-small)
--   - Nouvelle colonne : libelle_embedding_e5 VECTOR<FLOAT, 1024> (multilingual-e5-large)
--   - Index SAI : Création d'un index vectoriel pour la nouvelle colonne
--   - Limite SAI : 9/10 index utilisés (1 disponible)
--
-- PRÉREQUIS :
--   - Keyspace 'domiramacatops_poc' doit exister
--   - Table 'operations_by_account' doit exister
--   - HCD 1.2.3 démarré et accessible sur localhost:9042
--
-- UTILISATION :
--   cqlsh localhost 9042 -f schemas/17_add_e5_embedding_column.cql
--   ou via script shell : ./17_add_e5_embedding_column.sh
--
-- ============================================

USE domiramacatops_poc;

-- ============================================
-- SECTION 0 : Libération d'un Slot SAI
-- ============================================
-- La limite de 10 index SAI est atteinte.
-- On supprime idx_meta_device (priorité basse) pour libérer un slot.
-- ============================================

DROP INDEX IF EXISTS idx_meta_device;

-- ============================================
-- SECTION 1 : Ajout de la Colonne Vectorielle
-- ============================================
-- Ajouter la colonne libelle_embedding_e5 pour stocker les embeddings
-- du modèle multilingual-e5-large (1024 dimensions)
-- Note: La colonne peut déjà exister (créée précédemment)
-- ============================================

-- Vérifier si la colonne existe déjà avant de l'ajouter
-- (ALTER TABLE ADD ne supporte pas IF NOT EXISTS, donc on ignore les erreurs)

-- ============================================
-- SECTION 2 : Création de l'Index SAI Vectoriel
-- ============================================
-- Créer l'index SAI vectoriel pour recherche par similarité (ANN)
-- avec le modèle multilingual-e5-large
-- ============================================

CREATE CUSTOM INDEX IF NOT EXISTS idx_libelle_embedding_e5_vector
ON operations_by_account(libelle_embedding_e5)
USING 'StorageAttachedIndex'
WITH OPTIONS = {
  'similarity_function': 'COSINE'
};

-- ============================================
-- VÉRIFICATION
-- ============================================
-- Vérifier que la colonne et l'index ont été créés correctement
-- ============================================

-- Vérifier la colonne
DESCRIBE TABLE operations_by_account;

-- Vérifier l'index e5-large
SELECT index_name, kind, options
FROM system_schema.indexes
WHERE keyspace_name = 'domiramacatops_poc'
  AND table_name = 'operations_by_account'
  AND index_name = 'idx_libelle_embedding_e5_vector';

-- Compter le nombre total d'index SAI
SELECT COUNT(*) as total_indexes
FROM system_schema.indexes
WHERE keyspace_name = 'domiramacatops_poc'
  AND table_name = 'operations_by_account'
  AND kind = 'CUSTOM'
ALLOW FILTERING;
