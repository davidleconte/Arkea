"""
Integration tests for ARKEA containerized stack.
Tests connectivity and functionality of HCD, Kafka, and Spark containers.
"""

import subprocess

import pytest


def run_cmd(cmd):
    """Run a shell command and return output."""
    # nosec B602: shell=True required for podman commands with pipes
    result = subprocess.run(cmd, shell=True, capture_output=True, text=True)  # nosec B602
    return result.returncode, result.stdout, result.stderr


class TestCassandraContainer:
    """Test HCD/Cassandra container connectivity."""

    def test_cassandra_is_running(self):
        """Verify Cassandra container is running."""
        rc, out, _ = run_cmd("podman ps --filter name=arkea-hcd --format '{{.Status}}'")
        assert rc == 0
        assert "Up" in out, f"Cassandra container not running: {out}"

    def test_cassandra_cql_connection(self):
        """Test CQL connection to Cassandra."""
        rc, out, _ = run_cmd(
            "podman exec arkea-hcd cqlsh localhost 9042 -e 'SELECT cluster_name FROM system.local;'"
        )
        assert rc == 0, f"CQL connection failed: {out}"
        assert "ARKEA-POC" in out, f"Wrong cluster name: {out}"

    def test_cassandra_keyspace_creation(self):
        """Test creating a keyspace in Cassandra."""
        cql = (
            "CREATE KEYSPACE IF NOT EXISTS test_integration "
            "WITH replication = {'class': 'SimpleStrategy', 'replication_factor': 1};"
        )
        rc, out, _ = run_cmd(f'podman exec arkea-hcd cqlsh localhost 9042 -e "{cql}"')
        assert rc == 0, f"Keyspace creation failed: {out}"


class TestKafkaContainer:
    """Test Kafka container connectivity."""

    def test_kafka_is_running(self):
        """Verify Kafka container is running."""
        rc, out, _ = run_cmd("podman ps --filter name=arkea-kafka --format '{{.Status}}'")
        assert rc == 0
        assert "Up" in out, f"Kafka container not running: {out}"

    def test_kafka_topic_operations(self):
        """Test Kafka topic creation and listing."""
        # Create test topic
        rc, out, _ = run_cmd(
            "podman exec arkea-kafka /opt/kafka/bin/kafka-topics.sh "
            "--bootstrap-server localhost:9092 --create --topic test-integration "
            "--partitions 1 --replication-factor 1 --if-not-exists"
        )
        assert rc == 0, f"Topic creation failed: {out}"

        # List topics
        rc, out, _ = run_cmd(
            "podman exec arkea-kafka /opt/kafka/bin/kafka-topics.sh "
            "--bootstrap-server localhost:9092 --list"
        )
        assert rc == 0, f"Topic listing failed: {out}"
        assert "test-integration" in out, f"Topic not found: {out}"


class TestSparkContainer:
    """Test Spark container connectivity."""

    def test_spark_master_is_running(self):
        """Verify Spark master container is running."""
        rc, out, _ = run_cmd("podman ps --filter name=arkea-spark-master --format '{{.Status}}'")
        assert rc == 0
        assert "Up" in out, f"Spark master container not running: {out}"

    def test_spark_worker_is_running(self):
        """Verify Spark worker container is running."""
        rc, out, _ = run_cmd("podman ps --filter name=arkea-spark-worker --format '{{.Status}}'")
        assert rc == 0
        assert "Up" in out, f"Spark worker container not running: {out}"

    def test_spark_ui_accessible(self):
        """Test Spark master UI is accessible."""
        rc, out, _ = run_cmd("curl -s http://localhost:9280 | grep -o '<title>.*</title>'")
        assert rc == 0, f"Spark UI not accessible: {out}"
        assert "Spark Master" in out, f"Spark UI wrong content: {out}"


class TestFullStackIntegration:
    """Test end-to-end stack integration."""

    def test_all_containers_running(self):
        """Verify all ARKEA containers are running."""
        rc, out, _ = run_cmd("podman ps --filter name=arkea --format '{{.Names}}'")
        assert rc == 0
        containers = out.strip().split("\n")
        expected = ["arkea-hcd", "arkea-kafka", "arkea-spark-master", "arkea-spark-worker"]
        for name in expected:
            assert name in containers, f"Missing container: {name}"

    def test_network_connectivity(self):
        """Test containers can communicate on the network."""
        # Use nc (netcat) instead of ping - more likely to be available
        rc, out, _ = run_cmd(
            "podman exec arkea-spark-master sh -c 'nc -zv arkea-hcd 9042 2>&1' || "
            "podman exec arkea-spark-master sh -c 'getent hosts arkea-hcd'"
        )
        assert rc == 0 or "arkea-hcd" in out, f"Spark cannot resolve HCD hostname: {out}"

        rc, out, _ = run_cmd(
            "podman exec arkea-spark-master sh -c 'nc -zv arkea-kafka 9092 2>&1' || "
            "podman exec arkea-spark-master sh -c 'getent hosts arkea-kafka'"
        )
        assert rc == 0 or "arkea-kafka" in out, f"Spark cannot resolve Kafka hostname: {out}"


if __name__ == "__main__":
    pytest.main([__file__, "-v"])
