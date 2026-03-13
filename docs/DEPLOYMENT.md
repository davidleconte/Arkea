# 🚀 Guide de Déploiement - ARKEA

**Date** : 2026-03-13
**Objectif** : Guide complet pour déployer le projet ARKEA
**Version** : 1.0

---

## 📋 Table des Matières

- [Prérequis](#prérequis)
- [Installation](#installation)
- [Configuration](#configuration)
- [Démarrage](#démarrage)
- [Vérification](#vérification)
- [Dépannage](#dépannage)

---

## 🔧 Prérequis

### Système d'Exploitation

- ✅ **macOS** 12+ (testé sur MacBook Pro M3 Pro)
- ✅ **Linux** (Ubuntu 20.04+, CentOS 7+, RHEL 7+, Debian 10+, Fedora 30+)
- ✅ **Windows** (via WSL2 - voir [Guide Windows](GUIDE_INSTALLATION_WINDOWS.md))

### Logiciels Requis

#### Java

- ✅ **Java 11** (pour HCD et Spark 3.5.1)
- ✅ **Java 17** (pour Kafka 4.1.1, optionnel)

**Installation** :

```bash
# macOS (Homebrew)
brew install openjdk@11
brew install openjdk@17

# Linux
sudo apt-get install openjdk-11-jdk
sudo apt-get install openjdk-17-jdk
```

**Vérification** :

```bash
java -version
# Doit afficher Java 11 ou 17
```

#### Python

- ✅ **Python 3.8-3.11** (pour cqlsh et scripts)

**Installation** :

```bash
# macOS (Homebrew)
brew install python@3.11

# Linux
sudo apt-get install python3.11
```

**Vérification** :

```bash
python3 --version
# Doit afficher Python 3.8-3.11
```

#### Homebrew (macOS uniquement)

- ✅ **Homebrew** (pour Kafka sur macOS)

**Installation** :

```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
```

**Note** : Sur **Linux**, Kafka est installé via le script `02_install_kafka_linux.sh`. Sur **Windows (WSL2)**, suivez le guide Linux dans WSL2.

#### jenv (Recommandé)

- ✅ **jenv** (gestionnaire de versions Java)

**Installation** :

```bash
# macOS
brew install jenv

# Configuration
echo 'export PATH="$HOME/.jenv/bin:$PATH"' >> ~/.bash_profile
echo 'eval "$(jenv init -)"' >> ~/.bash_profile
```

---

## 📦 Installation

### 1. Cloner le Projet

```bash
git clone https://github.com/votre-org/Arkea.git
cd Arkea
```

### 2. Installer HCD

```bash
./scripts/setup/01_install_hcd.sh
```

**Ce script** :

- ✅ Détecte automatiquement l'OS (macOS/Linux/Windows WSL2)
- ✅ Configure Java 11 automatiquement
- ✅ Extrait HCD 1.2.3 dans `binaire/hcd-1.2.3/`
- ✅ Configure les permissions
- ✅ Vérifie l'installation

**Voir** :

- `docs/GUIDE_INSTALLATION_HCD.md` - Guide détaillé cross-platform
- `docs/GUIDE_INSTALLATION_LINUX.md` - Guide Linux spécifique
- `docs/GUIDE_INSTALLATION_WINDOWS.md` - Guide Windows (WSL2)

### 3. Installer Spark et Kafka

**macOS** :

```bash
./scripts/setup/02_install_spark_kafka.sh
```

**Linux** :

```bash
# Installer Spark
./scripts/setup/02_install_spark_kafka.sh

# Installer Kafka (script dédié Linux)
./scripts/setup/02_install_kafka_linux.sh
```

**Windows (WSL2)** :

```bash
# Suivre les étapes Linux dans WSL2
./scripts/setup/02_install_spark_kafka.sh
./scripts/setup/02_install_kafka_linux.sh
```

**Ce script** :

- ✅ Détecte automatiquement l'OS
- ✅ Extrait Spark 3.5.1 dans `binaire/spark-3.5.1/`
- ✅ Installe Kafka via Homebrew (macOS) ou script Linux
- ✅ Télécharge `spark-cassandra-connector`
- ✅ Configure les chemins automatiquement

**Voir** :

- `docs/GUIDE_INSTALLATION_SPARK_KAFKA.md` - Guide détaillé
- `docs/GUIDE_INSTALLATION_LINUX.md` - Guide Linux spécifique

### 4. Vérifier l'Installation

```bash
./scripts/utils/80_verify_all.sh
```

**Vérifie** :

- ✅ Java 11 et 17 installés
- ✅ HCD installé
- ✅ Spark installé
- ✅ Kafka installé
- ✅ Python 3.8-3.11 installé

---

## ⚙️ Configuration

### 1. Configuration de l'Environnement

**Le système de configuration est entièrement portable** :

```bash
# Charger la configuration (détection automatique de l'OS)
source .poc-profile

# Vérifier
check_poc_env
```

**Fonctionnalités** :

- ✅ Détection automatique de l'OS (macOS/Linux/Windows WSL2)
- ✅ Détection automatique des chemins (Java, Kafka, HCD, Spark)
- ✅ Variables d'environnement surchargeables
- ✅ Configuration centralisée (`.poc-config.sh`)

**Voir** :

- `docs/CONFIGURATION_ENVIRONNEMENT.md` - Guide de configuration
- `docs/AUDIT_PORTABILITE_CROSS_PLATFORM_2025.md` - Détails portabilité

### 2. Variables d'Environnement (Optionnel)

Si vous devez personnaliser la configuration :

```bash
# Définir avant de sourcer .poc-profile
export ARKEA_HOME="/chemin/vers/Arkea"
export HCD_HOST="localhost"
export HCD_PORT="9042"
export KAFKA_BOOTSTRAP_SERVERS="localhost:9092"

source .poc-profile
```

### 3. Configuration HCD

**Fichier** : `binaire/hcd-1.2.3/resources/cassandra/conf/cassandra.yaml`

**Paramètres importants** :

- `cluster_name` : Nom du cluster
- `listen_address` : Adresse d'écoute
- `rpc_address` : Adresse RPC
- `seeds` : Nœuds seeds

**Par défaut** : Configuration fonctionne en local

### 4. Configuration Kafka

**Fichier** : `$KAFKA_HOME/.bottle/etc/kafka/server.properties` (macOS Homebrew)

**Paramètres importants** :

- `broker.id` : ID du broker
- `listeners` : Adresses d'écoute
- `log.dirs` : Répertoires de logs

**Par défaut** : Configuration fonctionne en local

---

## 🚀 Démarrage

### 1. Démarrer HCD

```bash
# En arrière-plan
./scripts/setup/03_start_hcd.sh background

# Ou en foreground (pour debug)
./scripts/setup/03_start_hcd.sh
```

**Vérification** :

```bash
# Vérifier que HCD est démarré
cqlsh $HCD_HOST $HCD_PORT -e "DESCRIBE KEYSPACES;"
```

### 2. Démarrer Kafka

```bash
# En arrière-plan
./scripts/setup/04_start_kafka.sh background

# Ou en foreground (pour debug)
./scripts/setup/04_start_kafka.sh
```

**Vérification** :

```bash
# Lister les topics
kafka-topics.sh --list --bootstrap-server localhost:9092
```

### 3. Configurer le Streaming Kafka → HCD

```bash
./scripts/setup/05_setup_kafka_hcd_streaming.sh
```

**Ce script** :

- Crée le keyspace `poc_hbase_migration`
- Crée la table `kafka_events`
- Configure les topics Kafka

### 4. Tester le Pipeline

```bash
./scripts/setup/06_test_kafka_hcd_streaming.sh
```

**Ce script** :

- Envoie des messages de test à Kafka
- Vérifie la réception dans HCD
- Affiche les résultats

---

## ✅ Vérification

### Vérification Complète

```bash
./scripts/utils/80_verify_all.sh
```

**Vérifie** :

- ✅ Installation de tous les composants
- ✅ Services démarrés (HCD, Kafka)
- ✅ Connexions fonctionnelles
- ✅ Configuration correcte

### Vérifications Manuelles

#### HCD

```bash
# Connexion CQL
cqlsh $HCD_HOST $HCD_PORT

# Dans cqlsh
DESCRIBE KEYSPACES;
USE poc_hbase_migration;
DESCRIBE TABLES;
```

#### Spark

```bash
# Spark Shell
$SPARK_HOME/bin/spark-shell

# Dans Spark Shell
import org.apache.spark.sql.cassandra._
spark.read.cassandraFormat("kafka_events", "poc_hbase_migration").load().show()
```

#### Kafka

```bash
# Lister les topics
kafka-topics.sh --list --bootstrap-server localhost:9092

# Consommer des messages
kafka-console-consumer.sh --bootstrap-server localhost:9092 --topic test-topic --from-beginning
```

---

## 🔧 Dépannage

### Problèmes Courants

#### HCD ne démarre pas

**Symptômes** :

- Erreur "Address already in use"
- Erreur "Cannot bind to address"

**Solutions** :

```bash
# Vérifier les ports
lsof -i :9042
netstat -an | grep 9042

# Tuer les processus existants
pkill -f cassandra
pkill -f hcd

# Redémarrer
./scripts/setup/03_start_hcd.sh background
```

#### Kafka ne démarre pas

**Symptômes** :

- Erreur "Address already in use"
- Erreur Zookeeper

**Solutions** :

```bash
# Vérifier Zookeeper
lsof -i :2181

# Vérifier Kafka
lsof -i :9092

# Redémarrer
./scripts/setup/04_start_kafka.sh background
```

#### Erreurs de Connexion

**Symptômes** :

- "Connection refused"
- "Timeout"

**Solutions** :

```bash
# Vérifier que les services sont démarrés
./scripts/utils/80_verify_all.sh

# Vérifier les variables d'environnement
echo $HCD_HOST
echo $HCD_PORT
echo $KAFKA_BOOTSTRAP_SERVERS

# Vérifier les logs
tail -f binaire/hcd-1.2.3/logs/cassandra/system.log
tail -f $KAFKA_HOME/libexec/logs/kafka.log
```

#### Problèmes de Mémoire

**Symptômes** :

- OutOfMemoryError
- Services qui crashent

**Solutions** :

```bash
# Augmenter la mémoire Java pour HCD
export JAVA_OPTS="-Xms2G -Xmx4G"

# Augmenter la mémoire pour Spark
export SPARK_DRIVER_MEMORY="2g"
export SPARK_EXECUTOR_MEMORY="2g"
```

---

## 📊 Monitoring

### Logs

**HCD** :

```bash
tail -f binaire/hcd-1.2.3/logs/cassandra/system.log
tail -f binaire/hcd-1.2.3/logs/cassandra/debug.log
```

**Kafka** :

```bash
tail -f $KAFKA_HOME/libexec/logs/kafka.log
```

**Spark** :

```bash
# Logs dans $SPARK_HOME/logs/
```

### Métriques

**HCD** :

```bash
# Nodetool
nodetool status
nodetool info
nodetool tpstats
```

**Kafka** :

```bash
# Métriques via JMX (port 9999 par défaut)
```

---

## 🔄 Mise à Jour

### Mettre à Jour HCD

```bash
# Sauvegarder les données
# Arrêter HCD
# Remplacer binaire/hcd-1.2.3/
# Redémarrer
```

### Mettre à Jour Spark

```bash
# Sauvegarder la configuration
# Remplacer binaire/spark-3.5.1/
# Redémarrer
```

---

## 📚 Références

- `docs/ARCHITECTURE.md` - Architecture du projet
- `docs/TROUBLESHOOTING.md` - Guide de dépannage détaillé
- `README.md` - Vue d'ensemble
- `CONTRIBUTING.md` - Guide de contribution

---

**Date** : 2026-03-13
**Version** : 1.0
**Statut** : ✅ **Documentation complète**
