# Guide d'Installation : Spark + spark-cassandra-connector + Kafka

**Date** : 2026-03-13 (Mise à jour pour portabilité cross-platform)
**Systèmes supportés** : macOS, Linux, Windows (WSL2)
**Objectif** : POC Migration HBase → HCD

---

## 📋 Vue d'Ensemble

Pour le POC, nous devons installer :

1. **Apache Spark** : Traitement distribué des données
2. **spark-cassandra-connector** : Connexion Spark ↔ Cassandra/HCD
3. **Apache Kafka** : Streaming de données (pour simuler l'intégration BIC/EDM)

---

## 🔧 Prérequis Vérifiés

- ✅ **Java 11** : OpenJDK 11.0.28 (via jenv)
- ✅ **Python** : 3.10.11
- ✅ **HCD** : 1.2.3 opérationnel (port 9042)
- ✅ **Podman** : 5.6.0 (pour Kafka si nécessaire)

---

## 1. Installation d'Apache Spark

### Option A : Installation via Homebrew (Recommandé)

```bash
# Installer Spark
brew install apache-spark

# Vérifier l'installation
spark-submit --version
```

### Option B : Installation Manuelle (Recommandé pour Linux)

**Utiliser le script d'installation automatique** :

```bash
# Charger la configuration
source .poc-profile

# Installer Spark (détection automatique de ARKEA_HOME)
./scripts/setup/02_install_spark_kafka.sh
```

**Ou installation manuelle** :

```bash
# Détecter automatiquement le répertoire du projet
cd "${ARKEA_HOME:-$(pwd)}"

# Télécharger Spark 3.5.1 (compatible avec Java 11)
mkdir -p software
cd software
curl -O https://archive.apache.org/dist/spark/spark-3.5.1/spark-3.5.1-bin-hadoop3.tgz

# Extraire
cd ..
mkdir -p binaire
tar xzf software/spark-3.5.1-bin-hadoop3.tgz -C binaire
mv binaire/spark-3.5.1-bin-hadoop3 binaire/spark-3.5.1

# Les variables sont configurées automatiquement par .poc-config.sh
# SPARK_HOME sera détecté automatiquement
```

**Note** : Sur **Linux**, utilisez `~/.bashrc` au lieu de `~/.zshrc`.

### Vérification

```bash
# Vérifier la version
spark-submit --version

# Lancer un test
spark-shell --version
```

---

## 2. Installation de spark-cassandra-connector

### Option A : Via Maven (Recommandé pour Scala/Java)

**Version compatible** : spark-cassandra-connector_2.12-3.5.0.jar

```bash
# Créer un répertoire pour les JARs (chemin portable)
mkdir -p "${ARKEA_HOME:-$(pwd)}/binaire/spark-jars"

# Télécharger le connector
cd "${ARKEA_HOME:-$(pwd)}/binaire/spark-jars"
curl -O https://repo1.maven.org/maven2/com/datastax/spark/spark-cassandra-connector_2.12/3.5.0/spark-cassandra-connector_2.12-3.5.0.jar

# Télécharger les dépendances (si nécessaire)
# Cassandra driver core
curl -O https://repo1.maven.org/maven2/com/datastax/oss/java-driver-core/4.17.0/java-driver-core-4.17.0.jar
```

### Option B : Via PySpark (Pour Python)

```bash
# Installer via pip
pip3 install pyspark
pip3 install cassandra-driver

# Le connector sera chargé via --packages lors de l'exécution
```

### Configuration Spark pour utiliser le connector

Créer un fichier de configuration : `spark-defaults.conf`

```bash
cd $SPARK_HOME/conf
cp spark-defaults.conf.template spark-defaults.conf
```

Ajouter dans `spark-defaults.conf` :

```properties
# Spark Cassandra Connector
spark.jars.packages com.datastax.spark:spark-cassandra-connector_2.12:3.5.0
spark.sql.extensions com.datastax.spark.connector.CassandraSparkExtensions
spark.cassandra.connection.host localhost
spark.cassandra.connection.port 9042
```

### Alternative : Via --packages (Recommandé)

Lors de l'exécution de Spark :

```bash
spark-shell --packages com.datastax.spark:spark-cassandra-connector_2.12:3.5.0 \
  --conf spark.cassandra.connection.host=localhost \
  --conf spark.cassandra.connection.port=9042
```

---

## 3. Installation d'Apache Kafka

### Option A : Via Homebrew (macOS uniquement)

```bash
# Installer Kafka
brew install kafka

# Démarrer Zookeeper (requis par Kafka < 2.8)
brew services start zookeeper

# Démarrer Kafka
brew services start kafka
```

**Note** : Kafka 4.1.1 (utilisé dans ce POC) n'utilise plus Zookeeper.

---

### Option B : Installation Automatique (Linux - Recommandé)

**Utiliser le script d'installation** :

```bash
# Charger la configuration
source .poc-profile

# Installer Kafka pour Linux
./scripts/setup/02_install_kafka_linux.sh
```

**Ce script** :

- Télécharge Kafka 4.1.1 depuis Apache
- Extrait dans `binaire/kafka/`
- Configure automatiquement `KAFKA_HOME`
- Compatible Ubuntu, CentOS, RHEL, Debian, Fedora

---

### Option C : Installation Manuelle (Linux)

```bash
# Détecter automatiquement le répertoire du projet
cd "${ARKEA_HOME:-$(pwd)}"

# Télécharger Kafka 4.1.1 (compatible avec Java 17)
mkdir -p software
cd software
curl -O https://archive.apache.org/dist/kafka/4.1.1/kafka_2.13-4.1.1.tgz

# Extraire
cd ..
mkdir -p binaire
tar xzf software/kafka_2.13-4.1.1.tgz -C binaire
mv binaire/kafka_2.13-4.1.1 binaire/kafka

# Les variables sont configurées automatiquement par .poc-config.sh
# KAFKA_HOME sera détecté automatiquement
```

**Voir** :

- `docs/GUIDE_INSTALLATION_LINUX.md` pour les détails Linux
- `docs/GUIDE_INSTALLATION_WINDOWS.md` pour Windows (WSL2)

### Option C : Via Podman (Alternative)

Si vous préférez utiliser Podman pour isoler Kafka :

```bash
# Créer un container Kafka avec Zookeeper
podman run -d --name kafka \
  -p 9092:9092 \
  -p 2181:2181 \
  apache/kafka:3.6.1
```

### Configuration Kafka

**Fichier** : `$KAFKA_HOME/config/server.properties`

Modifications recommandées pour développement local :

```properties
# Adresse d'écoute
listeners=PLAINTEXT://localhost:9092

# Répertoire des logs
log.dirs=/tmp/kafka-logs

# Zookeeper
zookeeper.connect=localhost:2181
```

### Démarrage Kafka

```bash
# Terminal 1 : Démarrer Zookeeper
cd $KAFKA_HOME
bin/zookeeper-server-start.sh config/zookeeper.properties

# Terminal 2 : Démarrer Kafka
cd $KAFKA_HOME
bin/kafka-server-start.sh config/server.properties
```

### Démarrage en Arrière-plan

```bash
# Zookeeper
nohup $KAFKA_HOME/bin/zookeeper-server-start.sh $KAFKA_HOME/config/zookeeper.properties > /tmp/zookeeper.log 2>&1 &

# Kafka
nohup $KAFKA_HOME/bin/kafka-server-start.sh $KAFKA_HOME/config/server.properties > /tmp/kafka.log 2>&1 &
```

### Vérification Kafka

```bash
# Créer un topic de test
$KAFKA_HOME/bin/kafka-topics.sh --create \
  --bootstrap-server localhost:9092 \
  --replication-factor 1 \
  --partitions 1 \
  --topic test-topic

# Lister les topics
$KAFKA_HOME/bin/kafka-topics.sh --list --bootstrap-server localhost:9092

# Producer de test
$KAFKA_HOME/bin/kafka-console-producer.sh \
  --bootstrap-server localhost:9092 \
  --topic test-topic

# Consumer de test (dans un autre terminal)
$KAFKA_HOME/bin/kafka-console-consumer.sh \
  --bootstrap-server localhost:9092 \
  --topic test-topic \
  --from-beginning
```

---

## 🔗 Intégration Spark + Kafka

### Installation de spark-sql-kafka

Spark 3.5.x inclut déjà `spark-sql-kafka`, mais pour être sûr :

```bash
# Vérifier que le package est disponible
spark-shell --packages org.apache.spark:spark-sql-kafka-0-10_2.12:3.5.1
```

### Exemple d'utilisation

```scala
// Dans spark-shell
import org.apache.spark.sql.functions._
import org.apache.spark.sql.types._

// Lire depuis Kafka
val kafkaDF = spark
  .readStream
  .format("kafka")
  .option("kafka.bootstrap.servers", "localhost:9092")
  .option("subscribe", "test-topic")
  .load()

// Écrire vers Cassandra
kafkaDF
  .selectExpr("CAST(key AS STRING)", "CAST(value AS STRING)")
  .writeStream
  .format("org.apache.spark.sql.cassandra")
  .option("keyspace", "poc_hbase_migration")
  .option("table", "test_table")
  .option("checkpointLocation", "/tmp/checkpoint")
  .start()
```

---

## 📝 Script d'Installation Automatisé

**Le script `scripts/setup/02_install_spark_kafka.sh` est déjà disponible !**

Il détecte automatiquement :

- Le répertoire du projet (`ARKEA_HOME`)
- L'OS (macOS/Linux)
- Les chemins appropriés selon l'OS

**Utilisation** :

```bash
# Charger la configuration
source .poc-profile

# Installer Spark et Kafka
./scripts/setup/02_install_spark_kafka.sh
```

**Pour Linux uniquement (Kafka)** :

```bash
./scripts/setup/02_install_kafka_linux.sh
```

---

### Ancien Script (Référence - Non Recommandé)

Si vous devez créer un script personnalisé :

```bash
#!/bin/bash

set -euo pipefail

# Détecter automatiquement le répertoire
INSTALL_DIR="${ARKEA_HOME:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)}"
cd "$INSTALL_DIR"

echo "=========================================="
echo "Installation Spark + Kafka pour POC"
echo "=========================================="

# 1. Installer Spark via Homebrew
echo "📦 Installation de Spark..."
if ! command -v spark-submit &> /dev/null; then
    brew install apache-spark
else
    echo "✅ Spark déjà installé"
fi

# 2. Installer Kafka via Homebrew
echo "📦 Installation de Kafka..."
if ! command -v kafka-server-start.sh &> /dev/null; then
    brew install kafka
else
    echo "✅ Kafka déjà installé"
fi

# 3. Créer répertoire pour JARs
echo "📁 Création du répertoire spark-jars..."
mkdir -p "$INSTALL_DIR/spark-jars"

# 4. Télécharger spark-cassandra-connector
echo "📥 Téléchargement de spark-cassandra-connector..."
cd "$INSTALL_DIR/spark-jars"
if [ ! -f "spark-cassandra-connector_2.12-3.5.0.jar" ]; then
    curl -O https://repo1.maven.org/maven2/com/datastax/spark/spark-cassandra-connector_2.12/3.5.0/spark-cassandra-connector_2.12-3.5.0.jar
    echo "✅ spark-cassandra-connector téléchargé"
else
    echo "✅ spark-cassandra-connector déjà présent"
fi

# 5. Installer PySpark et dépendances Python
echo "🐍 Installation des dépendances Python..."
pip3 install pyspark cassandra-driver kafka-python --quiet

echo ""
echo "=========================================="
echo "✅ Installation terminée !"
echo "=========================================="
echo ""
echo "Vérifications :"
echo "  - Spark: $(spark-submit --version 2>&1 | head -1)"
echo "  - Kafka: $(brew list kafka 2>/dev/null && echo 'installé' || echo 'non trouvé')"
echo ""
echo "Prochaines étapes :"
echo "  1. Démarrer Kafka: brew services start kafka"
echo "  2. Tester Spark: spark-shell"
echo "  3. Tester la connexion Spark → HCD"
```

---

## ✅ Checklist d'Installation

### Spark

- [ ] Spark installé (Homebrew ou manuel)
- [ ] `SPARK_HOME` configuré
- [ ] `spark-submit --version` fonctionne
- [ ] `spark-shell` démarre

### spark-cassandra-connector

- [ ] JAR téléchargé ou package configuré
- [ ] Configuration Spark mise à jour
- [ ] Test de connexion Spark → HCD réussi

### Kafka

- [ ] Kafka installé (Homebrew ou manuel)
- [ ] Zookeeper démarré
- [ ] Kafka démarré
- [ ] Topic de test créé
- [ ] Producer/Consumer testés

### Intégration

- [ ] Spark peut lire depuis Kafka
- [ ] Spark peut écrire vers HCD
- [ ] Pipeline Spark → Kafka → HCD fonctionnel

---

## 🧪 Tests de Validation

### Test 1 : Spark → HCD

```bash
# Démarrer spark-shell avec le connector
spark-shell --packages com.datastax.spark:spark-cassandra-connector_2.12:3.5.0 \
  --conf spark.cassandra.connection.host=localhost \
  --conf spark.cassandra.connection.port=9042
```

Dans spark-shell :

```scala
import com.datastax.spark.connector._
import org.apache.spark.sql.cassandra._

// Lire depuis HCD
val df = spark.read
  .format("org.apache.spark.sql.cassandra")
  .options(Map("keyspace" -> "system", "table" -> "local"))
  .load()

df.show()
```

### Test 2 : Kafka → Spark → HCD

```scala
// Lire depuis Kafka
val kafkaDF = spark
  .readStream
  .format("kafka")
  .option("kafka.bootstrap.servers", "localhost:9092")
  .option("subscribe", "test-topic")
  .load()

// Transformer et écrire vers HCD
kafkaDF
  .selectExpr("CAST(value AS STRING) as data")
  .writeStream
  .format("org.apache.spark.sql.cassandra")
  .option("keyspace", "poc_hbase_migration")
  .option("table", "kafka_data")
  .option("checkpointLocation", "/tmp/checkpoint")
  .start()
```

---

## 📚 Documentation et Références

- **Spark** : <https://spark.apache.org/docs/latest/>
- **spark-cassandra-connector** : <https://github.com/datastax/spark-cassandra-connector>
- **Kafka** : <https://kafka.apache.org/documentation/>
- **Spark + Kafka** : <https://spark.apache.org/docs/latest/structured-streaming-kafka-integration.html>

---

## 🚀 Prochaines Étapes

1. **Installer les composants** : Exécuter `install_spark_kafka.sh`
2. **Tester les connexions** : Spark → HCD, Kafka → Spark
3. **Créer les schémas** : Domirama/BIC dans HCD
4. **Développer les jobs Spark** : Ingestion, Détection, Exposition

---

**Prêt à installer ?** 🚀
