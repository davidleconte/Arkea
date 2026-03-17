-- ============================================
-- Fichier : 03_create_meta_categories_tables.cql
-- Création des 7 tables pour domirama-meta-categories
-- ============================================
--
-- OBJECTIF :
--   Ce fichier crée les 7 tables HCD correspondant à la table HBase
--   'B997X04:domirama-meta-categories' (7 "KeySpaces" logiques).
--
-- CONTEXTE HBase → HCD :
--   - Équivalent HBase : Table 'domirama-meta-categories' avec 7 "KeySpaces" logiques
--   - Transformation : 1 table HBase → 7 tables HCD distinctes (bonnes pratiques CQL)
--   - Fonctionnalités HBase :
--     * VERSIONS => '50' → Table d'historique dédiée
--     * INCREMENT atomique → Type COUNTER
--     * Colonnes dynamiques → Clustering key
--     * REPLICATION_SCOPE => '1' → NetworkTopologyStrategy
--
-- PRÉREQUIS :
--   - Keyspace 'domiramacatops_poc' doit exister
--   - HCD 1.2.3 démarré et accessible sur localhost:9042
--
-- UTILISATION :
--   cqlsh localhost 9042 -f 03_create_meta_categories_tables.cql
--   ou via script shell : ./03_setup_meta_categories_tables.sh
--
-- ============================================

USE domiramacatops_poc;

-- ============================================
-- TABLE 1 : acceptation_client
-- Source HBase : ACCEPT:{code_efs}:{no_contrat}:{no_pse}
-- ============================================
-- LOGIQUE MÉTIER :
--   - accepted BOOLEAN : true = client accepte l'affichage/catégorisation, false = client refuse
--   - accepted_at TIMESTAMP : Date de la décision client (peut être acceptation OU refus)
--   - Si accepted = false, accepted_at peut être renseigné (date du refus)
--   - Si accepted = true, accepted_at doit être renseigné (date de l'acceptation)
--   - Alternative sémantique : accepted_at pourrait être renommé en "decision_at" pour plus de clarté

CREATE TABLE IF NOT EXISTS acceptation_client (
    code_efs      TEXT,
    no_contrat    TEXT,
    no_pse        TEXT,
    accepted_at   TIMESTAMP,  -- Date de la décision client (acceptation OU refus)
    accepted      BOOLEAN,     -- true = accepte, false = refuse
    updated_at    TIMESTAMP,   -- Métadonnée ingestion
    updated_by    TEXT,        -- Métadonnée ingestion

    PRIMARY KEY ((code_efs, no_contrat, no_pse))
);

-- ============================================
-- TABLE 2 : opposition_categorisation
-- Source HBase : OPPOSITION:{code_efs}:{no_pse}
-- ============================================

CREATE TABLE IF NOT EXISTS opposition_categorisation (
    code_efs      TEXT,
    no_pse        TEXT,
    opposed       BOOLEAN,
    opposed_at    TIMESTAMP,
    updated_at    TIMESTAMP,  -- Métadonnée ingestion
    updated_by    TEXT,       -- Métadonnée ingestion

    PRIMARY KEY ((code_efs, no_pse))
);

-- ============================================
-- TABLE 3 : historique_opposition
-- Source HBase : HISTO_OPPOSITION:{code_efs}:{no_pse}:{timestamp} (VERSIONS => '50')
-- Remplace VERSIONS => '50' par table d'historique dédiée
-- ============================================

CREATE TABLE IF NOT EXISTS historique_opposition (
    code_efs      TEXT,
    no_pse        TEXT,
    horodate      TIMEUUID,  -- Clustering key pour ordre chronologique
    status         TEXT,      -- 'opposé' ou 'autorisé'
    timestamp      TIMESTAMP,
    raison         TEXT,      -- Raison du changement (optionnel)

    PRIMARY KEY ((code_efs, no_pse), horodate)
) WITH CLUSTERING ORDER BY (horodate DESC);

-- ============================================
-- TABLE 4 : feedback_par_libelle
-- Source HBase : ANALYZE_LABEL:{type_op}:{sens_op}:{libellé} (compteurs dynamiques)
-- Remplace colonnes dynamiques par clustering key 'categorie'
-- ============================================

CREATE TABLE IF NOT EXISTS feedback_par_libelle (
    type_operation     TEXT,
    sens_operation     TEXT,
    libelle_simplifie  TEXT,
    categorie          TEXT,      -- Clustering key (remplace colonnes dynamiques)
    count_engine       COUNTER,   -- Compteur moteur
    count_client       COUNTER,   -- Compteur client
    -- Note: Les tables COUNTER ne peuvent contenir QUE des colonnes COUNTER
    -- Les métadonnées (last_updated_at, updated_by) ne sont pas supportées

    PRIMARY KEY ((type_operation, sens_operation, libelle_simplifie), categorie)
);

-- ============================================
-- TABLE 5 : feedback_par_ics
-- Source HBase : ICS_DECISION:{type_op}:{sens_op}:{no_ICS} (compteurs dynamiques)
-- Remplace colonnes dynamiques par clustering key 'categorie'
-- ============================================

CREATE TABLE IF NOT EXISTS feedback_par_ics (
    type_operation     TEXT,
    sens_operation     TEXT,
    code_ics           TEXT,
    categorie          TEXT,      -- Clustering key
    count_engine       COUNTER,
    count_client       COUNTER,
    -- Note: Les tables COUNTER ne peuvent contenir QUE des colonnes COUNTER
    -- Les métadonnées (last_updated_at, updated_by) ne sont pas supportées

    PRIMARY KEY ((type_operation, sens_operation, code_ics), categorie)
);

-- ============================================
-- TABLE 6 : regles_personnalisees
-- Source HBase : CUSTOM_RULE:{code_efs}:{type_op}:{sens_op}:{libellé}
-- ============================================

CREATE TABLE IF NOT EXISTS regles_personnalisees (
    code_efs          TEXT,
    type_operation    TEXT,
    sens_operation    TEXT,
    libelle_simplifie TEXT,
    categorie_cible    TEXT,
    actif             BOOLEAN,
    priorite          INT,
    created_at        TIMESTAMP,
    updated_at        TIMESTAMP,
    created_by        TEXT,      -- Métadonnée ingestion
    version           INT,       -- Métadonnée ingestion

    PRIMARY KEY ((code_efs), type_operation, sens_operation, libelle_simplifie)
);

-- ============================================
-- TABLE 7 : decisions_salaires
-- Source HBase : SALARY_DECISION:{libellé}
-- ============================================

CREATE TABLE IF NOT EXISTS decisions_salaires (
    libelle_simplifie  TEXT,
    methode_utilisee    TEXT,
    modele             TEXT,
    actif              BOOLEAN,
    created_at         TIMESTAMP,
    updated_at         TIMESTAMP,

    PRIMARY KEY (libelle_simplifie)
);
