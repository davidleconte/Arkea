-- ============================================
-- Fichier : 13_dynamic_columns_test.cql
-- Tests de Filtrage sur Colonnes Dynamiques (MAP)
-- ============================================
--
-- OBJECTIF :
--   Ce fichier contient une série de tests de filtrage sur colonnes MAP
--   (équivalent colonnes dynamiques HBase) sur la table 'operations_by_account'.
--
--   Les tests couvrent :
--   - Filtrage par clé MAP (meta_flags['key'])
--   - Filtrage par valeur MAP (meta_flags CONTAINS 'value')
--   - Filtrage multi-clés MAP
--   - Filtrage combiné (MAP + Index SAI full-text)
--   - Mise à jour dynamique des MAP
--
-- CONTEXTE HBase → HCD :
--   - Équivalent HBase : ColumnFilter sur qualifier dynamique
--   - Différences :
--     * Structure typée MAP<TEXT, TEXT> (vs colonnes dynamiques HBase)
--     * Filtrage avec WHERE meta_flags['key'] (vs ColumnFilter)
--   - Améliorations :
--     * Filtrage combiné MAP + Index SAI (non disponible avec HBase)
--
-- PRÉREQUIS :
--   - Keyspace et table créés
--   - Données chargées dans la table
--   - Colonne meta_flags MAP<TEXT, TEXT> présente
--
-- UTILISATION :
--   cqlsh localhost 9042 -f 13_dynamic_columns_test.cql
--   ou via script shell : ./13_test_dynamic_columns.sh
--
-- ============================================

USE domiramacatops_poc;

-- ============================================
-- TEST 1 : Filtrage par clé MAP (source)
-- ============================================
-- Équivalent HBase : ColumnFilter sur qualifier 'meta:source'
SELECT code_si, contrat, date_op, numero_op, libelle, montant, meta_flags
FROM operations_by_account
WHERE code_si = '1'
  AND contrat = '100000000'
  AND meta_flags['source'] = 'mobile'
LIMIT 10;

-- ============================================
-- TEST 2 : Filtrage par clé MAP (device)
-- ============================================
-- Équivalent HBase : ColumnFilter sur qualifier 'meta:device'
SELECT code_si, contrat, date_op, numero_op, libelle, montant, meta_flags
FROM operations_by_account
WHERE code_si = '1'
  AND contrat = '100000000'
  AND meta_flags['device'] = 'iphone'
LIMIT 10;

-- ============================================
-- TEST 3 : Filtrage multi-clés MAP
-- ============================================
-- Équivalent HBase : Plusieurs ColumnFilters combinés
SELECT code_si, contrat, date_op, numero_op, libelle, montant, meta_flags
FROM operations_by_account
WHERE code_si = '1'
  AND contrat = '100000000'
  AND meta_flags['source'] = 'mobile'
  AND meta_flags['device'] = 'iphone'
LIMIT 10;

-- ============================================
-- TEST 4 : Filtrage avec CONTAINS KEY
-- ============================================
-- Équivalent HBase : Vérification présence qualifier
SELECT code_si, contrat, date_op, numero_op, libelle, meta_flags
FROM operations_by_account
WHERE code_si = '1'
  AND contrat = '100000000'
  AND meta_flags CONTAINS KEY 'ip'
LIMIT 10;

-- ============================================
-- TEST 5 : Filtrage avec CONTAINS (valeur)
-- ============================================
-- Équivalent HBase : ColumnFilter avec valeur
SELECT code_si, contrat, date_op, numero_op, libelle, meta_flags
FROM operations_by_account
WHERE code_si = '1'
  AND contrat = '100000000'
  AND meta_flags CONTAINS 'paris'
LIMIT 10;

-- ============================================
-- TEST 6 : Filtrage combiné (MAP + Full-Text)
-- ============================================
-- Valeur ajoutée HCD : Non disponible avec HBase
SELECT code_si, contrat, date_op, numero_op, libelle, montant, meta_flags
FROM operations_by_account
WHERE code_si = '1'
  AND contrat = '100000000'
  AND meta_flags['source'] = 'web'
  AND libelle : 'VIREMENT'
LIMIT 10;

-- ============================================
-- TEST 7 : Mise à jour dynamique MAP
-- ============================================
-- Équivalent HBase : Put avec nouveau qualifier
UPDATE operations_by_account
SET meta_flags['fraud_score'] = '0.85'
WHERE code_si = '1'
  AND contrat = '100000000'
  AND date_op = '2024-01-20 11:00:00'
  AND numero_op = 2;

-- Vérification de la mise à jour
SELECT code_si, contrat, date_op, numero_op, libelle, meta_flags
FROM operations_by_account
WHERE code_si = '1'
  AND contrat = '100000000'
  AND date_op = '2024-01-20 11:00:00'
  AND numero_op = 2;
