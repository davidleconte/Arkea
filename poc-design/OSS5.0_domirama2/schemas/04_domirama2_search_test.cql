-- ============================================
-- Fichier : 04_domirama2_search_test.cql
-- Tests de Recherche Full-Text avec Index SAI
-- ============================================
--
-- OBJECTIF :
--   Ce fichier contient une série de tests de recherche full-text sur la table
--   'operations_by_account' en utilisant les index SAI (Storage-Attached Index).
--
--   Les tests couvrent :
--   - Recherche par libellé (full-text search)
--   - Filtrage par catégorie automatique (cat_auto)
--   - Filtrage par catégorie client (cat_user)
--   - Recherches combinées (libellé + catégorie)
--   - Vérification de la pertinence des résultats
--   - Tests de la stratégie multi-version (cat_user vs cat_auto)
--
-- CONTEXTE HBase → HCD :
--   - Équivalent HBase : Requêtes HBase avec filtres + recherche Elasticsearch
--   - Différences :
--     * Recherche full-text intégrée (vs Elasticsearch externe)
--     * Syntaxe CQL avec opérateur ':' pour full-text (vs requêtes Elasticsearch)
--   - Améliorations :
--     * Pas de système externe nécessaire
--     * Performance améliorée (pas de réseau)
--
-- PRÉREQUIS :
--   - Keyspace et table créés (01_create_domirama2_schema.cql)
--   - Données chargées dans la table
--   - Index SAI créés
--
-- UTILISATION :
--   cqlsh localhost 9042 -f 04_domirama2_search_test.cql
--   ou via script shell : ./12_test_domirama2_search.sh
--
-- EXEMPLE :
--   cqlsh localhost 9042 -f schemas/04_domirama2_search_test.cql
--
-- SORTIE :
--   - Résultats des tests de recherche affichés
--   - Nombre de résultats pour chaque requête
--   - Validation de la pertinence des résultats
--
-- ============================================

USE domirama2_poc;

-- Test 1 : Recherche simple par terme (full-text SAI)
SELECT * FROM operations_by_account
WHERE code_si = '01'
  AND contrat = '1234567890'
  AND libelle : 'loyer'
LIMIT 10;

-- Test 2 : Recherche combinée (AND) avec full-text
SELECT * FROM operations_by_account
WHERE code_si = '01'
  AND contrat = '1234567890'
  AND libelle : 'loyer'
  AND libelle : 'janvier'
LIMIT 10;

-- Test 3 : Recherche avec filtre par montant (index SAI)
SELECT * FROM operations_by_account
WHERE code_si = '01'
  AND contrat = '1234567890'
  AND libelle : 'loyer'
  AND montant < -500
LIMIT 10;

-- Test 4 : Recherche par catégorie automatique
SELECT * FROM operations_by_account
WHERE code_si = '01'
  AND contrat = '1234567890'
  AND cat_auto = 'HABITATION'
LIMIT 10;

-- Test 5 : Recherche par catégorie client (corrigée)
SELECT * FROM operations_by_account
WHERE code_si = '01'
  AND contrat = '1234567890'
  AND cat_user IS NOT NULL  -- Opérations corrigées par le client
LIMIT 10;

-- Test 6 : Recherche avec score de confiance
SELECT * FROM operations_by_account
WHERE code_si = '01'
  AND contrat = '1234567890'
  AND cat_confidence >= 0.90  -- Catégories avec haute confiance
LIMIT 10;

-- Test 7 : Recherche par acceptation client
SELECT * FROM operations_by_account
WHERE code_si = '01'
  AND contrat = '1234567890'
  AND cat_validee = true  -- Catégories acceptées par le client
LIMIT 10;

-- Test 8 : Historique complet d'un compte (sans recherche)
SELECT * FROM operations_by_account
WHERE code_si = '01'
  AND contrat = '1234567890'
ORDER BY date_op DESC
LIMIT 100;

-- Test 9 : Historique avec plage de dates
SELECT * FROM operations_by_account
WHERE code_si = '01'
  AND contrat = '1234567890'
  AND date_op >= '2024-03-01'
  AND date_op < '2024-04-01'
ORDER BY date_op DESC
LIMIT 100;

-- Test 10 : Recherche insensible à la casse (analyzer français)
SELECT * FROM operations_by_account
WHERE code_si = '01'
  AND contrat = '1234567890'
  AND libelle : 'Loyer'  -- Doit trouver "LOYER" grâce à l'analyzer
LIMIT 10;

-- Test 11 : Recherche avec stemming français
SELECT * FROM operations_by_account
WHERE code_si = '01'
  AND contrat = '1234567890'
  AND libelle : 'loyers'  -- Doit trouver "LOYER" grâce au stemming
LIMIT 10;

-- Test 12 : Vérification logique cat_user vs cat_auto
-- Affiche les opérations avec leur catégorie finale (priorité cat_user)
SELECT
    date_op,
    libelle,
    montant,
    cat_auto,
    cat_confidence,
    cat_user,
    cat_date_user,
    cat_validee,
    -- Note: COALESCE n'existe pas en CQL, utiliser logique côté application
    -- cat_user IS NOT NULL ? cat_user : cat_auto
    cat_user,
    cat_auto,
    CASE
        WHEN cat_user IS NOT NULL THEN 'Corrigée par client'
        ELSE 'Automatique'
    END as source_categorie
FROM operations_by_account
WHERE code_si = '01'
  AND contrat = '1234567890'
ORDER BY date_op DESC
LIMIT 20;
