# 🐧 Guide d'Installation Linux - ARKEA

**Date** : 2025-12-01  
**Objectif** : Guide complet pour installer et configurer le projet ARKEA sur Linux  
**Version** : 1.0

---

## 📋 Table des Matières

- [Prérequis](#prérequis)
- [Installation](#installation)
- [Configuration](#configuration)
- [Vérification](#vérification)
- [Dépannage](#dépannage)

---

## 🔧 Prérequis

### Système d'Exploitation

- ✅ **Ubuntu** 20.04+ (testé)
- ✅ **CentOS** 7+ / **RHEL** 7+
- ✅ **Debian** 10+
- ✅ **Fedora** 30+

### Logiciels Requis

#### Java

- ✅ **Java 11** (pour HCD et Spark 3.5.1)
- ✅ **Java 17** (pour Kafka 4.1.1, optionnel)

**Installation Ubuntu/Debian** :

```bash
sudo apt-get update
sudo apt-get install -y openjdk-11-jdk openjdk-17-jdk
```

**Installation CentOS/RHEL** :

```bash
sudo yum install -y java-11-openjdk-devel java-17-openjdk-devel
```

**Installation Fedora** :

```bash
sudo dnf install -y java-11-openjdk-devel java-17-openjdk-devel
```

**Vérification** :

```bash
java -version
# Doit afficher Java 11 ou 17
```

**Configuration JAVA_HOME** :

```bash
# Ubuntu/Debian
export JAVA_HOME=/usr/lib/jvm/java-11-openjdk-amd64
export JAVA17_HOME=/usr/lib/jvm/java-17-openjdk-amd64

# CentOS/RHEL
export JAVA_HOME=/usr/lib/jvm/java-11-openjdk
export JAVA17_HOME=/usr/lib/jvm/java-17-openjdk

# Ajouter à ~/.bashrc ou ~/.bash_profile
echo 'export JAVA_HOME=/usr/lib/jvm/java-11-openjdk-amd64' >> ~/.bashrc
echo 'export JAVA17_HOME=/usr/lib/jvm/java-17-openjdk-amd64' >> ~/.bashrc
echo 'export PATH=$JAVA_HOME/bin:$PATH' >> ~/.bashrc
source ~/.bashrc
```

---

#### Python

- ✅ **Python 3.8-3.11** (pour cqlsh et scripts)

**Installation Ubuntu/Debian** :

```bash
sudo apt-get install -y python3.11 python3-pip
```

**Installation CentOS/RHEL** :

```bash
sudo yum install -y python3.11 python3-pip
```

**Installation Fedora** :

```bash
sudo dnf install -y python3.11 python3-pip
```

**Vérification** :

```bash
python3 --version
# Doit afficher Python 3.8-3.11
```

---

#### Outils Système

**Installation Ubuntu/Debian** :

```bash
sudo apt-get install -y curl wget tar gzip
```

**Installation CentOS/RHEL** :

```bash
sudo yum install -y curl wget tar gzip
```

**Installation Fedora** :

```bash
sudo dnf install -y curl wget tar gzip
```

---

## 📦 Installation

### 1. Cloner le Projet

```bash
git clone https://github.com/votre-org/Arkea.git
cd Arkea
```

---

### 2. Configurer l'Environnement

```bash
# Charger la configuration
source .poc-profile

# Vérifier
check_poc_env
```

**Variables d'Environnement Optionnelles** :

```bash
# Définir avant de sourcer .poc-profile
export ARKEA_HOME="/chemin/vers/Arkea"
export JAVA_HOME="/usr/lib/jvm/java-11-openjdk-amd64"
export JAVA17_HOME="/usr/lib/jvm/java-17-openjdk-amd64"
export HCD_HOST="localhost"
export HCD_PORT="9042"
export KAFKA_BOOTSTRAP_SERVERS="localhost:9092"

source .poc-profile
```

---

### 3. Installer HCD

```bash
./scripts/setup/01_install_hcd.sh
```

**Ce script** :

- Extrait HCD 1.2.3 dans `binaire/hcd-1.2.3/`
- Configure les permissions
- Vérifie l'installation
- Détecte automatiquement Java 11

**Vérification** :

```bash
ls -la binaire/hcd-1.2.3/bin/hcd
# Doit afficher le binaire HCD
```

---

### 4. Installer Spark

```bash
./scripts/setup/02_install_spark_kafka.sh
```

**Ce script** :

- Extrait Spark 3.5.1 dans `binaire/spark-3.5.1/`
- Télécharge `spark-cassandra-connector`
- Configure les chemins

**Note** : Ce script installe aussi Kafka (voir section suivante).

---

### 5. Installer Kafka

**Option 1 : Script Automatique (Recommandé)**

```bash
./scripts/setup/02_install_kafka_linux.sh
```

**Ce script** :

- Télécharge Kafka 4.1.1 depuis Apache
- Extrait dans `binaire/kafka/`
- Configure les chemins

**Option 2 : Installation Manuelle**

```bash
# Télécharger Kafka
cd software
wget https://archive.apache.org/dist/kafka/4.1.1/kafka_2.13-4.1.1.tgz

# Extraire
cd ../binaire
tar -xzf ../software/kafka_2.13-4.1.1.tgz
mv kafka_2.13-4.1.1 kafka

# Configurer
export KAFKA_HOME="$(pwd)/kafka"
export PATH="$KAFKA_HOME/bin:$PATH"
```

---

## ⚙️ Configuration

### 1. Configuration HCD

**Fichier** : `binaire/hcd-1.2.3/resources/cassandra/conf/cassandra.yaml`

**Paramètres importants** :

```yaml
cluster_name: 'ARKEA POC'
listen_address: localhost
rpc_address: localhost
seeds: "127.0.0.1"
```

**Par défaut** : Configuration fonctionne en local

---

### 2. Configuration Kafka

**Fichier** : `binaire/kafka/config/server.properties`

**Paramètres importants** :

```properties
broker.id=0
listeners=PLAINTEXT://localhost:9092
log.dirs=/tmp/kafka-logs
```

**Créer répertoire de logs** :

```bash
mkdir -p /tmp/kafka-logs
# Ou utiliser un répertoire personnalisé
mkdir -p $ARKEA_HOME/kafka-logs
# Modifier log.dirs dans server.properties
```

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

---

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

---

### 3. Configurer le Streaming Kafka → HCD

```bash
./scripts/setup/05_setup_kafka_hcd_streaming.sh
```

**Ce script** :

- Crée le keyspace `poc_hbase_migration`
- Crée la table `kafka_events`
- Configure les topics Kafka

---

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

---

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
ss -tuln | grep 9042
# Ou
netstat -tuln | grep 9042

# Tuer les processus existants
pkill -f cassandra
pkill -f hcd

# Redémarrer
./scripts/setup/03_start_hcd.sh background
```

---

#### Kafka ne démarre pas

**Symptômes** :

- Erreur "Address already in use"
- Erreur Zookeeper

**Solutions** :

```bash
# Vérifier Zookeeper (Kafka 2.8+ n'utilise plus Zookeeper)
# Vérifier Kafka
ss -tuln | grep 9092

# Redémarrer
./scripts/setup/04_start_kafka.sh background
```

---

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
tail -f binaire/kafka/logs/kafka.log
```

---

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

#### Problèmes de Permissions

**Symptômes** :

- "Permission denied"
- Erreurs d'écriture

**Solutions** :

```bash
# Vérifier les permissions
ls -la binaire/hcd-1.2.3/bin/hcd
ls -la binaire/kafka/bin/kafka-server-start.sh

# Ajouter les permissions d'exécution
chmod +x binaire/hcd-1.2.3/bin/hcd
chmod +x binaire/kafka/bin/kafka-server-start.sh
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
tail -f binaire/kafka/logs/kafka.log
```

**Spark** :

```bash
# Logs dans $SPARK_HOME/logs/
```

---

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

### Mettre à Jour Kafka

```bash
# Sauvegarder la configuration
# Remplacer binaire/kafka/
# Redémarrer
```

---

## 📚 Références

- `docs/DEPLOYMENT.md` - Guide de déploiement général
- `docs/TROUBLESHOOTING.md` - Guide de dépannage détaillé
- `README.md` - Vue d'ensemble
- `CONTRIBUTING.md` - Guide de contribution

---

**Date** : 2025-12-01  
**Version** : 1.0  
**Statut** : ✅ **Documentation complète**
