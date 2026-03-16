# 🚀 Guide de Déploiement - ARKEA

**Date** : 2026-03-16
**Objectif** : Guide complet pour déployer le projet ARKEA avec Podman
**Version** : 2.0

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

- ✅ **macOS** 12+ (testé sur MacBook Pro M3 Pro - ARM64)
- ✅ **Linux** (Ubuntu 20.04+, CentOS 7+, RHEL 7+, Debian 10+, Fedora 30+)
- ✅ **Windows** (via WSL2 - voir [Guide Windows](GUIDE_INSTALLATION_WINDOWS.md))

### Logiciels Requis

#### Java

- ✅ **Java 11+** (pour Cassandra 5.0.6 et Spark 3.5.1)

**Installation** :

```bash
# macOS (Homebrew)
brew install openjdk@11

# Linux
sudo apt-get install openjdk-11-jdk
```

**Vérification** :

```bash
java -version
# Doit afficher Java 11+
```

#### Python

- ✅ **Python 3.9-3.12** (pour scripts et tests)

**Installation** :

```bash
# macOS (Homebrew)
brew install python@3.12

# Linux
sudo apt-get install python3.12
```

**Vérification** :

```bash
python3 --version
# Doit afficher Python 3.9+
```

#### Podman & Podman-Compose

- ✅ **Podman** 5.x (conteneurisation)
- ✅ **podman-compose** (orchestration)

**Installation** :

```bash
# macOS (Homebrew)
brew install podman podman-compose

# Linux
sudo apt-get install podman podman-compose
```

**Vérification** :

```bash
podman --version
podman-compose --version
```

---

## 📦 Installation

### 1. Cloner le Projet

```bash
git clone https://github.com/davidleconte/Arkea.git
cd Arkea
```

### 2. Démarrer les Services avec Podman

```bash
# Démarrer tous les services (Cassandra, Kafka, Spark, Kafka UI)
podman-compose --profile full up -d
```

**Ce script** :

- ✅ Lance Cassandra 5.0.6 sur le port 9102
- ✅ Lance Kafka 3.7.1 (KRaft mode) sur le port 9192
- ✅ Lance Spark Master UI sur le port 9280
- ✅ Lance Spark Worker sur le port 9281
- ✅ Lance Kafka UI sur le port 9190

**Note** : Les conteneurs sont configurés avec une isolation 5-couches (voir `PODMAN_RULES.md`).

### 3. Vérifier l'Installation

```bash
# Via Makefile
make status

# Ou directement
podman ps --filter "name=arkea"
```

**Vérifie** :

- ✅ Cassandra 5.0.6 sain (healthy)
- ✅ Kafka 3.7.1 sain (healthy)
- ✅ Spark Master sain (healthy)
- ✅ Spark Worker en cours d'exécution
- ✅ Kafka UI en cours d'exécution

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
- ✅ Détection automatique des chemins
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

### Démarrer les Services

```bash
# Démarrer tous les services
podman-compose --profile full up -d

# Vérifier le statut
podman ps --filter "name=arkea"
```

**Services disponibles** :

| Service | Port | URL |
|---------|------|-----|
| Cassandra CQL | 9102 | `localhost:9102` |
| Spark Master UI | 9280 | <http://localhost:9280> |
| Spark Worker UI | 9281 | <http://localhost:9281> |
| Kafka | 9192 | `localhost:9192` |
| Kafka UI | 9190 | <http://localhost:9190> |

### Vérification

```bash
# Cassandra
podman exec arkea-hcd cqlsh localhost 9042 -e "DESCRIBE KEYSPACES;"

# Kafka
podman exec arkea-kafka /opt/kafka/bin/kafka-topics.sh --list --bootstrap-server localhost:9092
```

### Arrêter les Services

```bash
# Arrêter tous les services
podman-compose down

# Ou via Makefile
make stop
```

---

## ✅ Vérification

### Vérification Complète

```bash
# Via Makefile
make status

# Ou script direct
./scripts/utils/80_verify_all.sh
```

**Vérifie** :

- ✅ Conteneurs Cassandra, Kafka, Spark en cours d'exécution
- ✅ Services sains (healthy)
- ✅ Ports accessibles
- ✅ Configuration correcte

### Vérifications Manuelles

#### Cassandra

```bash
# Connexion CQL
podman exec -it arkea-hcd cqlsh localhost 9042

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
