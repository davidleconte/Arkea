-- ============================================
-- Fichier : 08_category_search_test.cql
-- Tests de Recherche par Catégorie avec Index SAI
-- ============================================
--
-- OBJECTIF :
--   Ce fichier contient une série de tests de recherche par catégorie sur la table
--   'operations_by_account' en utilisant les index SAI (Storage-Attached Index).
--   
--   Les tests couvrent :
--   - Recherche par catégorie automatique (cat_auto)
--   - Recherche par catégorie client (cat_user)
--   - Recherche combinée (cat_auto OU cat_user)
--   - Recherche avec score de confiance
--   - Recherche avec filtres additionnels (montant, type_operation)
--   - Vérification de la stratégie multi-version
--
-- CONTEXTE HBase → HCD :
--   - Équivalent HBase : SCAN avec filtres + recherche Elasticsearch
--   - Différences :
--     * Recherche intégrée (vs Elasticsearch externe)
--     * Syntaxe CQL avec WHERE (vs filtres HBase)
--   - Améliorations :
--     * Pas de système externe nécessaire
--     * Performance améliorée (pas de réseau)
--
-- PRÉREQUIS :
--   - Keyspace et table créés
--   - Données chargées dans la table
--   - Index SAI créés
--
-- UTILISATION :
--   cqlsh localhost 9042 -f 08_category_search_test.cql
--   ou via script shell : ./08_test_category_search.sh
--
-- ============================================

USE domiramacatops_poc;

-- ============================================
-- TEST 1 : Recherche par catégorie automatique
-- ============================================
-- Équivalent HBase : SCAN avec filter sur cat_auto
SELECT code_si, contrat, date_op, numero_op, libelle, montant, cat_auto, cat_confidence
FROM operations_by_account
WHERE code_si = '1'
  AND contrat = '100000000'
  AND cat_auto = 'ALIMENTATION'
LIMIT 10;

-- ============================================
-- TEST 2 : Recherche par catégorie client
-- ============================================
-- Équivalent HBase : SCAN avec filter sur cat_user
SELECT code_si, contrat, date_op, numero_op, libelle, montant, cat_user, cat_date_user
FROM operations_by_account
WHERE code_si = '1'
  AND contrat = '100000000'
  AND cat_user = 'RESTAURANT'
LIMIT 10;

-- ============================================
-- TEST 3 : Recherche combinée (cat_auto OU cat_user)
-- ============================================
-- Équivalent HBase : SCAN avec filter OR
SELECT code_si, contrat, date_op, numero_op, libelle, montant, cat_auto, cat_user
FROM operations_by_account
WHERE code_si = '1'
  AND contrat = '100000000'
  AND (cat_auto = 'ALIMENTATION' OR cat_user = 'RESTAURANT')
LIMIT 10;

-- ============================================
-- TEST 4 : Recherche avec score de confiance élevé
-- ============================================
-- Équivalent HBase : SCAN avec filter sur cat_confidence
SELECT code_si, contrat, date_op, numero_op, libelle, cat_auto, cat_confidence
FROM operations_by_account
WHERE code_si = '1'
  AND contrat = '100000000'
  AND cat_auto = 'ALIMENTATION'
  AND cat_confidence >= 0.8
LIMIT 10;

-- ============================================
-- TEST 5 : Recherche avec filtre montant
-- ============================================
-- Équivalent HBase : SCAN avec filter sur montant
SELECT code_si, contrat, date_op, numero_op, libelle, montant, cat_auto
FROM operations_by_account
WHERE code_si = '1'
  AND contrat = '100000000'
  AND cat_auto = 'ALIMENTATION'
  AND montant < -50
LIMIT 10;

-- ============================================
-- TEST 6 : Recherche avec filtre type d'opération
-- ============================================
-- Équivalent HBase : SCAN avec filter sur type_operation
SELECT code_si, contrat, date_op, numero_op, libelle, type_operation, cat_auto
FROM operations_by_account
WHERE code_si = '1'
  AND contrat = '100000000'
  AND cat_auto = 'ALIMENTATION'
  AND type_operation = 'CB'
LIMIT 10;

-- ============================================
-- TEST 7 : Recherche avec plage de dates
-- ============================================
-- Équivalent HBase : SCAN avec TIMERANGE
SELECT code_si, contrat, date_op, numero_op, libelle, cat_auto
FROM operations_by_account
WHERE code_si = '1'
  AND contrat = '100000000'
  AND cat_auto = 'ALIMENTATION'
  AND date_op >= '2024-01-01'
  AND date_op < '2024-02-01'
LIMIT 10;

-- ============================================
-- TEST 8 : Recherche opérations validées par client
-- ============================================
-- Équivalent HBase : SCAN avec filter sur cat_validee
SELECT code_si, contrat, date_op, numero_op, libelle, cat_user, cat_validee
FROM operations_by_account
WHERE code_si = '1'
  AND contrat = '100000000'
  AND cat_validee = true
LIMIT 10;

-- ============================================
-- TEST 9 : Recherche opérations corrigées par client
-- ============================================
-- Équivalent HBase : SCAN avec filter sur cat_user IS NOT NULL
SELECT code_si, contrat, date_op, numero_op, libelle, cat_auto, cat_user, cat_date_user
FROM operations_by_account
WHERE code_si = '1'
  AND contrat = '100000000'
  AND cat_user IS NOT NULL
LIMIT 10;

-- ============================================
-- TEST 10 : Recherche avec priorité cat_user vs cat_auto
-- ============================================
-- Démontre la stratégie multi-version : cat_user prioritaire sur cat_auto
SELECT code_si, contrat, date_op, numero_op, libelle, 
       cat_auto, cat_user,
       CASE WHEN cat_user IS NOT NULL THEN cat_user ELSE cat_auto END AS categorie_finale
FROM operations_by_account
WHERE code_si = '1'
  AND contrat = '100000000'
  AND (cat_auto = 'ALIMENTATION' OR cat_user = 'ALIMENTATION')
LIMIT 10;


