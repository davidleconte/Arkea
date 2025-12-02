# 📋 Plan de Mise en Œuvre - POC BIC

**Date** : 2025-12-01  
**Version** : 1.0.0  
**Objectif** : Plan détaillé script par script pour l'implémentation du POC BIC  
**Méthodologie** : Identique à `domiramaCatOps` avec contrôles qualité renforcés

---

## 📊 Résumé Exécutif

**Total Scripts Essentiels** : **18 scripts** (01-18) ✅  
**Total Scripts Optionnels/Futurs** : **7 scripts** (19-25) ⏳  
**Phases** : **5 phases** (Setup, Génération, Ingestion, Tests, Recherche)  
**Niveau de Qualité** : **Au moins égal à domiramaCatOps**  
**Contrôles** : Pertinence, Cohérence, Intégrité, Consistance, Conformité

---

## 🎯 Use Cases BIC à Couvrir

| Use Case | Description | Priorité | Scripts |
|----------|-------------|----------|---------|
| **BIC-01** | Timeline conseiller (2 ans d'historique) | 🔴 Critique | 11, 17, 21 |
| **BIC-02** | Ingestion Kafka temps réel (bic-event) | 🔴 Critique | 09, 22 |
| **BIC-03** | Export batch ORC incrémental (bic-unload) | 🟡 Haute | 14, 23 |
| **BIC-04** | Filtrage par canal (email, SMS, agence...) | 🟡 Haute | 12, 18 |
| **BIC-05** | Filtrage par type d'interaction | 🟡 Haute | 13, 18 |
| **BIC-06** | TTL 2 ans (vs 10 ans Domirama) | 🔴 Critique | 15, 24 |
| **BIC-07** | Format JSON + colonnes dynamiques | 🟡 Haute | 08, 16 |
| **BIC-08** | Backend API conseiller (lecture temps réel) | 🔴 Critique | 20, 24 |
| **BIC-09** | Écriture batch (bulkLoad équivalent) | 🟡 Haute | 08 |
| **BIC-10** | Lecture batch (STARTROW/STOPROW/TIMERANGE) | 🟡 Haute | 14 |
| **BIC-11** | Filtrage par résultat | 🟡 Moyenne | 12, 18 |
| **BIC-12** | Recherche full-text avec analyseurs Lucene | 🟡 Haute | 16 |
| **BIC-14** | Pagination | 🟡 Haute | 11, 17 |
| **BIC-15** | Filtres combinés exhaustifs | 🟡 Haute | 18 |

---

## 📋 PHASE 1 : SETUP (Scripts 01-04)

### Script 01 : Setup BIC Keyspace ✅ (DÉJÀ CRÉÉ)

**Fichier** : `scripts/01_setup_bic_keyspace.sh`  
**Statut** : ✅ Créé  
**Objectif** : Créer le keyspace `bic_poc`

**Contrôles de Validation** :
- ✅ **Pertinence** : Keyspace créé avec réplication SimpleStrategy (POC)
- ✅ **Cohérence** : Nom conforme (`bic_poc`)
- ✅ **Intégrité** : Vérification que le keyspace existe après création
- ✅ **Consistance** : Utilise `setup_paths()` et fonctions didactiques
- ✅ **Conformité** : Conforme aux exigences IBM (keyspace dédié)

**Critères de Qualité** :
- [x] Utilise `set -euo pipefail`
- [x] Utilise `setup_paths()` depuis `utils/didactique_functions.sh`
- [x] Messages colorés (info, success, error, warn)
- [x] Vérifications préalables (HCD démarré)
- [x] Gestion d'erreurs complète
- [x] Documentation inline complète

**Ordre d'Exécution** : **1er**

---

### Script 02 : Setup BIC Tables ✅ (DÉJÀ CRÉÉ)

**Fichier** : `scripts/02_setup_bic_tables.sh`  
**Statut** : ✅ Créé  
**Objectif** : Créer les tables `interactions_by_client` et `interactions_by_conseiller`

**Contrôles de Validation** :
- ✅ **Pertinence** : Tables créées avec schéma conforme IBM
- ✅ **Cohérence** : Partition key `(code_efs, numero_client)` conforme
- ✅ **Intégrité** : Clustering ORDER BY `date_interaction DESC` conforme
- ✅ **Consistance** : TTL 2 ans (63072000 secondes) conforme
- ✅ **Conformité** : Colonnes conformes aux exigences (json_data, colonnes_dynamiques)

**Critères de Qualité** :
- [x] Utilise `set -euo pipefail`
- [x] Utilise `setup_paths()`
- [x] Messages colorés
- [x] Vérifications préalables (keyspace existe)
- [x] Gestion d'erreurs
- [x] Documentation inline

**Ordre d'Exécution** : **2ème** (après 01)

---

### Script 03 : Setup BIC Indexes ✅ (DÉJÀ CRÉÉ)

**Fichier** : `scripts/03_setup_bic_indexes.sh`  
**Statut** : ✅ Créé  
**Objectif** : Créer les index SAI pour recherche avancée

**Contrôles de Validation** :
- ✅ **Pertinence** : Index SAI sur colonnes filtrables (canal, type_interaction, date_interaction, json_data)
- ✅ **Cohérence** : Index conformes aux exigences IBM (SAI Storage-Attached Index)
- ✅ **Intégrité** : Index créés avec options correctes (case_sensitive, normalize)
- ✅ **Consistance** : Noms d'index cohérents (`idx_interactions_*`)
- ✅ **Conformité** : Index full-text sur json_data conforme

**Critères de Qualité** :
- [x] Utilise `set -euo pipefail`
- [x] Utilise `setup_paths()`
- [x] Messages colorés
- [x] Vérifications préalables (tables existent)
- [x] Gestion d'erreurs
- [x] Documentation inline

**Ordre d'Exécution** : **3ème** (après 02)

---

### Script 04 : Verify Setup ✅ (DÉJÀ CRÉÉ)

**Fichier** : `scripts/04_verify_setup.sh`  
**Statut** : ✅ Créé  
**Objectif** : Vérifier que le setup est complet et fonctionnel

**Contrôles de Validation** :
- ✅ **Pertinence** : Vérifie keyspace, tables, index
- ✅ **Cohérence** : Vérifie que tous les éléments sont présents
- ✅ **Intégrité** : Test de connexion et requête
- ✅ **Consistance** : Rapport de vérification complet
- ✅ **Conformité** : Vérifie conformité aux exigences

**Critères de Qualité** :
- [x] Utilise `set -euo pipefail`
- [x] Utilise `setup_paths()`
- [x] Messages colorés
- [x] Vérifications complètes
- [x] Rapport détaillé
- [x] Documentation inline

**Ordre d'Exécution** : **4ème** (après 03)

---

## 📋 PHASE 2 : GÉNÉRATION DE DONNÉES (Scripts 05-07)

### Script 05 : Generate Interactions Parquet ✅ (DÉJÀ CRÉÉ)

**Fichier** : `scripts/05_generate_interactions_parquet.sh`  
**Statut** : ✅ Créé  
**Objectif** : Générer des données de test Parquet pour BIC

**Exigences** :
- Générer au moins 10 000 interactions
- Couvrir tous les canaux (email, SMS, agence, telephone, web, RDV)
- Couvrir tous les types (consultation, conseil, transaction, reclamation)
- Période : 2 ans d'historique
- Format : Parquet avec colonnes conformes au schéma

**Contrôles de Validation** :
- ⏳ **Pertinence** : Données réalistes et variées
- ⏳ **Cohérence** : Format Parquet conforme
- ⏳ **Intégrité** : Toutes les colonnes requises présentes
- ⏳ **Consistance** : Distribution temporelle sur 2 ans
- ⏳ **Conformité** : Conforme au schéma `interactions_by_client`

**Critères de Qualité** (au moins égal à domiramaCatOps) :
- [ ] Utilise `set -euo pipefail`
- [ ] Utilise `setup_paths()`
- [ ] Messages colorés (info, success, error, warn, demo, code, section, result, expected)
- [ ] Documentation inline complète (OBJECTIF, PRÉREQUIS, UTILISATION, SORTIE)
- [ ] Code Spark complet avec explications
- [ ] Génération de rapport didactique
- [ ] Vérifications préalables
- [ ] Gestion d'erreurs complète
- [ ] Affichage des statistiques de génération

**Référence** : `domiramaCatOps/scripts/04_generate_operations_parquet.sh`

**Ordre d'Exécution** : **5ème** (après 04)

---

### Script 06 : Generate Interactions JSON ✅ (DÉJÀ CRÉÉ)

**Fichier** : `scripts/06_generate_interactions_json.sh`  
**Statut** : ✅ Créé  
**Objectif** : Générer des données de test JSON pour ingestion temps réel

**Exigences** :
- Générer des événements JSON conformes au format Kafka `bic-event`
- Format compatible avec ingestion Kafka
- Au moins 1 000 événements
- Structure JSON conforme aux exigences

**Contrôles de Validation** :
- ⏳ **Pertinence** : Format JSON conforme Kafka
- ⏳ **Cohérence** : Structure conforme aux exigences
- ⏳ **Intégrité** : Tous les champs requis présents
- ⏳ **Consistance** : Format uniforme
- ⏳ **Conformité** : Conforme au format `bic-event`

**Critères de Qualité** :
- [ ] Utilise `set -euo pipefail`
- [ ] Utilise `setup_paths()`
- [ ] Messages colorés
- [ ] Documentation inline complète
- [ ] Génération de rapport didactique
- [ ] Vérifications préalables
- [ ] Gestion d'erreurs
- [ ] Affichage des statistiques

**Ordre d'Exécution** : **6ème** (après 05)

---

### Script 07 : Generate Test Data ✅ (DÉJÀ CRÉÉ)

**Fichier** : `scripts/07_generate_test_data.sh`  
**Statut** : ✅ Créé  
**Objectif** : Générer des données de test spécifiques pour les tests

**Exigences** :
- Données ciblées pour chaque test
- Scénarios de test couverts
- Données de validation

**Contrôles de Validation** :
- ⏳ **Pertinence** : Données adaptées aux tests
- ⏳ **Cohérence** : Format conforme
- ⏳ **Intégrité** : Couverture complète des scénarios
- ⏳ **Consistance** : Données reproductibles
- ⏳ **Conformité** : Conforme aux besoins de test

**Critères de Qualité** :
- [ ] Utilise `set -euo pipefail`
- [ ] Utilise `setup_paths()`
- [ ] Messages colorés
- [ ] Documentation inline complète
- [ ] Génération de rapport didactique
- [ ] Vérifications préalables
- [ ] Gestion d'erreurs

**Ordre d'Exécution** : **7ème** (après 06)

---

## 📋 PHASE 3 : INGESTION (Scripts 08-10)

### Script 08 : Load Interactions Batch ✅ (DÉJÀ CRÉÉ)

**Fichier** : `scripts/08_load_interactions_batch.sh`  
**Statut** : ✅ Créé  
**Objectif** : Ingestion batch des données Parquet dans HCD (équivalent bulkLoad HBase - BIC-09)

**Exigences** :
- Lecture Parquet via Spark
- Écriture dans `interactions_by_client`
- Transformation des données si nécessaire
- Gestion des erreurs
- Rapport de chargement
- **NOUVEAU** : Documenter équivalence avec bulkLoad HBase (inputs-clients)

**Contrôles de Validation** :
- ⏳ **Pertinence** : Ingestion batch conforme
- ⏳ **Cohérence** : Mapping Parquet → HCD correct
- ⏳ **Intégrité** : Toutes les données chargées
- ⏳ **Consistance** : Pas de doublons
- ⏳ **Conformité** : Conforme aux exigences batch

**Critères de Qualité** (au moins égal à domiramaCatOps) :
- [ ] Utilise `set -euo pipefail`
- [ ] Utilise `setup_paths()`
- [ ] Messages colorés complets
- [ ] Documentation inline complète
- [ ] Code Spark complet avec explications détaillées
- [ ] Génération de rapport didactique (`doc/demonstrations/08_INGESTION_BATCH_DEMONSTRATION.md`)
- [ ] Vérifications préalables (HCD, Spark, fichiers Parquet)
- [ ] Gestion d'erreurs complète
- [ ] Affichage des statistiques de chargement
- [ ] Vérification post-chargement (comptage, échantillonnage)

**Référence** : `domiramaCatOps/scripts/05_load_operations_data_parquet.sh`

**Ordre d'Exécution** : **8ème** (après 07)

---

### Script 09 : Load Interactions Realtime (Kafka) ✅ (DÉJÀ CRÉÉ)

**Fichier** : `scripts/09_load_interactions_realtime.sh`  
**Statut** : ✅ Créé  
**Objectif** : Ingestion temps réel depuis Kafka (topic `bic-event`)

**Exigences** :
- Consumer Kafka pour topic `bic-event`
- Spark Streaming ou Kafka Connect
- Écriture en temps réel dans HCD
- Gestion des erreurs et reprise
- Monitoring du flux

**Contrôles de Validation** :
- ✅ **Pertinence** : Ingestion temps réel conforme
- ✅ **Cohérence** : Format Kafka → HCD correct
- ✅ **Intégrité** : Tous les événements traités
- ✅ **Consistance** : Pas de perte de données
- ✅ **Conformité** : Conforme aux exigences Kafka (BIC-02)

**Critères de Qualité** :
- [x] Utilise `set -euo pipefail`
- [x] Utilise `setup_paths()`
- [x] Messages colorés complets
- [x] Documentation inline complète
- [x] Code Spark Streaming complet avec explications
- [x] Génération de rapport didactique (`doc/demonstrations/09_INGESTION_KAFKA_DEMONSTRATION.md`)
- [x] Vérifications préalables (Kafka, HCD, topic `bic-event`)
- [x] Gestion d'erreurs et reprise
- [x] Monitoring du flux
- [x] Statistiques de traitement

**Référence** : `domiramaCatOps/scripts/27_demo_kafka_streaming.sh`

**Ordre d'Exécution** : **9ème** (après 08)

---

### Script 10 : Load Interactions JSON ✅ (DÉJÀ CRÉÉ)

**Fichier** : `scripts/10_load_interactions_json.sh`  
**Statut** : ✅ Créé  
**Objectif** : Ingestion de fichiers JSON individuels

**Exigences** :
- Lecture de fichiers JSON
- Écriture dans HCD
- Gestion des erreurs

**Contrôles de Validation** :
- ✅ **Pertinence** : Ingestion JSON conforme
- ✅ **Cohérence** : Format JSON → HCD correct
- ✅ **Intégrité** : Toutes les données chargées
- ✅ **Consistance** : Format uniforme
- ✅ **Conformité** : Conforme aux exigences

**Critères de Qualité** :
- [x] Utilise `set -euo pipefail`
- [x] Utilise `setup_paths()`
- [x] Messages colorés
- [x] Documentation inline complète
- [x] Génération de rapport didactique (`doc/demonstrations/10_INGESTION_JSON_DEMONSTRATION.md`)
- [x] Vérifications préalables
- [x] Gestion d'erreurs

**Ordre d'Exécution** : **10ème** (après 09)

---

## 📋 PHASE 4 : TESTS (Scripts 11-15)

### Script 11 : Test Timeline Conseiller ✅ (DÉJÀ CRÉÉ)

**Fichier** : `scripts/11_test_timeline_conseiller.sh`  
**Statut** : ✅ Créé  
**Objectif** : Tester la timeline conseiller (BIC-01) avec pagination (BIC-14)

**Exigences** :
- Requête timeline complète d'un client
- Tri chronologique DESC
- **NOUVEAU** : Pagination explicite (LIMIT/OFFSET) - **BIC-14**
- Performance < 100ms
- Couverture 2 ans d'historique

**Contrôles de Validation** :
- ⏳ **Pertinence** : Timeline conforme aux exigences
- ⏳ **Cohérence** : Tri chronologique correct
- ⏳ **Intégrité** : Toutes les interactions présentes
- ⏳ **Consistance** : Ordre cohérent
- ⏳ **Conformité** : Conforme BIC-01 (timeline 2 ans) et BIC-14 (pagination)

**Critères de Qualité** (au moins égal à domiramaCatOps) :
- [ ] Utilise `set -euo pipefail`
- [ ] Utilise `setup_paths()` et fonctions didactiques
- [ ] Messages colorés complets
- [ ] Documentation inline complète
- [ ] Requêtes CQL avec explications détaillées
- [ ] Génération de rapport didactique (`doc/demonstrations/11_TIMELINE_DEMONSTRATION.md`)
- [ ] Tests de performance
- [ ] Vérifications de résultats
- [ ] Comparaison avec attentes
- [ ] **NOUVEAU** : Tests de pagination (LIMIT, OFFSET, page suivante/précédente)

**Référence** : `domiramaCatOps/scripts/13_test_dynamic_columns.sh`

**Ordre d'Exécution** : **11ème** (après 10)

---

### Script 12 : Test Filtrage Canal ✅ (DÉJÀ CRÉÉ)

**Fichier** : `scripts/12_test_filtrage_canal.sh`  
**Statut** : ✅ Créé  
**Objectif** : Tester le filtrage par canal (BIC-04) et par résultat (BIC-11)

**Exigences** :
- Filtrage par canal (email, SMS, agence, telephone, web, RDV, agenda, mail)
- Filtrage par résultat (succès, échec, etc.) - **BIC-11**
- Utilisation des index SAI
- Performance optimale

**Contrôles de Validation** :
- ⏳ **Pertinence** : Filtrage conforme (canal + résultat)
- ⏳ **Cohérence** : Utilisation des index SAI
- ⏳ **Intégrité** : Résultats corrects
- ⏳ **Consistance** : Performance constante
- ⏳ **Conformité** : Conforme BIC-04 et BIC-11

**Critères de Qualité** :
- [ ] Utilise `set -euo pipefail`
- [ ] Utilise `setup_paths()` et fonctions didactiques
- [ ] Messages colorés complets
- [ ] Documentation inline complète
- [ ] Requêtes CQL avec explications
- [ ] Génération de rapport didactique
- [ ] Tests de performance
- [ ] Vérifications de résultats
- [ ] **NOUVEAU** : Tests de filtrage par résultat

**Ordre d'Exécution** : **12ème** (après 11)

---

### Script 13 : Test Filtrage Type ✅ (DÉJÀ CRÉÉ)

**Fichier** : `scripts/13_test_filtrage_type.sh`  
**Statut** : ✅ Créé  
**Objectif** : Tester le filtrage par type d'interaction (BIC-05)

**Exigences** :
- Filtrage par type (consultation, conseil, transaction, reclamation)
- Utilisation des index SAI
- Performance optimale

**Contrôles de Validation** :
- ✅ **Pertinence** : Filtrage conforme
- ✅ **Cohérence** : Utilisation des index SAI
- ✅ **Intégrité** : Résultats corrects
- ✅ **Consistance** : Performance constante
- ✅ **Conformité** : Conforme BIC-05

**Critères de Qualité** :
- [x] Utilise `set -euo pipefail`
- [x] Utilise `setup_paths()` et fonctions didactiques
- [x] Messages colorés complets
- [x] Documentation inline complète
- [x] Requêtes CQL avec explications
- [x] Génération de rapport didactique (`doc/demonstrations/13_FILTRAGE_TYPE_DEMONSTRATION.md`)
- [x] Tests de performance
- [x] Vérifications de résultats

**Ordre d'Exécution** : **13ème** (après 12)

---

### Script 14 : Test Export Batch ✅ (DÉJÀ CRÉÉ)

**Fichier** : `scripts/14_test_export_batch.sh`  
**Statut** : ✅ Créé  
**Objectif** : Tester l'export batch ORC (BIC-03) avec équivalences HBase (BIC-10)

**Exigences** :
- Export incrémental ORC
- Filtrage par période
- Format ORC conforme
- Export vers HDFS (simulé localement)
- **NOUVEAU** : Documenter équivalence STARTROW/STOPROW (filtrage par client_id)
- **NOUVEAU** : Documenter équivalence TIMERANGE (filtrage par date_interaction)

**Contrôles de Validation** :
- ⏳ **Pertinence** : Export conforme
- ⏳ **Cohérence** : Format ORC correct
- ⏳ **Intégrité** : Toutes les données exportées
- ⏳ **Consistance** : Export incrémental fonctionnel
- ⏳ **Conformité** : Conforme BIC-03 (bic-unload)

**Critères de Qualité** :
- [ ] Utilise `set -euo pipefail`
- [ ] Utilise `setup_paths()`
- [ ] Messages colorés complets
- [ ] Documentation inline complète
- [ ] Code Spark complet avec explications
- [ ] Génération de rapport didactique
- [ ] Vérifications préalables
- [ ] Gestion d'erreurs
- [ ] Vérification du fichier ORC généré

**Ordre d'Exécution** : **14ème** (après 13)

---

### Script 15 : Test TTL ✅ (DÉJÀ CRÉÉ)

**Fichier** : `scripts/15_test_ttl.sh`  
**Statut** : ✅ Créé  
**Objectif** : Tester le TTL 2 ans (BIC-06)

**Exigences** :
- Vérification du TTL 2 ans
- Test d'expiration automatique
- Validation de la purge

**Contrôles de Validation** :
- ✅ **Pertinence** : TTL conforme
- ✅ **Cohérence** : TTL 2 ans (63072000 secondes)
- ✅ **Intégrité** : Expiration automatique fonctionnelle
- ✅ **Consistance** : Purge cohérente
- ✅ **Conformité** : Conforme BIC-06

**Critères de Qualité** :
- [x] Utilise `set -euo pipefail`
- [x] Utilise `setup_paths()`
- [x] Messages colorés complets
- [x] Documentation inline complète
- [x] Tests de TTL avec explications
- [x] Génération de rapport didactique (`doc/demonstrations/15_TTL_DEMONSTRATION.md`)
- [x] Vérifications préalables
- [x] Gestion d'erreurs

**Ordre d'Exécution** : **15ème** (après 14)

---

## 📋 PHASE 5 : RECHERCHE ET DÉMONSTRATIONS (Scripts 16-25)

### Script 16 : Test Full-Text Search ✅ (DÉJÀ CRÉÉ)

**Fichier** : `scripts/16_test_fulltext_search.sh`  
**Statut** : ✅ Créé  
**Objectif** : Tester la recherche full-text sur json_data/details (BIC-07, BIC-12)

**Exigences** :
- Recherche full-text dans json_data/details
- Utilisation des index SAI full-text
- Recherche par mots-clés
- **NOUVEAU** : Support analyseurs Lucene (français) - **BIC-12**
- **NOUVEAU** : Recherche par préfixe, racine (stemming)
- **NOUVEAU** : Recherche floue (fuzzy)

**Contrôles de Validation** :
- ⏳ **Pertinence** : Recherche full-text conforme avec analyseurs
- ⏳ **Cohérence** : Utilisation des index SAI avec analyseurs Lucene
- ⏳ **Intégrité** : Résultats corrects
- ⏳ **Consistance** : Performance acceptable
- ⏳ **Conformité** : Conforme BIC-07 et BIC-12

**Critères de Qualité** :
- [ ] Utilise `set -euo pipefail`
- [ ] Utilise `setup_paths()` et fonctions didactiques
- [ ] Messages colorés complets
- [ ] Documentation inline complète
- [ ] Requêtes CQL avec explications
- [ ] Génération de rapport didactique
- [ ] Tests de performance
- [ ] Vérifications de résultats
- [ ] **NOUVEAU** : Configuration analyseurs Lucene
- [ ] **NOUVEAU** : Tests recherche par préfixe, racine, fuzzy

**Référence** : inputs-ibm - Section "Extensions potentielles : recherche textuelle"

**Ordre d'Exécution** : **16ème** (après 15)

---

### Script 17 : Test Timeline Query ✅ (DÉJÀ CRÉÉ)

**Fichier** : `scripts/17_test_timeline_query.sh`  
**Statut** : ✅ Créé  
**Objectif** : Tests avancés de requêtes timeline

**Exigences** :
- Requêtes timeline complexes
- Filtres combinés
- Pagination avancée

**Contrôles de Validation** :
- ✅ **Pertinence** : Requêtes conformes
- ✅ **Cohérence** : Logique correcte
- ✅ **Intégrité** : Résultats corrects
- ✅ **Consistance** : Performance constante
- ✅ **Conformité** : Conforme BIC-01

**Critères de Qualité** :
- [x] Utilise `set -euo pipefail`
- [x] Utilise `setup_paths()` et fonctions didactiques
- [x] Messages colorés complets
- [x] Documentation inline complète
- [x] Requêtes CQL avec explications
- [x] Génération de rapport didactique (`doc/demonstrations/17_TIMELINE_QUERY_ADVANCED_DEMONSTRATION.md`)
- [x] Tests de performance
- [x] Vérifications de résultats

**Ordre d'Exécution** : **17ème** (après 16)

---

### Script 18 : Test Filtering ✅ (DÉJÀ CRÉÉ)

**Fichier** : `scripts/18_test_filtering.sh`  
**Statut** : ✅ Créé  
**Objectif** : Tests de filtrage avancé exhaustif (BIC-15)

**Exigences** :
- **NOUVEAU** : Tous les filtres combinés (canal + type + résultat + période) - **BIC-15**
- Utilisation des index SAI multiples
- Performance optimale
- Toutes les combinaisons de filtres testées

**Contrôles de Validation** :
- ⏳ **Pertinence** : Filtrage combiné exhaustif conforme
- ⏳ **Cohérence** : Utilisation des index SAI
- ⏳ **Intégrité** : Résultats corrects pour toutes les combinaisons
- ⏳ **Consistance** : Performance constante
- ⏳ **Conformité** : Conforme BIC-04, BIC-05, BIC-11, BIC-15

**Critères de Qualité** :
- [ ] Utilise `set -euo pipefail`
- [ ] Utilise `setup_paths()` et fonctions didactiques
- [ ] Messages colorés complets
- [ ] Documentation inline complète
- [ ] Requêtes CQL avec explications
- [ ] Génération de rapport didactique
- [ ] Tests de performance
- [ ] Vérifications de résultats
- [ ] **NOUVEAU** : Tests de toutes les combinaisons de filtres
- [ ] **NOUVEAU** : Tests canal + type + résultat + période

**Ordre d'Exécution** : **18ème** (après 17)

---

### Script 19 : Test Performance

**Fichier** : `scripts/19_test_performance.sh`  
**Statut** : ⏳ À créer  
**Objectif** : Tests de performance globaux

**Exigences** :
- Tests de latence
- Tests de débit
- Comparaison avec HBase (si possible)
- Métriques détaillées

**Contrôles de Validation** :
- ⏳ **Pertinence** : Tests de performance pertinents
- ⏳ **Cohérence** : Métriques cohérentes
- ⏳ **Intégrité** : Tests complets
- ⏳ **Consistance** : Résultats reproductibles
- ⏳ **Conformité** : Conforme aux exigences de performance

**Critères de Qualité** :
- [ ] Utilise `set -euo pipefail`
- [ ] Utilise `setup_paths()`
- [ ] Messages colorés complets
- [ ] Documentation inline complète
- [ ] Tests de performance avec explications
- [ ] Génération de rapport didactique
- [ ] Métriques détaillées
- [ ] Comparaisons

**Ordre d'Exécution** : **19ème** (après 18)

---

### Script 20 : Test API Backend

**Fichier** : `scripts/20_test_api_backend.sh`  
**Statut** : ⏳ À créer  
**Objectif** : Tester l'API backend conseiller (BIC-08)

**Exigences** :
- Tests d'API REST/GraphQL (Data API)
- Lecture temps réel
- Filtres via API
- Performance API

**Contrôles de Validation** :
- ⏳ **Pertinence** : API conforme
- ⏳ **Cohérence** : Format API correct
- ⏳ **Intégrité** : Toutes les fonctionnalités testées
- ⏳ **Consistance** : Performance constante
- ⏳ **Conformité** : Conforme BIC-08

**Critères de Qualité** :
- [ ] Utilise `set -euo pipefail`
- [ ] Utilise `setup_paths()`
- [ ] Messages colorés complets
- [ ] Documentation inline complète
- [ ] Tests d'API avec explications
- [ ] Génération de rapport didactique
- [ ] Vérifications préalables (Data API démarrée)
- [ ] Gestion d'erreurs

**Ordre d'Exécution** : **20ème** (après 19)

---

### Script 21 : Demo Timeline Complete

**Fichier** : `scripts/21_demo_timeline_complete.sh`  
**Statut** : ⏳ À créer  
**Objectif** : Démonstration complète de la timeline (BIC-01)

**Exigences** :
- Démonstration complète
- Scénarios réalistes
- Documentation auto-générée

**Contrôles de Validation** :
- ⏳ **Pertinence** : Démonstration complète
- ⏳ **Cohérence** : Scénarios cohérents
- ⏳ **Intégrité** : Tous les aspects couverts
- ⏳ **Consistance** : Documentation complète
- ⏳ **Conformité** : Conforme BIC-01

**Critères de Qualité** :
- [ ] Utilise `set -euo pipefail`
- [ ] Utilise `setup_paths()` et fonctions didactiques
- [ ] Messages colorés complets
- [ ] Documentation inline complète
- [ ] Génération de rapport didactique complet (`doc/demonstrations/21_TIMELINE_COMPLETE_DEMONSTRATION.md`)
- [ ] Scénarios détaillés
- [ ] Résultats documentés

**Ordre d'Exécution** : **21ème** (après 20)

---

### Script 22 : Demo Kafka Streaming

**Fichier** : `scripts/22_demo_kafka_streaming.sh`  
**Statut** : ⏳ À créer  
**Objectif** : Démonstration streaming Kafka (BIC-02)

**Exigences** :
- Démonstration complète
- Scénarios réalistes
- Documentation auto-générée

**Contrôles de Validation** :
- ⏳ **Pertinence** : Démonstration complète
- ⏳ **Cohérence** : Scénarios cohérents
- ⏳ **Intégrité** : Tous les aspects couverts
- ⏳ **Consistance** : Documentation complète
- ⏳ **Conformité** : Conforme BIC-02

**Critères de Qualité** :
- [ ] Utilise `set -euo pipefail`
- [ ] Utilise `setup_paths()`
- [ ] Messages colorés complets
- [ ] Documentation inline complète
- [ ] Génération de rapport didactique complet
- [ ] Scénarios détaillés
- [ ] Résultats documentés

**Ordre d'Exécution** : **22ème** (après 21)

---

### Script 23 : Demo Export Batch

**Fichier** : `scripts/23_demo_export_batch.sh`  
**Statut** : ⏳ À créer  
**Objectif** : Démonstration export batch (BIC-03)

**Exigences** :
- Démonstration complète
- Scénarios réalistes
- Documentation auto-générée

**Contrôles de Validation** :
- ⏳ **Pertinence** : Démonstration complète
- ⏳ **Cohérence** : Scénarios cohérents
- ⏳ **Intégrité** : Tous les aspects couverts
- ⏳ **Consistance** : Documentation complète
- ⏳ **Conformité** : Conforme BIC-03

**Critères de Qualité** :
- [ ] Utilise `set -euo pipefail`
- [ ] Utilise `setup_paths()`
- [ ] Messages colorés complets
- [ ] Documentation inline complète
- [ ] Génération de rapport didactique complet
- [ ] Scénarios détaillés
- [ ] Résultats documentés

**Ordre d'Exécution** : **23ème** (après 22)

---

### Script 24 : Demo Data API

**Fichier** : `scripts/24_demo_data_api.sh`  
**Statut** : ⏳ À créer  
**Objectif** : Démonstration Data API (BIC-08)

**Exigences** :
- Démonstration complète
- Scénarios réalistes
- Documentation auto-générée

**Contrôles de Validation** :
- ⏳ **Pertinence** : Démonstration complète
- ⏳ **Cohérence** : Scénarios cohérents
- ⏳ **Intégrité** : Tous les aspects couverts
- ⏳ **Consistance** : Documentation complète
- ⏳ **Conformité** : Conforme BIC-08

**Critères de Qualité** :
- [ ] Utilise `set -euo pipefail`
- [ ] Utilise `setup_paths()`
- [ ] Messages colorés complets
- [ ] Documentation inline complète
- [ ] Génération de rapport didactique complet
- [ ] Scénarios détaillés
- [ ] Résultats documentés

**Ordre d'Exécution** : **24ème** (après 23)

---

### Script 25 : Demo Complete

**Fichier** : `scripts/25_demo_complete.sh`  
**Statut** : ⏳ À créer  
**Objectif** : Démonstration complète de tous les use cases

**Exigences** :
- Démonstration complète de tous les use cases BIC
- Scénarios réalistes
- Documentation auto-générée complète

**Contrôles de Validation** :
- ⏳ **Pertinence** : Démonstration complète
- ⏳ **Cohérence** : Tous les use cases couverts
- ⏳ **Intégrité** : Tous les aspects couverts
- ⏳ **Consistance** : Documentation complète
- ⏳ **Conformité** : Conforme à tous les use cases BIC

**Critères de Qualité** :
- [ ] Utilise `set -euo pipefail`
- [ ] Utilise `setup_paths()`
- [ ] Messages colorés complets
- [ ] Documentation inline complète
- [ ] Génération de rapport didactique complet
- [ ] Scénarios détaillés
- [ ] Résultats documentés

**Ordre d'Exécution** : **25ème** (dernier)

---

## 🔍 CRITÈRES DE VALIDATION GLOBAUX

### Pour Chaque Script

1. **Pertinence** : Le script répond-il aux exigences BIC ?
2. **Cohérence** : Le script est-il cohérent avec les autres scripts ?
3. **Intégrité** : Le script fonctionne-t-il correctement ?
4. **Consistance** : Le script est-il reproductible ?
5. **Conformité** : Le script est-il conforme aux exigences clients/IBM ?

### Niveau de Qualité Minimum

**Au moins égal à domiramaCatOps** :
- ✅ `set -euo pipefail`
- ✅ `setup_paths()` depuis `utils/didactique_functions.sh`
- ✅ Messages colorés complets (info, success, error, warn, demo, code, section, result, expected)
- ✅ Documentation inline complète (OBJECTIF, PRÉREQUIS, UTILISATION, SORTIE)
- ✅ Génération de rapport didactique dans `doc/demonstrations/`
- ✅ Vérifications préalables
- ✅ Gestion d'erreurs complète
- ✅ Affichage des statistiques et résultats

---

## 📊 ORDRE D'EXÉCUTION COMPLET

```
Phase 1 : Setup (01-04) ✅
  → 01_setup_bic_keyspace.sh ✅
  → 02_setup_bic_tables.sh ✅
  → 03_setup_bic_indexes.sh ✅
  → 04_verify_setup.sh ✅

Phase 2 : Génération (05-07) ✅
  → 05_generate_interactions_parquet.sh ✅
  → 06_generate_interactions_json.sh ✅
  → 07_generate_test_data.sh ✅

Phase 3 : Ingestion (08-10) ✅
  → 08_load_interactions_batch.sh ✅
  → 09_load_interactions_realtime.sh ✅
  → 10_load_interactions_json.sh ✅

Phase 4 : Tests (11-15) ✅
  → 11_test_timeline_conseiller.sh ✅
  → 12_test_filtrage_canal.sh ✅
  → 13_test_filtrage_type.sh ✅
  → 14_test_export_batch.sh ✅
  → 15_test_ttl.sh ✅

Phase 5 : Recherche (16-18) ✅
  → 16_test_fulltext_search.sh ✅
  → 17_test_timeline_query.sh ✅
  → 18_test_filtering.sh ✅

Phase 6 : Démonstrations Avancées (19-25) ⏳
  → 19_test_performance.sh
  → 20_test_api_backend.sh
  → 21_demo_timeline_complete.sh
  → 22_demo_kafka_streaming.sh
  → 23_demo_export_batch.sh
  → 24_demo_data_api.sh
  → 25_demo_complete.sh
```

---

## ✅ CHECKLIST DE VALIDATION PAR SCRIPT

Pour chaque script créé, vérifier :

- [ ] **Pertinence** : Répond aux exigences BIC
- [ ] **Cohérence** : Cohérent avec les autres scripts
- [ ] **Intégrité** : Fonctionne correctement
- [ ] **Consistance** : Reproductible
- [ ] **Conformité** : Conforme aux exigences clients/IBM
- [ ] **Qualité** : Au moins égal à domiramaCatOps
- [ ] **Documentation** : Documentation inline complète
- [ ] **Rapport** : Rapport didactique généré (si applicable)
- [ ] **Tests** : Tests validés
- [ ] **Performance** : Performance acceptable

---

**Date** : 2025-12-01  
**Version** : 1.0.0  
**Statut** : ✅ Plan complet établi

