# 📖 Guide : Vue d'Ensemble du POC BIC

**Date** : 2025-12-01
**Version** : 1.0.0
**Objectif** : Vue d'ensemble du POC BIC (Base d'Interaction Client)

---

## 📋 Table des Matières

- [Vue d'Ensemble](#vue-densemble)
- [Objectifs](#objectifs)
- [Use Cases](#use-cases)
- [Architecture](#architecture)
- [Structure du Projet](#structure-du-projet)
- [Démarrage Rapide](#démarrage-rapide)

---

## 🎯 Vue d'Ensemble

Le **POC BIC (Base d'Interaction Client)** démontre la migration de la table BIC de HBase vers DataStax HCD, en se concentrant sur les interactions entre les conseillers et les clients.

### Contexte

La table BIC dans HBase stocke :

- Les interactions entre conseillers et clients
- Historique sur 2 ans (TTL)
- Données en format JSON avec colonnes dynamiques
- Ingestion temps réel via Kafka (`bic-event`)
- Export batch pour analyse (`bic-unload`)

---

## 🎯 Objectifs

### Objectifs Fonctionnels

1. ✅ **Timeline conseiller** : Afficher l'historique des interactions d'un client
2. ✅ **Ingestion temps réel** : Traiter les événements Kafka en streaming
3. ✅ **Export batch** : Exporter les données pour analyse (ORC/HDFS)
4. ✅ **Filtrage avancé** : Par canal, type, période
5. ✅ **Recherche full-text** : Recherche dans le contenu JSON

### Objectifs Techniques

1. ✅ **Performance équivalente** : Temps de réponse < 100ms
2. ✅ **Scalabilité** : Support de millions d'interactions
3. ✅ **TTL 2 ans** : Rétention automatique
4. ✅ **Format flexible** : JSON + colonnes dynamiques

---

## 📊 Use Cases

### UC-01 : Timeline Conseiller

**Description** : Afficher toutes les interactions d'un client sur 2 ans

**Requête** :

```cql
SELECT * FROM bic_poc.interactions_by_client
WHERE code_efs = 'EFS001' AND numero_client = 'CLIENT123'
ORDER BY date_interaction DESC
LIMIT 100;
```

### UC-02 : Filtrage par Canal

**Description** : Filtrer les interactions par canal (email, SMS, agence)

**Requête** :

```cql
SELECT * FROM bic_poc.interactions_by_client
WHERE code_efs = 'EFS001'
  AND numero_client = 'CLIENT123'
  AND canal = 'email'
ORDER BY date_interaction DESC;
```

### UC-03 : Ingestion Kafka Temps Réel

**Description** : Ingérer les événements `bic-event` depuis Kafka

**Flux** :

```
Kafka Topic (bic-event)
    ↓
Spark Streaming
    ↓
HCD (interactions_by_client)
```

### UC-04 : Export Batch ORC

**Description** : Exporter les données pour analyse

**Flux** :

```
HCD (interactions_by_client)
    ↓
Spark Batch
    ↓
ORC Files (HDFS)
```

---

## 🏗️ Architecture

### Composants

- **HCD** : Stockage des interactions
- **Spark Streaming** : Traitement Kafka → HCD
- **Spark Batch** : Export ORC
- **Kafka** : Ingestion temps réel
- **Data API** : API REST/GraphQL (optionnel)

### Flux de Données

```
┌─────────┐
│  Kafka  │ (bic-event topic)
└────┬────┘
     │ Streaming
     ▼
┌─────────┐
│  Spark  │ (Streaming processing)
└────┬────┘
     │ Écriture
     ▼
┌─────────┐
│   HCD   │ (interactions_by_client)
└────┬────┘
     │ Export
     ▼
┌─────────┐
│  Spark  │ (Batch export)
└────┬────┘
     │ ORC
     ▼
┌─────────┐
│  HDFS   │ (Analyse)
└─────────┘
```

---

## 📁 Structure du Projet

```
bic/
├── scripts/              # Scripts organisés par fonction
├── doc/                  # Documentation complète
├── schemas/              # Schémas CQL
├── utils/                # Utilitaires
├── examples/             # Exemples de code
├── data/                 # Données de test
└── archive/              # Archives
```

Voir [`../README.md`](../README.md) pour la structure complète.

---

## 🚀 Démarrage Rapide

### 1. Prérequis

```bash
# Vérifier que HCD est démarré
cqlsh $HCD_HOST $HCD_PORT -e "DESCRIBE KEYSPACES;"

# Vérifier que Kafka est démarré (pour ingestion temps réel)
kafka-topics.sh --list --bootstrap-server localhost:9092
```

### 2. Setup Initial

```bash
cd poc-design/bic

# Créer le keyspace
cqlsh $HCD_HOST $HCD_PORT -f schemas/01_create_bic_keyspace.cql

# Créer les tables
cqlsh $HCD_HOST $HCD_PORT -f schemas/02_create_bic_tables.cql

# Créer les index
cqlsh $HCD_HOST $HCD_PORT -f schemas/03_create_bic_indexes.cql
```

### 3. Génération et Ingestion

```bash
# Générer des données de test
./scripts/generation/05_generate_interactions_parquet.sh

# Ingestion batch
./scripts/ingestion/08_load_interactions_batch.sh
```

---

## 📚 Documentation Complémentaire

- **Guide Setup** : [`02_GUIDE_SETUP.md`](02_GUIDE_SETUP.md)
- **Guide Ingestion** : [`03_GUIDE_INGESTION.md`](03_GUIDE_INGESTION.md)
- **Guide Recherche** : [`04_GUIDE_RECHERCHE.md`](04_GUIDE_RECHERCHE.md)
- **Architecture** : [`../design/02_ARCHITECTURE.md`](../design/02_ARCHITECTURE.md)

---

**Date** : 2025-12-01
**Version** : 1.0.0
