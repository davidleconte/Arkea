-- ============================================
-- Fichier : 13_create_meta_flags_map_indexes.cql
-- Création des index SAI sur KEYS et VALUES de meta_flags
-- ============================================
--
-- OBJECTIF :
--   Créer des index SAI sur les clés et valeurs du MAP meta_flags
--   pour permettre CONTAINS KEY et CONTAINS côté base de données
--   (sans filtrage côté application).
--
-- CONTEXTE :
--   - CONTAINS KEY nécessite un index SAI sur KEYS(meta_flags)
--   - CONTAINS nécessite un index SAI sur VALUES(meta_flags)
--   - Ces index permettent de résoudre les requêtes côté base de données
--
-- AVANTAGES :
--   - ✅ Performance optimale (index SAI distribué)
--   - ✅ Pas de filtrage côté application
--   - ✅ Scalabilité sur grand volume
--   - ✅ Pas d'ALLOW FILTERING nécessaire
--
-- LIMITE :
--   - ⚠️  Maximum 10 index SAI par table
--   - ✅ État actuel : 7 index (3 places disponibles)
--   - ✅ Après création : 9 index (1 place disponible)
--
-- UTILISATION :
--   cqlsh localhost 9042 -f schemas/13_create_meta_flags_map_indexes.cql
--   ou via script shell : ./13_create_meta_flags_map_indexes.sh
--
-- ============================================

USE domiramacatops_poc;

-- ============================================
-- SECTION 1 : Index SAI sur KEYS(meta_flags)
-- ============================================
-- Permet : WHERE meta_flags CONTAINS KEY 'ip'
-- ============================================

CREATE CUSTOM INDEX IF NOT EXISTS idx_meta_flags_keys
ON operations_by_account(KEYS(meta_flags))
USING 'StorageAttachedIndex';

-- ============================================
-- SECTION 2 : Index SAI sur VALUES(meta_flags)
-- ============================================
-- Permet : WHERE meta_flags CONTAINS 'paris'
-- ============================================

CREATE CUSTOM INDEX IF NOT EXISTS idx_meta_flags_values
ON operations_by_account(VALUES(meta_flags))
USING 'StorageAttachedIndex';

-- ============================================
-- VÉRIFICATION
-- ============================================

SELECT index_name, kind, options 
FROM system_schema.indexes 
WHERE keyspace_name = 'domiramacatops_poc' 
  AND table_name = 'operations_by_account'
  AND index_name IN ('idx_meta_flags_keys', 'idx_meta_flags_values');


