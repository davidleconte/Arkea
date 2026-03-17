-- ============================================
-- Fichier : 03_create_domirama2_schema_fuzzy.cql
-- Configuration de la Recherche Floue avec Vector Search
-- ============================================
--
-- OBJECTIF :
--   Ce fichier configure la recherche floue (fuzzy search) en ajoutant une
--   colonne vectorielle 'libelle_embedding' de type VECTOR pour stocker
--   les embeddings ByteT5, permettant des recherches par similarité sémantique.
--
--   Fonctionnalités :
--   - Ajout de la colonne 'libelle_embedding' (VECTOR<FLOAT, 1472>)
--   - Création d'un index SAI vectoriel sur 'libelle_embedding'
--   - Support des recherches par similarité cosinus (ANN - Approximate Nearest Neighbor)
--   - Tolérance aux typos et variations linguistiques
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
--   - HCD 1.2.3 démarré et accessible sur localhost:9042
--
-- UTILISATION :
--   cqlsh localhost 9042 -f 03_create_domirama2_schema_fuzzy.cql
--   ou via script shell : ./21_setup_fuzzy_search.sh
--
-- EXEMPLE :
--   cqlsh localhost 9042 -f schemas/03_create_domirama2_schema_fuzzy.cql
--
-- SORTIE :
--   - Colonne 'libelle_embedding' ajoutée à la table
--   - Index SAI vectoriel créé
--   - Vérification : DESCRIBE TABLE domirama2_poc.operations_by_account;
--
-- ============================================

USE domirama2_poc;

-- ============================================
-- SECTION 1 : Ajout de la Colonne Vectorielle
-- ============================================
-- Ajouter la colonne VECTOR pour stocker les embeddings ByteT5
-- Type : VECTOR<FLOAT, 1472> (1472 dimensions pour ByteT5-small)
-- Équivalent HBase : Pas d'équivalent direct (nécessite Elasticsearch + ML externe)
-- Avantage : Recherche par similarité sémantique intégrée
-- ============================================
ALTER TABLE operations_by_account ADD libelle_embedding VECTOR<FLOAT, 1472>;

-- ============================================
-- SECTION 2 : Création de l'Index SAI Vectoriel
-- ============================================
-- Créer l'index SAI vectoriel pour recherche par similarité (ANN)
-- Équivalent HBase : Pas d'équivalent direct (nécessite Elasticsearch + ML externe)
-- Fonctionnement : Index ANN (Approximate Nearest Neighbor) pour recherche rapide
--                  par similarité cosinus dans l'espace vectoriel
-- ============================================
CREATE CUSTOM INDEX IF NOT EXISTS idx_libelle_embedding_vector
ON operations_by_account(libelle_embedding)
USING 'StorageAttachedIndex';

-- ============================================
-- VÉRIFICATION
-- ============================================
-- Vérifier que la colonne et l'index ont été créés correctement
-- ============================================
DESCRIBE TABLE operations_by_account;
