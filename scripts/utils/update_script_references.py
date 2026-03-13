#!/usr/bin/env python3
"""
Script pour mettre à jour les références aux anciens chemins de scripts
Remplace les références aux anciens chemins de scripts par les nouveaux.
"""

import re
from pathlib import Path
from typing import Dict, List

# Mapping des anciens chemins vers les nouveaux
SCRIPT_MAPPING: Dict[str, str] = {
    # Scripts setup
    r"\./01_install_hcd\.sh": "./scripts/setup/01_install_hcd.sh",
    r"\./02_install_spark_kafka\.sh": "./scripts/setup/02_install_spark_kafka.sh",
    r"\./03_start_hcd\.sh": "./scripts/setup/03_start_hcd.sh",
    r"\./04_start_kafka\.sh": "./scripts/setup/04_start_kafka.sh",
    r"\./05_setup_kafka_hcd_streaming\.sh": "./scripts/setup/05_setup_kafka_hcd_streaming.sh",
    r"\./06_test_kafka_hcd_streaming\.sh": "./scripts/setup/06_test_kafka_hcd_streaming.sh",
    # Scripts utils
    r"\./70_kafka-helper\.sh": "./scripts/utils/70_kafka-helper.sh",
    r"\./80_verify_all\.sh": "./scripts/utils/80_verify_all.sh",
    r"\./90_list_scripts\.sh": "./scripts/utils/90_list_scripts.sh",
    # Références dans les messages d'erreur
    r"\./01_install_hcd\.sh": "./scripts/setup/01_install_hcd.sh",
    r"\./02_install_spark_kafka\.sh": "./scripts/setup/02_install_spark_kafka.sh",
    r"\./03_start_hcd\.sh": "./scripts/setup/03_start_hcd.sh",
    r"\./04_start_kafka\.sh": "./scripts/setup/04_start_kafka.sh",
    r"\./05_setup_kafka_hcd_streaming\.sh": "./scripts/setup/05_setup_kafka_hcd_streaming.sh",
    r"\./06_test_kafka_hcd_streaming\.sh": "./scripts/setup/06_test_kafka_hcd_streaming.sh",
    r"\./70_kafka-helper\.sh": "./scripts/utils/70_kafka-helper.sh",
    r"\./80_verify_all\.sh": "./scripts/utils/80_verify_all.sh",
    r"\./90_list_scripts\.sh": "./scripts/utils/90_list_scripts.sh",
}

# Répertoires à traiter
DIRS_TO_PROCESS: List[str] = [
    "poc-design",
    "docs",
    ".",
]

# Extensions de fichiers à traiter
EXTENSIONS: List[str] = [".sh", ".md", ".py", ".txt"]


def update_file_references(file_path: Path) -> bool:
    """Met à jour les références dans un fichier.

    Args:
        file_path: Chemin vers le fichier à traiter.

    Returns:
        True si le fichier a été modifié, False sinon.
    """
    try:
        with open(file_path, "r", encoding="utf-8") as f:
            content = f.read()

        updated = False

        # Appliquer chaque remplacement
        for old_pattern, new_path in SCRIPT_MAPPING.items():
            # Compter les occurrences avant
            count_before = len(re.findall(old_pattern, content))
            if count_before > 0:
                # Remplacer
                content = re.sub(old_pattern, new_path, content)
                count_after = len(re.findall(old_pattern, content))
                if count_after < count_before:
                    updated = True
                    replaced = count_before - count_after
                    print(f"  ✅ {old_pattern} → {new_path} ({replaced} remplacements)")

        # Écrire si modifié
        if updated:
            with open(file_path, "w", encoding="utf-8") as f:
                f.write(content)
            return True

        return False
    except Exception as e:
        print(f"  ❌ Erreur: {e}")
        return False


def main() -> None:
    """Fonction principale — met à jour les références de scripts dans le projet."""
    base_dir = Path(__file__).parent.parent.parent

    print("🔄 Mise à jour des références aux scripts...")
    print(f"   Répertoire de base: {base_dir}")
    print("")

    total_files = 0
    updated_files = 0

    for dir_name in DIRS_TO_PROCESS:
        dir_path = base_dir / dir_name
        if not dir_path.exists():
            continue

        print(f"📁 Traitement de: {dir_name}/")

        for ext in EXTENSIONS:
            for file_path in dir_path.rglob(f"*{ext}"):
                # Ignorer certains fichiers
                if any(
                    skip in str(file_path) for skip in [".git", "archive", ".bak", "node_modules"]
                ):
                    continue

                total_files += 1
                relative_path = file_path.relative_to(base_dir)

                if update_file_references(file_path):
                    updated_files += 1
                    print(f"  📝 {relative_path}")

        print("")

    print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
    print("✅ Mise à jour terminée")
    print(f"   Fichiers traités: {total_files}")
    print(f"   Fichiers mis à jour: {updated_files}")
    print("")


if __name__ == "__main__":
    main()
