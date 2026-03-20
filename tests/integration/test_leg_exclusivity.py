"""
Integration tests for strict dual-leg exclusivity:
- podman leg and binary leg must never be active at the same time.
"""

import socket
import subprocess


def run_cmd(cmd: str):
    """Run a shell command and return (rc, stdout, stderr)."""
    # nosec B602: shell=True required for Make/bash composition
    result = subprocess.run(cmd, shell=True, capture_output=True, text=True)  # nosec B602
    return result.returncode, result.stdout, result.stderr


def is_port_open(host: str, port: int, timeout: float = 1.5) -> bool:
    """Check if a TCP port is reachable."""
    with socket.socket(socket.AF_INET, socket.SOCK_STREAM) as sock:
        sock.settimeout(timeout)
        return sock.connect_ex((host, port)) == 0


def test_podman_leg_excludes_binary_host_port():
    """
    When podman leg is active, host binary CQL port 9042 must not be reachable.
    """
    rc, out, err = run_cmd("ARKEA_LEG=podman make start-hcd")
    assert rc == 0, f"Unable to start podman leg HCD: {out}\n{err}"

    # Active host port should be reachable
    assert is_port_open("localhost", 9102), "Expected podman host port 9102 to be reachable."

    # Binary host port must remain closed for exclusivity
    assert not is_port_open(
        "localhost", 9042
    ), "Binary host port 9042 must be closed when ARKEA_LEG=podman."


def test_binary_leg_blocked_without_explicit_override():
    """
    Binary leg is policy-blocked unless ARKEA_ENABLE_BINARY_LEG=1.
    """
    rc, out, err = run_cmd("ARKEA_LEG=binary make start-hcd")
    assert rc != 0, "Binary leg should be blocked by default."
    assert "ARKEA_ENABLE_BINARY_LEG=1" in f"{out}\n{err}" or "Error" in f"{out}\n{err}"


def test_stop_all_sanitizes_ports():
    """
    stop-all should sanitize both runtime surfaces.
    """
    rc, out, err = run_cmd("make stop-all")
    assert rc == 0, f"stop-all failed: {out}\n{err}"
    assert not is_port_open("localhost", 9042), "Port 9042 should be closed after stop-all."
    assert not is_port_open("localhost", 9102), "Port 9102 should be closed after stop-all."


def test_direct_binary_script_blocked_under_podman_policy():
    """
    Direct binary startup script must be blocked when podman leg policy is active.
    """
    rc, out, err = run_cmd("ARKEA_LEG=podman ./scripts/setup/03_start_hcd.sh")
    combined = f"{out}\n{err}"
    assert rc != 0, "Direct binary script execution should fail under podman policy."
    assert (
        "ARKEA_ENABLE_BINARY_LEG=1" in combined
        or "disabled by policy" in combined
        or "ERROR" in combined
    )
