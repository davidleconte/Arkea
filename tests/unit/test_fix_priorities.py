#!/usr/bin/env python3
"""
Tests for scripts/utils/fix_priorities.py

Usage: pytest tests/unit/test_fix_priorities.py -v
"""

import os
import tempfile
from pathlib import Path
from unittest.mock import patch, MagicMock

import pytest

# Import the module under test
import sys

sys.path.insert(0, str(Path(__file__).parent.parent.parent / "scripts" / "utils"))
import fix_priorities


class TestFindFiles:
    """Tests for find_files() function."""

    def test_find_files_with_sh_extension(self, tmp_path):
        """Test finding .sh files in a directory."""
        (tmp_path / "test1.sh").touch()
        (tmp_path / "test2.sh").touch()
        (tmp_path / "readme.md").touch()

        files = fix_priorities.find_files(tmp_path, [".sh"])
        assert len(files) == 2
        assert all(f.suffix == ".sh" for f in files)

    def test_find_files_with_multiple_extensions(self, tmp_path):
        """Test finding files with multiple extensions."""
        (tmp_path / "test.sh").touch()
        (tmp_path / "test.py").touch()
        (tmp_path / "test.scala").touch()

        files = fix_priorities.find_files(tmp_path, [".sh", ".py"])
        assert len(files) == 2

    def test_find_files_excludes_directories(self, tmp_path):
        """Test that excluded directories are skipped."""
        excluded_dir = tmp_path / ".git"
        excluded_dir.mkdir()
        (excluded_dir / "test.sh").touch()
        (tmp_path / "main.sh").touch()

        files = fix_priorities.find_files(tmp_path, [".sh"], exclude_dirs={".git"})
        assert len(files) == 1
        assert files[0].name == "main.sh"

    def test_find_files_empty_directory(self, tmp_path):
        """Test finding files in empty directory."""
        files = fix_priorities.find_files(tmp_path, [".sh"])
        assert len(files) == 0


class TestFixHardcodedPaths:
    """Tests for fix_hardcoded_paths() function."""

    def test_fix_hardcoded_path_dry_run(self, tmp_path):
        """Test dry-run mode does not modify files."""
        test_file = tmp_path / "test.sh"
        test_file.write_text('INSTALL_DIR="/Users/david.leconte/Documents/Arkea"')

        with patch.object(fix_priorities, "ARKEA_HOME", tmp_path):
            result = fix_priorities.fix_hardcoded_paths(test_file, dry_run=True)

        assert result is True
        assert (
            test_file.read_text()
            == 'INSTALL_DIR="/Users/david.leconte/Documents/Arkea"'
        )

    def test_fix_hardcoded_path_actual_fix(self, tmp_path):
        """Test actual fix modifies files."""
        test_file = tmp_path / "test.sh"
        test_file.write_text('INSTALL_DIR="/Users/david.leconte/Documents/Arkea"')

        with patch.object(fix_priorities, "ARKEA_HOME", tmp_path):
            result = fix_priorities.fix_hardcoded_paths(test_file, dry_run=False)

        assert result is True
        assert test_file.read_text() == 'INSTALL_DIR="${ARKEA_HOME}"'

    def test_no_hardcoded_paths(self, tmp_path):
        """Test file without hardcoded paths."""
        test_file = tmp_path / "test.sh"
        test_file.write_text('echo "Hello World"')

        result = fix_priorities.fix_hardcoded_paths(test_file, dry_run=False)

        assert result is False
        assert test_file.read_text() == 'echo "Hello World"'

    def test_fix_multiple_patterns(self, tmp_path):
        """Test fixing multiple hardcoded patterns in one file."""
        test_file = tmp_path / "test.sh"
        test_file.write_text(
            'INSTALL_DIR="/Users/david.leconte/Documents/Arkea"\n'
            'USER_PATH="/Users/david.leconte"\n'
        )

        with patch.object(fix_priorities, "ARKEA_HOME", tmp_path):
            result = fix_priorities.fix_hardcoded_paths(test_file, dry_run=False)

        assert result is True
        content = test_file.read_text()
        assert 'INSTALL_DIR="${ARKEA_HOME}"' in content
        assert 'USER_PATH="${USER_HOME:-$HOME}"' in content


class TestFixLocalhostReferences:
    """Tests for fix_localhost_references() function."""

    def test_fix_localhost_dry_run(self, tmp_path):
        """Test dry-run mode does not modify files."""
        test_file = tmp_path / "test.sh"
        test_file.write_text("cqlsh localhost:9042")

        with patch.object(fix_priorities, "ARKEA_HOME", tmp_path):
            result = fix_priorities.fix_localhost_references(test_file, dry_run=True)

        assert result is True
        assert test_file.read_text() == "cqlsh localhost:9042"

    def test_fix_localhost_actual_fix(self, tmp_path):
        """Test actual fix modifies localhost references."""
        test_file = tmp_path / "test.sh"
        test_file.write_text("cqlsh localhost:9042")

        with patch.object(fix_priorities, "ARKEA_HOME", tmp_path):
            result = fix_priorities.fix_localhost_references(test_file, dry_run=False)

        assert result is True
        assert "HCD_HOST:-localhost" in test_file.read_text()

    def test_fix_localhost_kafka_port(self, tmp_path):
        """Test fixing Kafka localhost references."""
        test_file = tmp_path / "test.sh"
        test_file.write_text("kafka-topics.sh --bootstrap-server localhost:9092")

        with patch.object(fix_priorities, "ARKEA_HOME", tmp_path):
            result = fix_priorities.fix_localhost_references(test_file, dry_run=False)

        assert result is True
        assert "KAFKA_BOOTSTRAP_SERVERS:-localhost:9092" in test_file.read_text()

    def test_fix_localhost_scala_file(self, tmp_path):
        """Test fixing localhost in Scala files uses Scala patterns."""
        test_file = tmp_path / "test.scala"
        test_file.write_text('val host = "localhost:9042"')

        with patch.object(fix_priorities, "ARKEA_HOME", tmp_path):
            result = fix_priorities.fix_localhost_references(test_file, dry_run=False)

        assert result is True
        content = test_file.read_text()
        assert "sys.env.getOrElse" in content or "HCD_HOST" in content

    def test_no_localhost_references(self, tmp_path):
        """Test file without localhost references."""
        test_file = tmp_path / "test.sh"
        test_file.write_text('echo "No localhost here"')

        result = fix_priorities.fix_localhost_references(test_file, dry_run=False)

        assert result is False


class TestRemoveStrangeFiles:
    """Tests for remove_strange_files() function."""

    def test_remove_strange_files_dry_run(self, tmp_path):
        """Test dry-run mode does not remove files."""
        strange_file = tmp_path / "="
        strange_file.touch()

        with patch.object(fix_priorities, "ARKEA_HOME", tmp_path):
            result = fix_priorities.remove_strange_files(dry_run=True)

        assert strange_file.exists()

    def test_remove_strange_files_actual(self, tmp_path):
        """Test actual removal of strange files."""
        binaire_dir = tmp_path / "binaire" / "spark-3.5.1"
        binaire_dir.mkdir(parents=True)
        strange_file = binaire_dir / "="
        strange_file.touch()

        with patch.object(fix_priorities, "ARKEA_HOME", tmp_path):
            result = fix_priorities.remove_strange_files(dry_run=False)

        assert not strange_file.exists()


class TestMainFunction:
    """Tests for main() function."""

    def test_main_dry_run_flag(self, tmp_path):
        """Test --dry-run flag in main."""
        test_file = tmp_path / "test.sh"
        test_file.write_text('INSTALL_DIR="/Users/david.leconte/Documents/Arkea"')

        with patch.object(fix_priorities, "ARKEA_HOME", tmp_path):
            with patch(
                "sys.argv", ["fix_priorities.py", "--dry-run", "--priority", "1"]
            ):
                fix_priorities.main()

        assert (
            test_file.read_text()
            == 'INSTALL_DIR="/Users/david.leconte/Documents/Arkea"'
        )

    def test_main_priority_1_only(self, tmp_path):
        """Test --priority 1 only fixes hardcoded paths."""
        test_file = tmp_path / "test.sh"
        test_file.write_text('INSTALL_DIR="/Users/david.leconte/Documents/Arkea"')

        with patch.object(fix_priorities, "ARKEA_HOME", tmp_path):
            with patch("sys.argv", ["fix_priorities.py", "--priority", "1"]):
                fix_priorities.main()

        assert test_file.read_text() == 'INSTALL_DIR="${ARKEA_HOME}"'

    def test_main_priority_2_only(self, tmp_path):
        """Test --priority 2 only fixes localhost references."""
        test_file = tmp_path / "test.sh"
        test_file.write_text("cqlsh localhost:9042")

        with patch.object(fix_priorities, "ARKEA_HOME", tmp_path):
            with patch("sys.argv", ["fix_priorities.py", "--priority", "2"]):
                fix_priorities.main()

        assert "HCD_HOST" in test_file.read_text()

    def test_main_all_priorities(self, tmp_path):
        """Test --priority all fixes everything."""
        test_file = tmp_path / "test.sh"
        test_file.write_text(
            'INSTALL_DIR="/Users/david.leconte/Documents/Arkea"\n'
            "cqlsh localhost:9042\n"
        )

        with patch.object(fix_priorities, "ARKEA_HOME", tmp_path):
            with patch("sys.argv", ["fix_priorities.py", "--priority", "all"]):
                fix_priorities.main()

        content = test_file.read_text()
        assert "ARKEA_HOME" in content
        assert "HCD_HOST" in content


class TestEdgeCases:
    """Edge case tests."""

    def test_fix_file_read_error(self, tmp_path):
        """Test handling of file read errors."""
        test_file = tmp_path / "test.sh"
        test_file.mkdir()

        result = fix_priorities.fix_hardcoded_paths(test_file, dry_run=False)
        assert result is False

    def test_fix_file_with_unicode(self, tmp_path):
        """Test handling files with unicode content."""
        test_file = tmp_path / "test.sh"
        test_file.write_text(
            '# Commentaire en français: éàù\nINSTALL_DIR="/Users/david.leconte/Documents/Arkea"',
            encoding="utf-8",
        )

        with patch.object(fix_priorities, "ARKEA_HOME", tmp_path):
            result = fix_priorities.fix_hardcoded_paths(test_file, dry_run=False)

        assert result is True
        content = test_file.read_text(encoding="utf-8")
        assert "éàù" in content
        assert "${ARKEA_HOME}" in content

    def test_empty_file(self, tmp_path):
        """Test handling empty files."""
        test_file = tmp_path / "test.sh"
        test_file.write_text("")

        result = fix_priorities.fix_hardcoded_paths(test_file, dry_run=False)
        assert result is False


if __name__ == "__main__":
    pytest.main([__file__, "-v"])
