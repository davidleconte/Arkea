# 📊 Analyse de la Proposition MECE IBM - Migration HBase → HCD

**Date** : 2025-11-25  
**Document analysé** : `inputs-ibm/PROPOSITION_MECE_MIGRATION_HBASE_HCD.md`  
**Source** : IBM / DataStax  
**Taille** : ~1560 lignes

---

## 📋 Vue d'Ensemble

Ce document est une **proposition MECE (Mutually Exclusive, Collectively Exhaustive)** complète pour la migration d'HBase vers IBM Hyper-Converged Database (HCD) avec Storage-Attached Indexing (SAI). Il couvre tous les aspects de la migration : technologique, données, applicatif, et organisationnel.

---

## 🎯 Structure du Document

### 1. **Axe Technologique** (Lignes 1-79)

**Constats actuels** :

- Infrastructure HBase 1.1.2 sur HDP 2.6.4 (version ancienne)
- Deux instances HBase en production + une hors-prod
- Architecture lourde (HDFS, Yarn, ZooKeeper) en fin de vie
- Fonctionnalités HBase utilisées : TTL, Bloom filters, INCREMENT, multi-version, scans distribués

**Enjeux de la migration** :

- Garantir performances et disponibilité
- Répliquer les fonctionnalités clés (TTL, scans avec filtres, incréments atomiques, versionnement, bulk load)
- Refonte de l'architecture (pas de lift-and-shift)
- Continuité du service et fiabilité
- Intégration écosystème et IA
- Coût total de possession

**Propositions** :

- Adoption d'HCD (Cassandra 4.x) avec architecture cloud-native
- Consolidation sur un unique cluster Cassandra/HCD
- Maximisation des lectures par clé de partition
- **Indexation secondaire via SAI** (atout central)
- Consistance via Consistency Level QUORUM
- Outils de migration (DSBulk, Spark, Kafka Connector)
- Intégration IA native (vecteurs, embeddings, RAG)

---

### 2. **Axe Données** (Lignes 81-216)

**Constats actuels** :

- Schémas HBase sur mesure pour chaque projet
- **Domirama** : transactions sur 10 ans, clé composite, données COBOL Base64
- **Catégorisation** : extension Domirama avec CF `category`, TTL 10 ans
- **BIC** : interactions clients sur 2 ans, JSON + colonnes dynamiques, TTL 2 ans
- **EDM** : événements marketing, design identique à BIC
- **domirama-meta-categories** : table multi-usages avec préfixes de clés

**Enjeux de la migration** :

- Transformation de schéma (colonnes dynamiques → schéma fixe)
- Partitionnement et clés primaires (éviter partitions trop volumineuses)
- Représentation des données complexes (multi-version, colonnes dynamiques, JSON)
- Indexation vs. dénormalisation
- Migration de données et qualité
- Gestion de l'historique

**Propositions** :

- **Table `operations_by_account`** (Domirama) : partition par (entite_id, compte_id), clustering par date
- **Table `category_feedback`** : ensemble de tables séparées (MECE)
- **Table `interactions_by_client`** (BIC) : partition par client, clustering par date
- **Table `events_by_client`** (EDM) : structure similaire à BIC
- Stratégies d'accès avec SAI et dénormalisation ciblée
- Migration des données via Spark avec validation

---

### 3. **Axe Applicatif** (Lignes 217-361)

**Constats actuels** :

- Applications fortement couplées à HBase
- **Domirama** : construction index Solr en mémoire au login
- **Batch Domirama** : PIG + MapReduce
- **Service Catégorisation** : moteur IA + API
- **BIC backend** : timeline conseiller
- **Consumers Kafka** : bic-event, edm-event (Tomcat)
- **Batch BIC unload** : export ORC HDFS

**Enjeux de la migration** :

- Refonte du code d'accès aux données (HBase → CQL/driver Cassandra)
- Maintien des fonctionnalités équivalentes
- Adaptation des pipelines batch/stream
- Phases de transition double écriture/lecture
- Formation et appropriation
- Tests et QA

**Propositions** :

- Abstraction et couches d'accès aux données
- **Mise à jour Domirama** : remplacer Solr par requêtes SAI, API catégorisation simplifiée
- **Mise à jour BIC/EDM** : Kafka Connector, backend conseiller optimisé, batch unload via Spark
- Tests et validation (shadow reads, A/B testing)
- Améliorations potentielles grâce à l'IA

---

### 4. **Axe Organisationnel** (Lignes 362-461)

**Constats actuels** :

- Dette technique (HBase 1.1.2, HDP 2.6.4)
- Gestion des coûts du cluster Hadoop
- Organisation des équipes (séparation par usage)
- Compétences HBase rares sur le marché
- Processus actuels (Pig/MR, Oozie/Azkaban)
- Contraintes réglementaires

**Enjeux de la migration** :

- Gestion de projet et conduite du changement
- Formation et appropriation des outils
- Redéfinition des rôles
- Impact financier à court terme
- Gestion du risque
- Silos et mutualisation
- Conformité et sécurité
- Décommissionnement du cluster Hadoop

**Propositions** :

- **Découpage en phases** :
  1. Phase 0 : Infrastructure & Préparation
  2. Phase 1 : Prototype EDM (périmètre réduit)
  3. Phase 2 : Migration BIC
  4. Phase 3 : Migration Domirama & Catégorisation
  5. Phase 4 : Décommissionnement & Optimisation
- Formation et support technique (IBM/DataStax)
- Optimisation des coûts et infrastructures
- Gouvernance des données et synergies
- Gestion du support et de la maintenance

---

### 5. **Refonte Domirama** (Lignes 462-657)

**Modélisation CQL** :

- Table `domirama` avec clé primaire composite
- Colonnes normalisées (décodage COBOL)
- Intégration catégorisation dans la table principale
- TTL 10 ans

**Recherche full-text** :

- Remplacement Solr par **CQL analyzers** (SAI avec Lucene)
- Requêtes `WHERE libelle : 'terme'` avec index SAI
- Élimination de l'index Solr en mémoire

**Recherche vectorielle** :

- Support des embeddings `VECTOR<FLOAT, N>`
- Index SAI vectoriel pour recherche par similarité
- Combinaison vector + mot-clé (hybrid search)

**Data API** :

- Exposition REST/GraphQL via Stargate
- Simplification de l'accès applicatif

**Ingestion batch** :

- Remplacement PIG/MapReduce par **Spark** ou **DSBulk**
- Pipeline moderne sans dépendance Hadoop

**TTL et purge** :

- `default_time_to_live` au niveau table
- Gestion automatique par Cassandra

**Stratégie d'indexation** :

- Clé primaire pour accès direct par client
- Index SAI texte sur libellé (remplacement Solr)
- Index SAI vectoriel pour recherche sémantique
- Index SAI numériques pour filtres par montant/catégorie

---

### 6. **Refonte domirama-meta-categories** (Lignes 658-777)

**Modèle de données CQL refondu** :

- **Séparation MECE** : plusieurs tables au lieu d'une table multi-usages
- **ACCEPTATION_CLIENT** : acceptation affichage catégorie
- **OPPOSITION_CATEGORISATION** : opposition client
- **HISTORIQUE_OPPOSITION** : historique des changements
- **FEEDBACK_PAR_LIBELLE** : feedbacks par libellé (compteurs)
- **FEEDBACK_PAR_ICS** : feedbacks par code ICS
- **REGLES_PERSONNALISEES** : règles custom client
- **DECISIONS_SALAIRES** : décisions salaires

**Gestion des compteurs** :

- Tables dédiées avec type `counter`
- `UPDATE ... SET col = col + 1` pour incréments atomiques
- Consistency Level LOCAL_QUORUM

**Indexation SAI** :

- Index sur libellés (recherche texte)
- Index sur champs numériques (type, code ICS)
- Index vectoriel optionnel

**API d'accès** :

- Data API REST/GraphQL pour exposition
- Opérations d'écriture (PUT/INCREMENT) via API

**Considérations** :

- Versionnement : table d'historique dédiée au lieu de multi-version
- TTL : pas applicable aux compteurs
- Scalabilité : partitions bien dimensionnées
- Maintenance : évolution facilitée par séparation MECE

---

### 7. **Refonte bi-client (BIC)** (Lignes 778-912)

**Schéma CQL** :

- Table `bic.client_interaction` : partition par `client_id`, clustering par `interaction_id` (timeuuid)
- Colonnes : `type_interaction`, `canal`, `resultat`, `details` (JSON)
- TTL 2 ans (`default_time_to_live = 63072000`)

**Indexation SAI** :

- Index sur `canal`, `type_interaction`, `resultat`
- Recherches filtrées efficaces sans scans complets

**TTL et purge** :

- Gestion automatique par Cassandra
- Suppression après 2 ans sans intervention

**Data API** :

- Exposition REST/GraphQL pour applications
- Simplification du développement

**Ingestion Kafka** :

- **DataStax Kafka Connector** pour ingestion temps réel
- Écriture directe depuis Kafka vers Cassandra

**Lecture temps réel** :

- Requête optimisée par partition client
- Filtres par attribut via SAI
- Pas de multi-version (simplification)

**Export batch** :

- Job Spark pour extraction incrémentale
- Alternative : Kafka Connect HDFS Sink

**Extensions** :

- Indexation textuelle avec analyseurs Lucene
- Recherche vectorielle sémantique (optionnel)

---

### 8. **Guide POC** (Lignes 913-1560)

**POC1 - "Sans jars client"** :

- Objectif : Prouver Spark + Cassandra avec schéma Domirama
- Données : CSV simulé mais structuré
- Composants : Spark, Cassandra (Podman), schéma CQL
- Code : Loader CSV → Spark → Cassandra, Détection récurrence

**POC2 - "Avec jars client"** :

- Objectif : Utiliser les vrais flux (SequenceFile + OperationDecoder)
- Données : SequenceFile avec décodage COBOL
- Composants : Jars Arkéa (cobol, operationdecoder, thrift, hadoop)
- Code : Loader SequenceFile → Spark → Cassandra

**Pré-requis** :

- Homebrew, Java 17, sbt, Spark
- Podman + Cassandra en conteneur
- Schéma Cassandra pour POC

**Structure du code** :

- Case classes : `Operation`, `RecurrentOperation`
- Loader : `DomiramaSparkLoaderCsv`, `DomiramaSparkLoaderSeq`
- Détection : `RecurrentDetectionSpark`

---

## 🎯 Points Clés de la Proposition

### ✅ Avantages de la Migration

1. **Simplification architecturale** :
   - Suppression de HDFS, Yarn, ZooKeeper
   - Cluster unique au lieu de deux instances HBase
   - Architecture cloud-native

2. **Performance améliorée** :
   - Indexation SAI native (remplacement Solr)
   - Recherche full-text intégrée
   - Recherche vectorielle pour IA

3. **Réduction des coûts** :
   - Moins de composants à maintenir
   - Meilleure efficacité disque (SAI)
   - Scaling horizontal simplifié

4. **Modernisation** :
   - Remplacement PIG/MapReduce par Spark
   - API REST/GraphQL moderne
   - Intégration IA native

### ⚠️ Points d'Attention

1. **Refonte complète du modèle de données** :
   - Colonnes dynamiques → schéma fixe
   - Multi-version → tables d'historique
   - Colonnes dynamiques → lignes multiples

2. **Migration des données** :
   - Transformation ETL non triviale
   - Validation qualité essentielle
   - Gestion de la cohabitation HBase/HCD

3. **Formation des équipes** :
   - Montée en compétence Cassandra
   - Nouveaux outils (nodetool, cqlsh, OpsCenter)
   - Adaptation des processus

4. **Risques** :
   - Perte de fonctionnalités si mal migré
   - Performance à valider en production
   - Coûts initiaux (licences, formation)

---

## 📊 Comparaison avec l'Analyse Client

### Alignements

✅ **Projets identifiés** : Domirama, Catégorisation, BIC, EDM  
✅ **Fonctionnalités HBase** : TTL, scans, INCREMENT, multi-version  
✅ **Schémas de données** : Structures compatibles avec l'analyse client  
✅ **Patterns d'accès** : Scans, bulk load, temps réel

### Compléments IBM

🆕 **SAI** : Indexation secondaire native (non mentionné dans l'analyse client)  
🆕 **Recherche vectorielle** : Support embeddings pour IA  
🆕 **Data API** : Exposition REST/GraphQL  
🆕 **Guide POC détaillé** : Deux scénarios avec code complet

---

## 🚀 Prochaines Étapes Recommandées

1. **Valider la proposition** avec les équipes techniques
2. **Prioriser les phases** de migration
3. **Démarrer le POC1** (sans jars client) pour valider l'approche
4. **Préparer POC2** (avec jars client) pour tester les vrais flux
5. **Planifier la formation** des équipes
6. **Dimensionner le cluster** HCD pour la production

---

## 📝 Notes Importantes

- Ce document est une **proposition IBM** et doit être validée par Arkéa
- Les schémas proposés sont des **recommandations** à adapter selon les besoins réels
- Le guide POC est **exécutable** et peut être utilisé comme base pour le POC
- La migration nécessitera un **investissement significatif** en temps et ressources

---

**Analyse complète de la proposition IBM MECE terminée !** ✅
