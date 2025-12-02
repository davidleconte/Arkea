#!/bin/bash
# ============================================
# Configuration POC Domirama2
# ============================================
#
# Ce fichier contient la configuration centralisée pour tous les scripts.
# Il peut être personnalisé selon l'environnement.
#
# UTILISATION :
#   source .poc-config.sh
#   ou
#   Les scripts appellent automatiquement setup_paths() qui charge ce fichier
#
# ============================================

# ============================================
# CHEMINS (Détection automatique si non définis)
# ============================================

# Répertoire racine du projet Arkea
# Si non défini, sera détecté automatiquement par setup_paths()
# ARKEA_HOME="/Users/david.leconte/Documents/Arkea"

# Répertoire HCD
# Si non défini, sera détecté automatiquement : ${ARKEA_HOME}/binaire/hcd-1.2.3
# HCD_DIR="/Users/david.leconte/Documents/Arkea/binaire/hcd-1.2.3"

# Répertoire Spark
# Si non défini, sera détecté automatiquement : ${ARKEA_HOME}/binaire/spark-3.5.1
# SPARK_HOME="/Users/david.leconte/Documents/Arkea/binaire/spark-3.5.1"

# ============================================
# CONFIGURATION HCD
# ============================================

# Host HCD (par défaut: localhost)
HCD_HOST="${HCD_HOST:-localhost}"

# Port HCD (par défaut: 9042)
HCD_PORT="${HCD_PORT:-9042}"

# ============================================
# CONFIGURATION JAVA
# ============================================

# Version Java requise (pour jenv)
JAVA_VERSION="${JAVA_VERSION:-11}"

# ============================================
# CONFIGURATION SPARK
# ============================================

# Spark Cassandra Connector version
SPARK_CASSANDRA_CONNECTOR_VERSION="${SPARK_CASSANDRA_CONNECTOR_VERSION:-3.5.0}"

# ============================================
# CONFIGURATION DATA API
# ============================================

# Data API Endpoint (si Stargate déployé)
DATA_API_ENDPOINT="${DATA_API_ENDPOINT:-http://localhost:8080}"

# Data API Credentials (par défaut pour POC local)
DATA_API_USERNAME="${DATA_API_USERNAME:-cassandra}"
DATA_API_PASSWORD="${DATA_API_PASSWORD:-cassandra}"

# ============================================
# EXPORT DES VARIABLES
# ============================================

export HCD_HOST HCD_PORT JAVA_VERSION
export SPARK_CASSANDRA_CONNECTOR_VERSION
export DATA_API_ENDPOINT DATA_API_USERNAME DATA_API_PASSWORD

