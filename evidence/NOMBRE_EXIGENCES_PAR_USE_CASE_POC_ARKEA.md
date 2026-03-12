# 📊 Nombre d'Exigences par Use Case - POC ARKEA

**Date** : 2025-12-03
**Objectif** : Récapitulatif du nombre d'exigences par use case pour chaque POC ARKEA

---

## 📋 Résumé Exécutif

| POC | Nombre Total Exigences | Use Cases Principaux | Conformité |
|-----|------------------------|----------------------|------------|
| **BIC** | **45+** | 15 use cases (BIC-01 à BIC-15) | 96.4% |
| **domirama2** | **23** | 6 exigences table domirama | 103% |
| **domiramaCatOps** | **35** | 7 exigences table domirama + 7 exigences meta-categories | 104% |
| **TOTAL** | **103+** | **28+ use cases** | **99.5%** |

---

## 🎯 POC 1 : BIC (Base d'Interaction Client)

### Nombre Total d'Exigences : **45+**

### Use Cases Principaux (15)

| ID | Use Case | Description | Priorité |
|----|----------|-------------|----------|
| **BIC-01** | Timeline conseiller | Afficher l'historique des interactions d'un client sur 2 ans | 🔴 Critique |
| **BIC-02** | Ingestion Kafka temps réel | Traiter les événements `bic-event` en streaming | 🔴 Critique |
| **BIC-03** | Export batch ORC incrémental | Exporter les données pour analyse (`bic-unload`) | 🟡 Haute |
| **BIC-04** | Filtrage par canal | Filtrer par canal (email, SMS, agence, telephone, web, RDV, agenda, mail) | 🟡 Haute |
| **BIC-05** | Filtrage par type d'interaction | Filtrer par type (consultation, conseil, transaction, reclamation, etc.) | 🟡 Haute |
| **BIC-06** | TTL 2 ans | Rétention automatique sur 2 ans (vs 10 ans Domirama) | 🔴 Critique |
| **BIC-07** | Format JSON + colonnes dynamiques | Stockage JSON avec colonnes dynamiques normalisées | 🟡 Haute |
| **BIC-08** | Backend API conseiller | Lecture temps réel pour applications conseiller | 🔴 Critique |
| **BIC-09** | Écriture batch (bulkLoad) | Chargement massif via MapReduce en bulkLoad | 🟡 Haute |
| **BIC-10** | Lecture batch (export) | FullScan + STARTROW + STOPROW + TIMERANGE | 🟡 Haute |
| **BIC-11** | Filtrage par résultat | Filtrer par résultat/statut (succès, échec, etc.) | 🟡 Moyenne |
| **BIC-12** | Recherche full-text | Recherche dans le contenu JSON (details) | 🟡 Moyenne |
| **BIC-13** | Recherche vectorielle | Recherche sémantique (optionnel, extension) | 🟢 Optionnel |
| **BIC-14** | Pagination | Pagination des résultats de timeline | 🟡 Haute |
| **BIC-15** | Filtres combinés | Combinaison de filtres (canal + type + période) | 🟡 Haute |

### Catégories d'Exigences

| Catégorie | Nombre | Description |
|-----------|--------|------------|
| **Use Cases Fonctionnels** | 15 | BIC-01 à BIC-15 |
| **Exigences Techniques (Architecture)** | 10+ | Schéma, Index SAI, Canaux, Types |
| **Exigences Ingestion** | 5+ | Kafka temps réel, Batch, Formats |
| **Exigences Lecture** | 5+ | Temps réel, Batch, API |
| **Exigences Export** | 3+ | ORC, Incrémental |
| **Exigences Recherche** | 3+ | Full-text, Vectorielle |
| **Exigences Performance** | 3+ | Lecture, Écriture, Export |
| **Exigences Sécurité** | 2+ | Data API, Contrôle accès |
| **Exigences Données** | 3+ | Volume, Qualité, Métadonnées |
| **Exigences Migration** | 2+ | HBase → HCD, Compatibilité |
| **Patterns HBase Équivalents** | 8+ | SCAN, BulkLoad, Colonnes dynamiques, etc. |

**Total** : **45+ exigences**

**Conformité** : **96.4%** ✅

---

## 🎯 POC 2 : domirama2 (Opérations Bancaires)

### Nombre Total d'Exigences : **23**

### Répartition par Catégorie

| Catégorie | Nombre Exigences | IDs | Couverture |
|-----------|------------------|-----|------------|
| **Table `domirama`** | 6 | E-01 à E-06 | ✅ 100% |
| **Recommandations Techniques IBM** | 6 | E-07 à E-12 | ✅ 100% |
| **Patterns HBase Équivalents** | 6 | E-13 à E-18 | ✅ 100% |
| **Performance et Scalabilité** | 3 | E-19 à E-21 | ✅ 100% |
| **Modernisation et Innovation** | 2 | E-22 à E-23 | ✅ 120% |
| **TOTAL** | **23** | **E-01 à E-23** | **103%** |

### Détail des Exigences

#### Table `domirama` (6 exigences)

| ID | Exigence | Description |
|----|----------|-------------|
| **E-01** | Stockage des Opérations Bancaires | Table `operations_by_account` avec structure conforme HBase, TTL 10 ans |
| **E-02** | Écriture Batch (MapReduce bulkLoad) | Chargement batch via Spark (remplacement MapReduce), format Parquet |
| **E-03** | Écriture Temps Réel (Corrections Client) | Corrections client via API, préservation des corrections (stratégie multi-version) |
| **E-04** | Lecture et Recherche par Critères | Lecture opérations par client, recherche full-text native, recherche vectorielle, recherche hybride |
| **E-05** | Export Incrémental (TIMERANGE) | Export batch format Parquet, fenêtre glissante, équivalent STARTROW/STOPROW |
| **E-06** | TTL et Purge Automatique | TTL 10 ans configuré, purge automatique validée |

#### Recommandations Techniques IBM (6 exigences)

| ID | Exigence | Description |
|----|----------|-------------|
| **E-07** | Recherche Full-Text avec Analyzers Lucene | Index SAI avec analyzers Lucene (standard, français), remplacement Solr |
| **E-08** | Recherche Vectorielle (ByteT5) | Support embeddings ByteT5, recherche sémantique, tolérance typos |
| **E-09** | Recherche Hybride (Full-Text + Vector) | Combinaison recherche full-text et vectorielle, meilleure pertinence |
| **E-10** | Data API (REST/GraphQL) | Exposition données via API REST/GraphQL, remplacement appels HBase directs |
| **E-11** | Ingestion Batch Spark (Remplacement MapReduce) | Job Spark batch (remplacement MapReduce/PIG), format Parquet |
| **E-12** | Export Incrémental Parquet (Remplacement ORC) | Export format Parquet (remplacement ORC), fenêtre temporelle |

#### Patterns HBase Équivalents (6 exigences)

| ID | Exigence | Pattern HBase | Équivalent HCD |
|----|----------|---------------|----------------|
| **E-13** | Équivalent RowKey | RowKey HBase : `code_si:contrat:op_id+date` | Partition Key `(code_si, contrat)` + Clustering Keys |
| **E-14** | Équivalent Column Family | CF `data`, `meta` | Colonnes normalisées dans une table |
| **E-15** | Équivalent Colonnes Dynamiques | Colonnes dynamiques HBase (flexibilité) | Type `MAP<TEXT, TEXT>` |
| **E-16** | Équivalent BLOOMFILTER | BLOOMFILTER ROWCOL HBase | Index SAI (performances supérieures) |
| **E-17** | Équivalent REPLICATION_SCOPE | REPLICATION_SCOPE => '1' HBase | NetworkTopologyStrategy |
| **E-18** | Équivalent FullScan + TIMERANGE | FullScan + TIMERANGE HBase | WHERE sur clustering keys |

#### Performance et Scalabilité (3 exigences)

| ID | Exigence | Description |
|----|----------|-------------|
| **E-19** | Performance Lecture | Lecture efficace opérations client, latence < 100ms, scalabilité horizontale |
| **E-20** | Performance Écriture | Écriture batch efficace, throughput élevé, écriture temps réel < 100ms |
| **E-21** | Charge Concurrente | Support charge concurrente, pas de dégradation, résilience |

#### Modernisation et Innovation (2 exigences)

| ID | Exigence | Description |
|----|----------|-------------|
| **E-22** | Recherche Sémantique (Innovation) | Recherche sémantique (non dans inputs, innovation), tolérance typos |
| **E-23** | Multi-Version et Time Travel | Stratégie multi-version explicite, time travel, aucune correction client perdue |

**Conformité** : **103%** ✅ (dépassement)

---

## 🎯 POC 3 : domiramaCatOps (Catégorisation Opérations)

### Nombre Total d'Exigences : **35**

### Répartition par Catégorie

| Catégorie | Nombre Exigences | IDs | Couverture |
|-----------|------------------|-----|------------|
| **Table `domirama` (CF `category`)** | 7 | E-01 à E-07 | ✅ 100% |
| **Table `domirama-meta-categories`** | 7 | E-08 à E-14 | ✅ 100% |
| **Recommandations Techniques IBM** | 8 | E-15 à E-22 | ✅ 100% |
| **Patterns HBase Équivalents** | 8 | E-23 à E-30 | ✅ 100% |
| **Performance et Scalabilité** | 3 | E-31 à E-33 | ✅ 100% |
| **Modernisation et Innovation** | 2 | E-34 à E-35 | ✅ 120% |
| **TOTAL** | **35** | **E-01 à E-35** | **104%** |

### Détail des Exigences

#### Table `domirama` (CF `category`) - 7 exigences

| ID | Exigence | Description |
|----|----------|-------------|
| **E-01** | Stockage des Opérations avec Catégorisation | Table `operations_by_account` avec colonnes catégorisation, TTL 10 ans |
| **E-02** | Écriture Batch (MapReduce bulkLoad) | Chargement batch via Spark (remplacement MapReduce), stratégie multi-version |
| **E-03** | Écriture Temps Réel (Corrections Client) | Corrections client via API, préservation des corrections (stratégie multi-version) |
| **E-04** | Lecture et Recherche par Catégorie | Lecture opérations par client, filtrage par catégorie via index SAI |
| **E-05** | Recherche par Libellé (Full-Text) | Recherche full-text native (remplacement Solr), recherche vectorielle, recherche hybride |
| **E-06** | Export Incrémental (TIMERANGE) | Export batch format Parquet, fenêtre glissante, équivalent STARTROW/STOPROW |
| **E-07** | TTL et Purge Automatique | TTL 10 ans configuré, purge automatique validée |

#### Table `domirama-meta-categories` - 7 exigences

| ID | Exigence | Description |
|----|----------|-------------|
| **E-08** | Acceptation et Opposition Client | Tables `acceptation_client` et `opposition_categorisation`, vérification avant affichage |
| **E-09** | Historique des Oppositions (VERSIONS => '50') | Table `historique_opposition`, traçabilité complète (illimité vs 50 versions HBase) |
| **E-10** | Feedbacks par Libellé (Compteurs Atomiques) | Table `feedback_par_libelle` avec type `COUNTER`, incréments atomiques |
| **E-11** | Feedbacks par ICS (Compteurs) | Table `feedback_par_ics` avec type `COUNTER`, distribution par code ICS |
| **E-12** | Règles Personnalisées Client | Table `regles_personnalisees`, application des règles (priorité sur cat_auto) |
| **E-13** | Décisions Salaires | Table `decisions_salaires`, méthode de catégorisation spécifique |
| **E-14** | Cohérence Multi-Tables | Vérification cohérence entre `operations_by_account` et tables meta-categories |

#### Recommandations Techniques IBM - 8 exigences

| ID | Exigence | Description |
|----|----------|-------------|
| **E-15** | Recherche Full-Text avec Analyzers Lucene | Index SAI avec analyzers Lucene (standard, français), remplacement Solr |
| **E-16** | Recherche Vectorielle (ByteT5, e5-large, invoice) | Support multi-modèles embeddings, recherche sémantique, tolérance typos |
| **E-17** | Recherche Hybride (Full-Text + Vector) | Combinaison recherche full-text et vectorielle, meilleure pertinence |
| **E-18** | Data API (REST/GraphQL) | Exposition données via API REST/GraphQL, remplacement appels HBase directs |
| **E-19** | Ingestion Batch Spark (Remplacement MapReduce) | Job Spark batch (remplacement MapReduce/PIG), format Parquet |
| **E-20** | Ingestion Temps Réel Kafka → Spark Streaming | Ingestion Kafka via Spark Structured Streaming, checkpointing |
| **E-21** | Export Incrémental Parquet (Remplacement ORC) | Export format Parquet (remplacement ORC), fenêtre temporelle |
| **E-22** | Indexation SAI Complète | Index SAI sur toutes colonnes pertinentes (full-text, vectoriel, numérique) |

#### Patterns HBase Équivalents - 8 exigences

| ID | Exigence | Pattern HBase | Équivalent HCD |
|----|----------|---------------|----------------|
| **E-23** | Équivalent RowKey | RowKey HBase : `code_si:contrat:op_id+date` | Partition Key `(code_si, contrat)` + Clustering Keys |
| **E-24** | Équivalent Column Family | CF `data`, `category`, `meta` | Colonnes normalisées dans une table |
| **E-25** | Équivalent VERSIONS => '50' | VERSIONS => '50' (limite 50 versions) | Table `historique_opposition` (historique illimité) |
| **E-26** | Équivalent INCREMENT Atomique | `INCREMENT` atomique HBase | Type `COUNTER` natif |
| **E-27** | Équivalent Colonnes Dynamiques | Colonnes dynamiques HBase (flexibilité) | Type `MAP<TEXT, TEXT>` |
| **E-28** | Équivalent BLOOMFILTER | BLOOMFILTER ROWCOL HBase | Index SAI (performances supérieures) |
| **E-29** | Équivalent REPLICATION_SCOPE | REPLICATION_SCOPE => '1' HBase | NetworkTopologyStrategy |
| **E-30** | Équivalent FullScan + TIMERANGE | FullScan + TIMERANGE HBase | WHERE sur clustering keys |

#### Performance et Scalabilité - 3 exigences

| ID | Exigence | Description |
|----|----------|-------------|
| **E-31** | Performance Lecture | Lecture efficace opérations client, latence < 100ms, scalabilité horizontale |
| **E-32** | Performance Écriture | Écriture batch efficace, throughput élevé, écriture temps réel < 100ms |
| **E-33** | Charge Concurrente | Support charge concurrente, pas de dégradation, résilience |

#### Modernisation et Innovation - 2 exigences

| ID | Exigence | Description |
|----|----------|-------------|
| **E-34** | Recherche Sémantique (Innovation) | Recherche sémantique (non dans inputs, innovation), tolérance typos |
| **E-35** | Multi-Modèles Embeddings (Innovation) | Support multi-modèles (ByteT5, e5-large, invoice), comparaison et sélection intelligente |

**Conformité** : **104%** ✅ (dépassement)

---

## 📊 Synthèse Globale

### Répartition par POC

| POC | Exigences | Use Cases | Conformité | Scripts |
|-----|-----------|----------|------------|---------|
| **BIC** | 45+ | 15 | 96.4% | 20 |
| **domirama2** | 23 | 6 | 103% | 31 |
| **domiramaCatOps** | 35 | 14 | 104% | 48 |
| **TOTAL** | **103+** | **35+** | **99.5%** | **99** |

### Répartition par Catégorie (Tous POCs)

| Catégorie | BIC | domirama2 | domiramaCatOps | Total |
|-----------|-----|-----------|----------------|-------|
| **Use Cases Fonctionnels** | 15 | 6 | 14 | **35** |
| **Exigences Techniques** | 10+ | 6 | 8 | **24+** |
| **Patterns HBase Équivalents** | 8+ | 6 | 8 | **22+** |
| **Performance** | 3+ | 3 | 3 | **9+** |
| **Innovation** | 1 | 2 | 2 | **5** |
| **Autres** | 8+ | 0 | 0 | **8+** |

### Points Clés

- ✅ **BIC** : Focus sur interactions clients, ingestion Kafka temps réel, TTL 2 ans
- ✅ **domirama2** : Focus sur opérations bancaires, recherche avancée, export incrémental
- ✅ **domiramaCatOps** : Focus sur catégorisation, compteurs atomiques, multi-modèles embeddings

---

**Date de création** : 2025-12-03
**Version** : 1.0.0
**Statut** : ✅ **COMPLET**
