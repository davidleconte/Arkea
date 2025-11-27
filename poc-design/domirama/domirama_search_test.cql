-- ============================================
-- Tests de Recherche Full-Text avec SAI
-- Remplacement de Solr par SAI
-- ============================================

USE domirama_poc;

-- ============================================
-- Test 1 : Recherche simple par terme
-- ============================================
-- Ancien workflow HBase: SCAN complet → Index Solr → MultiGet
-- Nouveau workflow HCD: Requête CQL directe avec index SAI

SELECT * FROM operations_by_account
WHERE code_si = '01' 
  AND contrat = '1234567890'
  AND libelle : 'loyer'
LIMIT 10;

-- ============================================
-- Test 2 : Recherche combinée (AND)
-- ============================================
SELECT * FROM operations_by_account
WHERE code_si = '01' 
  AND contrat = '1234567890'
  AND libelle : 'loyer' 
  AND libelle : 'janvier'
LIMIT 10;

-- ============================================
-- Test 3 : Recherche avec filtre par montant
-- ============================================
SELECT * FROM operations_by_account
WHERE code_si = '01' 
  AND contrat = '1234567890'
  AND libelle : 'loyer'
  AND montant < -500
LIMIT 10;

-- ============================================
-- Test 4 : Recherche par type d'opération
-- ============================================
SELECT * FROM operations_by_account
WHERE code_si = '01' 
  AND contrat = '1234567890'
  AND type_operation = 'VIREMENT'
LIMIT 10;

-- ============================================
-- Test 5 : Recherche par catégorie (si disponible)
-- ============================================
SELECT * FROM operations_by_account
WHERE code_si = '01' 
  AND contrat = '1234567890'
  AND cat_auto = 'Habitation'
LIMIT 10;

-- ============================================
-- Test 6 : Historique complet d'un compte (sans recherche)
-- ============================================
-- Équivalent du SCAN HBase, mais optimisé par partition
SELECT * FROM operations_by_account
WHERE code_si = '01' 
  AND contrat = '1234567890'
LIMIT 100;

-- ============================================
-- Test 7 : Historique avec plage de dates
-- ============================================
SELECT * FROM operations_by_account
WHERE code_si = '01' 
  AND contrat = '1234567890'
  AND op_date >= '2024-03-01'
  AND op_date < '2024-04-01'
LIMIT 100;

-- ============================================
-- Test 8 : Comptage par type d'opération
-- ============================================
SELECT type_operation, COUNT(*) as count
FROM operations_by_account
WHERE code_si = '01' 
  AND contrat = '1234567890'
GROUP BY type_operation;

-- ============================================
-- Test 9 : Recherche insensible à la casse
-- ============================================
-- L'analyzer Lucene gère automatiquement la casse
SELECT * FROM operations_by_account
WHERE code_si = '01' 
  AND contrat = '1234567890'
  AND libelle : 'Loyer'  -- Recherche "Loyer" ou "loyer"
LIMIT 10;

-- ============================================
-- Test 10 : Recherche avec stemming français
-- ============================================
-- L'analyzer français gère les pluriels, féminins, etc.
SELECT * FROM operations_by_account
WHERE code_si = '01' 
  AND contrat = '1234567890'
  AND libelle : 'loyers'  -- Trouve aussi "loyer", "loyère", etc.
LIMIT 10;

