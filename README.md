# 🚀 POC Migration HBase → HCD (Hyper-Converged Database)

**Date** : 2025-11-25  
**Objectif** : Démonstration de faisabilité de la migration HBase vers DataStax HCD

---

## 📋 Vue d'Ensemble

Ce projet démontre la faisabilité de migrer l'architecture HBase existante chez Arkéa vers DataStax Hyper-Converged Database (HCD) en utilisant Spark, Kafka et Cassandra.

### Composants Principaux

- **HCD 1.2.3** - Base de données cible (basée sur Cassandra 4.0.11)
- **Spark 3.5.1** - Traitement distribué et streaming
- **Kafka 4.1.1** - Streaming de données
- **spark-cassandra-connector 3.5.0** - Intégration Spark ↔ HCD

---

## 🏗️ Structure du Projet

```
Arkea/
├── inputs-clients/     # Documents fournis par le client
├── inputs-ibm/          # Documents fournis par IBM
├── software/            # Archives des logiciels (.tar.gz, .tgz)
├── binaire/             # Logiciels extraits et installés
├── docs/                # Documentation complète
├── [0-9]*.sh           # Scripts numérotés (01-06, 70-90)
└── .poc-profile         # Configuration des variables d'environnement
```

---

## 🚀 Démarrage Rapide

### 1. Configuration de l'Environnement

```bash
cd /Users/david.leconte/Documents/Arkea
source .poc-profile
check_poc_env
```

### 2. Installation

```bash
# Installer HCD
./01_install_hcd.sh

# Installer Spark et Kafka
./02_install_spark_kafka.sh
```

### 3. Démarrage des Services

```bash
# Démarrer HCD
./03_start_hcd.sh background

# Démarrer Kafka
./04_start_kafka.sh background
```

### 4. Configuration et Test

```bash
# Configurer le streaming Kafka → HCD
./05_setup_kafka_hcd_streaming.sh

# Tester le pipeline complet
./06_test_kafka_hcd_streaming.sh
```

---

## 📚 Documentation

Toute la documentation est dans le répertoire `docs/` :

- **STRUCTURE_PROJET.md** - Structure complète du projet
- **ORDRE_EXECUTION_SCRIPTS.md** - Guide d'exécution des scripts
- **GUIDE_INSTALLATION_*** - Guides d'installation
- **ARCHITECTURE_POC_COMPLETE.md** - Architecture technique
- **ANALYSE_ETAT_ART_HBASE.md** - Analyse de l'existant

Voir `docs/README.md` pour l'index complet.

---

## 🛠️ Scripts Disponibles

### Installation (01-06)
- `01_install_hcd.sh` - Installe HCD
- `02_install_spark_kafka.sh` - Installe Spark et Kafka
- `03_start_hcd.sh` - Démarre HCD
- `04_start_kafka.sh` - Démarre Kafka
- `05_setup_kafka_hcd_streaming.sh` - Configure le streaming
- `06_test_kafka_hcd_streaming.sh` - Test du pipeline

### Utilitaires (70-90)
- `70_kafka-helper.sh` - Helper pour Kafka
- `80_verify_all.sh` - Vérifie tous les composants
- `90_list_scripts.sh` - Liste tous les scripts

---

## ⚙️ Configuration

Le fichier `.poc-profile` contient toutes les variables d'environnement nécessaires :

```bash
source .poc-profile
```

Voir `docs/CONFIGURATION_ENVIRONNEMENT.md` pour les détails.

---

## 📊 Objectifs du POC

1. ✅ **Maîtrise de l'existant** - Analyse HBase/MR/Kafka/Elastic
2. ✅ **POC Spark + Cassandra/HCD** - Schémas réalistes, données simulées
3. 🔄 **Réutilisation de la logique métier** - Adaptation de `recurrentDetection` pour Spark
4. 🔄 **Design de migration** - Stratégies HBase → HCD, documentation MECE

---

## 🔍 Vérification

```bash
# Vérifier l'état de tous les composants
./80_verify_all.sh

# Lister tous les scripts
./90_list_scripts.sh
```

---

## 📝 Prérequis

- **macOS** (testé sur MacBook Pro M3 Pro)
- **Java 11** (pour HCD et Spark 3.5.1)
- **Java 17** (pour Kafka 4.1.1)
- **Python 3.8-3.11**
- **Homebrew** (pour Kafka)
- **jenv** (recommandé pour gérer les versions Java)

---

## 📖 Pour Plus d'Informations

- Documentation complète : `docs/`
- Structure du projet : `docs/STRUCTURE_PROJET.md`
- Configuration : `docs/CONFIGURATION_ENVIRONNEMENT.md`

---

## ✅ Statut

- ✅ Infrastructure installée et opérationnelle
- ✅ Pipeline Kafka → HCD fonctionnel
- ✅ Tests réussis
- 🔄 Schémas Domirama/BIC à créer
- 🔄 Jobs Spark métier à développer

---

**POC opérationnel et prêt pour le développement !** 🚀



