-- ============================================
-- Fichier : 07_domirama2_search_fuzzy.cql
-- Tests de Recherche Floue avec Vector Search (ByteT5)
-- ============================================
--
-- OBJECTIF :
--   Ce fichier contient des tests de recherche floue (fuzzy search) en utilisant
--   les embeddings ByteT5 stockés dans la colonne 'libelle_embedding' pour
--   trouver des opérations par similarité sémantique, même avec des typos.
--   
--   Les tests couvrent :
--   - Recherches avec typos (caractères manquants, inversés, remplacés)
--   - Recherches par similarité cosinus (ANN - Approximate Nearest Neighbor)
--   - Comparaison avec Full-Text Search
--   - Validation de la pertinence des résultats
--
-- CONTEXTE HBase → HCD :
--   - Équivalent HBase : Pas d'équivalent direct (nécessite Elasticsearch + ML externe)
--   - Améliorations :
--     * Recherche vectorielle native dans HCD
--     * Pas de système ML externe nécessaire
--     * Support des embeddings ByteT5 (1472 dimensions)
--     * Recherche par similarité cosinus intégrée (ANN)
--
-- PRÉREQUIS :
--   - Keyspace et table créés (01_create_domirama2_schema.cql)
--   - Fuzzy search configuré (03_create_domirama2_schema_fuzzy.cql)
--   - Embeddings générés (22_generate_embeddings.sh)
--   - Données chargées dans la table avec embeddings
--
-- UTILISATION :
--   cqlsh localhost 9042 -f 07_domirama2_search_fuzzy.cql
--   ou via script shell : ./23_test_fuzzy_search.sh
--
-- EXEMPLE :
--   cqlsh localhost 9042 -f schemas/07_domirama2_search_fuzzy.cql
--
-- SORTIE :
--   - Résultats des tests de fuzzy search affichés
--   - Démonstration de la tolérance aux typos
--   - Comparaison avec Full-Text Search
--   - Validation de la pertinence des résultats
--
-- NOTE IMPORTANTE :
--   Les requêtes ANN (Approximate Nearest Neighbor) nécessitent que le vecteur
--   de la requête soit généré côté application avec ByteT5 avant d'être utilisé
--   dans la requête CQL. Les exemples ci-dessous montrent la syntaxe, mais les
--   vecteurs doivent être générés dynamiquement.
--
-- ============================================

USE domirama2_poc;

-- ============================================
-- Test 1 : Recherche avec typo (caractère manquant)
-- ============================================
-- Requête: "loyr" au lieu de "loyer"
-- La recherche vectorielle devrait trouver "LOYER" grâce à la similarité sémantique
-- Note: Pour utiliser ANN, il faut d'abord encoder la requête en vecteur
-- Cette requête est un exemple de syntaxe CQL pour vector search

-- Exemple de recherche vectorielle (nécessite le vecteur de la requête)
-- SELECT libelle, montant
-- FROM operations_by_account
-- WHERE code_si = '1'
--   AND contrat = '5913101072'
-- ORDER BY libelle_embedding ANN OF [0.12, 0.5, ..., -0.03]  -- Vecteur de "loyr"
-- LIMIT 5;

-- ============================================
-- Test 2 : Recherche avec inversion de caractères
-- ============================================
-- Requête: "parsi" au lieu de "paris"
-- La recherche vectorielle devrait trouver "PARIS" grâce à la similarité sémantique

-- SELECT libelle, montant
-- FROM operations_by_account
-- WHERE code_si = '1'
--   AND contrat = '5913101072'
-- ORDER BY libelle_embedding ANN OF [0.15, 0.3, ..., 0.08]  -- Vecteur de "parsi"
-- LIMIT 5;

-- ============================================
-- Test 3 : Recherche avec plusieurs typos
-- ============================================
-- Requête: "impay" au lieu de "impayé"
-- La recherche vectorielle devrait trouver "IMPAYE" grâce à la similarité sémantique

-- SELECT libelle, montant
-- FROM operations_by_account
-- WHERE code_si = '1'
--   AND contrat = '5913101072'
-- ORDER BY libelle_embedding ANN OF [0.08, 0.4, ..., -0.12]  -- Vecteur de "impay"
-- LIMIT 5;

-- ============================================
-- Test 4 : Recherche combinée (vector + full-text)
-- ============================================
-- Combinaison de recherche vectorielle et filtrage textuel
-- Filtre d'abord par full-text, puis trie par similarité vectorielle

-- SELECT libelle, montant
-- FROM operations_by_account
-- WHERE code_si = '1'
--   AND contrat = '5913101072'
--   AND libelle : 'loy'  -- Filtre full-text (préfixe)
-- ORDER BY libelle_embedding ANN OF [0.12, 0.5, ..., -0.03]  -- Vecteur de la requête
-- LIMIT 5;

-- Note: Les requêtes ANN nécessitent que le vecteur de la requête soit généré
-- côté application avec ByteT5 avant d'être utilisé dans la requête CQL.

