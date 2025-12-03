-- ============================================
-- Fichier : 04_create_meta_categories_indexes.cql
-- Création des index SAI pour les 7 tables meta-categories
-- ============================================
--
-- OBJECTIF :
--   Ce fichier crée les index SAI (Storage-Attached Index) pour optimiser
--   les recherches et filtrages sur les tables meta-categories.
--
-- PRÉREQUIS :
--   - Les 7 tables meta-categories doivent exister
--   - HCD 1.2.3 démarré et accessible sur localhost:9042
--
-- UTILISATION :
--   cqlsh localhost 9042 -f 04_create_meta_categories_indexes.cql
--   ou via script shell : ./03_setup_meta_categories_tables.sh
--
-- ============================================

USE domiramacatops_poc;

-- ============================================
-- INDEX SAI pour historique_opposition
-- ============================================

-- Index standard sur status (filtrage rapide)
CREATE CUSTOM INDEX IF NOT EXISTS idx_historique_status
ON historique_opposition(status)
USING 'StorageAttachedIndex';

-- Index full-text sur raison (recherche textuelle)
CREATE CUSTOM INDEX IF NOT EXISTS idx_historique_raison_fulltext
ON historique_opposition(raison)
USING 'StorageAttachedIndex'
WITH OPTIONS = {
  'index_analyzer': '{
    "tokenizer": {"name": "standard"},
    "filters": [
      {"name": "lowercase"},
      {"name": "frenchLightStem"},
      {"name": "asciiFolding"}
    ]
  }'
};

-- ============================================
-- INDEX SAI pour feedback_par_libelle
-- ============================================

-- Index full-text sur libelle_simplifie (recherche partielle)
CREATE CUSTOM INDEX IF NOT EXISTS idx_feedback_libelle_fulltext
ON feedback_par_libelle(libelle_simplifie)
USING 'StorageAttachedIndex'
WITH OPTIONS = {
  'index_analyzer': '{
    "tokenizer": {"name": "standard"},
    "filters": [
      {"name": "lowercase"},
      {"name": "frenchLightStem"},
      {"name": "asciiFolding"}
    ]
  }'
};

-- Index standard sur categorie (filtrage rapide)
CREATE CUSTOM INDEX IF NOT EXISTS idx_feedback_categorie
ON feedback_par_libelle(categorie)
USING 'StorageAttachedIndex';

-- ============================================
-- INDEX SAI pour feedback_par_ics
-- ============================================

-- Index standard sur categorie (filtrage rapide)
CREATE CUSTOM INDEX IF NOT EXISTS idx_feedback_ics_categorie
ON feedback_par_ics(categorie)
USING 'StorageAttachedIndex';

-- ============================================
-- INDEX SAI pour regles_personnalisees
-- ============================================

-- Index full-text sur libelle_simplifie (recherche partielle)
CREATE CUSTOM INDEX IF NOT EXISTS idx_regles_libelle_fulltext
ON regles_personnalisees(libelle_simplifie)
USING 'StorageAttachedIndex'
WITH OPTIONS = {
  'index_analyzer': '{
    "tokenizer": {"name": "standard"},
    "filters": [
      {"name": "lowercase"},
      {"name": "frenchLightStem"},
      {"name": "asciiFolding"}
    ]
  }'
};

-- Index standard sur categorie_cible (filtrage rapide)
CREATE CUSTOM INDEX IF NOT EXISTS idx_regles_categorie_cible
ON regles_personnalisees(categorie_cible)
USING 'StorageAttachedIndex';

-- Index standard sur actif (filtrage règles actives)
CREATE CUSTOM INDEX IF NOT EXISTS idx_regles_actif
ON regles_personnalisees(actif)
USING 'StorageAttachedIndex';

-- ============================================
-- INDEX SAI pour decisions_salaires
-- ============================================

-- Index standard sur methode_utilisee (filtrage rapide)
CREATE CUSTOM INDEX IF NOT EXISTS idx_decisions_methode
ON decisions_salaires(methode_utilisee)
USING 'StorageAttachedIndex';

-- Index standard sur modele (filtrage rapide)
CREATE CUSTOM INDEX IF NOT EXISTS idx_decisions_modele
ON decisions_salaires(modele)
USING 'StorageAttachedIndex';

-- Index standard sur actif (filtrage décisions actives)
CREATE CUSTOM INDEX IF NOT EXISTS idx_decisions_actif
ON decisions_salaires(actif)
USING 'StorageAttachedIndex';
