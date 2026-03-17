-- ============================================
-- Fichier : 06_domirama2_search_fulltext_complex.cql
-- Tests de Recherche Full-Text Complexes (Multi-termes, Accents, Variations)
-- ============================================
--
-- OBJECTIF :
--   Ce fichier contient des tests de recherche full-text complexes sur la table
--   'operations_by_account' en utilisant les index SAI avancés avec différents
--   analyzers (lowercase, asciifolding, frenchLightStem, stop words).
--
--   Les tests couvrent :
--   - Recherches multi-termes (plusieurs mots simultanément)
--   - Gestion des accents (asciifolding)
--   - Racinisation française (frenchLightStem)
--   - Recherches avec caractères manquants ou inversés
--   - Vérification de la pertinence des résultats
--
-- CONTEXTE HBase → HCD :
--   - Équivalent HBase : Requêtes HBase avec filtres + recherche Elasticsearch complexe
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
--   cqlsh localhost 9042 -f 06_domirama2_search_fulltext_complex.cql
--   ou via script shell : ./15_test_fulltext_complex.sh
--
-- EXEMPLE :
--   cqlsh localhost 9042 -f schemas/06_domirama2_search_fulltext_complex.cql
--
-- SORTIE :
--   - Résultats des tests de recherche complexes affichés
--   - Nombre de résultats pour chaque requête
--   - Démonstration des capacités des analyzers
--   - Validation de la pertinence des résultats
--
-- ============================================

USE domirama2_poc;

-- ============================================
-- Test 1 : Recherche multi-termes "loyer paris"
-- ============================================
-- Recherche les opérations contenant "loyer" ET "paris"
-- Note: Utiliser un compte réel chargé (code_si='1', contrat='5913101072' par exemple)
SELECT code_si, contrat, date_op, libelle, montant, cat_auto
FROM operations_by_account
WHERE code_si = '1'
  AND contrat = '5913101072'
  AND libelle : 'loyer'
  AND libelle : 'paris'
LIMIT 20;

-- ============================================
-- Test 2 : Recherche "virement impayé" (avec accent)
-- ============================================
-- Le full-text search avec asciifolding trouve "impaye" même si écrit "impayé"
SELECT code_si, contrat, date_op, libelle, montant, type_operation
FROM operations_by_account
WHERE code_si = '1'
  AND contrat = '5913101072'
  AND libelle : 'virement'
  AND libelle : 'impaye'
LIMIT 20;

-- ============================================
-- Test 3 : Recherche "virement impayé" (variante)
-- ============================================
-- Test avec différentes écritures
SELECT code_si, contrat, date_op, libelle, montant
FROM operations_by_account
WHERE code_si = '1'
  AND contrat = '5913101072'
  AND libelle : 'virement'
  AND libelle : 'impay'
LIMIT 20;

-- ============================================
-- Test 4 : Recherche "loyer impayé paris"
-- ============================================
-- Recherche triple terme
SELECT code_si, contrat, date_op, libelle, montant, cat_auto
FROM operations_by_account
WHERE code_si = '1'
  AND contrat = '5913101072'
  AND libelle : 'loyer'
  AND libelle : 'impaye'
  AND libelle : 'paris'
LIMIT 20;

-- ============================================
-- Test 5 : Recherche "carrefour paris" (multi-termes)
-- ============================================
SELECT code_si, contrat, date_op, libelle, montant, cat_auto
FROM operations_by_account
WHERE code_si = '1'
  AND contrat = '5913101072'
  AND libelle : 'carrefour'
  AND libelle : 'paris'
LIMIT 20;

-- ============================================
-- Test 6 : Recherche "restaurant paris" (multi-termes)
-- ============================================
SELECT code_si, contrat, date_op, libelle, montant, cat_auto
FROM operations_by_account
WHERE code_si = '1'
  AND contrat = '5913101072'
  AND libelle : 'restaurant'
  AND libelle : 'paris'
LIMIT 20;

-- ============================================
-- Test 7 : Recherche "edf facture" (multi-termes)
-- ============================================
SELECT code_si, contrat, date_op, libelle, montant, cat_auto
FROM operations_by_account
WHERE code_si = '1'
  AND contrat = '5913101072'
  AND libelle : 'edf'
  AND libelle : 'facture'
LIMIT 20;

-- ============================================
-- Test 8 : Recherche "orange facture" (multi-termes)
-- ============================================
SELECT code_si, contrat, date_op, libelle, montant, cat_auto
FROM operations_by_account
WHERE code_si = '1'
  AND contrat = '5913101072'
  AND libelle : 'orange'
  AND libelle : 'facture'
LIMIT 20;

-- ============================================
-- Test 9 : Recherche "ratp navigo paris" (triple terme)
-- ============================================
SELECT code_si, contrat, date_op, libelle, montant, cat_auto
FROM operations_by_account
WHERE code_si = '1'
  AND contrat = '5913101072'
  AND libelle : 'ratp'
  AND libelle : 'navigo'
  AND libelle : 'paris'
LIMIT 20;

-- ============================================
-- Test 10 : Recherche "amazon paris livraison" (triple terme)
-- ============================================
SELECT code_si, contrat, date_op, libelle, montant, cat_auto
FROM operations_by_account
WHERE code_si = '1'
  AND contrat = '5913101072'
  AND libelle : 'amazon'
  AND libelle : 'paris'
  AND libelle : 'livraison'
LIMIT 20;

-- ============================================
-- Test 11 : Recherche avec stemming "loyers paris" (pluriel)
-- ============================================
-- Le stemming français trouve "loyer" même si on cherche "loyers"
SELECT code_si, contrat, date_op, libelle, montant, cat_auto
FROM operations_by_account
WHERE code_si = '1'
  AND contrat = '5913101072'
  AND libelle : 'loyers'
  AND libelle : 'paris'
LIMIT 20;

-- ============================================
-- Test 12 : Recherche "virement sepa paris" (triple terme)
-- ============================================
SELECT code_si, contrat, date_op, libelle, montant, type_operation
FROM operations_by_account
WHERE code_si = '1'
  AND contrat = '5913101072'
  AND libelle : 'virement'
  AND libelle : 'sepa'
  AND libelle : 'paris'
LIMIT 20;

-- ============================================
-- Test 13 : Recherche "cinema paris" (multi-termes)
-- ============================================
SELECT code_si, contrat, date_op, libelle, montant, cat_auto
FROM operations_by_account
WHERE code_si = '1'
  AND contrat = '5913101072'
  AND libelle : 'cinema'
  AND libelle : 'paris'
LIMIT 20;

-- ============================================
-- Test 14 : Recherche "pharmacie paris" (multi-termes)
-- ============================================
SELECT code_si, contrat, date_op, libelle, montant, cat_auto
FROM operations_by_account
WHERE code_si = '1'
  AND contrat = '5913101072'
  AND libelle : 'pharmacie'
  AND libelle : 'paris'
LIMIT 20;

-- ============================================
-- Test 15 : Recherche "parking paris" (multi-termes)
-- ============================================
SELECT code_si, contrat, date_op, libelle, montant, cat_auto
FROM operations_by_account
WHERE code_si = '1'
  AND contrat = '5913101072'
  AND libelle : 'parking'
  AND libelle : 'paris'
LIMIT 20;

-- ============================================
-- Test 16 : Recherche "impayé" seul (test accent)
-- ============================================
-- Test que "impaye" trouve "IMPAYE" (asciifolding)
SELECT code_si, contrat, date_op, libelle, montant
FROM operations_by_account
WHERE code_si = '1'
  AND contrat = '5913101072'
  AND libelle : 'impaye'
LIMIT 20;

-- ============================================
-- Test 17 : Recherche "régularisation" (avec accent)
-- ============================================
-- Test asciifolding avec "regularisation"
SELECT code_si, contrat, date_op, libelle, montant
FROM operations_by_account
WHERE code_si = '1'
  AND contrat = '5913101072'
  AND libelle : 'regularisation'
LIMIT 20;

-- ============================================
-- Test 18 : Recherche combinée avec filtre montant
-- ============================================
-- "loyer paris" avec montant < -500
SELECT code_si, contrat, date_op, libelle, montant, cat_auto
FROM operations_by_account
WHERE code_si = '1'
  AND contrat = '5913101072'
  AND libelle : 'loyer'
  AND libelle : 'paris'
  AND montant < -500
LIMIT 20;

-- ============================================
-- Test 19 : Recherche combinée avec filtre catégorie
-- ============================================
-- "virement" avec catégorie "VIREMENT"
SELECT code_si, contrat, date_op, libelle, montant, cat_auto
FROM operations_by_account
WHERE code_si = '1'
  AND contrat = '5913101072'
  AND libelle : 'virement'
  AND cat_auto = 'VIREMENT'
LIMIT 20;

-- ============================================
-- Test 20 : Recherche "impayé" avec type d'opération
-- ============================================
-- "virement impayé" avec type VIREMENT
SELECT code_si, contrat, date_op, libelle, montant, type_operation
FROM operations_by_account
WHERE code_si = '1'
  AND contrat = '5913101072'
  AND libelle : 'virement'
  AND libelle : 'impaye'
  AND type_operation = 'VIREMENT'
LIMIT 20;
