#!/bin/bash

# Script de vérification globale de tous les composants
# Vérifie l'installation et l'état de HCD, Spark, Kafka, et leurs configurations

set -e

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m'

info() {
    echo -e "${GREEN}[✓]${NC} $1"
}

warn() {
    echo -e "${YELLOW}[⚠]${NC} $1"
}

error() {
    echo -e "${RED}[✗]${NC} $1"
}

section() {
    echo -e "\n${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${BLUE}$1${NC}"
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}\n"
}

INSTALL_DIR="/Users/david.leconte/Documents/Arkea"
cd "$INSTALL_DIR"

echo "=========================================="
echo "Vérification Globale des Composants"
echo "=========================================="
echo ""

# 1. Vérifier Java
section "1. Java"
if command -v jenv &> /dev/null; then
    eval "$(jenv init -)" 2>/dev/null || true
    cd "$INSTALL_DIR"
    jenv local 11 2>/dev/null || true
    eval "$(jenv init -)"
    JAVA_VERSION=$(java -version 2>&1 | head -1)
    if echo "$JAVA_VERSION" | grep -q "11"; then
        info "Java 11 configuré via jenv: $JAVA_VERSION"
    else
        warn "Java 11 non détecté via jenv. Version: $JAVA_VERSION"
    fi
else
    if [ -d "/opt/homebrew/opt/openjdk@11" ]; then
        export JAVA_HOME=/opt/homebrew/opt/openjdk@11
        JAVA_VERSION=$(java -version 2>&1 | head -1)
        info "Java 11 trouvé via Homebrew: $JAVA_VERSION"
    else
        error "Java 11 non trouvé"
    fi
fi

# 2. Vérifier HCD
section "2. HCD (Hyper-Converged Database)"
HCD_DIR="$INSTALL_DIR/binaire/hcd-1.2.3"
if [ -d "$HCD_DIR" ]; then
    info "HCD installé dans: $HCD_DIR"
    if [ -f "$HCD_DIR/bin/hcd" ]; then
        info "Binaire hcd trouvé"
    else
        error "Binaire hcd non trouvé"
    fi
    
    # Vérifier si HCD est démarré
    if lsof -Pi :9042 -sTCP:LISTEN -t >/dev/null 2>&1; then
        info "HCD est démarré (port 9042)"
    else
        warn "HCD n'est pas démarré (port 9042 non utilisé)"
    fi
else
    error "HCD non installé. Exécutez: ./install_hcd.sh"
fi

# 3. Vérifier Spark
section "3. Spark"
SPARK_DIR="$INSTALL_DIR/binaire/spark-3.5.1"
if [ -d "$SPARK_DIR" ]; then
    info "Spark 3.5.1 installé dans: $SPARK_DIR"
    if [ -f "$SPARK_DIR/bin/spark-shell" ]; then
        info "Binaire spark-shell trouvé"
        export SPARK_HOME="$SPARK_DIR"
        export PATH=$SPARK_HOME/bin:$PATH
        
        # Vérifier la version
        if command -v spark-submit &> /dev/null; then
            SPARK_VERSION=$(spark-submit --version 2>&1 | head -1)
            info "Version: $SPARK_VERSION"
        fi
    else
        error "Binaire spark-shell non trouvé"
    fi
else
    error "Spark 3.5.1 non installé. Exécutez: ./install_spark_kafka.sh"
fi

# 4. Vérifier Kafka
section "4. Kafka"
KAFKA_HOME="/opt/homebrew/opt/kafka"
if [ -d "$KAFKA_HOME" ]; then
    info "Kafka installé dans: $KAFKA_HOME"
    if [ -f "$KAFKA_HOME/libexec/bin/kafka-server-start.sh" ]; then
        info "Binaire kafka-server-start.sh trouvé"
    else
        error "Binaire kafka-server-start.sh non trouvé"
    fi
    
    # Vérifier si Kafka est démarré
    if lsof -Pi :9092 -sTCP:LISTEN -t >/dev/null 2>&1; then
        info "Kafka est démarré (port 9092)"
    else
        warn "Kafka n'est pas démarré (port 9092 non utilisé)"
    fi
else
    error "Kafka non installé. Exécutez: ./install_spark_kafka.sh"
fi

# 5. Vérifier spark-cassandra-connector
section "5. spark-cassandra-connector"
CONNECTOR_JAR="$INSTALL_DIR/binaire/spark-jars/spark-cassandra-connector_2.12-3.5.0.jar"
if [ -f "$CONNECTOR_JAR" ]; then
    info "spark-cassandra-connector trouvé: $CONNECTOR_JAR"
else
    warn "spark-cassandra-connector non trouvé. Il sera téléchargé automatiquement lors du premier usage."
fi

# 6. Vérifier les schémas HCD
section "6. Schémas HCD"
if lsof -Pi :9042 -sTCP:LISTEN -t >/dev/null 2>&1; then
    cd "$HCD_DIR"
    jenv local 11 2>/dev/null || true
    eval "$(jenv init -)" 2>/dev/null || true
    
    # Vérifier le keyspace poc_hbase_migration
    if ./bin/cqlsh localhost 9042 -e "DESCRIBE KEYSPACE poc_hbase_migration;" 2>&1 | grep -q "CREATE KEYSPACE"; then
        info "Keyspace poc_hbase_migration existe"
        
        # Vérifier la table kafka_events
        if ./bin/cqlsh localhost 9042 -e "USE poc_hbase_migration; DESCRIBE TABLE kafka_events;" 2>&1 | grep -q "CREATE TABLE"; then
            info "Table kafka_events existe"
        else
            warn "Table kafka_events n'existe pas. Exécutez: ./setup_kafka_hcd_streaming.sh"
        fi
    else
        warn "Keyspace poc_hbase_migration n'existe pas. Exécutez: ./setup_kafka_hcd_streaming.sh"
    fi
    cd "$INSTALL_DIR"
else
    warn "HCD n'est pas démarré. Impossible de vérifier les schémas."
fi

# 7. Vérifier les scripts
section "7. Scripts Disponibles"
SCRIPTS=(
    "install_hcd.sh"
    "install_spark_kafka.sh"
    "start_hcd.sh"
    "start_kafka.sh"
    "kafka-helper.sh"
    "setup_kafka_hcd_streaming.sh"
    "test_kafka_hcd_streaming.sh"
)

for script in "${SCRIPTS[@]}"; do
    if [ -f "$INSTALL_DIR/$script" ] && [ -x "$INSTALL_DIR/$script" ]; then
        info "$script (exécutable)"
    elif [ -f "$INSTALL_DIR/$script" ]; then
        warn "$script (non exécutable, exécutez: chmod +x $script)"
    else
        error "$script (non trouvé)"
    fi
done

# 8. Vérifier les fichiers de configuration
section "8. Fichiers de Configuration"
if [ -f "$INSTALL_DIR/create_kafka_schema.cql" ]; then
    info "create_kafka_schema.cql trouvé"
else
    warn "create_kafka_schema.cql non trouvé"
fi

if [ -f "$INSTALL_DIR/kafka_to_hcd_streaming.scala" ]; then
    info "kafka_to_hcd_streaming.scala trouvé"
else
    warn "kafka_to_hcd_streaming.scala non trouvé"
fi

# Résumé
echo ""
echo "=========================================="
echo "Résumé"
echo "=========================================="
echo ""
echo "Pour démarrer tous les services :"
echo "  ./start_hcd.sh background"
echo "  ./start_kafka.sh background"
echo ""
echo "Pour configurer le streaming Kafka → HCD :"
echo "  ./setup_kafka_hcd_streaming.sh"
echo ""
echo "Pour tester le pipeline complet :"
echo "  ./test_kafka_hcd_streaming.sh"
echo ""
echo "Pour voir tous les scripts disponibles :"
echo "  ./list_scripts.sh"
echo ""

