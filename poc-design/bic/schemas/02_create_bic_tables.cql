-- =============================================================================
-- Schéma : Création des Tables BIC
-- =============================================================================
-- Date : 2025-12-01
-- Objectif : Créer les tables pour le POC BIC
-- =============================================================================

USE bic_poc;

-- =============================================================================
-- Table Principale : interactions_by_client
-- =============================================================================
-- Description : Stocke toutes les interactions entre conseillers et clients
-- TTL : 2 ans (63072000 secondes)
-- Partition Key : (code_efs, numero_client) - Permet de récupérer toutes les interactions d'un client
-- Clustering : date_interaction DESC, canal ASC, type_interaction ASC, idt_tech ASC
-- =============================================================================

CREATE TABLE IF NOT EXISTS bic_poc.interactions_by_client (
    -- Partition Key
    code_efs text,                    -- Code établissement financier
    numero_client text,                -- Numéro client
    
    -- Clustering Columns
    date_interaction timestamp,        -- Date/heure de l'interaction
    canal text,                        -- Canal (email, SMS, agence, telephone, web, etc.)
    type_interaction text,             -- Type (consultation, conseil, transaction, reclamation, etc.)
    idt_tech text,                     -- Identifiant technique unique
    
    -- Données
    resultat text,                     -- Résultat/statut (succès, échec, en_cours, annule) - BIC-11
    json_data text,                    -- Données JSON complètes de l'interaction
    colonnes_dynamiques map<text, text>, -- Colonnes dynamiques (flexibilité)
    
    -- Métadonnées
    created_at timestamp,               -- Date de création de l'enregistrement
    updated_at timestamp,              -- Date de mise à jour
    version int,                        -- Version de l'enregistrement
    
    PRIMARY KEY ((code_efs, numero_client), date_interaction, canal, type_interaction, idt_tech)
) WITH CLUSTERING ORDER BY (date_interaction DESC, canal ASC, type_interaction ASC)
  AND default_time_to_live = 63072000;  -- 2 ans en secondes (2 * 365 * 24 * 60 * 60)

-- =============================================================================
-- Table Secondaire : interactions_by_conseiller (Optionnel)
-- =============================================================================
-- Description : Vue alternative par conseiller (pour timeline conseiller)
-- =============================================================================

CREATE TABLE IF NOT EXISTS bic_poc.interactions_by_conseiller (
    code_efs text,
    id_conseiller text,                -- Identifiant du conseiller
    date_interaction timestamp,
    numero_client text,
    canal text,
    type_interaction text,
    idt_tech text,
    json_data text,
    colonnes_dynamiques map<text, text>,
    created_at timestamp,
    updated_at timestamp,
    version int,
    
    PRIMARY KEY ((code_efs, id_conseiller), date_interaction, numero_client, canal, type_interaction, idt_tech)
) WITH CLUSTERING ORDER BY (date_interaction DESC, numero_client ASC)
  AND default_time_to_live = 63072000;  -- 2 ans

-- Afficher les tables créées
DESCRIBE TABLES;

