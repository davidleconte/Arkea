#!/bin/bash

# Script d'installation Kafka pour Linux
# Pour POC Migration HBase → HCD

set -euo pipefail

# Charger la configuration centralisée
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ARKEA_HOME="${ARKEA_HOME:-$(cd "$SCRIPT_DIR/../.." && pwd)}"
if [ -f "${ARKEA_HOME}/.poc-config.sh" ]; then
    # shellcheck source=/dev/null
    source "${ARKEA_HOME}/.poc-config.sh"
fi

# Variables
INSTALL_DIR="${ARKEA_HOME:-${INSTALL_DIR:-$(cd "$SCRIPT_DIR/../.." && pwd)}}"
export ARKEA_HOME="$INSTALL_DIR"
KAFKA_VERSION="${KAFKA_VERSION:-4.1.1}"
SCALA_VERSION="2.13"
KAFKA_TGZ="kafka_${SCALA_VERSION}-${KAFKA_VERSION}.tgz"
KAFKA_DIR="kafka_${SCALA_VERSION}-${KAFKA_VERSION}"
KAFKA_DOWNLOAD_URL="https://archive.apache.org/dist/kafka/${KAFKA_VERSION}/${KAFKA_TGZ}"
SOFTWARE_DIR="${SOFTWARE_DIR:-${INSTALL_DIR}/software}"
BINAIRE_DIR="${BINAIRE_DIR:-${INSTALL_DIR}/binaire}"

# Couleurs
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

echo "=========================================="
echo "Installation Kafka ${KAFKA_VERSION} pour Linux"
echo "=========================================="
echo ""

# Vérifier Java 17
info "Vérification de Java 17..."
if [ -z "${JAVA17_HOME:-}" ] && [ -z "${JAVA_HOME:-}" ]; then
    if command -v java &> /dev/null; then
        JAVA_VERSION=$(java -version 2>&1 | head -1 | grep -oE 'version "([0-9]+)' | grep -oE '[0-9]+')
        if [ "$JAVA_VERSION" -lt 17 ]; then
            error "Java 17+ requis. Version actuelle : Java $JAVA_VERSION"
            error "Installez Java 17 avec : sudo apt-get install openjdk-17-jdk"
            exit 1
        fi
        info "Java $JAVA_VERSION détecté"
    else
        error "Java non installé. Installez Java 17 avec : sudo apt-get install openjdk-17-jdk"
        exit 1
    fi
fi

# Créer répertoires si nécessaire
mkdir -p "$SOFTWARE_DIR"
mkdir -p "$BINAIRE_DIR"

# Télécharger Kafka si nécessaire
if [ ! -f "${SOFTWARE_DIR}/${KAFKA_TGZ}" ]; then
    info "Téléchargement de Kafka ${KAFKA_VERSION} depuis ${KAFKA_DOWNLOAD_URL}..."
    curl -L "${KAFKA_DOWNLOAD_URL}" -o "${SOFTWARE_DIR}/${KAFKA_TGZ}" --progress-bar
    if [ $? -ne 0 ]; then
        error "Échec du téléchargement de Kafka ${KAFKA_VERSION}."
        exit 1
    fi
    info "✅ Kafka ${KAFKA_VERSION} téléchargé dans ${SOFTWARE_DIR}."
else
    info "Kafka ${KAFKA_VERSION} déjà téléchargé dans ${SOFTWARE_DIR}."
fi

# Extraire Kafka
if [ ! -d "${BINAIRE_DIR}/kafka" ]; then
    info "Extraction de ${KAFKA_TGZ}..."
    tar -xzf "${SOFTWARE_DIR}/${KAFKA_TGZ}" -C "${BINAIRE_DIR}"
    if [ $? -ne 0 ]; then
        error "Échec de l'extraction de Kafka ${KAFKA_VERSION}."
        exit 1
    fi
    mv "${BINAIRE_DIR}/${KAFKA_DIR}" "${BINAIRE_DIR}/kafka"
    info "✅ Kafka ${KAFKA_VERSION} extrait dans ${BINAIRE_DIR}/kafka"
else
    info "✅ Kafka déjà installé dans ${BINAIRE_DIR}/kafka"
fi

export KAFKA_HOME="${BINAIRE_DIR}/kafka"
export PATH="${KAFKA_HOME}/bin:${PATH}"

# Créer répertoire de logs
mkdir -p "${KAFKA_HOME}/logs"

# Configuration Kafka (optionnel - utiliser les valeurs par défaut)
info "Configuration Kafka..."
KAFKA_CONFIG="${KAFKA_HOME}/config/server.properties"
if [ -f "$KAFKA_CONFIG" ]; then
    # Backup de la configuration originale
    if [ ! -f "${KAFKA_CONFIG}.backup" ]; then
        cp "$KAFKA_CONFIG" "${KAFKA_CONFIG}.backup"
        info "Backup de la configuration créé : ${KAFKA_CONFIG}.backup"
    fi
    info "Configuration par défaut conservée. Vous pouvez modifier ${KAFKA_CONFIG} si nécessaire."
fi

# Résumé
echo ""
echo "=========================================="
info "✅ Installation terminée !"
echo "=========================================="
echo ""
echo "Répertoires créés :"
echo "  - Kafka : ${KAFKA_HOME}"
echo "  - Logs : ${KAFKA_HOME}/logs"
echo ""
echo "Variables d'environnement :"
echo "  export KAFKA_HOME=${KAFKA_HOME}"
echo "  export PATH=\${KAFKA_HOME}/bin:\$PATH"
echo ""
echo "Pour démarrer Kafka :"
echo "  ${KAFKA_HOME}/bin/kafka-server-start.sh ${KAFKA_CONFIG}"
echo ""
echo "Pour démarrer en arrière-plan :"
echo "  nohup ${KAFKA_HOME}/bin/kafka-server-start.sh ${KAFKA_CONFIG} > ${KAFKA_HOME}/logs/kafka.log 2>&1 &"
echo ""
info "Voir GUIDE_INSTALLATION_LINUX.md pour plus de détails."

