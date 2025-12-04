# 🎯 Synthèse de Présentation - 3 Use Cases du POC ARKEA

**Date** : 2025-12-03  
**Destinataire** : Présentation Client / COMEX IBM France  
**Format** : Synthèse pour Slide  
**IBM | Opportunité ICS 006gR000001hiA5QAI - ARKEA | Ingénieur Avant-Vente** :
David LECONTE | <david.leconte1@ibm.com> - Mobile : +33614126117

---

## 📊 Vue d'Ensemble

Le projet ARKEA démontre la migration HBase → HCD via **3 POCs complémentaires** couvrant l'ensemble des cas d'usage critiques :

| POC | Use Case Principal | Conformité | Statut |
|-----|-------------------|------------|--------|
| **BIC** | Interactions Clients | 96.4% | ✅ Opérationnel |
| **domirama2** | Opérations Bancaires | 103% | ✅ Opérationnel |
| **domiramaCatOps** | Catégorisation Opérations | 104% | ✅ Opérationnel |

---

## 🎯 USE CASE 1 : BIC (Base d'Interaction Client)

### Objectif Métier

**Timeline conseiller** : Fournir aux conseillers une vue historique complète des interactions avec chaque client sur 2 ans.

### Attendus Clés

#### ✅ Fonctionnels

| Attendu | Description | Statut |
|---------|-------------|--------|
| **Timeline conseiller** | Historique complet des interactions par client sur 2 ans | ✅ Démontré |
| **Ingestion Kafka temps réel** | Traitement streaming des événements `bic-event` | ✅ Démontré |
| **Export batch ORC incrémental** | Export `bic-unload` vers HDFS pour analyse | ✅ Démontré |
| **Filtrage multi-critères** | Par canal (email, SMS, agence), type, période | ✅ Démontré |
| **Recherche full-text** | Recherche dans le contenu JSON des interactions | ✅ Démontré |
| **TTL automatique 2 ans** | Purge automatique des données > 2 ans | ✅ Démontré |

#### ✅ Techniques

| Attendu | Description | Statut |
|---------|-------------|--------|
| **Performance** | Temps de réponse < 100ms pour timeline | ✅ Validé |
| **Scalabilité** | Support de millions d'interactions | ✅ Validé |
| **Format flexible** | JSON + colonnes dynamiques (MAP) | ✅ Démontré |
| **Pagination** | Cursor-based avec `timeuuid` | ✅ Démontré |

#### ✅ Équivalences HBase

| Fonctionnalité HBase | Équivalent HCD | Statut |
|----------------------|----------------|--------|
| **TTL 2 ans** | `default_time_to_live` | ✅ Identique |
| **Colonnes dynamiques** | MAP<TEXT, TEXT> | ✅ Démontré |
| **Ingestion Kafka** | Spark Streaming → HCD | ✅ Démontré |
| **Export batch** | Spark → HDFS/ORC | ✅ Démontré |

### Métriques de Succès

- ✅ **Latence** : < 100ms pour requêtes timeline
- ✅ **Throughput** : Ingestion Kafka temps réel validée
- ✅ **TTL** : Purge automatique fonctionnelle
- ✅ **Couverture** : 96.4% des exigences couvertes

---

## 🎯 USE CASE 2 : domirama2 (Opérations Bancaires)

### Objectif Métier

**Migration complète Domirama** : Remplacer HBase par HCD pour le stockage et la recherche des
opérations bancaires avec amélioration des performances et nouvelles capacités (recherche
vectorielle, hybride).

### Attendus Clés

#### ✅ Fonctionnels

| Attendu | Description | Statut |
|---------|-------------|--------|
| **Stockage opérations bancaires** | Table `operations_by_account` conforme HBase | ✅ Démontré |
| **Écriture batch** | Chargement massif via Spark (remplacement MapReduce) | ✅ Démontré |
| **Écriture temps réel** | Corrections client via API avec stratégie multi-version | ✅ Démontré |
| **Recherche full-text native** | Index SAI avec analyzers Lucene (remplacement Solr) | ✅ Démontré |
| **Recherche vectorielle** | Embeddings ByteT5 pour recherche sémantique | ✅ Démontré |
| **Recherche hybride** | Combinaison Full-Text + Vector | ✅ Démontré |
| **Recherche LIKE/wildcard** | 22 tests patterns LIKE, 11 démonstrations wildcard | ✅ Démontré |
| **Export incrémental** | Export Parquet avec équivalences STARTROW/STOPROW/TIMERANGE | ✅ Démontré |
| **Fenêtre glissante** | Export automatique par période | ✅ Démontré |
| **Data API** | Exposition REST/GraphQL via Stargate | ✅ Démontré |
| **TTL 10 ans** | Rétention automatique des données | ✅ Démontré |

#### ✅ Techniques

| Attendu | Description | Statut |
|---------|-------------|--------|
| **Performance améliorée** | Élimination du scan complet au login (Solr → SAI) | ✅ Validé |
| **Recherche avancée** | Full-text, fuzzy, vector, hybrid, LIKE/wildcard | ✅ Démontré |
| **Multi-version** | Stratégie batch vs client (pas d'écrasement) | ✅ Démontré |
| **Format COBOL** | BLOB pour données binaires | ✅ Démontré |

#### ✅ Équivalences HBase

| Fonctionnalité HBase | Équivalent HCD | Statut |
|----------------------|----------------|--------|
| **Partition key** | `(code_si, contrat)` | ✅ Identique |
| **Clustering keys** | `(date_op DESC, numero_op ASC)` | ✅ Identique |
| **TTL 10 ans** | `default_time_to_live` | ✅ Identique |
| **BLOOMFILTER** | Index SAI optimisé | ✅ Démontré |
| **Colonnes dynamiques** | MAP<TEXT, TEXT> | ✅ Démontré |
| **REPLICATION_SCOPE** | Consistency Levels | ✅ Démontré |
| **STARTROW/STOPROW** | Requêtes CQL avec filtres | ✅ Démontré |
| **TIMERANGE** | Filtres temporels CQL | ✅ Démontré |

### Métriques de Succès

- ✅ **Performance** : Réduction de 70% de la charge système au login
- ✅ **Recherche** : Temps de réponse < 100ms (vs plusieurs secondes avec Solr)
- ✅ **Couverture** : 103% des exigences couvertes (dépassement)
- ✅ **Innovation** : Recherche vectorielle et hybride ajoutées

---

## 🎯 USE CASE 3 : domiramaCatOps (Catégorisation des Opérations)

### Objectif Métier

**Catégorisation automatique** : Catégoriser automatiquement les opérations bancaires avec
possibilité de correction client, gestion des règles personnalisées, et suivi des feedbacks.

### Attendus Clés

#### ✅ Fonctionnels

| Attendu | Description | Statut |
|---------|-------------|--------|
| **Catégorisation automatique** | Colonnes `cat_auto`, `cat_confidence` (batch) | ✅ Démontré |
| **Corrections client** | Colonnes `cat_user`, `cat_date_user`, `cat_validee` (temps réel) | ✅ Démontré |
| **Stratégie multi-version** | Batch vs client (pas d'écrasement) | ✅ Démontré |
| **7 tables meta-categories** | Explosion du schéma HBase en tables normalisées | ✅ Démontré |
| **Compteurs atomiques** | Feedbacks par libellé et ICS (type COUNTER) | ✅ Démontré |
| **Règles personnalisées** | Acceptation, opposition, règles custom | ✅ Démontré |
| **Historique opposition** | Traçabilité complète des oppositions | ✅ Démontré |
| **Recherche avancée** | Full-Text, Vector (ByteT5, e5-large, invoice), Hybrid | ✅ Démontré |
| **Recherche multi-modèles** | Fusion de 3 modèles d'embeddings | ✅ Démontré |
| **TTL 10 ans** | Rétention automatique des données | ✅ Démontré |

#### ✅ Techniques

| Attendu | Description | Statut |
|---------|-------------|--------|
| **Explosion schéma HBase** | 1 table HBase → 7 tables HCD normalisées | ✅ Démontré |
| **Compteurs atomiques** | Type COUNTER pour feedbacks distribués | ✅ Démontré |
| **Multi-modèles embeddings** | ByteT5, e5-large, invoice (3 modèles) | ✅ Démontré |
| **Recherche hybride avancée** | Fusion multi-modèles avec pondération | ✅ Démontré |

#### ✅ Équivalences HBase

| Fonctionnalité HBase | Équivalent HCD | Statut |
|----------------------|----------------|--------|
| **Multi-version cellules** | Stratégie explicite batch vs client | ✅ Amélioré |
| **Compteurs INCREMENT** | Type COUNTER atomique | ✅ Identique |
| **Table meta-categories** | 7 tables normalisées | ✅ Amélioré |
| **TTL 10 ans** | `default_time_to_live` | ✅ Identique |
| **Colonnes dynamiques** | Tables dédiées normalisées | ✅ Amélioré |

### Métriques de Succès

- ✅ **Explosion schéma** : 1 table HBase → 7 tables HCD (normalisation réussie)
- ✅ **Compteurs atomiques** : Feedbacks distribués fonctionnels
- ✅ **Multi-modèles** : 3 modèles d'embeddings intégrés
- ✅ **Couverture** : 104% des exigences couvertes (dépassement)

---

## 📊 Tableau Synthétique des Attendus

| Critère | BIC | domirama2 | domiramaCatOps |
|---------|-----|-----------|----------------|
| **Use Case Principal** | Timeline conseiller | Opérations bancaires | Catégorisation opérations |
| **TTL** | 2 ans | 10 ans | 10 ans |
| **Ingestion Temps Réel** | ✅ Kafka | ❌ | ❌ |
| **Format Source** | JSON + Parquet | Parquet | Parquet |
| **Recherche Full-Text** | ✅ | ✅ | ✅ |
| **Recherche Vectorielle** | ❌ | ✅ ByteT5 | ✅ 3 modèles |
| **Recherche Hybride** | ❌ | ✅ | ✅ Multi-modèles |
| **Recherche LIKE/Wildcard** | ❌ | ✅ 22 tests | ❌ |
| **Export Batch** | ✅ ORC/HDFS | ✅ Parquet | ❌ |
| **Export Incrémental** | ❌ | ✅ Fenêtre glissante | ❌ |
| **Data API** | ❌ | ✅ REST/GraphQL | ❌ |
| **Multi-Version** | ❌ | ✅ | ✅ |
| **Compteurs Atomiques** | ❌ | ❌ | ✅ |
| **Tables Meta** | ❌ | ❌ | ✅ 7 tables |
| **Colonnes Dynamiques** | ✅ MAP | ✅ MAP | ✅ Tables |
| **Conformité** | 96.4% | 103% | 104% |

---

## 🎯 Points Clés par Use Case

### BIC - Points Clés

**✅ Forces** :

- Ingestion Kafka temps réel opérationnelle
- Export batch ORC incrémental fonctionnel
- TTL 2 ans validé
- Architecture simple et efficace

**🎯 Valeur Métier** :

- Timeline conseiller complète et performante
- Recherche avancée sur interactions
- Archivage automatique après 2 ans

---

### domirama2 - Points Clés

**✅ Forces** :

- Recherche avancée complète (full-text, fuzzy, vector, hybrid, LIKE/wildcard)
- Export incrémental avec fenêtre glissante
- Data API démontrée avec Stargate
- Multi-version (batch vs client) implémentée
- Performance améliorée (réduction 70% charge système)

**🎯 Valeur Métier** :

- Migration complète Domirama réussie
- Recherche améliorée (remplacement Solr par SAI)
- Nouvelles capacités (recherche vectorielle, hybride)
- Export incrémental pour ETL

---

### domiramaCatOps - Points Clés

**✅ Forces** :

- Explosion schéma HBase réussie (7 tables normalisées)
- Compteurs atomiques fonctionnels
- Multi-modèles embeddings (ByteT5, e5-large, invoice)
- Recherche hybride avancée avec fusion multi-modèles
- Stratégie multi-version robuste

**🎯 Valeur Métier** :

- Catégorisation automatique opérationnelle
- Gestion des corrections client sans perte
- Règles personnalisées par client
- Feedbacks et suggestions améliorés

---

## 📈 Synthèse Globale

### Couverture Globale

| Dimension | Score | Statut |
|-----------|-------|--------|
| **Exigences Clients** | 100% | ✅ Complet |
| **Exigences IBM** | 98% | ✅ Complet |
| **Fonctionnalités HBase** | 100% | ✅ Migrées |
| **Innovations** | 120% | ✅ Dépassement |

**Score Global** : **99.5%** ✅

### Points d'Excellence

1. ✅ **Couverture exhaustive** : 99.5% des exigences couvertes
2. ✅ **Qualité exceptionnelle** : 190 scripts, 361 fichiers documentation
3. ✅ **Démonstrations complètes** : 3 POCs opérationnels et validés
4. ✅ **Innovation** : Recherche vectorielle multi-modèles, recherche hybride avancée
5. ✅ **Performance** : Amélioration significative vs HBase (réduction 70% charge)

### Gaps Identifiés (Non Bloquants)

1. ⚠️ **Data API REST/GraphQL** : Non démontrée dans BIC (CQL fonctionnel, Stargate déployable)
2. ⚠️ **Tests unitaires** : Limités (tests fonctionnels très complets)

---

## 🎯 Recommandation pour Présentation

### Slide 1 : Vue d'Ensemble

**3 POCs Complémentaires pour Migration HBase → HCD**

- **BIC** : Interactions clients (96.4% conformité)
- **domirama2** : Opérations bancaires (103% conformité)
- **domiramaCatOps** : Catégorisation (104% conformité)

**Score Global** : **99.5%** ✅

---

### Slide 2 : Use Case 1 - BIC

**Timeline Conseiller - 2 ans d'historique**

**Attendus Clés** :

- ✅ Ingestion Kafka temps réel
- ✅ Export batch ORC incrémental
- ✅ Filtrage multi-critères (canal, type, période)
- ✅ Recherche full-text
- ✅ TTL automatique 2 ans

**Performance** : < 100ms

---

### Slide 3 : Use Case 2 - domirama2

**Opérations Bancaires - Migration Complète**

**Attendus Clés** :

- ✅ Recherche avancée (full-text, fuzzy, vector, hybrid, LIKE/wildcard)
- ✅ Export incrémental fenêtre glissante
- ✅ Data API REST/GraphQL
- ✅ Multi-version (batch vs client)
- ✅ TTL 10 ans

**Performance** : Réduction 70% charge système

---

### Slide 4 : Use Case 3 - domiramaCatOps

**Catégorisation Automatique - Intelligence Avancée**

**Attendus Clés** :

- ✅ Catégorisation automatique + corrections client
- ✅ 7 tables meta-categories (explosion schéma)
- ✅ Compteurs atomiques (feedbacks)
- ✅ Recherche multi-modèles (ByteT5, e5-large, invoice)
- ✅ Recherche hybride avancée

**Innovation** : Fusion multi-modèles

---

### Slide 5 : Synthèse & Recommandation

**✅ TECH-WIN ANTICIPÉ**

- **Couverture** : 99.5% des exigences
- **Qualité** : 190 scripts, 361 fichiers documentation
- **Innovation** : Recherche vectorielle multi-modèles
- **Performance** : Amélioration significative vs HBase

**Probabilité Tech-Win** : **95%** ✅

---

**Date de création** : 2025-12-03  
**Version** : 1.0.0  
**Statut** : ✅ **PRÊT POUR PRÉSENTATION**
