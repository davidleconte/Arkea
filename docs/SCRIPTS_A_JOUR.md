# ✅ Scripts d'Installation, Configuration et Tests - À Jour

**Date de mise à jour** : 2025-12-02  
**Statut** : ✅ Tous les scripts sont à jour, cohérents et portables cross-platform

---

## 📋 Liste des Scripts

### 📦 Installation

| Script | Description | Statut | Plateformes |
|--------|-------------|--------|-------------|
| `scripts/setup/01_install_hcd.sh` | Installe HCD 1.2.3 avec vérification Java 11 | ✅ À jour | macOS, Linux, Windows (WSL2) |
| `scripts/setup/02_install_spark_kafka.sh` | Installe Spark 3.5.1, Kafka et spark-cassandra-connector | ✅ À jour | macOS, Linux |
| `scripts/setup/02_install_kafka_linux.sh` | Installe Kafka 4.1.1 pour Linux | ✅ Nouveau | Linux uniquement |

### 🚀 Démarrage

| Script | Description | Statut | Plateformes |
|--------|-------------|--------|-------------|
| `scripts/setup/03_start_hcd.sh` | Démarre HCD (premier plan ou arrière-plan) | ✅ À jour | macOS, Linux, Windows (WSL2) |
| `scripts/setup/04_start_kafka.sh` | Démarre Kafka (premier plan ou arrière-plan) | ✅ À jour | macOS, Linux, Windows (WSL2) |

### 🔧 Configuration

| Script | Description | Statut | Plateformes |
|--------|-------------|--------|-------------|
| `scripts/setup/05_setup_kafka_hcd_streaming.sh` | Configure le streaming Kafka → HCD | ✅ À jour | Toutes |
| `scripts/setup/06_test_kafka_hcd_streaming.sh` | Test complet du pipeline Kafka → HCD | ✅ À jour | Toutes |

### 🛠️ Utilitaires

| Script | Description | Statut | Plateformes |
|--------|-------------|--------|-------------|
| `scripts/utils/70_kafka-helper.sh` | Helper pour utiliser Kafka avec Java 17 | ✅ À jour | macOS, Linux |
| `scripts/utils/80_verify_all.sh` | Vérifie l'état de tous les composants | ✅ À jour | Toutes |
| `scripts/utils/90_list_scripts.sh` | Liste tous les scripts disponibles | ✅ À jour | Toutes |
| `scripts/utils/91_check_consistency.sh` | Vérification de cohérence (chemins hardcodés, scripts, documentation) | ✅ Nouveau | Toutes |
| `scripts/utils/92_generate_docs.sh` | Génération automatique de documentation (index, listes, tableaux) | ✅ Nouveau | Toutes |
| `scripts/utils/93_fix_hardcoded_paths.sh` | Correction automatique des chemins hardcodés | ✅ Nouveau | Toutes |
| `scripts/utils/95_cleanup.sh` | Nettoyage automatique (UNLOAD_*, fichiers temporaires, logs anciens) | ✅ Nouveau | Toutes |
| `scripts/utils/portable_functions.sh` | Fonctions portables cross-platform | ✅ Nouveau | Toutes |

**Nouvelles Fonctions Portables** :

- `get_realpath()` - Chemin réel portable (macOS/Linux/Windows)
- `check_port()` - Vérification de port portable
- `kill_process()` - Arrêt de processus portable
- `detect_os()` - Détection de l'OS

---

## 🔄 Modifications Récentes

### 1. `install_spark_kafka.sh` ✅ Mis à jour

**Changements** :

- ✅ Installation manuelle de Spark 3.5.1 (au lieu de Homebrew qui installe Spark 4.x)
- ✅ Désinstallation automatique de Spark 4.x si présent
- ✅ Téléchargement et extraction de Spark 3.5.1 depuis archive.apache.org
- ✅ Instructions mises à jour pour utiliser les scripts locaux

**Raison** : Spark 4.x nécessite Java 17, mais HCD nécessite Java 11. Spark 3.5.1 est compatible avec Java 11.

### 2. `verify_all.sh` ✅ Nouveau

**Fonctionnalités** :

- ✅ Vérifie Java (version et configuration)
- ✅ Vérifie HCD (installation et état)
- ✅ Vérifie Spark (installation et version)
- ✅ Vérifie Kafka (installation et état)
- ✅ Vérifie spark-cassandra-connector
- ✅ Vérifie les schémas HCD
- ✅ Vérifie les scripts disponibles

### 3. `list_scripts.sh` ✅ Nouveau

**Fonctionnalités** :

- ✅ Liste tous les scripts avec leur description
- ✅ Organisé par catégorie (Installation, Démarrage, Configuration, Tests, Utilitaires)
- ✅ Affiche les fichiers Scala de test
- ✅ Référence la documentation

---

## 📝 Utilisation

### Vérifier l'état de tous les composants

```bash
./verify_all.sh
```

### Lister tous les scripts disponibles

```bash
./list_scripts.sh
```

### Installation complète (ordre recommandé)

```bash
# Charger la configuration (détection automatique de l'OS)
source .poc-profile

# 1. Installer HCD (cross-platform)
./scripts/setup/01_install_hcd.sh

# 2. Installer Spark et Kafka
# macOS : Utilise Homebrew automatiquement
# Linux : Utilise les scripts d'installation automatique
./scripts/setup/02_install_spark_kafka.sh

# Linux uniquement : Installer Kafka si nécessaire
# ./scripts/setup/02_install_kafka_linux.sh

# 3. Démarrer HCD
./start_hcd.sh background

# 4. Démarrer Kafka
./start_kafka.sh background

# 5. Configurer le streaming
./setup_kafka_hcd_streaming.sh

# 6. Tester le pipeline
./test_kafka_hcd_streaming.sh
```

---

## ✅ Vérifications de Cohérence

### Chemins

Tous les scripts utilisent le chemin correct :

- `INSTALL_DIR="/Users/david.leconte/Documents/Arkea"`
- `HCD_DIR="$INSTALL_DIR/hcd-1.2.3"`
- `SPARK_HOME="$INSTALL_DIR/spark-3.5.1"`

### Versions Java

- **HCD** : Java 11 (via jenv ou Homebrew)
- **Spark 3.5.1** : Java 11 (via jenv ou Homebrew)
- **Kafka 4.1.1** : Java 17 (via Homebrew)

### Versions des Composants

- **HCD** : 1.2.3
- **Spark** : 3.5.1
- **Kafka** : 4.1.1
- **spark-cassandra-connector** : 3.5.0
- **spark-sql-kafka** : 3.5.1 (téléchargé automatiquement)

---

## 🔍 Détails par Script

### `install_hcd.sh`

- ✅ Vérifie Java 11 (jenv ou Homebrew)
- ✅ Extrait HCD depuis le tarball
- ✅ Crée les répertoires de données
- ✅ Configure les permissions

### `install_spark_kafka.sh`

- ✅ Vérifie Java 11
- ✅ Désinstalle Spark 4.x si présent
- ✅ Télécharge Spark 3.5.1
- ✅ Installe Kafka via Homebrew
- ✅ Télécharge spark-cassandra-connector
- ✅ Installe les dépendances Python

### `start_hcd.sh`

- ✅ Configure Java 11 via jenv
- ✅ Vérifie que HCD n'est pas déjà démarré
- ✅ Démarre HCD (premier plan ou arrière-plan)
- ✅ Affiche les logs

### `start_kafka.sh`

- ✅ Configure Java 17
- ✅ Vérifie que Kafka n'est pas déjà démarré
- ✅ Démarre Kafka (premier plan ou arrière-plan)
- ✅ Affiche les logs

### `setup_kafka_hcd_streaming.sh`

- ✅ Crée le répertoire de checkpoint
- ✅ Crée le keyspace `poc_hbase_migration`
- ✅ Crée la table `kafka_events`
- ✅ Vérifie que Kafka et HCD sont démarrés

### `test_kafka_hcd_streaming.sh`

- ✅ Vérifie que Kafka et HCD sont démarrés
- ✅ Crée le topic `test-topic` si nécessaire
- ✅ Produit des messages de test
- ✅ Lance un job Spark pour transférer vers HCD
- ✅ Vérifie les données dans HCD

### `kafka-helper.sh`

- ✅ Configure Java 17 automatiquement
- ✅ Exécute les commandes Kafka
- ✅ Gère les chemins Kafka Homebrew

---

## 🎯 Prochaines Étapes

Tous les scripts sont à jour et prêts à l'emploi. Pour continuer le POC :

1. ✅ **Installation** - Terminée
2. ✅ **Configuration** - Terminée
3. ✅ **Tests** - Réussis
4. 🔄 **Schémas Domirama/BIC** - À créer
5. 🔄 **Jobs Spark métier** - À développer
6. 🔄 **Migration HBase → HCD** - À documenter

---

**Tous les scripts sont à jour et cohérents ! ✅**
