#!/usr/bin/env python3
"""
Script de Migration : Mise à jour automatique de tous les scripts shell

Ce script met à jour automatiquement tous les scripts shell pour :
1. Remplacer les chemins hardcodés par la détection automatique
2. Ajouter set -euo pipefail au lieu de set -e
3. Remplacer localhost 9042 par $HCD_HOST $HCD_PORT

Usage:
    python3 migrate_all_scripts.py [--dry-run]
"""

import re
import shutil
import sys
from pathlib import Path

DRY_RUN = "--dry-run" in sys.argv


def info(msg):
    print(f"ℹ️  {msg}")


def success(msg):
    print(f"✅ {msg}")


def warn(msg):
    print(f"⚠️  {msg}")


def error(msg):
    print(f"❌ {msg}")


# Bloc de détection automatique des chemins
SETUP_PATHS_BLOCK = """# Charger les fonctions utilitaires et configurer les chemins
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
if [ -f "${SCRIPT_DIR}/utils/didactique_functions.sh" ]; then
    source "${SCRIPT_DIR}/utils/didactique_functions.sh"
    setup_paths
else
    # Fallback si les fonctions ne sont pas disponibles
    SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    INSTALL_DIR="${ARKEA_HOME:-$(cd "$SCRIPT_DIR/../.." && pwd)}"
    HCD_DIR="${HCD_DIR:-${INSTALL_DIR}/binaire/hcd-1.2.3}"
    SPARK_HOME="${SPARK_HOME:-${INSTALL_DIR}/binaire/spark-3.5.1}"
    HCD_HOST="${HCD_HOST:-localhost}"
    HCD_PORT="${HCD_PORT:-9042}"
fi"""


def migrate_script(script_path):
    """Migre un script shell"""
    script_name = script_path.name
    info(f"Traitement de {script_name}...")

    # Lire le contenu
    with open(script_path, "r", encoding="utf-8") as f:
        content = f.read()

    modified = False

    # 1. Remplacer set -e par set -euo pipefail (si pas déjà présent)
    if re.search(r"^set -e$", content, re.MULTILINE) and "set -euo pipefail" not in content:
        content = re.sub(r"^set -e$", "set -euo pipefail", content, flags=re.MULTILINE)
        modified = True
        info("  → set -e remplacé par set -euo pipefail")

    # 2. Remplacer les chemins hardcodés INSTALL_DIR
    hardcoded_pattern = r'INSTALL_DIR="/Users/david\.leconte/Documents/Arkea"'
    if re.search(hardcoded_pattern, content):
        # Trouver la section à remplacer (INSTALL_DIR jusqu'à SCRIPT_DIR suivant)
        pattern = rf"{hardcoded_pattern}\s*\nHCD_DIR=.*?\n(?:SPARK_HOME=.*?\n)?SCRIPT_DIR=.*?\n"

        if re.search(pattern, content):
            # Remplacer le bloc complet
            content = re.sub(pattern, SETUP_PATHS_BLOCK + "\n", content, flags=re.MULTILINE)
        else:
            # Remplacer juste INSTALL_DIR et les lignes suivantes jusqu'à SCRIPT_DIR
            lines = content.split("\n")
            new_lines = []
            skip_until_script_dir = False
            setup_paths_added = False

            for i, line in enumerate(lines):
                if re.search(hardcoded_pattern, line):
                    skip_until_script_dir = True
                    if not setup_paths_added:
                        new_lines.append(SETUP_PATHS_BLOCK)
                        setup_paths_added = True
                    continue

                if skip_until_script_dir:
                    if (
                        line.strip().startswith("SCRIPT_DIR=")
                        or line.strip().startswith("SCHEMA_FILE=")
                        or line.strip().startswith("PARQUET_FILE=")
                        or line.strip().startswith("RED=")
                    ):
                        skip_until_script_dir = False
                        new_lines.append(line)
                    # Sinon, on skip cette ligne (HCD_DIR, SPARK_HOME, etc.)
                    continue

                new_lines.append(line)

            content = "\n".join(new_lines)

        modified = True
        info("  → Chemins hardcodés remplacés par détection automatique")

    # 3. Remplacer localhost 9042 par $HCD_HOST $HCD_PORT
    # Pattern: localhost 9042 (avec ou sans guillemets)
    replacements = [
        (r"localhost 9042", '"$HCD_HOST" "$HCD_PORT"'),
        (r"${HCD_HOST:-localhost}:${HCD_PORT:-9042}", '"$HCD_HOST:$HCD_PORT"'),
        (r'"localhost" 9042', '"$HCD_HOST" "$HCD_PORT"'),
        (r"'localhost' 9042", '"$HCD_HOST" "$HCD_PORT"'),
        (
            r"--conf spark\.cassandra\.connection\.host=localhost",
            '--conf spark.cassandra.connection.host="$HCD_HOST"',
        ),
        (
            r"--conf spark\.cassandra\.connection\.port=9042",
            '--conf spark.cassandra.connection.port="$HCD_PORT"',
        ),
        (
            r'\.config\("spark\.cassandra\.connection\.host", "localhost"\)',
            '.config("spark.cassandra.connection.host", "$HCD_HOST")',
        ),
        (
            r'\.config\("spark\.cassandra\.connection\.port", "9042"\)',
            '.config("spark.cassandra.connection.port", "$HCD_PORT")',
        ),
    ]

    for pattern, replacement in replacements:
        if re.search(pattern, content):
            content = re.sub(pattern, replacement, content)
            modified = True
            info(f"  → {pattern} remplacé par {replacement}")

    # 4. Améliorer les vérifications HCD
    # Chercher les vérifications pgrep et les améliorer si check_hcd_prerequisites n'est pas présent
    if "check_hcd_prerequisites" not in content and 'pgrep -f "cassandra"' in content:
        # Remplacer la première occurrence de vérification HCD
        old_check = (
            r'if ! pgrep -f "cassandra" > /dev/null; then\s*\n\s*error "HCD.*?"\s*\n'
            r"\s*exit 1\s*\n\s*fi"
        )
        new_check = """# Vérifier les prérequis HCD
if ! check_hcd_prerequisites 2>/dev/null; then
    if ! pgrep -f "cassandra" > /dev/null; then
        error "HCD n'est pas démarré. Exécutez d'abord: ./scripts/setup/03_start_hcd.sh"
        exit 1
    fi
    if ! nc -z "$HCD_HOST" "$HCD_PORT" 2>/dev/null; then
        error "HCD n'est pas accessible sur $HCD_HOST:$HCD_PORT"
        exit 1
    fi
fi"""

        if re.search(old_check, content, re.MULTILINE):
            content = re.sub(old_check, new_check, content, flags=re.MULTILINE)
            modified = True
            info("  → Vérification HCD améliorée")

    # Écrire le contenu modifié
    if modified:
        if not DRY_RUN:
            # Créer une sauvegarde
            backup_path = script_path.with_suffix(script_path.suffix + ".bak")
            shutil.copy2(script_path, backup_path)

            # Écrire le nouveau contenu
            with open(script_path, "w", encoding="utf-8") as f:
                f.write(content)

            success(f"  → {script_name} mis à jour (sauvegarde: {backup_path.name})")
        else:
            warn(f"  → {script_name} serait modifié (dry-run)")
    else:
        info(f"  → {script_name} déjà à jour")

    return modified


def main():
    script_dir = Path(__file__).parent

    # Trouver tous les scripts .sh à la racine (exclure migrate_scripts.sh et les archives)
    scripts = [
        p
        for p in script_dir.glob("*.sh")
        if p.name != "migrate_scripts.sh" and p.name != "migrate_all_scripts.py"
    ]

    if not scripts:
        error("Aucun script trouvé")
        return

    info(f"Début de la migration de {len(scripts)} scripts...")
    if DRY_RUN:
        warn("Mode dry-run : aucun fichier ne sera modifié")

    modified_count = 0
    for script in sorted(scripts):
        if migrate_script(script):
            modified_count += 1

    print()
    if DRY_RUN:
        warn(f"Mode dry-run terminé : {modified_count} scripts seraient modifiés")
    else:
        success(f"Migration terminée ! {modified_count} scripts modifiés")
        info("Les fichiers originaux sont sauvegardés avec l'extension .bak")


if __name__ == "__main__":
    main()
