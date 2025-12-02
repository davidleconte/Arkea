# ⚙️ Configuration de l'Environnement POC

**Date** : 2025-11-25  
**Fichier** : `.poc-profile`

---

## 📋 Vue d'Ensemble

Le fichier `.poc-profile` contient toutes les variables d'environnement nécessaires pour le bon fonctionnement du POC.

---

## 🚀 Utilisation

### Charger la Configuration

```bash
# Dans le répertoire du projet
cd /Users/david.leconte/Documents/Arkea
source .poc-profile
```

### Charger Automatiquement au Démarrage

Ajouter à votre `~/.zshrc` ou `~/.bash_profile` :

```bash
# Configuration POC HBase → HCD
if [ -f "/Users/david.leconte/Documents/Arkea/.poc-profile" ]; then
    source /Users/david.leconte/Documents/Arkea/.poc-profile
fi
```

---

## 📦 Variables Configurées

### Répertoires de Base

| Variable | Valeur | Description |
|----------|--------|-------------|
| `POC_HOME` | `/Users/david.leconte/Documents/Arkea` | Répertoire racine du projet |

### Java

| Variable | Valeur | Description |
|----------|--------|-------------|
| `JAVA_HOME` | Défini via jenv ou Homebrew | Java 11 pour HCD et Spark |
| `JAVA11_HOME` | Défini via jenv ou Homebrew | Java 11 explicite |
| `JAVA17_HOME` | `/opt/homebrew/opt/openjdk@17/...` | Java 17 pour Kafka |

### HCD (Hyper-Converged Database)

| Variable | Valeur | Description |
|----------|--------|-------------|
| `HCD_HOME` | `$POC_HOME/binaire/hcd-1.2.3` | Répertoire HCD |
| `HCD_VERSION` | `1.2.3` | Version HCD |
| `CASSANDRA_HOME` | `$HCD_HOME/resources/cassandra` | Répertoire Cassandra |
| `CASSANDRA_HOST` | `localhost` | Host Cassandra |
| `CASSANDRA_PORT` | `9042` | Port Cassandra |
| `CQLSH_HOST` | `localhost` | Host cqlsh |
| `CQLSH_PORT` | `9042` | Port cqlsh |

### Spark

| Variable | Valeur | Description |
|----------|--------|-------------|
| `SPARK_HOME` | `$POC_HOME/binaire/spark-3.5.1` | Répertoire Spark |
| `SPARK_VERSION` | `3.5.1` | Version Spark |
| `SPARK_CONF_DIR` | `$SPARK_HOME/conf` | Répertoire de configuration |
| `SPARK_CASSANDRA_CONNECTOR_VERSION` | `3.5.0` | Version du connector |
| `SPARK_CASSANDRA_CONNECTOR_JAR` | `$POC_HOME/binaire/spark-jars/...` | JAR du connector |
| `SPARK_SQL_KAFKA_VERSION` | `3.5.1` | Version spark-sql-kafka |
| `SPARK_OPTS` | Options Cassandra | Options Spark pour Cassandra |
| `SPARK_PACKAGES` | Packages nécessaires | Packages Spark à charger |

### Kafka

| Variable | Valeur | Description |
|----------|--------|-------------|
| `KAFKA_HOME` | `/opt/homebrew/opt/kafka` | Répertoire Kafka |
| `KAFKA_VERSION` | `4.1.1` | Version Kafka |
| `KAFKA_CONFIG` | `$KAFKA_HOME/.bottle/etc/kafka` | Configuration Kafka |
| `KAFKA_LOG_DIR` | `$KAFKA_HOME/libexec/logs` | Répertoire de logs |
| `KAFKA_BOOTSTRAP_SERVERS` | `localhost:9092` | Serveurs Kafka |
| `KAFKA_ZOOKEEPER_CONNECT` | `localhost:2181` | Zookeeper |

### Python

| Variable | Valeur | Description |
|----------|--------|-------------|
| `PYSPARK_PYTHON` | `python3` | Python pour PySpark |
| `PYSPARK_DRIVER_PYTHON` | `python3` | Python driver PySpark |

### Répertoires de Données

| Variable | Valeur | Description |
|----------|--------|-------------|
| `HCD_DATA_DIR` | `$POC_HOME/hcd-data` | Données HCD |
| `SPARK_CHECKPOINT_DIR` | `/tmp/spark-checkpoints` | Checkpoints Spark |

### Keyspace et Tables

| Variable | Valeur | Description |
|----------|--------|-------------|
| `POC_KEYSPACE` | `poc_hbase_migration` | Keyspace POC |
| `KAFKA_EVENTS_TABLE` | `kafka_events` | Table événements Kafka |

---

## 🛠️ Fonctions Utilitaires

### `check_poc_env`

Vérifie que toutes les variables sont correctement configurées :

```bash
check_poc_env
```

### `start_hcd [background]`

Démarre HCD :

```bash
start_hcd              # Premier plan
start_hcd background   # Arrière-plan
```

### `start_kafka [background]`

Démarre Kafka :

```bash
start_kafka              # Premier plan
start_kafka background   # Arrière-plan
```

### `spark_shell_poc`

Lance Spark Shell avec tous les packages nécessaires :

```bash
spark_shell_poc
```

---

## ✅ Vérification

Après avoir chargé le fichier, vérifiez la configuration :

```bash
source .poc-profile
check_poc_env
```

---

## 📝 Notes

- Le fichier détecte automatiquement Java via `jenv` ou Homebrew
- Les chemins sont relatifs à `POC_HOME`
- Les fonctions utilitaires facilitent l'utilisation des composants
- Le fichier affiche un résumé lors du chargement (si dans un shell interactif)

---

**Configuration prête à l'emploi !** ✅





