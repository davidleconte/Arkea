# ⚙️ Configuration de l'Environnement POC

**Date** : 2025-12-02 (Mise à jour pour portabilité cross-platform)  
**Fichiers** : `.poc-profile` et `.poc-config.sh`

---

## 📋 Vue d'Ensemble

Le projet ARKEA utilise un système de configuration en **3 niveaux** pour une portabilité maximale :

1. **Niveau 1** : Variables d'environnement système (priorité maximale)
2. **Niveau 2** : Fichier `.poc-config.sh` (configuration centralisée)
3. **Niveau 3** : Détection automatique (fallback)

Le fichier `.poc-profile` charge automatiquement `.poc-config.sh` qui détecte l'OS et configure tous les chemins.

---

## 🚀 Utilisation

### Charger la Configuration

```bash
# Dans le répertoire du projet (détection automatique)
cd "$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
# Ou définir manuellement
export ARKEA_HOME="/chemin/vers/Arkea"
cd "$ARKEA_HOME"

# Charger la configuration
source .poc-profile
```

### Charger Automatiquement au Démarrage

Ajouter à votre `~/.zshrc`, `~/.bash_profile`, ou `~/.bashrc` :

```bash
# Configuration POC HBase → HCD (Cross-Platform)
# Détection automatique du répertoire ARKEA
if [ -z "${ARKEA_HOME:-}" ]; then
    # Essayer de détecter depuis le répertoire courant
    ARKEA_HOME="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd 2>/dev/null || pwd)"
fi

if [ -f "${ARKEA_HOME}/.poc-profile" ]; then
    source "${ARKEA_HOME}/.poc-profile"
fi
```

**Note** : Sur **Linux** et **Windows (WSL2)**, utilisez `~/.bashrc` au lieu de `~/.zshrc`.

---

## 📦 Variables Configurées

### Répertoires de Base

| Variable | Valeur | Description |
|----------|--------|-------------|
| `ARKEA_HOME` | Détecté automatiquement | Répertoire racine du projet (détection auto) |
| `POC_HOME` | `$ARKEA_HOME` | Alias de `ARKEA_HOME` (compatibilité) |
| `BINAIRE_DIR` | `$ARKEA_HOME/binaire` | Répertoire des binaires installés |
| `SOFTWARE_DIR` | `$ARKEA_HOME/software` | Répertoire des archives logicielles |
| `DATA_DIR` | `$ARKEA_HOME/data` | Répertoire des données |
| `HCD_DATA_DIR` | `$ARKEA_HOME/hcd-data` | Répertoire des données HCD |

### Java

| Variable | Valeur | Description |
|----------|--------|-------------|
| `JAVA_HOME` | Détecté automatiquement | Java 11 pour HCD et Spark (jenv > Homebrew > système) |
| `JAVA11_HOME` | Détecté automatiquement | Java 11 explicite (macOS/Linux) |
| `JAVA17_HOME` | Détecté automatiquement | Java 17 pour Kafka (macOS/Linux) |

**Détection automatique** :
- **macOS** : Homebrew (`/opt/homebrew/opt/openjdk@11` ou `/usr/local/opt/openjdk@11`)
- **Linux** : Système (`/usr/lib/jvm/java-11-openjdk-amd64`)
- **Windows (WSL2)** : Système Linux
- **jenv** : Priorité si disponible (toutes plateformes)

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
| `KAFKA_HOME` | Détecté automatiquement | Répertoire Kafka (macOS: Homebrew, Linux: `/opt/kafka` ou `$ARKEA_HOME/binaire/kafka`) |
| `KAFKA_VERSION` | `4.1.1` | Version Kafka |
| `KAFKA_CONFIG` | Détecté automatiquement | Configuration Kafka (macOS: `.bottle/etc/kafka`, Linux: `config/server.properties`) |
| `KAFKA_LOG_DIR` | Détecté automatiquement | Répertoire de logs (macOS: `libexec/logs`, Linux: `logs`) |
| `KAFKA_BOOTSTRAP_SERVERS` | `localhost:9092` | Serveurs Kafka |
| `KAFKA_ZOOKEEPER_CONNECT` | `localhost:2181` | Zookeeper (Kafka 2.8+ n'utilise plus Zookeeper) |

**Détection automatique** :
- **macOS** : Homebrew (`/opt/homebrew/opt/kafka` ou `/usr/local/opt/kafka`)
- **Linux** : `/opt/kafka`, `/usr/local/kafka`, ou `$ARKEA_HOME/binaire/kafka`
- **Installation** : Utiliser `scripts/setup/02_install_kafka_linux.sh` sur Linux

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

---

## 🌍 Portabilité Cross-Platform

Le système de configuration est **entièrement portable** et supporte :

- ✅ **macOS** 12+ (détection Homebrew)
- ✅ **Linux** (Ubuntu, CentOS, RHEL, Debian, Fedora)
- ✅ **Windows** (via WSL2)

**Fonctionnalités** :
- Détection automatique de l'OS via `$OSTYPE`
- Chemins portables (pas de chemins hardcodés)
- Fonctions utilitaires portables (`check_port`, `kill_process`, `get_realpath`)
- Support multi-OS pour Java, Kafka, HCD, Spark

**Voir** :
- `docs/GUIDE_INSTALLATION_LINUX.md` pour Linux
- `docs/GUIDE_INSTALLATION_WINDOWS.md` pour Windows (WSL2)
- `docs/AUDIT_PORTABILITE_CROSS_PLATFORM_2025.md` pour les détails

---

## 📝 Notes

- Le fichier `.poc-config.sh` détecte automatiquement l'OS et configure tous les chemins
- Les chemins sont relatifs à `ARKEA_HOME` (détecté automatiquement)
- Les variables d'environnement système ont la priorité maximale
- Les fonctions utilitaires facilitent l'utilisation des composants
- Le fichier affiche un résumé lors du chargement (si dans un shell interactif)

---

**Configuration prête à l'emploi et portable !** ✅

