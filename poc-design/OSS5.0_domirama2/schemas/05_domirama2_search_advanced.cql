-- ============================================
-- Fichier : 05_domirama2_search_advanced.cql
-- Tests de Recherche Full-Text Avancés avec Index SAI
-- ============================================
--
-- OBJECTIF :
--   Ce fichier contient des tests de recherche full-text avancés en utilisant
--   les index SAI avec différents analyzers configurés dans le fichier 02.
--
--   Les tests démontrent :
--   - Recherches avec analyzers (lowercase, asciifolding, frenchLightStem)
--   - Recherches combinées (libellé + catégorie)
--   - Performance des index SAI
--   - Pertinence des résultats
--
-- CONTEXTE HBase → HCD :
--   - Équivalent HBase : Requêtes HBase avec filtres + recherche Elasticsearch avancée
--   - Différences :
--     * Recherche full-text intégrée (vs Elasticsearch externe)
--     * Analyzers Lucene natifs (vs configuration Elasticsearch)
--   - Améliorations :
--     * Pas de système externe nécessaire
--     * Performance améliorée (pas de réseau)
--
-- PRÉREQUIS :
--   - Keyspace et table créés (01_create_domirama2_schema.cql)
--   - Index avancés configurés (02_create_domirama2_schema_advanced.cql)
--   - Données chargées dans la table
--
-- UTILISATION :
--   cqlsh localhost 9042 -f 05_domirama2_search_advanced.cql
--   ou via script shell : ./17_test_advanced_search.sh
--
-- EXEMPLE :
--   cqlsh localhost 9042 -f schemas/05_domirama2_search_advanced.cql
--
-- SORTIE :
--   - Résultats des tests de recherche avancés affichés
--   - Comparaison des performances avec/sans index
--   - Validation de la pertinence des résultats
--
-- ============================================

USE domirama2_poc;

-- ============================================
-- Test 1 : Recherche avec stemming français (idx_libelle_fulltext)
-- ============================================
-- Trouve "loyers", "loyer", "loyé" grâce au stemming
SELECT code_si, contrat, libelle, montant, cat_auto
FROM operations_by_account
WHERE code_si = '1'
  AND contrat = '5913101072'
  AND libelle : 'loyers'  -- Pluriel → trouve "LOYER"
LIMIT 5;

-- ============================================
-- Test 2 : Recherche exacte (idx_libelle_exact)
-- ============================================
-- Pour noms propres et codes exacts
SELECT code_si, contrat, libelle, montant
FROM operations_by_account
WHERE code_si = '1'
  AND contrat = '5913101072'
  AND libelle : 'CARREFOUR'  -- Exact match
LIMIT 5;

-- ============================================
-- Test 3 : Recherche de phrase complète (idx_libelle_keyword)
-- ============================================
-- Pour phrases exactes
SELECT code_si, contrat, libelle, montant
FROM operations_by_account
WHERE code_si = '1'
  AND contrat = '5913101072'
  AND libelle : 'PAIEMENT PAR CARTE BANCAIRE'
LIMIT 5;

-- ============================================
-- Test 4 : Recherche partielle avec fall-back (libelle → libelle_tokens)
-- ============================================
-- Pour typos et recherches partielles
-- Stratégie : Essayer d'abord libelle (terme complet), puis fall-back sur libelle_tokens (collection)
-- "carref" (partiel) trouve "CARREFOUR" via fall-back sur libelle_tokens CONTAINS
SELECT code_si, contrat, libelle, montant
FROM operations_by_account
WHERE code_si = '1'
  AND contrat = '5913101072'
  AND libelle : 'carref'  -- Partiel → aucun résultat, déclenche fall-back sur libelle_tokens
LIMIT 5;

-- ============================================
-- Test 5 : Recherche multi-termes complexes
-- ============================================
-- Combinaison de plusieurs termes avec stemming
SELECT code_si, contrat, libelle, montant, cat_auto
FROM operations_by_account
WHERE code_si = '1'
  AND contrat = '5913101072'
  AND libelle : 'virement'
  AND libelle : 'permanent'
  AND libelle : 'mensuel'
LIMIT 5;

-- ============================================
-- Test 6 : Recherche avec stop words (idx_libelle_french)
-- ============================================
-- Ignore "de", "du", "des", "le", "la", "les"
SELECT code_si, contrat, libelle, montant
FROM operations_by_account
WHERE code_si = '1'
  AND contrat = '5913101072'
  AND libelle : 'banque'
  AND libelle : 'paris'
LIMIT 5;

-- ============================================
-- Test 7 : Recherche avec accents et asciifolding
-- ============================================
-- "impayé" → trouve "IMPAYE"
SELECT code_si, contrat, libelle, montant
FROM operations_by_account
WHERE code_si = '1'
  AND contrat = '5913101072'
  AND libelle : 'impayé'  -- Avec accent
  AND libelle : 'régularisation'  -- Avec accent
LIMIT 5;

-- ============================================
-- Test 8 : Recherche triple terme avec proximité
-- ============================================
SELECT code_si, contrat, libelle, montant, cat_auto
FROM operations_by_account
WHERE code_si = '1'
  AND contrat = '5913101072'
  AND libelle : 'prelevement'
  AND libelle : 'automatique'
  AND libelle : 'facture'
LIMIT 5;

-- ============================================
-- Test 9 : Recherche avec filtre montant
-- ============================================
SELECT code_si, contrat, libelle, montant, cat_auto
FROM operations_by_account
WHERE code_si = '1'
  AND contrat = '5913101072'
  AND libelle : 'loyer'
  AND libelle : 'paris'
  AND montant < -1000
LIMIT 5;

-- ============================================
-- Test 10 : Recherche avec filtre catégorie
-- ============================================
SELECT code_si, contrat, libelle, montant, cat_auto
FROM operations_by_account
WHERE code_si = '1'
  AND contrat = '5913101072'
  AND libelle : 'virement'
  AND libelle : 'impaye'
  AND cat_auto = 'VIREMENT'
LIMIT 5;

-- ============================================
-- Test 11 : Recherche avec filtre type opération
-- ============================================
SELECT code_si, contrat, libelle, montant, type_operation
FROM operations_by_account
WHERE code_si = '1'
  AND contrat = '5913101072'
  AND libelle : 'prelevement'
  AND type_operation = 'PRELEVEMENT'
LIMIT 5;

-- ============================================
-- Test 12 : Recherche avec date (range)
-- ============================================
SELECT code_si, contrat, libelle, montant, date_op
FROM operations_by_account
WHERE code_si = '1'
  AND contrat = '5913101072'
  AND libelle : 'loyer'
  AND date_op >= '2024-01-01'
  AND date_op < '2025-01-01'
LIMIT 5;

-- ============================================
-- Test 13 : Recherche complexe multi-critères
-- ============================================
SELECT code_si, contrat, libelle, montant, cat_auto, type_operation
FROM operations_by_account
WHERE code_si = '1'
  AND contrat = '5913101072'
  AND libelle : 'virement'
  AND libelle : 'sepa'
  AND cat_auto = 'VIREMENT'
  AND type_operation = 'VIREMENT'
  AND montant > 0
LIMIT 5;

-- ============================================
-- Test 14 : Recherche avec variations (stemming)
-- ============================================
-- Teste le stemming français avancé
SELECT code_si, contrat, libelle, montant
FROM operations_by_account
WHERE code_si = '1'
  AND contrat = '5913101072'
  AND libelle : 'prelevements'  -- Pluriel → trouve "PRELEVEMENT"
LIMIT 5;

-- ============================================
-- Test 15 : Recherche avec noms propres
-- ============================================
-- Noms propres sans stemming
SELECT code_si, contrat, libelle, montant
FROM operations_by_account
WHERE code_si = '1'
  AND contrat = '5913101072'
  AND libelle : 'EDF'
  AND libelle : 'ORANGE'
LIMIT 5;

-- ============================================
-- Test 16 : Recherche avec codes et numéros
-- ============================================
SELECT code_si, contrat, libelle, montant
FROM operations_by_account
WHERE code_si = '1'
  AND contrat = '5913101072'
  AND libelle : '1234567890'  -- Numéro de chèque
LIMIT 5;

-- ============================================
-- Test 17 : Recherche avec abréviations
-- ============================================
SELECT code_si, contrat, libelle, montant
FROM operations_by_account
WHERE code_si = '1'
  AND contrat = '5913101072'
  AND libelle : 'DAB'
  AND libelle : 'SEPA'
LIMIT 5;

-- ============================================
-- Test 18 : Recherche avec localisation précise
-- ============================================
SELECT code_si, contrat, libelle, montant
FROM operations_by_account
WHERE code_si = '1'
  AND contrat = '5913101072'
  AND libelle : 'paris'
  AND libelle : '15eme'
  AND libelle : '16eme'
LIMIT 5;

-- ============================================
-- Test 19 : Recherche avec termes techniques
-- ============================================
SELECT code_si, contrat, libelle, montant
FROM operations_by_account
WHERE code_si = '1'
  AND contrat = '5913101072'
  AND libelle : 'contactless'
  AND libelle : 'instantané'
LIMIT 5;

-- ============================================
-- Test 20 : Recherche avec combinaison complexe
-- ============================================
SELECT code_si, contrat, libelle, montant, cat_auto, type_operation, date_op
FROM operations_by_account
WHERE code_si = '1'
  AND contrat = '5913101072'
  AND libelle : 'virement'
  AND libelle : 'permanent'
  AND cat_auto = 'VIREMENT'
  AND type_operation = 'VIREMENT'
  AND montant < 0
  AND date_op >= '2023-01-01'
LIMIT 10;
