# 🏦 POC BIC (Base d'Interaction Client)

**Date** : 2025-12-01  
**Version** : 1.0.0  
**Objectif** : Démonstration de la migration de la table BIC (Base d'Interaction Client) de HBase vers HCD  
**IBM | Opportunité ICS 006gR000001hiA5QAI - AREKA | Ingénieur Avant-Vente** : David LECONTE | <david.leconte1@ibm.com> - Mobile : +33614126117

---

## 📋 Vue d'Ensemble

Ce POC démontre la migration de la **Base d'Interaction Client (BIC)** de HBase vers DataStax Hyper-Converged Database (HCD), en se concentrant sur les interactions entre les conseillers et les clients.

### Caractéristiques Principales

- ✅ **Timeline conseiller** : 2 ans d'historique des interactions
- ✅ **Ingestion Kafka temps réel** : Événements `bic-event` en streaming
- ✅ **Export batch ORC incrémental** : Export `bic-unload` pour analyse
- ✅ **Filtrage par canal** : Email, SMS, agence, téléphone, etc.
- ✅ **Filtrage par type d'interaction** : Consultation, conseil, transaction, etc.
- ✅ **TTL 2 ans** : Rétention des données (vs 10 ans pour Domirama)
- ✅ **Format JSON + colonnes dynamiques** : Flexibilité du schéma
- ✅ **Backend API conseiller** : Lecture temps réel pour applications

---

## 🏗️ Structure du Projet

```
bic/
├── scripts/                  # Scripts d'automatisation
│   ├── setup/               # Scripts de configuration (01-04)
│   ├── generation/          # Génération de données (05-07)
│   ├── ingestion/           # Ingestion de données (08-10)
│   ├── tests/               # Tests fonctionnels (11-15)
│   ├── recherche/           # Recherche et requêtes (16-20)
│   └── demonstrations/      # Démonstrations complètes (21-25)
│
├── doc/                      # Documentation complète
│   ├── design/              # Design et architecture
│   ├── guides/               # Guides d'utilisation
│   ├── implementation/       # Documents d'implémentation
│   ├── results/             # Résultats de tests
│   ├── corrections/          # Corrections appliquées
│   ├── audits/              # Audits et analyses
│   ├── demonstrations/      # Rapports de démonstrations
│   └── templates/           # Templates réutilisables
│
├── schemas/                  # Schémas CQL
│   ├── keyspace.cql         # Création du keyspace
│   ├── tables.cql           # Création des tables
│   └── indexes.cql          # Création des index SAI
│
├── utils/                    # Utilitaires
│   └── didactique_functions.sh  # Fonctions communes
│
├── examples/                 # Exemples de code
│   ├── python/              # Scripts Python
│   └── scala/               # Scripts Scala/Spark
│
├── data/                     # Données de test
│   ├── parquet/             # Fichiers Parquet
│   └── json/                # Fichiers JSON
│
├── archive/                  # Archives
│
└── README.md                 # Ce fichier
```

---

## 🚀 Démarrage Rapide

### 1. Prérequis

- ✅ HCD 1.2.3 installé et démarré
- ✅ Spark 3.5.1 configuré
- ✅ Kafka 4.1.1 configuré (pour ingestion temps réel)
- ✅ Python 3.8-3.11

### 2. Configuration de l'Environnement

```bash
cd /path/to/Arkea
source .poc-profile
check_poc_env
```

### 3. Setup Initial

```bash
cd poc-design/bic

# Créer le keyspace et les tables
./scripts/setup/01_setup_bic_keyspace.sh

# Créer les index SAI
./scripts/setup/02_setup_bic_indexes.sh
```

### 4. Génération et Ingestion

```bash
# Générer des données de test
./scripts/generation/05_generate_interactions_parquet.sh

# Ingestion batch
./scripts/ingestion/08_load_interactions_batch.sh

# Ingestion temps réel (Kafka)
./scripts/ingestion/09_load_interactions_realtime.sh
```

---

## 📚 Documentation

Toute la documentation est dans le répertoire `doc/` :

### Guides Principaux

- **doc/guides/01_README.md** - Vue d'ensemble du POC BIC
- **doc/guides/02_GUIDE_SETUP.md** - Guide de configuration
- **doc/guides/03_GUIDE_INGESTION.md** - Guide d'ingestion
- **doc/guides/04_GUIDE_RECHERCHE.md** - Guide de recherche

### Design et Architecture

- **doc/design/01_DATA_MODEL.md** - Modèle de données
- **doc/design/02_ARCHITECTURE.md** - Architecture du POC
- **doc/design/03_MIGRATION_STRATEGY.md** - Stratégie de migration

Voir `doc/INDEX.md` pour l'index complet.

---

## 🎯 Use Cases Couverts

### 1. Timeline Conseiller

- ✅ Historique des interactions sur 2 ans
- ✅ Filtrage par client
- ✅ Tri chronologique
- ✅ Pagination

### 2. Ingestion Temps Réel

- ✅ Kafka streaming (`bic-event` topic)
- ✅ Spark Streaming → HCD
- ✅ Traitement en temps réel
- ✅ Gestion des erreurs

### 3. Export Batch

- ✅ Export incrémental ORC
- ✅ Filtrage par période
- ✅ Export pour analyse (HDFS)

### 4. Recherche et Filtrage

- ✅ Par canal (email, SMS, agence, etc.)
- ✅ Par type d'interaction
- ✅ Par période
- ✅ Recherche full-text sur contenu

---

## 🛠️ Scripts Disponibles

### Setup (scripts/setup/)

- `01_setup_bic_keyspace.sh` - Création du keyspace
- `02_setup_bic_tables.sh` - Création des tables
- `03_setup_bic_indexes.sh` - Création des index SAI
- `04_verify_setup.sh` - Vérification de la configuration

### Génération (scripts/generation/)

- `05_generate_interactions_parquet.sh` - Génération données Parquet
- `06_generate_interactions_json.sh` - Génération données JSON
- `07_generate_test_data.sh` - Génération données de test

### Ingestion (scripts/ingestion/)

- `08_load_interactions_batch.sh` - Ingestion batch (Parquet)
- `09_load_interactions_realtime.sh` - Ingestion temps réel (Kafka)
- `10_load_interactions_json.sh` - Ingestion JSON

### Tests (scripts/tests/)

- `11_test_timeline_conseiller.sh` - Test timeline conseiller
- `12_test_filtrage_canal.sh` - Test filtrage par canal
- `13_test_filtrage_type.sh` - Test filtrage par type
- `14_test_export_batch.sh` - Test export batch
- `15_test_ttl.sh` - Test TTL 2 ans

### Recherche (scripts/recherche/)

- `16_test_fulltext_search.sh` - Recherche full-text
- `17_test_timeline_query.sh` - Requêtes timeline
- `18_test_filtering.sh` - Tests de filtrage avancé
- `19_test_performance.sh` - Tests de performance
- `20_test_api_backend.sh` - Tests API backend

### Démonstrations (scripts/demonstrations/)

- `21_demo_timeline_complete.sh` - Démonstration timeline complète
- `22_demo_kafka_streaming.sh` - Démonstration streaming Kafka
- `23_demo_export_batch.sh` - Démonstration export batch
- `24_demo_data_api.sh` - Démonstration Data API
- `25_demo_complete.sh` - Démonstration complète

---

## 📊 Schéma de Données

### Keyspace

```cql
CREATE KEYSPACE bic_poc
WITH REPLICATION = {
  'class': 'SimpleStrategy',
  'replication_factor': 1
};
```

### Table Principale

```cql
CREATE TABLE bic_poc.interactions_by_client (
    code_efs text,
    numero_client text,
    date_interaction timestamp,
    canal text,
    type_interaction text,
    idt_tech text,
    json_data text,
    colonnes_dynamiques map<text, text>,
    PRIMARY KEY ((code_efs, numero_client), date_interaction, canal, type_interaction, idt_tech)
) WITH CLUSTERING ORDER BY (date_interaction DESC, canal ASC)
  AND default_time_to_live = 63072000;  -- 2 ans en secondes
```

---

## ⚙️ Configuration

Le POC BIC utilise la configuration centralisée du projet ARKEA :

- `.poc-config.sh` - Configuration centralisée
- Variables d'environnement : `HCD_HOST`, `HCD_PORT`, `KAFKA_BOOTSTRAP_SERVERS`

---

## 🔍 Vérification

```bash
# Vérifier la configuration
./scripts/setup/04_verify_setup.sh

# Vérifier les données
cqlsh $HCD_HOST $HCD_PORT -e "USE bic_poc; SELECT COUNT(*) FROM interactions_by_client;"
```

---

## 📝 Prérequis

- **HCD 1.2.3** - Installé et démarré
- **Spark 3.5.1** - Pour traitement batch
- **Kafka 4.1.1** - Pour ingestion temps réel
- **Python 3.8-3.11** - Pour scripts Python

---

## 📖 Pour Plus d'Informations

- Documentation complète : `doc/`
- Architecture : `doc/design/02_ARCHITECTURE.md`
- Guide de déploiement : `doc/guides/02_GUIDE_SETUP.md`
- Guide de dépannage : `../../docs/TROUBLESHOOTING.md`

---

## ✅ Statut

- 🔄 **Structure créée** - Répertoires et fichiers de base
- 🔄 **Schémas à créer** - Keyspace et tables
- 🔄 **Scripts à développer** - Scripts de setup, ingestion, tests
- 🔄 **Documentation à compléter** - Guides et design

---

**POC BIC en cours de développement !** 🚀
