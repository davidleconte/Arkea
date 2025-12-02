#!/usr/bin/env python3
"""
Script pour corriger la qualité des scripts domiramaCatOps
- Ajouter set -euo pipefail
- Ajouter setup_paths()
- Remplacer localhost par $HCD_HOST
"""

import os
import re
from pathlib import Path

SCRIPT_DIR = Path(__file__).parent
SETUP_PATHS_CODE = """# Configuration - Utiliser setup_paths si disponible
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
if [ -f "$SCRIPT_DIR/../utils/didactique_functions.sh" ]; then
    source "$SCRIPT_DIR/../utils/didactique_functions.sh"
    setup_paths
else
    # Fallback si les fonctions ne sont pas disponibles
    INSTALL_DIR="${ARKEA_HOME:-$(cd "$SCRIPT_DIR/../.." && pwd)}"
    HCD_DIR="${HCD_DIR:-${INSTALL_DIR}/binaire/hcd-1.2.3}"
    SPARK_HOME="${SPARK_HOME:-${INSTALL_DIR}/binaire/spark-3.5.1}"
    HCD_HOST="${HCD_HOST:-localhost}"
    HCD_PORT="${HCD_PORT:-9042}"
fi
"""


def has_set_euo_pipefail(content):
    """Vérifie si le script a set -euo pipefail"""
    return bool(re.search(r"^set\s+-[euo\s]+pipefail", content, re.MULTILINE))


def has_setup_paths(content):
    """Vérifie si le script a setup_paths()"""
    return "setup_paths" in content


def find_shebang_and_set_line(content):
    """Trouve la ligne du shebang et la ligne set"""
    lines = content.split("\n")
    shebang_idx = None
    set_idx = None

    for i, line in enumerate(lines):
        if line.startswith("#!/bin/bash"):
            shebang_idx = i
        if re.match(r"^set\s+-[euo]", line):
            set_idx = i
            break

    return shebang_idx, set_idx


def find_config_section(content):
    """Trouve où insérer setup_paths()"""
    lines = content.split("\n")

    # Chercher après set -euo pipefail ou set -e
    for i, line in enumerate(lines):
        if re.match(r"set\s+-[euo\s]+pipefail", line) or re.match(r"set\s+-e", line):
            # Chercher la section de configuration qui suit
            for j in range(i + 1, min(i + 50, len(lines))):
                # Si on trouve déjà setup_paths, on ne fait rien
                if "setup_paths" in lines[j]:
                    return None
                # Si on trouve SCRIPT_DIR ou INSTALL_DIR, on remplace
                if re.match(r"SCRIPT_DIR=|INSTALL_DIR=", lines[j]):
                    return j
            # Sinon, insérer après set -e
            return i + 1

    return None


def replace_localhost(content):
    """Remplace localhost hardcodé par $HCD_HOST"""
    # Patterns à remplacer
    replacements = [
        (r"localhost\s+9042", r'"$HCD_HOST" "$HCD_PORT"'),
        (r"localhost:9042", r'"${HCD_HOST}:${HCD_PORT}"'),
        (r"nc -z localhost", r'nc -z "$HCD_HOST"'),
        (r"http://localhost:", r"http://${HCD_HOST}:"),
    ]

    new_content = content
    for pattern, replacement in replacements:
        # Ne remplacer que si ce n'est pas déjà dans une variable
        if not re.search(r"\$HCD_HOST", new_content):
            new_content = re.sub(pattern, replacement, new_content)

    return new_content


def fix_script(script_path):
    """Corrige un script"""
    with open(script_path, "r", encoding="utf-8") as f:
        content = f.read()

    original_content = content
    modified = False

    # 1. Ajouter set -euo pipefail si manquant
    if not has_set_euo_pipefail(content):
        shebang_idx, set_idx = find_shebang_and_set_line(content)
        lines = content.split("\n")

        if shebang_idx is not None:
            # Remplacer set -e par set -euo pipefail, ou ajouter après shebang
            if set_idx is not None:
                # Remplacer la ligne set existante
                if re.match(r"^set\s+-e\s*$", lines[set_idx]):
                    lines[set_idx] = "set -euo pipefail"
                    modified = True
            else:
                # Ajouter après shebang
                lines.insert(shebang_idx + 1, "set -euo pipefail")
                modified = True

            content = "\n".join(lines)

    # 2. Ajouter setup_paths() si manquant
    if not has_setup_paths(content):
        insert_pos = find_config_section(content)
        if insert_pos is not None:
            lines = content.split("\n")

            # Trouver où commence la section de configuration actuelle
            config_start = insert_pos
            config_end = insert_pos

            # Trouver la fin de la section de configuration
            for i in range(insert_pos, min(insert_pos + 30, len(lines))):
                if (
                    lines[i].strip()
                    and not lines[i].strip().startswith("#")
                    and not re.match(r"[A-Z_]+=", lines[i])
                ):
                    if not lines[i].strip().startswith("$"):
                        config_end = i
                        break
                config_end = i + 1

            # Remplacer la section de configuration
            new_lines = lines[:config_start]
            new_lines.extend(SETUP_PATHS_CODE.split("\n"))

            # Garder les lignes après la configuration qui ne sont pas remplacées
            skip_patterns = [
                r"^SCRIPT_DIR=",
                r"^INSTALL_DIR=",
                r"^HCD_DIR=",
                r"^SPARK_HOME=",
                r"^HCD_HOST=",
                r"^HCD_PORT=",
                r"^NODETOOL=",
                r"^CQLSH=",
            ]

            for i in range(config_start, config_end):
                line = lines[i]
                should_skip = False
                for pattern in skip_patterns:
                    if re.match(pattern, line.strip()):
                        should_skip = True
                        break
                if not should_skip and line.strip():
                    new_lines.append(line)

            new_lines.extend(lines[config_end:])
            content = "\n".join(new_lines)
            modified = True

    # 3. Remplacer localhost hardcodé
    if "localhost" in content and "$HCD_HOST" not in content:
        new_content = replace_localhost(content)
        if new_content != content:
            content = new_content
            modified = True

    # Sauvegarder si modifié
    if modified:
        backup_path = script_path.with_suffix(".sh.bak")
        with open(backup_path, "w", encoding="utf-8") as f:
            f.write(original_content)

        with open(script_path, "w", encoding="utf-8") as f:
            f.write(content)

        return True

    return False


def main():
    """Corrige tous les scripts"""
    print("🔄 Correction de la qualité des scripts domiramaCatOps...")
    print()

    scripts = sorted(SCRIPT_DIR.glob("*.sh"))
    fixed = 0

    for script_path in scripts:
        if script_path.name.startswith("fix_") or script_path.name.startswith("AUDIT_"):
            continue

        if fix_script(script_path):
            print(f"  ✅ {script_path.name}")
            fixed += 1
        else:
            print(f"  ⚪ {script_path.name} (déjà conforme)")

    print()
    print(f"✅ {fixed} scripts corrigés")
    print(f"📦 Sauvegardes créées : *.sh.bak")


if __name__ == "__main__":
    main()
