-- =============================================================================
-- Schéma : Création du Keyspace BIC
-- =============================================================================
-- Date : 2025-12-01
-- Objectif : Créer le keyspace pour le POC BIC
-- =============================================================================

-- Créer le keyspace avec réplication SimpleStrategy (pour POC)
CREATE KEYSPACE IF NOT EXISTS bic_poc
WITH REPLICATION = {
    'class': 'SimpleStrategy',
    'replication_factor': 1
};

-- Utiliser le keyspace
USE bic_poc;

-- Afficher la confirmation
DESCRIBE KEYSPACE bic_poc;

