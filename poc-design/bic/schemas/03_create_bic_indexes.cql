-- =============================================================================
-- Schéma : Création des Index SAI pour BIC
-- =============================================================================
-- Date : 2025-12-01
-- Objectif : Créer les index SAI pour recherche avancée
-- =============================================================================

USE bic_poc;

-- =============================================================================
-- Index Full-Text sur json_data
-- =============================================================================
-- Permet la recherche full-text dans le contenu JSON des interactions

CREATE CUSTOM INDEX IF NOT EXISTS idx_interactions_json_data_fulltext
ON bic_poc.interactions_by_client (json_data)
USING 'org.apache.cassandra.index.sai.StorageAttachedIndex'
WITH OPTIONS = {
    'case_sensitive': 'false',
    'normalize': 'true'
};

-- =============================================================================
-- Index sur canal
-- =============================================================================
-- Permet le filtrage rapide par canal (email, SMS, agence, etc.)

CREATE CUSTOM INDEX IF NOT EXISTS idx_interactions_canal
ON bic_poc.interactions_by_client (canal)
USING 'org.apache.cassandra.index.sai.StorageAttachedIndex';

-- =============================================================================
-- Index sur type_interaction
-- =============================================================================
-- Permet le filtrage rapide par type d'interaction

CREATE CUSTOM INDEX IF NOT EXISTS idx_interactions_type
ON bic_poc.interactions_by_client (type_interaction)
USING 'org.apache.cassandra.index.sai.StorageAttachedIndex';

-- =============================================================================
-- Index sur date_interaction (pour requêtes de période)
-- =============================================================================
-- Permet les requêtes de période efficaces

CREATE CUSTOM INDEX IF NOT EXISTS idx_interactions_date
ON bic_poc.interactions_by_client (date_interaction)
USING 'org.apache.cassandra.index.sai.StorageAttachedIndex';

-- =============================================================================
-- Index sur resultat (BIC-11 : Filtrage par résultat)
-- =============================================================================
-- Permet le filtrage rapide par résultat/statut (succès, échec, etc.)

CREATE CUSTOM INDEX IF NOT EXISTS idx_interactions_resultat
ON bic_poc.interactions_by_client (resultat)
USING 'org.apache.cassandra.index.sai.StorageAttachedIndex';

