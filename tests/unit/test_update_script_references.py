#!/usr/bin/env python3
"""
Tests for scripts/utils/update_script_references.py

Usage: pytest tests/unit/test_update_script_references.py -v
"""

import sys
from pathlib import Path

import pytest

sys.path.insert(0, str(Path(__file__).parent.parent.parent / "scripts" / "utils"))
import update_script_references  # noqa: E402


class TestScriptMapping:
    """Tests for SCRIPT_MAPPING configuration."""

    def test_mapping_has_setup_scripts(self):
        """Test that setup scripts are mapped."""
        patterns = list(update_script_references.SCRIPT_MAPPING.keys())
        # Check some key patterns exist
        assert any("01_install_hcd" in p for p in patterns)
        assert any("03_start_hcd" in p for p in patterns)
        assert any("04_start_kafka" in p for p in patterns)

    def test_mapping_has_utils_scripts(self):
        """Test that utility scripts are mapped."""
        patterns = list(update_script_references.SCRIPT_MAPPING.keys())
        assert any("80_verify_all" in p for p in patterns)
        assert any("90_list_scripts" in p for p in patterns)

    def test_mapping_values_are_valid_paths(self):
        """Test that all mapped values are valid script paths."""
        for new_path in update_script_references.SCRIPT_MAPPING.values():
            assert new_path.startswith("./scripts/"), f"Invalid path: {new_path}"


class TestUpdateFileReferences:
    """Tests for update_file_references() function."""

    def test_update_single_reference(self, tmp_path):
        """Test updating a single script reference."""
        test_file = tmp_path / "test.md"
        test_file.write_text("Run ./01_install_hcd.sh to install HCD")

        result = update_script_references.update_file_references(test_file)

        assert result is True
        content = test_file.read_text()
        assert "./scripts/setup/01_install_hcd.sh" in content
        assert "./01_install_hcd.sh" not in content

    def test_update_multiple_references(self, tmp_path):
        """Test updating multiple references in one file."""
        test_file = tmp_path / "test.md"
        test_file.write_text("1. Run ./03_start_hcd.sh\n2. Run ./04_start_kafka.sh\n")

        result = update_script_references.update_file_references(test_file)

        assert result is True
        content = test_file.read_text()
        assert "./scripts/setup/03_start_hcd.sh" in content
        assert "./scripts/setup/04_start_kafka.sh" in content

    def test_no_references_to_update(self, tmp_path):
        """Test file with no script references."""
        test_file = tmp_path / "test.md"
        test_file.write_text("This file has no script references.")

        result = update_script_references.update_file_references(test_file)

        assert result is False
        assert test_file.read_text() == "This file has no script references."

    def test_already_correct_paths(self, tmp_path):
        """Test file that already has correct paths."""
        test_file = tmp_path / "test.md"
        test_file.write_text("Run ./scripts/setup/03_start_hcd.sh")

        result = update_script_references.update_file_references(test_file)

        # Should return False (no changes made)
        # The old pattern won't match since it's already correct
        assert result is False

    def test_file_read_error(self, tmp_path):
        """Test handling of file read errors."""
        # Create a directory instead of a file
        test_file = tmp_path / "not_a_file"
        test_file.mkdir()

        result = update_script_references.update_file_references(test_file)

        assert result is False

    def test_update_in_shell_script(self, tmp_path):
        """Test updating references in shell scripts."""
        test_file = tmp_path / "test.sh"
        test_file.write_text("#!/bin/bash\necho 'Run ./80_verify_all.sh for verification'")

        result = update_script_references.update_file_references(test_file)

        assert result is True
        content = test_file.read_text()
        assert "./scripts/utils/80_verify_all.sh" in content


class TestExtensions:
    """Tests for file extension handling."""

    def test_processes_sh_files(self, tmp_path):
        """Test that .sh files are processed."""
        test_file = tmp_path / "test.sh"
        test_file.write_text("./01_install_hcd.sh")

        result = update_script_references.update_file_references(test_file)

        assert result is True

    def test_processes_md_files(self, tmp_path):
        """Test that .md files are processed."""
        test_file = tmp_path / "test.md"
        test_file.write_text("./01_install_hcd.sh")

        result = update_script_references.update_file_references(test_file)

        assert result is True

    def test_processes_py_files(self, tmp_path):
        """Test that .py files are processed."""
        test_file = tmp_path / "test.py"
        test_file.write_text("# Run: ./01_install_hcd.sh")

        result = update_script_references.update_file_references(test_file)

        assert result is True


class TestEdgeCases:
    """Edge case tests."""

    def test_empty_file(self, tmp_path):
        """Test handling empty files."""
        test_file = tmp_path / "empty.sh"
        test_file.write_text("")

        result = update_script_references.update_file_references(test_file)

        assert result is False

    def test_file_with_unicode(self, tmp_path):
        """Test handling files with unicode content."""
        test_file = tmp_path / "test.md"
        test_file.write_text(
            "# Documentation éàù\n\nExécutez ./03_start_hcd.sh",
            encoding="utf-8",
        )

        result = update_script_references.update_file_references(test_file)

        assert result is True
        content = test_file.read_text(encoding="utf-8")
        assert "éàù" in content
        assert "./scripts/setup/03_start_hcd.sh" in content

    def test_reference_in_code_block(self, tmp_path):
        """Test that references in code blocks are also updated."""
        test_file = tmp_path / "test.md"
        test_file.write_text("```bash\n./01_install_hcd.sh\n```\n")

        result = update_script_references.update_file_references(test_file)

        assert result is True
        assert "./scripts/setup/01_install_hcd.sh" in test_file.read_text()


if __name__ == "__main__":
    pytest.main([__file__, "-v"])
