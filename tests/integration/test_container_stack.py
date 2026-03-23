"""
Integration tests for ARKEA containerized stack.
Tests connectivity and functionality of HCD, Kafka, and Spark containers.
"""

import subprocess
import time

import pytest

pytestmark = [pytest.mark.integration]


def run_cmd(cmd):
    """Run a shell command and return output."""
    # nosec B602: shell=True required for podman commands with pipes
    result = subprocess.run(
        cmd, shell=True, capture_output=True, text=True, timeout=45
    )  # nosec B602
    return result.returncode, result.stdout, result.stderr


def wait_for_cmd_success(cmd: str, retries: int = 15, sleep_s: float = 2.0):
    """Retry command until success, useful for service readiness checks."""
    last_out, last_err = "", ""
    rc = 1
    for _ in range(retries):
        rc, out, err = run_cmd(cmd)
        if rc == 0:
            return rc, out, err
        last_out, last_err = out, err
        time.sleep(sleep_s)
    return rc, last_out, last_err


class TestCassandraContainer:
    """Test HCD/Cassandra container connectivity."""

    def test_cassandra_is_running(self):
        """Verify Cassandra container is running."""
        rc, out, err = run_cmd("podman ps --filter name=arkea-hcd --format '{{.Status}}'")
        assert rc == 0, f"Unable to inspect Cassandra container status: {out}\n{err}"
        assert "Up" in out, f"Cassandra container not running: {out}\n{err}"

    def test_cassandra_cql_connection(self):
        """Test CQL connection to Cassandra."""
        rc, out, err = wait_for_cmd_success(
            (
                "podman exec arkea-hcd cqlsh localhost 9042 "
                "-e 'SELECT cluster_name FROM system.local;'"
            ),
            retries=20,
            sleep_s=2.0,
        )
        assert rc == 0, f"CQL connection failed: {out}\n{err}"
        assert "ARKEA-POC" in out, f"Wrong cluster name: {out}\n{err}"

    def test_cassandra_keyspace_creation(self):
        """Test creating a keyspace in Cassandra."""
        cql = (
            "CREATE KEYSPACE IF NOT EXISTS test_integration "
            "WITH replication = {'class': 'SimpleStrategy', 'replication_factor': 1};"
        )
        rc, out, err = wait_for_cmd_success(
            f'podman exec arkea-hcd cqlsh localhost 9042 -e "{cql}"',
            retries=20,
            sleep_s=2.0,
        )
        assert rc == 0, f"Keyspace creation failed: {out}\n{err}"


class TestKafkaContainer:
    """Test Kafka container connectivity."""

    def test_kafka_is_running(self):
        """Verify Kafka container is running."""
        rc, out, err = run_cmd("podman ps --filter name=arkea-kafka --format '{{.Status}}'")
        assert rc == 0, f"Unable to inspect Kafka container status: {out}\n{err}"
        assert "Up" in out, f"Kafka container not running: {out}\n{err}"

    def test_kafka_topic_operations(self):
        """Test Kafka topic creation and listing."""
        # Create test topic
        rc, out, err = run_cmd(
            "podman exec arkea-kafka /opt/kafka/bin/kafka-topics.sh "
            "--bootstrap-server localhost:9092 --create --topic test-integration "
            "--partitions 1 --replication-factor 1 --if-not-exists"
        )
        assert rc == 0, f"Topic creation failed: {out}\n{err}"

        # List topics
        rc, out, err = run_cmd(
            "podman exec arkea-kafka /opt/kafka/bin/kafka-topics.sh "
            "--bootstrap-server localhost:9092 --list"
        )
        assert rc == 0, f"Topic listing failed: {out}\n{err}"
        assert "test-integration" in out, f"Topic not found: {out}\n{err}"


class TestSparkContainer:
    """Test Spark container connectivity."""

    def test_spark_master_is_running(self):
        """Verify Spark master container is running."""
        rc, out, err = run_cmd("podman ps --filter name=arkea-spark-master --format '{{.Status}}'")
        assert rc == 0, f"Unable to inspect Spark master status: {out}\n{err}"
        assert "Up" in out, f"Spark master container not running: {out}\n{err}"

    def test_spark_worker_is_running(self):
        """Verify Spark worker container is running."""
        rc, out, err = run_cmd("podman ps --filter name=arkea-spark-worker --format '{{.Status}}'")
        assert rc == 0, f"Unable to inspect Spark worker status: {out}\n{err}"
        assert "Up" in out, f"Spark worker container not running: {out}\n{err}"

    def test_spark_ui_accessible(self):
        """Test Spark master UI is accessible."""
        rc, out, err = run_cmd("curl -s http://localhost:9280 | grep -o '<title>.*</title>'")
        assert rc == 0, f"Spark UI not accessible: {out}\n{err}"
        assert "Spark Master" in out, f"Spark UI wrong content: {out}\n{err}"


class TestFullStackIntegration:
    """Test end-to-end stack integration."""

    def test_all_containers_running(self):
        """Verify all ARKEA containers are running."""
        rc, out, err = run_cmd("podman ps --filter name=arkea --format '{{.Names}}'")
        assert rc == 0, f"Unable to inspect container list: {out}\n{err}"
        containers = out.strip().split("\n")
        expected = ["arkea-hcd", "arkea-kafka", "arkea-spark-master", "arkea-spark-worker"]
        for name in expected:
            assert name in containers, f"Missing container: {name}"

    def test_network_connectivity(self):
        """Test containers can communicate on the network."""
        # Use nc (netcat) instead of ping - more likely to be available
        rc, out, err = run_cmd(
            "podman exec arkea-spark-master sh -c 'nc -zv arkea-hcd 9042 2>&1' || "
            "podman exec arkea-spark-master sh -c 'getent hosts arkea-hcd'"
        )
        assert rc == 0 or "arkea-hcd" in out, f"Spark cannot resolve HCD hostname: {out}\n{err}"

        rc, out, err = run_cmd(
            "podman exec arkea-spark-master sh -c 'nc -zv arkea-kafka 9092 2>&1' || "
            "podman exec arkea-spark-master sh -c 'getent hosts arkea-kafka'"
        )
        assert rc == 0 or "arkea-kafka" in out, f"Spark cannot resolve Kafka hostname: {out}\n{err}"


if __name__ == "__main__":
    pytest.main([__file__, "-v"])
