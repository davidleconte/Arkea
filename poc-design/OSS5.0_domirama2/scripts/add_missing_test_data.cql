-- ============================================
-- Fichier : add_missing_test_data.cql
-- Ajout de données manquantes pour les tests avancés
-- ============================================
--
-- OBJECTIF :
--   Ajouter des opérations avec des libellés spécifiques pour permettre
--   aux tests avancés de retourner des résultats.
--
-- CONTEXTE :
--   Certains tests échouent car les données correspondantes n'existent pas
--   dans la table. Ce script ajoute les opérations nécessaires.
--
-- UTILISATION :
--   cqlsh localhost 9042 -f scripts/add_missing_test_data.cql
--
-- ============================================

USE domirama2_poc;

-- Variables pour le compte de test
-- code_si = '1', contrat = '5913101072'

-- ============================================
-- Test 3 : PAIEMENT PAR CARTE BANCAIRE
-- ============================================
INSERT INTO operations_by_account (
    code_si, contrat, date_op, numero_op, op_id,
    libelle, montant, devise, date_valeur, type_operation, sens_operation,
    cat_auto, cat_confidence
) VALUES (
    '1', '5913101072', '2024-11-15 10:30:00', 1001, 'op_test_3_001',
    'PAIEMENT PAR CARTE BANCAIRE', -45.50, 'EUR', '2024-11-15 10:30:00', 'CARTE', 'DEBIT',
    'ALIMENTATION', 0.95
);

-- ============================================
-- Test 4 : Recherche partielle avec libelle_tokens (SET<TEXT>)
-- Note : Le test cherche "carref" (partiel) via libelle_tokens CONTAINS
-- On ajoute les données avec libelle_tokens rempli (ngrams générés)
-- ============================================
-- Fonction Python pour générer les ngrams (3-8 caractères) :
-- def generate_ngrams(text, min_n=3, max_n=8):
--     text_lower = text.lower().replace(' ', '')
--     ngrams = set()
--     for i in range(len(text_lower)):
--         for n in range(min_n, min(max_n + 1, len(text_lower) - i + 1)):
--             ngrams.add(text_lower[i:i+n])
--     return ngrams

INSERT INTO operations_by_account (
    code_si, contrat, date_op, numero_op, op_id,
    libelle, libelle_tokens, montant, devise, date_valeur, type_operation, sens_operation,
    cat_auto, cat_confidence
) VALUES (
    '1', '5913101072', '2024-11-16 14:20:00', 1002, 'op_test_4_001',
    'CB CARREFOUR MARKET PARIS',
    {'cbc', 'bca', 'car', 'arr', 'rre', 'ref', 'efo', 'fou', 'our', 'carref', 'arref', 'rref', 'refo', 'efou', 'four', 'carrefo', 'arrefo', 'rrefo', 'refou', 'efour', 'carrefour', 'mar', 'ark', 'rke', 'ket', 'market', 'par', 'ari', 'ris', 'paris'},
    -28.90, 'EUR', '2024-11-16 14:20:00', 'CARTE', 'DEBIT',
    'ALIMENTATION', 0.92
);

INSERT INTO operations_by_account (
    code_si, contrat, date_op, numero_op, op_id,
    libelle, libelle_tokens, montant, devise, date_valeur, type_operation, sens_operation,
    cat_auto, cat_confidence
) VALUES (
    '1', '5913101072', '2024-11-17 15:30:00', 1002, 'op_test_4_002',
    'CARTE CARREFOUR HYPERMARCHE LILLE',
    {'car', 'art', 'rte', 'carte', 'carref', 'arref', 'rref', 'refo', 'efou', 'four', 'carrefour', 'hyp', 'ype', 'per', 'erm', 'rma', 'mar', 'arc', 'rch', 'che', 'hyperm', 'yperma', 'permar', 'ermarc', 'rmarch', 'marche', 'hypermarche', 'lil', 'ill', 'lle', 'lille'},
    -125.50, 'EUR', '2024-11-17 15:30:00', 'CARTE', 'DEBIT',
    'ALIMENTATION', 0.91
);

INSERT INTO operations_by_account (
    code_si, contrat, date_op, numero_op, op_id,
    libelle, libelle_tokens, montant, devise, date_valeur, type_operation, sens_operation,
    cat_auto, cat_confidence
) VALUES (
    '1', '5913101072', '2024-11-18 10:15:00', 1002, 'op_test_4_003',
    'RETRAIT DAB CARREFOUR PARIS 15EME',
    {'ret', 'etr', 'tra', 'rai', 'ait', 'retra', 'etrai', 'trait', 'retrait', 'dab', 'carref', 'arref', 'rref', 'refo', 'efou', 'four', 'carrefour', 'par', 'ari', 'ris', 'paris', '15e', '5em', 'eme', '15eme'},
    -60.00, 'EUR', '2024-11-18 10:15:00', 'RETRAIT', 'DEBIT',
    'RETRAIT', 0.93
);

-- ============================================
-- Test 5 : VIREMENT PERMANENT MENSUEL
-- ============================================
INSERT INTO operations_by_account (
    code_si, contrat, date_op, numero_op, op_id,
    libelle, montant, devise, date_valeur, type_operation, sens_operation,
    cat_auto, cat_confidence
) VALUES (
    '1', '5913101072', '2024-11-01 00:00:00', 1003, 'op_test_5_001',
    'VIREMENT PERMANENT MENSUEL VERS LIVRET A', -200.00, 'EUR', '2024-11-01 00:00:00', 'VIREMENT', 'DEBIT',
    'EPARGNE', 0.98
);

-- ============================================
-- Test 6 : BANQUE DE PARIS (pour stop words)
-- ============================================
INSERT INTO operations_by_account (
    code_si, contrat, date_op, numero_op, op_id,
    libelle, montant, devise, date_valeur, type_operation, sens_operation,
    cat_auto, cat_confidence
) VALUES (
    '1', '5913101072', '2024-11-10 09:00:00', 1004, 'op_test_6_001',
    'FRAIS BANQUE DE PARIS AGENCE CENTRALE', -15.00, 'EUR', '2024-11-10 09:00:00', 'FRAIS', 'DEBIT',
    'FRAIS', 0.99
);

-- ============================================
-- Test 8 : PRELEVEMENT AUTOMATIQUE FACTURE
-- ============================================
INSERT INTO operations_by_account (
    code_si, contrat, date_op, numero_op, op_id,
    libelle, montant, devise, date_valeur, type_operation, sens_operation,
    cat_auto, cat_confidence
) VALUES (
    '1', '5913101072', '2024-11-05 00:00:00', 1005, 'op_test_8_001',
    'PRELEVEMENT AUTOMATIQUE FACTURE EDF NOVEMBRE', -85.30, 'EUR', '2024-11-05 00:00:00', 'PRELEVEMENT', 'DEBIT',
    'ENERGIE', 0.96
);

-- ============================================
-- Test 15 : EDF ORANGE (noms propres)
-- ============================================
-- Données séparées (EDF seul, ORANGE seul)
INSERT INTO operations_by_account (
    code_si, contrat, date_op, numero_op, op_id,
    libelle, montant, devise, date_valeur, type_operation, sens_operation,
    cat_auto, cat_confidence
) VALUES (
    '1', '5913101072', '2024-11-08 00:00:00', 1006, 'op_test_15_001',
    'PRELEVEMENT EDF FACTURE ELECTRICITE', -95.50, 'EUR', '2024-11-08 00:00:00', 'PRELEVEMENT', 'DEBIT',
    'ENERGIE', 0.97
);

INSERT INTO operations_by_account (
    code_si, contrat, date_op, numero_op, op_id,
    libelle, montant, devise, date_valeur, type_operation, sens_operation,
    cat_auto, cat_confidence
) VALUES (
    '1', '5913101072', '2024-11-12 00:00:00', 1007, 'op_test_15_002',
    'PRELEVEMENT ORANGE FACTURE TELEPHONE', -35.90, 'EUR', '2024-11-12 00:00:00', 'PRELEVEMENT', 'DEBIT',
    'TELECOM', 0.94
);

-- Donnée pour Test 15 : EDF ET ORANGE dans le même libellé
INSERT INTO operations_by_account (
    code_si, contrat, date_op, numero_op, op_id,
    libelle, montant, devise, date_valeur, type_operation, sens_operation,
    cat_auto, cat_confidence
) VALUES (
    '1', '5913101072', '2024-11-25 00:00:00', 1015, 'op_test_15_003',
    'PRELEVEMENT EDF ET ORANGE FACTURES COMBINEES', -131.40, 'EUR', '2024-11-25 00:00:00', 'PRELEVEMENT', 'DEBIT',
    'DIVERS', 0.95
);

-- ============================================
-- Test 16 : Numéro de chèque 1234567890
-- ============================================
INSERT INTO operations_by_account (
    code_si, contrat, date_op, numero_op, op_id,
    libelle, montant, devise, date_valeur, type_operation, sens_operation,
    cat_auto, cat_confidence
) VALUES (
    '1', '5913101072', '2024-11-20 11:00:00', 1008, 'op_test_16_001',
    'CHEQUE 1234567890 EMIS PARIS', -150.00, 'EUR', '2024-11-20 11:00:00', 'CHEQUE', 'DEBIT',
    'DIVERS', 0.91
);

-- ============================================
-- Test 17 : DAB SEPA (abréviations)
-- ============================================
INSERT INTO operations_by_account (
    code_si, contrat, date_op, numero_op, op_id,
    libelle, montant, devise, date_valeur, type_operation, sens_operation,
    cat_auto, cat_confidence
) VALUES (
    '1', '5913101072', '2024-11-18 16:45:00', 1009, 'op_test_17_001',
    'RETRAIT DAB SEPA PARIS 15EME', -50.00, 'EUR', '2024-11-18 16:45:00', 'RETRAIT', 'DEBIT',
    'RETRAIT', 0.93
);

-- ============================================
-- Test 18 : PARIS 15EME 16EME (localisation précise)
-- ============================================
-- Données séparées (paris + 15eme, paris + 16eme)
INSERT INTO operations_by_account (
    code_si, contrat, date_op, numero_op, op_id,
    libelle, montant, devise, date_valeur, type_operation, sens_operation,
    cat_auto, cat_confidence
) VALUES (
    '1', '5913101072', '2024-11-19 12:30:00', 1010, 'op_test_18_001',
    'CB RESTAURANT PARIS 15EME RUE VAUGIRARD', -32.50, 'EUR', '2024-11-19 12:30:00', 'CARTE', 'DEBIT',
    'RESTAURANT', 0.90
);

INSERT INTO operations_by_account (
    code_si, contrat, date_op, numero_op, op_id,
    libelle, montant, devise, date_valeur, type_operation, sens_operation,
    cat_auto, cat_confidence
) VALUES (
    '1', '5913101072', '2024-11-21 19:00:00', 1011, 'op_test_18_002',
    'CB CINEMA PARIS 16EME AVENUE FOCH', -12.00, 'EUR', '2024-11-21 19:00:00', 'CARTE', 'DEBIT',
    'LOISIRS', 0.88
);

-- Donnée pour Test 18 : PARIS ET 15EME ET 16EME dans le même libellé
INSERT INTO operations_by_account (
    code_si, contrat, date_op, numero_op, op_id,
    libelle, montant, devise, date_valeur, type_operation, sens_operation,
    cat_auto, cat_confidence
) VALUES (
    '1', '5913101072', '2024-11-23 12:00:00', 1016, 'op_test_18_003',
    'CB RESTAURANT PARIS 15EME PUIS CINEMA PARIS 16EME', -45.00, 'EUR', '2024-11-23 12:00:00', 'CARTE', 'DEBIT',
    'LOISIRS', 0.90
);

-- ============================================
-- Test 19 : CONTACTLESS INSTANTANE (termes techniques)
-- ============================================
INSERT INTO operations_by_account (
    code_si, contrat, date_op, numero_op, op_id,
    libelle, montant, devise, date_valeur, type_operation, sens_operation,
    cat_auto, cat_confidence
) VALUES (
    '1', '5913101072', '2024-11-22 08:15:00', 1012, 'op_test_19_001',
    'PAIEMENT CONTACTLESS INSTANTANE PARIS METRO', -2.10, 'EUR', '2024-11-22 08:15:00', 'CARTE', 'DEBIT',
    'TRANSPORT', 0.89
);

-- ============================================
-- Test 20 : VIREMENT PERMANENT (avec filtres)
-- ============================================
INSERT INTO operations_by_account (
    code_si, contrat, date_op, numero_op, op_id,
    libelle, montant, devise, date_valeur, type_operation, sens_operation,
    cat_auto, cat_confidence
) VALUES (
    '1', '5913101072', '2023-12-01 00:00:00', 1013, 'op_test_20_001',
    'VIREMENT PERMANENT VERS ASSURANCE VIE', -300.00, 'EUR', '2023-12-01 00:00:00', 'VIREMENT', 'DEBIT',
    'VIREMENT', 0.99
);

INSERT INTO operations_by_account (
    code_si, contrat, date_op, numero_op, op_id,
    libelle, montant, devise, date_valeur, type_operation, sens_operation,
    cat_auto, cat_confidence
) VALUES (
    '1', '5913101072', '2024-01-01 00:00:00', 1014, 'op_test_20_002',
    'VIREMENT PERMANENT VERS LIVRET A', -250.00, 'EUR', '2024-01-01 00:00:00', 'VIREMENT', 'DEBIT',
    'VIREMENT', 0.98
);

-- ============================================
-- Vérification
-- ============================================
SELECT code_si, contrat, libelle, montant, cat_auto, date_op
FROM operations_by_account
WHERE code_si = '1' AND contrat = '5913101072'
  AND date_op >= '2023-11-01'
ORDER BY date_op DESC
LIMIT 20;
