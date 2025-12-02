#!/usr/bin/env python3
"""
Script pour ajouter setup_paths() aux scripts qui ne l'ont pas
"""

import os
import re
from pathlib import Path

SCRIPT_DIR = Path(__file__).parent
SCRIPTS_TO_UPDATE = [
    "24_demonstration_fuzzy_search.sh",
    "27_export_incremental_parquet_spark_shell.sh",
    "28_demo_fenetre_glissante.sh",
    "28_demo_fenetre_glissante_spark_submit.sh",
    "29_demo_requetes_fenetre_glissante.sh",
    "30_demo_requetes_startrow_stoprow.sh",
    "31_demo_bloomfilter_equivalent_v2.sh",
    "32_demo_performance_comparison.sh",
    "33_demo_colonnes_dynamiques_v2.sh",
    "34_demo_replication_scope_v2.sh",
    "35_demo_dsbulk_v2.sh",
    "36_setup_data_api.sh",
    "37_demo_data_api.sh",
    "38_verifier_endpoint_data_api.sh",
    "39_deploy_stargate.sh",
    "40_demo_data_api_complete.sh",
    "41_demo_complete_podman.sh",
    "demo_data_api_http.sh",
]

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


def update_script(script_path):
    """Met à jour un script pour ajouter setup_paths()"""
    with open(script_path, "r", encoding="utf-8") as f:
        content = f.read()

    # Vérifier si setup_paths existe déjà
    if "setup_paths" in content:
        print(f"  ⚠️  {script_path.name} : setup_paths() déjà présent")
        return False

    # Trouver où insérer
    insert_pos = find_config_section(content)
    if insert_pos is None:
        print(f"  ⚠️  {script_path.name} : Impossible de trouver où insérer")
        return False

    lines = content.split("\n")

    # Trouver où commence la section de configuration actuelle
    config_start = insert_pos
    config_end = insert_pos

    # Trouver la fin de la section de configuration (jusqu'à la première fonction ou section)
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
    # (sauter les lignes qui définissent SCRIPT_DIR, INSTALL_DIR, HCD_DIR, etc.)
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

    # Sauvegarder
    backup_path = script_path.with_suffix(".sh.bak")
    with open(backup_path, "w", encoding="utf-8") as f:
        f.write(content)

    with open(script_path, "w", encoding="utf-8") as f:
        f.write("\n".join(new_lines))

    print(f"  ✅ {script_path.name} : setup_paths() ajouté")
    return True


def main():
    """Met à jour tous les scripts"""
    print("🔄 Ajout de setup_paths() aux scripts...")
    print()

    updated = 0
    for script_name in SCRIPTS_TO_UPDATE:
        script_path = SCRIPT_DIR / script_name
        if script_path.exists():
            if update_script(script_path):
                updated += 1
        else:
            print(f"  ⚠️  {script_name} : Fichier non trouvé")

    print()
    print(f"✅ {updated} scripts mis à jour")
    print(f"📦 Sauvegardes créées : *.sh.bak")


if __name__ == "__main__":
    main()
