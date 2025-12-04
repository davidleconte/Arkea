#!/bin/bash
# =============================================================================
# Configuration Centralisée POC HBase → HCD
# =============================================================================
# Date : 2025-12-01
# Usage : Source automatique par setup_paths() ou manuellement
# Priorité : Variables d'environnement > Ce fichier > Détection automatique
# =============================================================================

# Détecter la racine du projet (ARKEA_HOME)
# Priorité 1: Variable d'environnement ARKEA_HOME
# Priorité 2: Détection automatique (répertoire parent de ce fichier)
if [ -z "${ARKEA_HOME:-}" ]; then
    # Ce fichier est à la racine, donc ARKEA_HOME = répertoire de ce fichier
    ARKEA_HOME="$(cd "$(dirname "${BASH_SOURCE[0]:-${0}}")" && pwd)"
    export ARKEA_HOME
fi

# =============================================================================
# Chemins de Base (Relatifs à ARKEA_HOME)
# =============================================================================

# Répertoires principaux
export POC_HOME="${ARKEA_HOME}"
export BINAIRE_DIR="${BINAIRE_DIR:-${ARKEA_HOME}/binaire}"
export SOFTWARE_DIR="${SOFTWARE_DIR:-${ARKEA_HOME}/software}"
export DATA_DIR="${DATA_DIR:-${ARKEA_HOME}/data}"
export HCD_DATA_DIR="${HCD_DATA_DIR:-${ARKEA_HOME}/hcd-data}"

# =============================================================================
# HCD Configuration
# =============================================================================

# HCD Home (priorité: env > détection auto)
if [ -z "${HCD_DIR:-}" ] && [ -z "${HCD_HOME:-}" ]; then
    # Détection automatique
    if [ -d "${BINAIRE_DIR}/hcd-1.2.3" ]; then
        export HCD_DIR="${BINAIRE_DIR}/hcd-1.2.3"
    elif [ -d "${ARKEA_HOME}/binaire/hcd-1.2.3" ]; then
        export HCD_DIR="${ARKEA_HOME}/binaire/hcd-1.2.3"
    fi
else
    export HCD_DIR="${HCD_DIR:-${HCD_HOME}}"
fi

export HCD_VERSION="${HCD_VERSION:-1.2.3}"
export CASSANDRA_HOME="${CASSANDRA_HOME:-${HCD_DIR}/resources/cassandra}"

# HCD Connection (priorité: env > défaut)
export HCD_HOST="${HCD_HOST:-localhost}"
export HCD_PORT="${HCD_PORT:-9042}"
export CASSANDRA_HOST="${CASSANDRA_HOST:-${HCD_HOST}}"
export CASSANDRA_PORT="${CASSANDRA_PORT:-${HCD_PORT}}"
export CQLSH_HOST="${CQLSH_HOST:-${HCD_HOST}}"
export CQLSH_PORT="${CQLSH_PORT:-${HCD_PORT}}"

# =============================================================================
# Spark Configuration
# =============================================================================

# Spark Home (priorité: env > détection auto)
if [ -z "${SPARK_HOME:-}" ]; then
    if [ -d "${BINAIRE_DIR}/spark-3.5.1" ]; then
        export SPARK_HOME="${BINAIRE_DIR}/spark-3.5.1"
    elif [ -d "${ARKEA_HOME}/binaire/spark-3.5.1" ]; then
        export SPARK_HOME="${ARKEA_HOME}/binaire/spark-3.5.1"
    fi
fi

export SPARK_VERSION="${SPARK_VERSION:-3.5.1}"
export SPARK_CONF_DIR="${SPARK_CONF_DIR:-${SPARK_HOME}/conf}"
export SPARK_CHECKPOINT_DIR="${SPARK_CHECKPOINT_DIR:-/tmp/spark-checkpoints}"

# Spark Cassandra Connector
export SPARK_CASSANDRA_CONNECTOR_VERSION="${SPARK_CASSANDRA_CONNECTOR_VERSION:-3.5.0}"
export SPARK_CASSANDRA_CONNECTOR_JAR="${SPARK_CASSANDRA_CONNECTOR_JAR:-${ARKEA_HOME}/binaire/spark-jars/spark-cassandra-connector_2.12-${SPARK_CASSANDRA_CONNECTOR_VERSION}.jar}"

# =============================================================================
# Kafka Configuration (Détection Auto Multi-OS)
# =============================================================================

# Kafka Home (priorité: env > détection auto)
if [ -z "${KAFKA_HOME:-}" ]; then
    # Détection automatique selon OS
    if [[ "$OSTYPE" == "darwin"* ]]; then
        # macOS (Homebrew)
        if [ -d "/opt/homebrew/opt/kafka" ]; then
            export KAFKA_HOME="/opt/homebrew/opt/kafka"
        elif [ -d "/usr/local/opt/kafka" ]; then
            export KAFKA_HOME="/usr/local/opt/kafka"
        fi
    elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
        # Linux (détection standard)
        if [ -d "/opt/kafka" ]; then
            export KAFKA_HOME="/opt/kafka"
        elif [ -d "/usr/local/kafka" ]; then
            export KAFKA_HOME="/usr/local/kafka"
        fi
    fi
fi

export KAFKA_VERSION="${KAFKA_VERSION:-4.1.1}"
export KAFKA_BOOTSTRAP_SERVERS="${KAFKA_BOOTSTRAP_SERVERS:-${KAFKA_BOOTSTRAP_SERVERS:-localhost:9092}}"
export KAFKA_ZOOKEEPER_CONNECT="${KAFKA_ZOOKEEPER_CONNECT:-${KAFKA_ZOOKEEPER_CONNECT:-localhost:2181}}"

# Zookeeper (détection auto)
if [ -z "${ZOOKEEPER_HOME:-}" ]; then
    if [[ "$OSTYPE" == "darwin"* ]]; then
        if [ -d "/opt/homebrew/opt/zookeeper" ]; then
            export ZOOKEEPER_HOME="/opt/homebrew/opt/zookeeper"
        elif [ -d "/usr/local/opt/zookeeper" ]; then
            export ZOOKEEPER_HOME="/usr/local/opt/zookeeper"
        fi
    elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
        if [ -d "/opt/zookeeper" ]; then
            export ZOOKEEPER_HOME="/opt/zookeeper"
        fi
    fi
fi

# =============================================================================
# Java Configuration (Détection Auto Multi-OS)
# =============================================================================

# Java 11 (priorité: jenv > Homebrew > système)
if [ -z "${JAVA_HOME:-}" ]; then
    # Essayer jenv d'abord
    if command -v jenv &> /dev/null; then
        eval "$(jenv init -)" 2>/dev/null || true
        if jenv versions | grep -q "11"; then
            export JAVA_HOME=$(jenv prefix 11 2>/dev/null || echo "")
            export JAVA11_HOME="$JAVA_HOME"
        fi
    fi

    # Fallback Homebrew (macOS)
    if [ -z "$JAVA_HOME" ] && [[ "$OSTYPE" == "darwin"* ]]; then
        if [ -d "/opt/homebrew/opt/openjdk@11/libexec/openjdk.jdk/Contents/Home" ]; then
            export JAVA_HOME="/opt/homebrew/opt/openjdk@11/libexec/openjdk.jdk/Contents/Home"
        elif [ -d "/opt/homebrew/opt/openjdk@11" ]; then
            export JAVA_HOME="/opt/homebrew/opt/openjdk@11"
        elif [ -d "/usr/local/opt/openjdk@11/libexec/openjdk.jdk/Contents/Home" ]; then
            export JAVA_HOME="/usr/local/opt/openjdk@11/libexec/openjdk.jdk/Contents/Home"
        fi
        export JAVA11_HOME="$JAVA_HOME"
    fi

    # Fallback système
    if [ -z "$JAVA_HOME" ] && command -v java &> /dev/null; then
        # Fonction portable pour obtenir le chemin réel
        local java_path=$(which java)
        if [[ "$OSTYPE" == "darwin"* ]]; then
            # macOS (BSD) - utiliser Python ou fallback
            if command -v python3 &> /dev/null; then
                java_path=$(python3 -c "import os; print(os.path.realpath('$java_path'))" 2>/dev/null || echo "$java_path")
            fi
        else
            # Linux (GNU) - utiliser readlink -f
            java_path=$(readlink -f "$java_path" 2>/dev/null || echo "$java_path")
        fi
        export JAVA_HOME=$(dirname $(dirname "$java_path"))
    fi
fi

# Java 17 (pour Kafka, optionnel)
if [ -z "${JAVA17_HOME:-}" ]; then
    if [[ "$OSTYPE" == "darwin"* ]]; then
        if [ -d "/opt/homebrew/opt/openjdk@17/libexec/openjdk.jdk/Contents/Home" ]; then
            export JAVA17_HOME="/opt/homebrew/opt/openjdk@17/libexec/openjdk.jdk/Contents/Home"
        elif [ -d "/opt/homebrew/opt/openjdk@17" ]; then
            export JAVA17_HOME="/opt/homebrew/opt/openjdk@17"
        fi
    fi
fi

# =============================================================================
# Python Configuration
# =============================================================================

# Python pour cqlsh et PySpark
if command -v python3.11 &> /dev/null; then
    export CQLSH_PYTHON=$(which python3.11)
    export PYSPARK_PYTHON=$(which python3.11)
    export PYSPARK_DRIVER_PYTHON=$(which python3.11)
elif command -v python3 &> /dev/null; then
    export PYSPARK_PYTHON=$(which python3)
    export PYSPARK_DRIVER_PYTHON=$(which python3)
fi

# =============================================================================
# PATH Configuration
# =============================================================================

# Ajouter les binaires au PATH (si disponibles)
[ -n "${SPARK_HOME:-}" ] && [ -d "${SPARK_HOME}/bin" ] && export PATH="${SPARK_HOME}/bin:${PATH}"
[ -n "${HCD_DIR:-}" ] && [ -d "${HCD_DIR}/bin" ] && export PATH="${HCD_DIR}/bin:${PATH}"
[ -n "${KAFKA_HOME:-}" ] && [ -d "${KAFKA_HOME}/libexec/bin" ] && export PATH="${KAFKA_HOME}/libexec/bin:${PATH}"
[ -n "${JAVA_HOME:-}" ] && [ -d "${JAVA_HOME}/bin" ] && export PATH="${JAVA_HOME}/bin:${PATH}"

# =============================================================================
# Data API Configuration
# =============================================================================

export DATA_API_ENDPOINT="${DATA_API_ENDPOINT:-http://localhost:8080}"
export DATA_API_USERNAME="${DATA_API_USERNAME:-cassandra}"
export DATA_API_PASSWORD="${DATA_API_PASSWORD:-cassandra}"
export DATA_API_TOKEN="${DATA_API_TOKEN:-Cassandra:Y2Fzc2FuZHJh:Y2Fzc2FuZHJh}"

# =============================================================================
# Hugging Face Configuration
# =============================================================================

export HF_API_KEY="${HF_API_KEY:-}"

# =============================================================================
# Keyspace et Tables HCD
# =============================================================================

export POC_KEYSPACE="${POC_KEYSPACE:-poc_hbase_migration}"
export KAFKA_EVENTS_TABLE="${KAFKA_EVENTS_TABLE:-kafka_events}"

# =============================================================================
# Spark Configuration Options
# =============================================================================

export SPARK_SQL_KAFKA_VERSION="${SPARK_SQL_KAFKA_VERSION:-3.5.1}"
export SPARK_OPTS="${SPARK_OPTS:---conf spark.cassandra.connection.host=${HCD_HOST} --conf spark.cassandra.connection.port=${HCD_PORT} --conf spark.sql.extensions=com.datastax.spark.connector.CassandraSparkExtensions}"
export SPARK_PACKAGES="${SPARK_PACKAGES:-org.apache.spark:spark-sql-kafka-0-10_2.12:${SPARK_SQL_KAFKA_VERSION},com.datastax.spark:spark-cassandra-connector_2.12:${SPARK_CASSANDRA_CONNECTOR_VERSION}}"
