-- ============================================
-- Fichier : 13_create_meta_flags_indexes.cql
-- Création des colonnes dérivées et index SAI pour meta_flags
-- ============================================
--
-- OBJECTIF :
--   Ce fichier ajoute des colonnes dérivées pour les clés MAP fréquemment utilisées
--   et crée des index SAI sur ces colonnes pour éviter ALLOW FILTERING.
--
-- CONTEXTE :
--   SAI ne supporte pas directement l'indexation des clés MAP.
--   Solution : Colonnes dérivées + Index SAI
--
-- PRÉREQUIS :
--   - Table operations_by_account doit exister
--   - HCD 1.2.3 démarré et accessible sur localhost:9042
--
-- UTILISATION :
--   cqlsh localhost 9042 -f 13_create_meta_flags_indexes.cql
--
-- ============================================

USE domiramacatops_poc;

-- ============================================
-- SECTION 1 : Ajout des colonnes dérivées
-- ============================================
-- Ces colonnes stockent les valeurs des clés MAP fréquemment utilisées
-- Elles sont mises à jour lors de l'insertion/update des données
-- ============================================

-- Colonne dérivée pour meta_flags['source']
-- Note: IF NOT EXISTS n'est pas supporté dans ALTER TABLE ADD, donc on ignore les erreurs si la colonne existe déjà
ALTER TABLE operations_by_account ADD meta_source TEXT;

-- Colonne dérivée pour meta_flags['device']
ALTER TABLE operations_by_account ADD meta_device TEXT;

-- Colonne dérivée pour meta_flags['channel']
ALTER TABLE operations_by_account ADD meta_channel TEXT;

-- Colonne dérivée pour meta_flags['fraud_score']
ALTER TABLE operations_by_account ADD meta_fraud_score TEXT;

-- Colonne dérivée pour meta_flags['ip']
ALTER TABLE operations_by_account ADD meta_ip TEXT;

-- Colonne dérivée pour meta_flags['location']
ALTER TABLE operations_by_account ADD meta_location TEXT;

-- ============================================
-- SECTION 2 : Création des index SAI
-- ============================================
-- Index SAI sur les colonnes dérivées pour filtrage rapide
-- ============================================

-- Index SAI sur meta_source
CREATE CUSTOM INDEX IF NOT EXISTS idx_meta_source
ON operations_by_account(meta_source)
USING 'StorageAttachedIndex';

-- Index SAI sur meta_device
CREATE CUSTOM INDEX IF NOT EXISTS idx_meta_device
ON operations_by_account(meta_device)
USING 'StorageAttachedIndex';

-- Index SAI sur meta_channel
CREATE CUSTOM INDEX IF NOT EXISTS idx_meta_channel
ON operations_by_account(meta_channel)
USING 'StorageAttachedIndex';

-- Index SAI sur meta_fraud_score (pour range queries si nécessaire)
CREATE CUSTOM INDEX IF NOT EXISTS idx_meta_fraud_score
ON operations_by_account(meta_fraud_score)
USING 'StorageAttachedIndex';

-- Index SAI sur meta_ip
CREATE CUSTOM INDEX IF NOT EXISTS idx_meta_ip
ON operations_by_account(meta_ip)
USING 'StorageAttachedIndex';

-- Index SAI sur meta_location
CREATE CUSTOM INDEX IF NOT EXISTS idx_meta_location
ON operations_by_account(meta_location)
USING 'StorageAttachedIndex';

-- ============================================
-- VÉRIFICATION
-- ============================================
-- Note: LIKE n'est pas supporté dans WHERE sur system_schema.indexes de cette manière
-- La vérification se fait via le script shell qui filtre les résultats
SELECT index_name FROM system_schema.indexes 
WHERE keyspace_name = 'domiramacatops_poc' 
  AND table_name = 'operations_by_account';

