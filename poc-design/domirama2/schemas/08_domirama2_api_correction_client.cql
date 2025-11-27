-- ============================================
-- Fichier : 08_domirama2_api_correction_client.cql
-- Exemples d'API Correction Client (Stratégie Multi-Version)
-- ============================================
--
-- OBJECTIF :
--   Ce fichier contient des exemples d'utilisation de l'API pour les corrections
--   client, démontrant la stratégie multi-version conforme à la proposition IBM.
--   
--   Stratégie Multi-Version (conforme IBM) :
--   - Le BATCH écrit UNIQUEMENT cat_auto et cat_confidence
--   - Le CLIENT écrit dans cat_user, cat_date_user, cat_validee
--   - L'APPLICATION priorise cat_user si non nul, sinon cat_auto
--   - Cette séparation garantit qu'aucune correction client ne sera perdue
--     lors des ré-exécutions du batch
--
-- CONTEXTE HBase → HCD :
--   - Équivalent HBase : Mise à jour de colonnes dans CF 'categorisation'
--   - Différences :
--     * Séparation explicite batch/client (vs logique applicative HBase)
--     * Colonnes typées (cat_user, cat_date_user, cat_validee)
--   - Améliorations :
--     * Garantie de non-perte des corrections client
--     * Time travel possible (via cat_date_user)
--     * Traçabilité complète des modifications
--
-- PRÉREQUIS :
--   - Keyspace et table créés (01_create_domirama2_schema.cql)
--   - Données chargées dans la table (batch)
--   - API client configurée
--
-- UTILISATION :
--   cqlsh localhost 9042 -f 08_domirama2_api_correction_client.cql
--   ou via script shell : ./13_test_domirama2_api_client.sh
--
-- EXEMPLE :
--   cqlsh localhost 9042 -f schemas/08_domirama2_api_correction_client.cql
--
-- SORTIE :
--   - Exemples d'UPDATE pour correction client
--   - Vérification que cat_user est mis à jour (cat_auto non modifié)
--   - Démonstration de la logique de priorité
--
-- ============================================

USE domirama2_poc;

-- ============================================
-- EXEMPLE 1 : Correction Catégorie par Client
-- ============================================
-- Le client corrige la catégorie d'une opération via l'API
-- 
-- IMPORTANT - Stratégie Multi-Version :
--   - L'API écrit UNIQUEMENT dans cat_user, cat_date_user, cat_validee
--   - L'API NE TOUCHE JAMAIS cat_auto (qui reste la valeur du batch)
--   - Cette séparation garantit qu'aucune correction client ne sera perdue
--     lors des ré-exécutions du batch
-- ============================================

UPDATE operations_by_account
SET cat_user = 'ALIMENTATION',  -- Nouvelle catégorie choisie par le client
    cat_date_user = toTimestamp(now()),  -- Date de modification
    cat_validee = true  -- Client accepte cette catégorie
WHERE code_si = '01'
  AND contrat = '1234567890'
  AND date_op = '2024-03-10 09:00:00+0000'
  AND numero_op = 4;

-- ============================================
-- EXEMPLE 2 : Client Accepte la Catégorie Automatique
-- ============================================
-- Le client valide la catégorie proposée par le batch
-- 
-- Stratégie : On met juste cat_validee = true, sans modifier cat_user
-- Cela permet de tracer que le client a validé la catégorie automatique
-- ============================================

UPDATE operations_by_account
SET cat_validee = true
WHERE code_si = '01'
  AND contrat = '1234567890'
  AND date_op = '2024-03-15 14:20:00+0000'
  AND numero_op = 5;

-- ============================================
-- EXEMPLE 3 : Client Rejette la Catégorie Automatique
-- ============================================
-- Le client rejette la catégorie proposée par le batch et en propose une autre
-- 
-- Stratégie : On met cat_user avec la nouvelle catégorie et cat_validee = false
-- Cela permet de tracer que le client a rejeté la catégorie automatique
-- ============================================

UPDATE operations_by_account
SET cat_user = 'DIVERS',  -- Catégorie alternative
    cat_date_user = toTimestamp(now()),
    cat_validee = false  -- Client rejette la proposition automatique
WHERE code_si = '01'
  AND contrat = '1234567890'
  AND date_op = '2024-03-20 11:30:00+0000'
  AND numero_op = 6;

-- ============================================
-- VÉRIFICATION : Lecture avec Priorité cat_user vs cat_auto
-- ============================================
-- L'application doit prioriser cat_user si non nul, sinon cat_auto
-- 
-- Logique de priorité (à implémenter côté application) :
--   - Si cat_user IS NOT NULL → utiliser cat_user (correction client)
--   - Sinon → utiliser cat_auto (catégorie batch)
-- 
-- Note : COALESCE n'existe pas en CQL, la logique doit être gérée côté application
-- Exemple côté app : cat_user IS NOT NULL ? cat_user : cat_auto
-- ============================================

-- Logique de priorité (à implémenter côté application) :
--   - Si cat_user IS NOT NULL → utiliser cat_user (correction client)
--   - Sinon → utiliser cat_auto (catégorie batch)
-- Note: COALESCE n'existe pas en CQL, la logique doit être gérée côté application
-- Exemple côté app: cat_user IS NOT NULL ? cat_user : cat_auto

SELECT 
    code_si,
    contrat,
    date_op,
    numero_op,
    libelle,
    montant,
    cat_auto,        -- Catégorie automatique (batch)
    cat_confidence,  -- Score du moteur
    cat_user,        -- Catégorie client (si corrigée)
    cat_date_user,   -- Date de modification client
    cat_validee      -- Acceptation client
FROM operations_by_account
WHERE code_si = '01'
  AND contrat = '1234567890'
ORDER BY date_op DESC
LIMIT 10;

