"""
Runtime policy integration tests for ARKEA active leg behavior.
"""

import os
import socket
import subprocess
import time

import pytest

pytestmark = [pytest.mark.integration, pytest.mark.runtime_policy]


def run_cmd(cmd: str):
    """Run a shell command and return (rc, stdout, stderr)."""
    # nosec B602: shell=True required for Make/bash composition
    result = subprocess.run(
        cmd, shell=True, capture_output=True, text=True, timeout=45
    )  # nosec B602
    return result.returncode, result.stdout, result.stderr


def is_port_open(host: str, port: int, timeout: float = 1.5) -> bool:
    """Check if a TCP port is reachable."""
    with socket.socket(socket.AF_INET, socket.SOCK_STREAM) as sock:
        sock.settimeout(timeout)
        return sock.connect_ex((host, port)) == 0


def wait_for_ports(host: str, ports: list[int], retries: int = 15, delay_s: float = 2.0) -> bool:
    """Wait until all required ports are reachable."""
    for _ in range(retries):
        if all(is_port_open(host, port) for port in ports):
            return True
        time.sleep(delay_s)
    return all(is_port_open(host, port) for port in ports)


def test_binary_leg_blocked_by_default():
    """Binary leg must be blocked unless ARKEA_ENABLE_BINARY_LEG=1 is set."""
    rc, out, err = run_cmd("ARKEA_LEG=binary make start-hcd")
    combined = f"{out}\n{err}"
    assert rc != 0, "Binary leg should be blocked by default."
    assert "Starting HCD (binary leg)" in combined


def test_active_port_mapping_from_config_snapshot():
    """Active config snapshot should expose host ports 9102/9192 with podman leg."""
    rc, out, err = run_cmd(
        "bash -lc 'source .poc-config.sh && echo \"__CFG__:$ARKEA_LEG $HCD_PORT $KAFKA_PORT\"'"
    )
    assert rc == 0, f"Unable to read config snapshot: {err}"
    cfg_line = next((line for line in out.splitlines() if line.startswith("__CFG__:")), "")
    assert cfg_line, f"Config marker not found in output: {out}"
    values = cfg_line.replace("__CFG__:", "").strip().split()
    assert len(values) == 3
    assert values[0] == "podman"
    assert values[1] == "9102"
    assert values[2] == "9192"


def test_active_host_ports_smoke():
    """Verify active host ports; strict in CI, optional in local dev."""
    strict_mode = os.environ.get("ARKEA_STRICT_RUNTIME_POLICY", "0") == "1"

    if strict_mode:
        ready = wait_for_ports("localhost", [9102, 9192], retries=20, delay_s=2.0)
        assert ready, "Expected host ports 9102/9192 to be reachable in strict runtime policy mode."

    hcd_up = is_port_open("localhost", 9102)
    kafka_up = is_port_open("localhost", 9192)

    if not strict_mode and not hcd_up and not kafka_up:
        pytest.skip("Local run without active stack on 9102/9192; skipping runtime smoke.")

    assert hcd_up, "Expected host port 9102 (CQL) to be reachable."
    assert kafka_up, "Expected host port 9192 (Kafka) to be reachable."
