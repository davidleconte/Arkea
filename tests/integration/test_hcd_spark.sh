#!/bin/bash
set -euo pipefail

# =============================================================================
# Test : Intégration HCD ↔ Spark
# =============================================================================
# Date : 2025-12-02
# Description : Tests d'intégration entre HCD et Spark
# Usage : ./tests/integration/test_hcd_spark.sh
# Prérequis : HCD démarré, Spark configuré
# =============================================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ARKEA_HOME="$(cd "$SCRIPT_DIR/../.." && pwd)"

# Charger le framework de tests
source "$ARKEA_HOME/tests/utils/test_framework.sh"

# Charger la configuration
if [ -f "$ARKEA_HOME/.poc-config.sh" ]; then
    source "$ARKEA_HOME/.poc-config.sh"
else
    echo "❌ .poc-config.sh non trouvé"
    exit 1
fi

# =============================================================================
# Tests
# =============================================================================

test_suite_start "Tests d'intégration HCD ↔ Spark"

# Test 1 : HCD est démarré
test_hcd_running() {
    if [ -z "${HCD_HOST:-}" ] || [ -z "${HCD_PORT:-}" ]; then
        echo "⚠️ HCD_HOST ou HCD_PORT non défini, test ignoré"
        return 0
    fi

    assert_port_open "$HCD_PORT" "HCD devrait être démarré sur le port $HCD_PORT"
}

# Test 2 : Spark est configuré
test_spark_configured() {
    if [ -z "${SPARK_HOME:-}" ]; then
        echo "⚠️ SPARK_HOME non défini, test ignoré"
        return 0
    fi

    assert_dir_exists "$SPARK_HOME" "SPARK_HOME devrait exister"
    assert_file_exists "$SPARK_HOME/bin/spark-shell" "spark-shell devrait exister"
}

# Test 3 : Spark Cassandra Connector disponible
test_spark_cassandra_connector() {
    if [ -z "${SPARK_CASSANDRA_CONNECTOR_JAR:-}" ]; then
        echo "⚠️ SPARK_CASSANDRA_CONNECTOR_JAR non défini, test ignoré"
        return 0
    fi

    assert_file_exists "$SPARK_CASSANDRA_CONNECTOR_JAR" "Spark Cassandra Connector JAR devrait exister"
}

# Test 4 : Connexion Spark à HCD (test basique)
test_spark_hcd_connection() {
    if [ -z "${SPARK_HOME:-}" ] || [ -z "${SPARK_CASSANDRA_CONNECTOR_JAR:-}" ]; then
        echo "⚠️ SPARK_HOME ou SPARK_CASSANDRA_CONNECTOR_JAR non défini, test ignoré"
        return 0
    fi

    # Créer un script Scala de test temporaire
    local test_script
    test_script=$(mktemp)
    cat > "$test_script" <<'EOF'
import com.datastax.spark.connector._
import org.apache.spark.sql.SparkSession

val spark = SparkSession.builder()
  .appName("HCD Connection Test")
  .config("spark.cassandra.connection.host", sys.env.getOrElse("HCD_HOST", "localhost"))
  .config("spark.cassandra.connection.port", sys.env.getOrElse("HCD_PORT", "9042"))
  .getOrCreate()

try {
  val keyspaces = spark.sparkContext.cassandraTable("system", "local").collect()
  println(s"✅ Connexion réussie, ${keyspaces.length} ligne(s) trouvée(s)")
  spark.stop()
  System.exit(0)
} catch {
  case e: Exception =>
    println(s"❌ Erreur de connexion: ${e.getMessage}")
    spark.stop()
    System.exit(1)
}
EOF

    # Exécuter le test
    if "$SPARK_HOME/bin/spark-shell" \
        --jars "$SPARK_CASSANDRA_CONNECTOR_JAR" \
        --conf "spark.cassandra.connection.host=${HCD_HOST:-localhost}" \
        --conf "spark.cassandra.connection.port=${HCD_PORT:-9042}" \
        -i "$test_script" > /tmp/spark_test_output.log 2>&1; then
        echo "✅ Connexion Spark ↔ HCD réussie"
        TEST_PASSED=$((TEST_PASSED + 1))
        TEST_TOTAL=$((TEST_TOTAL + 1))
        rm -f "$test_script"
        return 0
    else
        echo "❌ Échec de connexion Spark ↔ HCD"
        echo "   Voir /tmp/spark_test_output.log pour les détails"
        TEST_FAILED=$((TEST_FAILED + 1))
        TEST_TOTAL=$((TEST_TOTAL + 1))
        rm -f "$test_script"
        return 1
    fi
}

# Exécuter les tests
test_hcd_running
test_spark_configured
test_spark_cassandra_connector
test_spark_hcd_connection

# Résumé
test_suite_end

# Code de sortie basé sur les résultats
if [ "$TEST_FAILED" -eq 0 ]; then
    exit 0
else
    exit 1
fi
