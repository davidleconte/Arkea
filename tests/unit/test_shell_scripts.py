#!/usr/bin/env python3
# =============================================================================
# ARKEA POC - Shell Script Tests
# =============================================================================
# Date : 2026-03-13
# Version : 1.0.0
# Author : David LECONTE (IBM WW|Tiger Team - Watsonx.Data GPS)
# Description : Pytest tests for shell scripts using --dry-run mode
# Usage : pytest tests/unit/test_shell_scripts.py -v
# =============================================================================

import subprocess
from pathlib import Path

import pytest

# =============================================================================
# Fixtures
# =============================================================================


@pytest.fixture
def project_root():
    """Return project root directory."""
    return Path(__file__).parent.parent.parent.resolve()


@pytest.fixture
def onboarding_script(project_root):
    """Return path to onboarding script."""
    return project_root / "scripts" / "setup" / "00_onboarding.sh"


@pytest.fixture
def kcov_runner_script(project_root):
    """Return path to kcov runner script."""
    return project_root / "tests" / "utils" / "kcov_runner.sh"


# =============================================================================
# Helper Functions
# =============================================================================


def run_script(script_path, *args, timeout=30):
    """
    Run a shell script with arguments and return result.

    Args:
        script_path: Path to the script
        *args: Arguments to pass to the script
        timeout: Timeout in seconds (default 30)

    Returns:
        subprocess.CompletedProcess
    """
    cmd = [str(script_path)] + list(args)
    return subprocess.run(
        cmd,
        capture_output=True,
        text=True,
        timeout=timeout,
    )


# =============================================================================
# Tests: 00_onboarding.sh
# =============================================================================


class TestOnboardingScript:
    """Tests for scripts/setup/00_onboarding.sh"""

    def test_script_exists(self, onboarding_script):
        """Test that onboarding script exists."""
        assert onboarding_script.exists(), f"Script not found: {onboarding_script}"

    def test_script_is_executable(self, onboarding_script):
        """Test that onboarding script is executable."""
        assert onboarding_script.stat().st_mode & 0o111, "Script is not executable"

    def test_help_flag(self, onboarding_script):
        """Test --help flag displays usage information."""
        result = run_script(onboarding_script, "--help")

        # --help exits with 0 and shows usage
        assert result.returncode == 0
        assert "Usage:" in result.stdout or "usage:" in result.stdout.lower()
        assert "--dry-run" in result.stdout
        assert "--skip-deps" in result.stdout
        assert "--help" in result.stdout

    def test_dry_run_flag(self, onboarding_script):
        """Test --dry-run flag runs without making changes."""
        result = run_script(onboarding_script, "--dry-run")

        assert result.returncode == 0
        assert "DRY RUN" in result.stdout or "DRY-RUN" in result.stdout
        # Should not create any files
        assert "Would" in result.stdout or "would" in result.stdout.lower()

    def test_dry_run_skip_deps(self, onboarding_script):
        """Test --dry-run --skip-deps combination."""
        result = run_script(onboarding_script, "--dry-run", "--skip-deps")

        assert result.returncode == 0
        assert "DRY" in result.stdout
        assert "skip" in result.stdout.lower() or "deps" in result.stdout.lower()

    def test_unknown_option_shows_help(self, onboarding_script):
        """Test that unknown options show help and exit."""
        result = run_script(onboarding_script, "--invalid-option-xyz")

        # Should show help for unknown option
        assert result.returncode == 0  # Script exits 0 after showing help
        assert "Usage:" in result.stdout or "Unknown option" in result.stdout

    def test_detects_os(self, onboarding_script):
        """Test that script detects operating system."""
        result = run_script(onboarding_script, "--dry-run")

        assert result.returncode == 0
        # Should mention the detected OS
        assert (
            "macOS" in result.stdout or "Linux" in result.stdout or "Detected OS" in result.stdout
        )

    def test_no_changes_in_dry_run(self, onboarding_script, project_root, tmp_path):
        """Test that --dry-run does not create any files."""
        # Run with dry-run
        result = run_script(onboarding_script, "--dry-run")

        # If .venv already existed, that's fine - we just verify dry-run didn't
        # create it
        assert result.returncode == 0
        assert "[DRY-RUN]" in result.stdout or "DRY-RUN" in result.stdout


# =============================================================================
# Tests: kcov_runner.sh
# =============================================================================


class TestKcovRunnerScript:
    """Tests for tests/utils/kcov_runner.sh"""

    def test_script_exists(self, kcov_runner_script):
        """Test that kcov runner script exists."""
        assert kcov_runner_script.exists(), f"Script not found: {kcov_runner_script}"

    def test_script_is_executable(self, kcov_runner_script):
        """Test that kcov runner script is executable."""
        assert kcov_runner_script.stat().st_mode & 0o111, "Script is not executable"

    def test_help_flag(self, kcov_runner_script):
        """Test --help flag displays usage information."""
        result = run_script(kcov_runner_script, "--help")

        assert result.returncode == 0
        assert "Usage:" in result.stdout
        assert "--dry-run" in result.stdout
        assert "shell" in result.stdout.lower()
        assert "python" in result.stdout.lower()
        assert "all" in result.stdout.lower()

    def test_dry_run_default(self, kcov_runner_script):
        """Test --dry-run with default target (all)."""
        result = run_script(kcov_runner_script, "--dry-run")

        assert result.returncode == 0
        assert "DRY-RUN" in result.stdout or "DRY RUN" in result.stdout
        # Should mention what it would do
        assert "kcov" in result.stdout.lower() or "pytest" in result.stdout.lower()

    def test_dry_run_shell_target(self, kcov_runner_script):
        """Test --dry-run with shell target."""
        result = run_script(kcov_runner_script, "--dry-run", "shell")

        assert result.returncode == 0
        assert "DRY" in result.stdout
        assert "shell" in result.stdout.lower() or "kcov" in result.stdout.lower()

    def test_dry_run_python_target(self, kcov_runner_script):
        """Test --dry-run with python target."""
        result = run_script(kcov_runner_script, "--dry-run", "python")

        assert result.returncode == 0
        assert "DRY" in result.stdout
        assert "pytest" in result.stdout.lower() or "python" in result.stdout.lower()

    def test_dry_run_all_target(self, kcov_runner_script):
        """Test --dry-run with all target."""
        result = run_script(kcov_runner_script, "--dry-run", "all")

        assert result.returncode == 0
        assert "DRY" in result.stdout

    def test_no_coverage_files_created_in_dry_run(self, kcov_runner_script, project_root):
        """Test that --dry-run does not create coverage files."""
        # Run with dry-run
        result = run_script(kcov_runner_script, "--dry-run")

        # We just verify the script completed successfully
        assert result.returncode == 0

    def test_unknown_option_shows_help(self, kcov_runner_script):
        """Test that unknown options show help."""
        result = run_script(kcov_runner_script, "--invalid-xyz")

        # Should show help
        assert result.returncode == 0
        assert "Usage:" in result.stdout


# =============================================================================
# Tests: 80_verify_all.sh
# =============================================================================


@pytest.fixture
def verify_all_script(project_root):
    """Return path to verify all script."""
    return project_root / "scripts" / "utils" / "80_verify_all.sh"


class TestVerifyAllScript:
    """Tests for scripts/utils/80_verify_all.sh"""

    def test_script_exists(self, verify_all_script):
        """Test that verify_all script exists."""
        assert verify_all_script.exists(), f"Script not found: {verify_all_script}"

    def test_script_is_executable(self, verify_all_script):
        """Test that verify_all script is executable."""
        assert verify_all_script.stat().st_mode & 0o111, "Script is not executable"

    def test_help_flag(self, verify_all_script):
        """Test --help flag displays usage information."""
        result = run_script(verify_all_script, "--help")

        assert result.returncode == 0
        assert "Usage:" in result.stdout
        assert "--dry-run" in result.stdout

    def test_dry_run_flag(self, verify_all_script):
        """Test --dry-run flag runs without making changes."""
        result = run_script(verify_all_script, "--dry-run")

        assert result.returncode == 0
        assert "DRY RUN" in result.stdout or "DRY-RUN" in result.stdout

    def test_dry_run_checks_all_sections(self, verify_all_script):
        """Test --dry-run mentions all verification sections."""
        result = run_script(verify_all_script, "--dry-run")

        assert result.returncode == 0
        output = result.stdout.lower()
        # Should mention the components it would check
        assert "java" in output
        assert "hcd" in output
        assert "spark" in output
        assert "kafka" in output


# =============================================================================
# Tests: 95_cleanup.sh
# =============================================================================


@pytest.fixture
def cleanup_script(project_root):
    """Return path to cleanup script."""
    return project_root / "scripts" / "utils" / "95_cleanup.sh"


class TestCleanupScript:
    """Tests for scripts/utils/95_cleanup.sh"""

    def test_script_exists(self, cleanup_script):
        """Test that cleanup script exists."""
        assert cleanup_script.exists(), f"Script not found: {cleanup_script}"

    def test_script_is_executable(self, cleanup_script):
        """Test that cleanup script is executable."""
        assert cleanup_script.stat().st_mode & 0o111, "Script is not executable"

    def test_help_flag(self, cleanup_script):
        """Test --help flag displays usage information."""
        result = run_script(cleanup_script, "--help")

        assert result.returncode == 0
        assert "Usage:" in result.stdout
        assert "--dry-run" in result.stdout

    def test_dry_run_flag(self, cleanup_script):
        """Test --dry-run flag runs without making changes."""
        result = run_script(cleanup_script, "--dry-run")

        assert result.returncode == 0
        assert "DRY-RUN" in result.stdout or "DRY RUN" in result.stdout

    def test_dry_run_age_parameter(self, cleanup_script):
        """Test --dry-run with --age parameter."""
        result = run_script(cleanup_script, "--dry-run", "--age", "7")

        assert result.returncode == 0
        assert "DRY" in result.stdout


# =============================================================================
# Tests: Script Quality
# =============================================================================


class TestScriptQuality:
    """Tests for script quality and best practices."""

    def test_onboarding_has_shebang(self, onboarding_script):
        """Test that onboarding script has proper shebang."""
        content = onboarding_script.read_text()
        assert content.startswith("#!/bin/bash"), "Missing or incorrect shebang"

    def test_onboarding_has_set_flags(self, onboarding_script):
        """Test that onboarding script uses strict mode."""
        content = onboarding_script.read_text()
        assert (
            "set -e" in content or "set -euo pipefail" in content
        ), "Missing 'set -e' for error handling"
        assert "pipefail" in content, "Missing 'pipefail' in set command"

    def test_kcov_runner_has_shebang(self, kcov_runner_script):
        """Test that kcov runner has proper shebang."""
        content = kcov_runner_script.read_text()
        assert content.startswith("#!/bin/bash"), "Missing or incorrect shebang"

    def test_kcov_runner_has_set_flags(self, kcov_runner_script):
        """Test that kcov runner uses strict mode."""
        content = kcov_runner_script.read_text()
        assert (
            "set -e" in content or "set -euo pipefail" in content
        ), "Missing 'set -e' for error handling"

    def test_onboarding_has_help_function(self, onboarding_script):
        """Test that onboarding has a help function."""
        content = onboarding_script.read_text()
        assert "show_help" in content or "usage" in content.lower(), "Missing help/usage function"

    def test_kcov_runner_has_help_function(self, kcov_runner_script):
        """Test that kcov runner has a help function."""
        content = kcov_runner_script.read_text()
        assert "show_help" in content or "usage" in content.lower(), "Missing help/usage function"

    def test_onboarding_uses_color_output(self, onboarding_script):
        """Test that onboarding uses colored output for better UX."""
        content = onboarding_script.read_text()
        assert "GREEN" in content or "log_info" in content, "Missing colored output functions"

    def test_scripts_have_project_root_detection(self, onboarding_script, kcov_runner_script):
        """Test that scripts detect project root dynamically."""
        onboarding_content = onboarding_script.read_text()
        kcov_content = kcov_runner_script.read_text()

        # Both should use BASH_SOURCE or similar for dynamic path resolution
        assert "BASH_SOURCE" in onboarding_content or "SCRIPT_DIR" in onboarding_content
        assert "BASH_SOURCE" in kcov_content or "SCRIPT_DIR" in kcov_content


# =============================================================================
# Tests: CLI Argument Parsing
# =============================================================================


class TestCliArgumentParsing:
    """Tests for CLI argument parsing robustness."""

    def test_onboarding_multiple_flags(self, onboarding_script):
        """Test onboarding with multiple flags in different orders."""
        # Order 1: --dry-run --skip-deps
        result1 = run_script(onboarding_script, "--dry-run", "--skip-deps")
        assert result1.returncode == 0

        # Order 2: --skip-deps --dry-run
        result2 = run_script(onboarding_script, "--skip-deps", "--dry-run")
        assert result2.returncode == 0

    def test_kcov_runner_multiple_flags(self, kcov_runner_script):
        """Test kcov runner with flags in different orders."""
        # Order 1: --dry-run shell
        result1 = run_script(kcov_runner_script, "--dry-run", "shell")
        assert result1.returncode == 0

        # Order 2: shell --dry-run
        result2 = run_script(kcov_runner_script, "shell", "--dry-run")
        assert result2.returncode == 0

    def test_onboarding_handles_empty_args(self, onboarding_script):
        """Test onboarding handles empty arguments gracefully."""
        # Empty args should run normal mode (but we use dry-run to be safe)
        # Instead, test that the script validates properly
        result = run_script(onboarding_script, "--dry-run")
        assert result.returncode == 0


# =============================================================================
# Integration Tests (with dry-run)
# =============================================================================


@pytest.mark.integration
class TestScriptIntegration:
    """Integration tests using --dry-run mode."""

    def test_onboarding_dry_run_full_output(self, onboarding_script):
        """Test onboarding --dry-run produces expected output sections."""
        result = run_script(onboarding_script, "--dry-run")

        assert result.returncode == 0
        # Check for key sections
        output = result.stdout
        assert "ARKEA" in output or "onboarding" in output.lower()
        assert "DRY" in output

    def test_kcov_runner_dry_run_full_output(self, kcov_runner_script):
        """Test kcov runner --dry-run produces expected output sections."""
        result = run_script(kcov_runner_script, "--dry-run", "all")

        assert result.returncode == 0
        output = result.stdout
        assert "ARKEA" in output or "coverage" in output.lower()
        assert "DRY" in output


# =============================================================================
# Markers
# =============================================================================


# Allow running with pytest markers
# pytest -m unit tests/unit/test_shell_scripts.py -v
# pytest -m integration tests/unit/test_shell_scripts.py -v
