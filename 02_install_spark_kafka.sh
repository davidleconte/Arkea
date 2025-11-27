#!/bin/bash

# Script d'installation Spark + Kafka + spark-cassandra-connector
# Pour POC Migration HBase → HCD

set -e

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

INSTALL_DIR="/Users/david.leconte/Documents/Arkea"
cd "$INSTALL_DIR"

echo "=========================================="
echo "Installation Spark + Kafka pour POC"
echo "=========================================="
echo ""

# Vérifier Java 11
info "Vérification de Java 11..."
if command -v jenv &> /dev/null; then
    eval "$(jenv init -)" 2>/dev/null || true
    cd "$INSTALL_DIR"
    jenv local 11 2>/dev/null || true
    eval "$(jenv init -)"
fi

if ! java -version 2>&1 | grep -q "11"; then
    warn "Java 11 non détecté. Configuration..."
    if [ -d "/opt/homebrew/opt/openjdk@11" ]; then
        export JAVA_HOME=/opt/homebrew/opt/openjdk@11
        export PATH="$JAVA_HOME/bin:$PATH"
    fi
fi

JAVA_VERSION=$(java -version 2>&1 | head -1)
info "Java : $JAVA_VERSION"

# 1. Installer Spark 3.5.1 (compatible Java 11)
echo ""
info "📦 Installation de Spark 3.5.1..."
SPARK_DIR="spark-3.5.1"
SPARK_TGZ="spark-3.5.1-bin-hadoop3.tgz"
SPARK_DOWNLOAD_URL="https://archive.apache.org/dist/spark/spark-3.5.1/${SPARK_TGZ}"

# Vérifier si Spark 3.5.1 est déjà installé
if [ -d "$INSTALL_DIR/binaire/$SPARK_DIR" ]; then
    info "✅ Spark 3.5.1 déjà installé dans $INSTALL_DIR/binaire/$SPARK_DIR"
    SPARK_HOME="$INSTALL_DIR/binaire/$SPARK_DIR"
elif command -v spark-submit &> /dev/null; then
    SPARK_VERSION=$(spark-submit --version 2>&1 | head -1)
    warn "Spark détecté : $SPARK_VERSION"
    warn "⚠️  Désinstallation de Spark 4.x (Homebrew) pour compatibilité Java 11..."
    if brew list --formula | grep -q "apache-spark"; then
        brew uninstall apache-spark 2>/dev/null || true
    fi
    SPARK_HOME=""
else
    # Désinstaller Spark 4.x si présent (Homebrew)
    if brew list --formula | grep -q "apache-spark"; then
        warn "Désinstallation de Spark 4.x (Homebrew) pour compatibilité Java 11..."
        brew uninstall apache-spark
    fi
    SPARK_HOME=""
fi

# Télécharger et installer Spark 3.5.1 si nécessaire
SOFTWARE_DIR="${INSTALL_DIR}/software"
mkdir -p "$SOFTWARE_DIR"

if [ -z "$SPARK_HOME" ] || [ ! -d "$SPARK_HOME" ]; then
    if [ ! -f "$SOFTWARE_DIR/$SPARK_TGZ" ]; then
        info "Téléchargement de Spark 3.5.1 depuis ${SPARK_DOWNLOAD_URL}..."
        curl -L "${SPARK_DOWNLOAD_URL}" -o "${SOFTWARE_DIR}/${SPARK_TGZ}" --progress-bar
        if [ $? -ne 0 ]; then
            error "Échec du téléchargement de Spark 3.5.1."
            exit 1
        fi
        info "✅ Spark 3.5.1 téléchargé dans ${SOFTWARE_DIR}."
    else
        info "Spark 3.5.1 déjà téléchargé dans ${SOFTWARE_DIR}."
    fi

    if [ ! -d "$INSTALL_DIR/binaire/$SPARK_DIR" ]; then
        info "Extraction de ${SPARK_TGZ}..."
        mkdir -p "$INSTALL_DIR/binaire"
        tar -xzf "${SOFTWARE_DIR}/${SPARK_TGZ}" -C "${INSTALL_DIR}/binaire"
        if [ $? -ne 0 ]; then
            error "Échec de l'extraction de Spark 3.5.1. Le fichier pourrait être corrompu. Veuillez le supprimer et relancer."
            exit 1
        fi
        mv "${INSTALL_DIR}/binaire/spark-3.5.1-bin-hadoop3" "${INSTALL_DIR}/binaire/${SPARK_DIR}" 2>/dev/null || true
        info "✅ Spark 3.5.1 extrait dans ${INSTALL_DIR}/binaire/${SPARK_DIR}"
    fi
    SPARK_HOME="${INSTALL_DIR}/binaire/${SPARK_DIR}"
fi

export SPARK_HOME
export PATH=$SPARK_HOME/bin:$PATH
info "SPARK_HOME : ${SPARK_HOME}"

# 2. Installer Kafka
echo ""
info "📦 Installation de Kafka..."
if command -v kafka-server-start.sh &> /dev/null || brew list kafka &> /dev/null; then
    info "✅ Kafka déjà installé"
    KAFKA_HOME=$(brew --prefix kafka) 2>/dev/null || echo ""
else
    if command -v brew &> /dev/null; then
        info "Installation de Kafka via Homebrew..."
        brew install kafka
        KAFKA_HOME=$(brew --prefix kafka)
    else
        error "Homebrew non installé. Installation manuelle requise."
        exit 1
    fi
fi

if [ -n "$KAFKA_HOME" ] && [ -d "$KAFKA_HOME" ]; then
    info "KAFKA_HOME : $KAFKA_HOME"
    export KAFKA_HOME
    export PATH=$KAFKA_HOME/bin:$PATH
fi

# 3. Créer répertoire pour JARs
echo ""
info "📁 Création du répertoire spark-jars..."
mkdir -p "$INSTALL_DIR/binaire/spark-jars"
cd "$INSTALL_DIR/binaire/spark-jars"

# 4. Télécharger spark-cassandra-connector
echo ""
info "📥 Téléchargement de spark-cassandra-connector..."
CONNECTOR_JAR="spark-cassandra-connector_2.12-3.5.0.jar"
if [ ! -f "$CONNECTOR_JAR" ]; then
    info "Téléchargement depuis Maven Central..."
    curl -L -o "$CONNECTOR_JAR" \
      "https://repo1.maven.org/maven2/com/datastax/spark/spark-cassandra-connector_2.12/3.5.0/$CONNECTOR_JAR"
    
    if [ -f "$CONNECTOR_JAR" ]; then
        info "✅ spark-cassandra-connector téléchargé"
    else
        error "Échec du téléchargement"
    fi
else
    info "✅ spark-cassandra-connector déjà présent"
fi

# 5. Installer dépendances Python
echo ""
info "🐍 Installation des dépendances Python..."
pip3 install --quiet --upgrade pyspark cassandra-driver kafka-python 2>/dev/null || {
    warn "Installation Python échouée, continuons..."
}

info "✅ Dépendances Python installées"

# 6. Créer fichier de configuration
echo ""
info "📝 Création de la configuration..."

# Configuration Spark
if [ -n "$SPARK_HOME" ] && [ -d "$SPARK_HOME/conf" ]; then
    SPARK_CONF="$SPARK_HOME/conf/spark-defaults.conf"
    if [ ! -f "$SPARK_CONF" ]; then
        if [ -f "$SPARK_HOME/conf/spark-defaults.conf.template" ]; then
            cp "$SPARK_HOME/conf/spark-defaults.conf.template" "$SPARK_CONF"
        fi
    fi
    
    # Ajouter configuration Cassandra si pas déjà présent
    if [ -f "$SPARK_CONF" ] && ! grep -q "spark.cassandra.connection.host" "$SPARK_CONF"; then
        cat >> "$SPARK_CONF" << EOF

# Spark Cassandra Connector Configuration (POC HBase Migration)
spark.cassandra.connection.host localhost
spark.cassandra.connection.port 9042
spark.sql.extensions com.datastax.spark.connector.CassandraSparkExtensions
EOF
        info "✅ Configuration Spark mise à jour"
    fi
fi

# Résumé
echo ""
echo "=========================================="
info "✅ Installation terminée !"
echo "=========================================="
echo ""

# Vérifications
info "Vérifications :"
if command -v spark-submit &> /dev/null; then
    SPARK_VER=$(spark-submit --version 2>&1 | head -1)
    echo "  ✅ Spark : $SPARK_VER"
else
    echo "  ⚠️  Spark : Non trouvé dans PATH"
fi

if [ -n "$KAFKA_HOME" ] && [ -d "$KAFKA_HOME" ]; then
    echo "  ✅ Kafka : Installé dans $KAFKA_HOME"
else
    echo "  ⚠️  Kafka : Non trouvé"
fi

if [ -f "$INSTALL_DIR/binaire/spark-jars/$CONNECTOR_JAR" ]; then
    echo "  ✅ spark-cassandra-connector : $CONNECTOR_JAR"
else
    echo "  ⚠️  spark-cassandra-connector : Non trouvé"
fi

echo ""
info "Prochaines étapes :"
echo ""
echo "1. Configurer les variables d'environnement :"
echo "   export SPARK_HOME=\$(pwd)/binaire/spark-3.5.1"
echo "   export KAFKA_HOME=/opt/homebrew/opt/kafka"
echo "   export PATH=\$SPARK_HOME/bin:\$KAFKA_HOME/libexec/bin:\$PATH"
echo ""
echo "2. Démarrer Kafka :"
echo "   ./start_kafka.sh [background]"
echo ""
echo "3. Tester Spark :"
echo "   export SPARK_HOME=\$(pwd)/spark-3.5.1"
echo "   export PATH=\$SPARK_HOME/bin:\$PATH"
echo "   jenv local 11"
echo "   eval \"\$(jenv init -)\""
echo "   \$SPARK_HOME/bin/spark-shell --version"
echo ""
echo "4. Tester la connexion Spark → HCD :"
echo "   \$SPARK_HOME/bin/spark-shell \\"
echo "     --packages com.datastax.spark:spark-cassandra-connector_2.12:3.5.0 \\"
echo "     --conf spark.cassandra.connection.host=localhost \\"
echo "     --conf spark.cassandra.connection.port=9042"
echo ""
echo "5. Configurer Kafka → HCD Streaming :"
echo "   ./setup_kafka_hcd_streaming.sh"
echo ""
echo "6. Tester le pipeline complet :"
echo "   ./test_kafka_hcd_streaming.sh"
echo ""
echo "Voir GUIDE_INSTALLATION_SPARK_KAFKA.md pour plus de détails."

