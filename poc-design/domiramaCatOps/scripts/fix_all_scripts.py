#!/usr/bin/env python3
"""
Script de correction systématique de tous les scripts .sh
Corrige les problèmes identifiés dans l'audit
"""

import os
import re
import sys
from pathlib import Path

SCRIPT_DIR = Path(__file__).parent
INSTALL_DIR = "/Users/david.leconte/Documents/Arkea"


def fix_script(script_path):
    """Corrige un script individuel"""
    with open(script_path, "r", encoding="utf-8") as f:
        content = f.read()

    original_content = content
    fixed = False

    # 1. Ajouter INSTALL_DIR et HCD_DIR si manquants (pour scripts récents)
    if "source" in content and "didactique_functions.sh" in content:
        if "HCD_DIR=" not in content and "HCD_HOME" in content:
            # Ajouter après SCRIPT_DIR ou INSTALL_DIR
            if "INSTALL_DIR=" not in content:
                content = re.sub(
                    r"(SCRIPT_DIR=.*\n)",
                    r'\1INSTALL_DIR="${INSTALL_DIR:-/Users/david.leconte/Documents/Arkea}"\n',
                    content,
                    count=1,
                )
            if "HCD_DIR=" not in content:
                content = re.sub(
                    r"(INSTALL_DIR=.*\n|SCRIPT_DIR=.*\n)",
                    r'\1HCD_DIR="${HCD_HOME:-${INSTALL_DIR}/binaire/hcd-1.2.3}"\n',
                    content,
                    count=1,
                )
            fixed = True

        # 2. Remplacer "$HCD_HOME"/bin/cqlsh par "${HCD_DIR}/bin/cqlsh"
        if '"$HCD_HOME"/bin/cqlsh' in content:
            content = content.replace('"$HCD_HOME"/bin/cqlsh', '"${HCD_DIR}/bin/cqlsh"')
            fixed = True

        # 3. Remplacer $HCD_HOME/bin/cqlsh (sans guillemets) par "${HCD_DIR}/bin/cqlsh"
        content = re.sub(r"\$HCD_HOME/bin/cqlsh", r'"${HCD_DIR}/bin/cqlsh"', content)
        if "$HCD_HOME/bin/cqlsh" in original_content:
            fixed = True

    # 4. Pour scripts anciens : remplacer cqlsh sans chemin par "${HCD_DIR}/bin/cqlsh"
    if "HCD_DIR=" in content and "cqlsh" in content:
        # Remplacer les occurrences de cqlsh qui ne sont pas déjà dans un chemin
        lines = content.split("\n")
        new_lines = []
        for line in lines:
            # Si la ligne contient cqlsh mais pas déjà un chemin complet
            if "cqlsh" in line and "bin/cqlsh" not in line and "CQLSH" not in line.upper():
                # Remplacer cqlsh par "${HCD_DIR}/bin/cqlsh" dans les commandes
                if re.search(r"\bcqlsh\b", line) and not line.strip().startswith("#"):
                    line = re.sub(r"\bcqlsh\b", r'"${HCD_DIR}/bin/cqlsh"', line)
                    fixed = True
            new_lines.append(line)
        content = "\n".join(new_lines)

    if fixed and content != original_content:
        with open(script_path, "w", encoding="utf-8") as f:
            f.write(content)
        return True
    return False


def main():
    """Corrige tous les scripts"""
    scripts_dir = SCRIPT_DIR
    fixed_count = 0

    for script_file in sorted(scripts_dir.glob("*.sh")):
        if script_file.name in ["FIX_SCRIPTS.sh", "AUDIT_SCRIPTS.sh", "fix_all_scripts.py"]:
            continue

        if fix_script(script_file):
            print(f"✅ Corrigé: {script_file.name}")
            fixed_count += 1
        else:
            print(f"ℹ️  Aucune correction: {script_file.name}")

    print(f"\n✅ {fixed_count} script(s) corrigé(s)")


if __name__ == "__main__":
    main()
