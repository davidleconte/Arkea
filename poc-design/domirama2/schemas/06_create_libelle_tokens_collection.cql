-- ============================================
-- Fichier : 06_create_libelle_tokens_collection.cql
-- Ajout d'une colonne collection pour recherche partielle avec CONTAINS
-- ============================================
--
-- OBJECTIF :
--   Ajouter une colonne libelle_tokens (SET<TEXT>) pour stocker tous les
--   ngrams (sous-chaînes) du libellé, permettant une vraie recherche partielle
--   avec l'opérateur CONTAINS.
--
-- CONTEXTE :
--   - SAI ne supporte pas nativement les filtres N-Gram sur colonnes TEXT
--   - CONTAINS fonctionne uniquement sur les collections (SET, LIST, MAP)
--   - Solution : Stocker les ngrams dans une SET<TEXT> et utiliser CONTAINS
--
-- AVANTAGES :
--   - ✅ Vraie recherche partielle : "carref" trouve "CARREFOUR"
--   - ✅ Utilise CONTAINS (supporté nativement par SAI sur collections)
--   - ✅ Pas besoin d'analyzer personnalisé
--   - ✅ Performance : Index SAI standard sur collection
--
-- INCONVÉNIENTS :
--   - ⚠️ Stockage supplémentaire (tous les ngrams)
--   - ⚠️ Génération des ngrams côté application (Spark/Java)
--
-- UTILISATION :
--   cqlsh localhost 9042 -f schemas/06_create_libelle_tokens_collection.cql
--
-- ============================================

USE domirama2_poc;

-- Ajouter la colonne collection pour les tokens/ngrams
ALTER TABLE operations_by_account ADD libelle_tokens SET<TEXT>;

-- Créer un index SAI sur la collection pour permettre CONTAINS
CREATE CUSTOM INDEX IF NOT EXISTS idx_libelle_tokens
ON operations_by_account(libelle_tokens)
USING 'StorageAttachedIndex';

-- ============================================
-- Exemple d'utilisation :
-- ============================================
-- 
-- 1. Insertion avec tokens (générés côté application) :
-- INSERT INTO operations_by_account (
--     code_si, contrat, date_op, numero_op, op_id,
--     libelle, libelle_tokens, montant, ...
-- ) VALUES (
--     '1', '5913101072', '2024-11-16', 1002, 'op_001',
--     'CB CARREFOUR MARKET PARIS',
--     {'cb', 'car', 'carref', 'carrefour', 'market', 'paris', 'cbc', 'bca', ...},  -- Ngrams
--     -28.90, ...
-- );
--
-- 2. Recherche partielle avec CONTAINS :
-- SELECT * FROM operations_by_account
-- WHERE code_si = '1' AND contrat = '5913101072'
--   AND libelle_tokens CONTAINS 'carref';  -- Trouve "CARREFOUR" !
--
-- ============================================


