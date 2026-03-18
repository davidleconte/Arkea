# =============================================================================
# ARKEA POC - Pytest Configuration and Fixtures
# =============================================================================
# Date : 2025-03-13
# Version : 1.0.0
# Author : David LECONTE (IBM WW|Tiger Team - Watsonx.Data GPS)
# Description : Centralized pytest fixtures for test isolation
# =============================================================================

import os
from pathlib import Path

import pytest

# Project root directory
PROJECT_ROOT = Path(__file__).parent.parent.resolve()


# =============================================================================
# Configuration
# =============================================================================


def pytest_configure(config):
    """Configure pytest with custom markers."""
    config.addinivalue_line("markers", "unit: Unit tests (no external dependencies)")
    config.addinivalue_line("markers", "integration: Integration tests (require HCD/Kafka)")
    config.addinivalue_line("markers", "e2e: End-to-end tests (full pipeline)")
    config.addinivalue_line("markers", "slow: Slow tests (skip with -m 'not slow')")


# =============================================================================
# Fixtures - Paths
# =============================================================================


@pytest.fixture
def project_root():
    """Return project root directory."""
    return PROJECT_ROOT


@pytest.fixture
def poc_config_path(project_root):
    """Return path to .poc-config.sh."""
    return project_root / ".poc-config.sh"


@pytest.fixture
def test_data_dir(project_root):
    """Return test data directory."""
    return project_root / "tests" / "fixtures" / "data"


@pytest.fixture
def schemas_dir(project_root):
    """Return schemas directory."""
    return project_root / "schemas"


# =============================================================================
# Fixtures - Environment
# =============================================================================


@pytest.fixture
def hcd_host():
    """Return HCD host from environment."""
    return os.environ.get("HCD_HOST", "localhost")


@pytest.fixture
def hcd_port():
    """Return HCD port from environment."""
    return int(os.environ.get("HCD_PORT", "9102"))


@pytest.fixture
def kafka_host():
    """Return Kafka host from environment."""
    return os.environ.get("KAFKA_HOST", "localhost")


@pytest.fixture
def kafka_port():
    """Return Kafka port from environment."""
    return int(os.environ.get("KAFKA_PORT", "9192"))


# =============================================================================
# Fixtures - POC Directories
# =============================================================================


@pytest.fixture
def bic_dir(project_root):
    """Return BIC POC directory."""
    return project_root / "poc-design" / "bic"


@pytest.fixture
def domirama2_dir(project_root):
    """Return Domirama2 POC directory."""
    return project_root / "poc-design" / "domirama2"


@pytest.fixture
def domiramaCatOps_dir(project_root):
    """Return DomiramaCatOps POC directory."""
    return project_root / "poc-design" / "domiramaCatOps"


# =============================================================================
# Fixtures - Test Isolation
# =============================================================================


@pytest.fixture
def isolated_env(tmp_path, monkeypatch):
    """
    Provide isolated environment for tests.
    Creates temporary directories and sets environment variables.
    """
    leg = os.environ.get("ARKEA_LEG", "podman")
    hcd_port = "9102" if leg == "podman" else "9042"
    kafka_port = "9192" if leg == "podman" else "9092"

    env_vars = {
        "ARKEA_HOME": str(tmp_path),
        "ARKEA_LEG": leg,
        "HCD_HOST": "localhost",
        "HCD_PORT": hcd_port,
        "KAFKA_HOST": "localhost",
        "KAFKA_PORT": kafka_port,
        "LOG_DIR": str(tmp_path / "logs"),
        "BINAIRE_DIR": str(tmp_path / "binaire"),
        "SOFTWARE_DIR": str(tmp_path / "software"),
    }

    for key, value in env_vars.items():
        monkeypatch.setenv(key, value)

    # Create directories
    for key in ["LOG_DIR", "BINAIRE_DIR", "SOFTWARE_DIR"]:
        Path(env_vars[key]).mkdir(parents=True, exist_ok=True)

    return env_vars


@pytest.fixture
def mock_hcd_connection(monkeypatch):
    """Mock HCD connection for tests that don't need real HCD."""
    # This can be extended to mock cassandra-driver


# =============================================================================
# Utility Functions
# =============================================================================


def skip_if_no_hcd():
    """Skip test if HCD is not available."""
    import socket

    leg = os.environ.get("ARKEA_LEG", "podman")
    port = int(os.environ.get("HCD_PORT", "9102" if leg == "podman" else "9042"))

    try:
        sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
        sock.settimeout(2)
        result = sock.connect_ex(("localhost", port))
        sock.close()
        if result != 0:
            pytest.skip(f"HCD not available on localhost:{port}")
    except Exception as e:
        pytest.skip(f"HCD connection check failed: {e}")


def skip_if_no_kafka():
    """Skip test if Kafka is not available."""
    import socket

    leg = os.environ.get("ARKEA_LEG", "podman")
    port = int(os.environ.get("KAFKA_PORT", "9192" if leg == "podman" else "9092"))

    try:
        sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
        sock.settimeout(2)
        result = sock.connect_ex(("localhost", port))
        sock.close()
        if result != 0:
            pytest.skip(f"Kafka not available on localhost:{port}")
    except Exception as e:
        pytest.skip(f"Kafka connection check failed: {e}")
