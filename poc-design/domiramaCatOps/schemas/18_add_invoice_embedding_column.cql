-- ============================================
-- Fichier : 18_add_invoice_embedding_column.cql
-- Ajout de la colonne vectorielle pour modèle spécialisé facturation
-- ============================================
--
-- OBJECTIF :
--   Ce fichier ajoute une colonne vectorielle supplémentaire pour stocker
--   les embeddings du modèle 'NoureddineSa/Invoices_bilingual-embedding-large' (1024 dimensions).
--   Ce modèle est spécialisé dans la facturation et devrait être plus pertinent
--   pour les libellés bancaires (LOYER, VIREMENT, TAXE, etc.).
--
-- CONTEXTE :
--   - Colonne existante : libelle_embedding VECTOR<FLOAT, 1472> (ByteT5-small)
--   - Colonne existante : libelle_embedding_e5 VECTOR<FLOAT, 1024> (multilingual-e5-large)
--   - Nouvelle colonne : libelle_embedding_invoice VECTOR<FLOAT, 1024> (Invoices_bilingual-embedding-large)
--   - Index SAI : Création d'un index vectoriel pour la nouvelle colonne
--   - Limite SAI : 10/10 index utilisés (nécessite suppression d'1 index)
--
-- PRÉREQUIS :
--   - Keyspace 'domiramacatops_poc' doit exister
--   - Table 'operations_by_account' doit exister
--   - HCD 1.2.3 démarré et accessible sur localhost:9042
--
-- UTILISATION :
--   cqlsh localhost 9042 -f schemas/18_add_invoice_embedding_column.cql
--   ou via script shell : ./18_add_invoice_embedding_column.sh
--
-- ============================================

USE domiramacatops_poc;

-- ============================================
-- SECTION 0 : Libération d'un Slot SAI
-- ============================================
-- La limite de 10 index SAI est atteinte.
-- On supprime idx_meta_source (priorité basse) pour libérer un slot.
-- ============================================

DROP INDEX IF EXISTS idx_meta_source;

-- ============================================
-- SECTION 1 : Ajout de la Colonne Vectorielle
-- ============================================
-- Ajouter la colonne libelle_embedding_invoice pour stocker les embeddings
-- du modèle Invoices_bilingual-embedding-large (1024 dimensions)
-- Note: La colonne peut déjà exister (créée précédemment)
-- ============================================

ALTER TABLE operations_by_account ADD libelle_embedding_invoice VECTOR<FLOAT, 1024>;

-- ============================================
-- SECTION 2 : Création de l'Index SAI Vectoriel
-- ============================================
-- Créer l'index SAI vectoriel pour recherche par similarité (ANN)
-- avec le modèle Invoices_bilingual-embedding-large
-- ============================================

CREATE CUSTOM INDEX IF NOT EXISTS idx_libelle_embedding_invoice_vector
ON operations_by_account(libelle_embedding_invoice)
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

-- Vérifier l'index invoice
SELECT index_name, kind, options
FROM system_schema.indexes
WHERE keyspace_name = 'domiramacatops_poc'
  AND table_name = 'operations_by_account'
  AND index_name = 'idx_libelle_embedding_invoice_vector';

-- Compter le nombre total d'index SAI
SELECT COUNT(*) as total_indexes
FROM system_schema.indexes
WHERE keyspace_name = 'domiramacatops_poc'
  AND table_name = 'operations_by_account'
  AND kind = 'CUSTOM'
ALLOW FILTERING;
