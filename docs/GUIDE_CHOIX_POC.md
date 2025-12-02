# 🎯 Guide de Choix de POC - ARKEA

**Date** : 2025-12-02  
**Objectif** : Aider à choisir le bon POC selon les besoins  
**Version** : 1.0.0

---

## 📋 Vue d'Ensemble

Le projet ARKEA contient **3 POCs** actifs pour la migration HBase → HCD :

1. **BIC** (Base d'Interaction Client)
2. **domirama2** (Domirama v2)
3. **domiramaCatOps** (Domirama Catégorisation des Opérations)

Chaque POC répond à des besoins spécifiques et démontre des fonctionnalités différentes d'HCD.

---

## 🎯 Quand Choisir BIC ?

### Cas d'Usage

- ✅ **Gestion des interactions clients** (appels, emails, rendez-vous)
- ✅ **Timeline des interactions** par client
- ✅ **Recherche full-text** sur les interactions
- ✅ **TTL automatique** (2 ans)
- ✅ **Ingestion temps réel** depuis Kafka
- ✅ **Export batch** vers HDFS (ORC)

### Caractéristiques Techniques

- **Format source** : JSON (Kafka) + Parquet (batch)
- **Colonnes dynamiques** : MAP pour flexibilité
- **Clustering key** : `timeuuid` pour ordre chronologique
- **Index SAI** : Full-text avec analyzers Lucene
- **TTL** : 2 ans (automatique)
- **Pagination** : Cursor-based avec `timeuuid`

### Exigences Métier

- Gestion des interactions clients en temps réel
- Historique complet des interactions
- Recherche avancée sur les contenus
- Archivage automatique après 2 ans

**Voir** : `poc-design/bic/README.md`

---

## 🎯 Quand Choisir domirama2 ?

### Cas d'Usage

- ✅ **Gestion des opérations bancaires** (Domirama)
- ✅ **Recherche avancée** (full-text, fuzzy, vector)
- ✅ **Recherche hybride** (full-text + vector)
- ✅ **Export incrémental** (fenêtre glissante)
- ✅ **Data API** (REST/GraphQL)
- ✅ **Multi-version** (batch vs client)

### Caractéristiques Techniques

- **Format source** : Parquet
- **Colonnes COBOL** : BLOB pour données binaires
- **Index SAI** : Full-text, fuzzy, vector (ByteT5, e5-large)
- **Recherche hybride** : Combinaison full-text + vector
- **Export** : Fenêtre glissante avec Spark
- **Data API** : REST/GraphQL pour intégration

### Exigences Métier

- Migration complète de Domirama HBase
- Recherche avancée sur les opérations
- Export incrémental pour ETL
- Intégration via API REST/GraphQL

**Voir** : `poc-design/domirama2/README.md`

---

## 🎯 Quand Choisir domiramaCatOps ?

### Cas d'Usage

- ✅ **Catégorisation automatique** des opérations
- ✅ **Corrections client** (temps réel)
- ✅ **7 tables meta-categories** (explosion du schéma HBase)
- ✅ **Compteurs atomiques** (feedbacks par libellé)
- ✅ **Règles personnalisées** (acceptation, opposition)
- ✅ **Historique des oppositions**

### Caractéristiques Techniques

- **Format source** : Parquet uniquement
- **Stratégie multi-version** : Batch vs client (pas d'écrasement)
- **7 tables meta-categories** : Acceptation, opposition, règles, feedbacks, etc.
- **Compteurs atomiques** : Type COUNTER pour feedbacks
- **Index SAI** : Full-text, vector (ByteT5, e5-large, invoice)
- **TTL** : 10 ans

### Exigences Métier

- Catégorisation automatique des opérations
- Gestion des corrections client
- Règles personnalisées par client
- Historique complet des oppositions
- Feedbacks et suggestions

**Voir** : `poc-design/domiramaCatOps/README.md`

---

## 📊 Tableau Comparatif

| Critère | BIC | domirama2 | domiramaCatOps |
|---------|-----|-----------|----------------|
| **Cas d'usage principal** | Interactions clients | Opérations bancaires | Catégorisation opérations |
| **Format source** | JSON + Parquet | Parquet | Parquet |
| **Ingestion temps réel** | ✅ Kafka | ❌ | ❌ |
| **TTL** | 2 ans | ❌ | 10 ans |
| **Colonnes dynamiques** | ✅ MAP | ❌ | ❌ |
| **Recherche full-text** | ✅ | ✅ | ✅ |
| **Recherche vector** | ❌ | ✅ | ✅ |
| **Recherche hybride** | ❌ | ✅ | ✅ |
| **Export batch** | ✅ HDFS/ORC | ✅ Parquet | ❌ |
| **Export incrémental** | ❌ | ✅ Fenêtre glissante | ❌ |
| **Data API** | ❌ | ✅ | ❌ |
| **Multi-version** | ❌ | ✅ | ✅ |
| **Compteurs atomiques** | ❌ | ❌ | ✅ |
| **Tables meta** | ❌ | ❌ | ✅ 7 tables |

---

## 🔍 Matrice de Décision

### Besoin : Gestion des interactions clients

**→ Choisir BIC**

- Timeline des interactions
- Recherche full-text
- TTL automatique
- Ingestion Kafka temps réel

---

### Besoin : Migration complète Domirama

**→ Choisir domirama2**

- Recherche avancée (full-text, fuzzy, vector)
- Export incrémental
- Data API
- Multi-version

---

### Besoin : Catégorisation automatique

**→ Choisir domiramaCatOps**

- Catégorisation automatique
- Corrections client
- 7 tables meta-categories
- Compteurs atomiques
- Règles personnalisées

---

## 🚀 Démarrage Rapide

### BIC

```bash
cd poc-design/bic
source ../../.poc-profile
./scripts/01_setup_bic_keyspace.sh
./scripts/05_generate_interactions.sh
./scripts/08_ingest_kafka.sh
./scripts/11_test_pagination.sh
```

### domirama2

```bash
cd poc-design/domirama2
source ../../.poc-profile
./scripts/10_setup_domirama2_poc.sh
./scripts/11_load_domirama2_data_fixed.sh
./scripts/12_test_domirama2_search.sh
```

### domiramaCatOps

```bash
cd poc-design/domiramaCatOps
source ../../.poc-profile
./scripts/01_setup_domiramaCatOps_keyspace.sh
./scripts/04_generate_operations_parquet.sh
./scripts/05_load_operations_data_parquet.sh
./scripts/08_test_category_search.sh
```

---

## 📚 Documentation Complémentaire

- **GUIDE_COMPARAISON_POCS.md** : Comparaison détaillée technique
- **poc-design/bic/README.md** : Documentation complète BIC
- **poc-design/domirama2/README.md** : Documentation complète domirama2
- **poc-design/domiramaCatOps/README.md** : Documentation complète domiramaCatOps

---

## ❓ Questions Fréquentes

### Puis-je utiliser plusieurs POCs en même temps ?

**Oui**, chaque POC utilise son propre keyspace :
- BIC : `bic_poc`
- domirama2 : `domirama2_poc`
- domiramaCatOps : `domiramacatops_poc`

### Quel POC pour la recherche vector ?

**domirama2** ou **domiramaCatOps** :
- domirama2 : Recherche hybride (full-text + vector)
- domiramaCatOps : Recherche vector avec 3 modèles (ByteT5, e5-large, invoice)

### Quel POC pour l'ingestion Kafka ?

**BIC** uniquement :
- Ingestion temps réel depuis Kafka
- Topic `bic-event`
- Spark Structured Streaming

### Quel POC pour l'export batch ?

**BIC** ou **domirama2** :
- BIC : Export HDFS/ORC
- domirama2 : Export Parquet incrémental (fenêtre glissante)

---

**Pour plus d'informations, voir** :
- `docs/GUIDE_COMPARAISON_POCS.md` - Comparaison technique détaillée
- `poc-design/*/README.md` - Documentation de chaque POC

