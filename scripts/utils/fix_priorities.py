#!/usr/bin/env python3
"""
Script : Correction des 3 Priorités Critiques - ARKEA
Date : 2025-12-02
Usage : python3 fix_priorities.py [--dry-run] [--priority 1|2|3|all]
Description : Corrige automatiquement les 3 priorités critiques identifiées dans l'audit
"""

import argparse
import os
import re
from pathlib import Path
from typing import Dict, List, Optional, Set

# Configuration
ARKEA_HOME = Path(__file__).parent.parent.parent.resolve()

# Patterns de correction
HARDCODED_PATTERNS: Dict[str, str] = {
    r"/Users/david\.leconte/Documents/Arkea": "${ARKEA_HOME}",
    r"/Users/david\.leconte": "${USER_HOME:-$HOME}",
    r'INSTALL_DIR="/Users/david\.leconte/Documents/Arkea"': 'INSTALL_DIR="${ARKEA_HOME}"',
    r"INSTALL_DIR=/Users/david\.leconte/Documents/Arkea": "INSTALL_DIR=${ARKEA_HOME}",
}

LOCALHOST_PATTERNS: Dict[str, str] = {
    r"localhost:9042": "${HCD_HOST:-localhost}:${HCD_PORT:-9042}",
    r'"localhost:9042"': '"${HCD_HOST:-localhost}:${HCD_PORT:-9042}"',
    r"'localhost:9042'": "'${HCD_HOST:-localhost}:${HCD_PORT:-9042}'",
    r"localhost:9092": "${KAFKA_BOOTSTRAP_SERVERS:-localhost:9092}",
    r'"localhost:9092"': '"${KAFKA_BOOTSTRAP_SERVERS:-localhost:9092}"',
    r"'localhost:9092'": "'${KAFKA_BOOTSTRAP_SERVERS:-localhost:9092}'",
    r"localhost:2181": "${KAFKA_ZOOKEEPER_CONNECT:-localhost:2181}",
    r'"localhost:2181"': '"${KAFKA_ZOOKEEPER_CONNECT:-localhost:2181}"',
    r"'localhost:2181'": "'${KAFKA_ZOOKEEPER_CONNECT:-localhost:2181}'",
    r"HCD est démarré sur localhost:9042": (
        "HCD est démarré sur ${HCD_HOST:-localhost}:${HCD_PORT:-9042}"
    ),
    r"cassandra sur localhost:9042": "cassandra sur ${HCD_HOST:-localhost}:${HCD_PORT:-9042}",
}

# Patterns Scala spécifiques
SCALA_LOCALHOST_PATTERNS: Dict[str, str] = {
    r"localhost:9042": (
        r'sys.env.getOrElse("HCD_HOST", "localhost") + ":" + '
        r'sys.env.getOrElse("HCD_PORT", "9042")'
    ),
    r"localhost:9092": r'sys.env.getOrElse("KAFKA_BOOTSTRAP_SERVERS", "localhost:9092")',
}


def find_files(
    directory: Path,
    extensions: List[str],
    exclude_dirs: Optional[Set[str]] = None,
) -> List[Path]:
    """Trouve tous les fichiers avec les extensions spécifiées.

    Args:
        directory: Répertoire racine à parcourir.
        extensions: Liste des extensions de fichier à inclure.
        exclude_dirs: Ensemble de noms de répertoires à exclure.

    Returns:
        Liste des chemins de fichiers trouvés.
    """
    if exclude_dirs is None:
        exclude_dirs = {".git", "binaire", "software", "logs", "archive", "__pycache__", ".backup"}

    files: List[Path] = []
    for root, dirs, filenames in os.walk(directory):
        # Exclure les répertoires
        dirs[:] = [d for d in dirs if d not in exclude_dirs]

        for filename in filenames:
            if any(filename.endswith(ext) for ext in extensions):
                filepath = Path(root) / filename
                files.append(filepath)

    return files


def fix_hardcoded_paths(filepath: Path, dry_run: bool = False) -> bool:
    """Corrige les chemins hardcodés dans un fichier.

    Args:
        filepath: Chemin vers le fichier à corriger.
        dry_run: Si True, simule sans modifier.

    Returns:
        True si le fichier a été modifié, False sinon.
    """
    try:
        with open(filepath, "r", encoding="utf-8") as f:
            content = f.read()
    except Exception as e:
        print(f"⚠️  Erreur lecture {filepath}: {e}")
        return False

    original_content = content
    changes = []

    for pattern, replacement in HARDCODED_PATTERNS.items():
        if re.search(pattern, content):
            content = re.sub(pattern, replacement, content)
            changes.append(f"{pattern} → {replacement}")

    if content != original_content:
        if not dry_run:
            try:
                with open(filepath, "w", encoding="utf-8") as f:
                    f.write(content)
                print(f"✅ Corrigé: {filepath.relative_to(ARKEA_HOME)}")
                for change in changes:
                    print(f"   - {change}")
            except Exception as e:
                print(f"❌ Erreur écriture {filepath}: {e}")
                return False
        else:
            print(f"[DRY-RUN] Corrigerait: {filepath.relative_to(ARKEA_HOME)}")
            for change in changes:
                print(f"   - {change}")
        return True

    return False


def fix_localhost_references(filepath: Path, dry_run: bool = False) -> bool:
    """Corrige les références localhost hardcodées dans un fichier.

    Args:
        filepath: Chemin vers le fichier à corriger.
        dry_run: Si True, simule sans modifier.

    Returns:
        True si le fichier a été modifié, False sinon.
    """
    try:
        with open(filepath, "r", encoding="utf-8") as f:
            content = f.read()
    except Exception as e:
        print(f"⚠️  Erreur lecture {filepath}: {e}")
        return False

    original_content = content
    changes = []

    # Utiliser les patterns Scala pour les fichiers Scala
    if filepath.suffix == ".scala":
        patterns = SCALA_LOCALHOST_PATTERNS
    else:
        patterns = LOCALHOST_PATTERNS

    for pattern, replacement in patterns.items():
        if re.search(pattern, content):
            content = re.sub(pattern, replacement, content)
            changes.append(f"{pattern} → {replacement}")

    if content != original_content:
        if not dry_run:
            try:
                with open(filepath, "w", encoding="utf-8") as f:
                    f.write(content)
                print(f"✅ Corrigé: {filepath.relative_to(ARKEA_HOME)}")
                for change in changes:
                    print(f"   - {change}")
            except Exception as e:
                print(f"❌ Erreur écriture {filepath}: {e}")
                return False
        else:
            print(f"[DRY-RUN] Corrigerait: {filepath.relative_to(ARKEA_HOME)}")
            for change in changes:
                print(f"   - {change}")
        return True

    return False


def remove_strange_files(dry_run: bool = False) -> int:
    """Supprime les fichiers étranges identifiés.

    Args:
        dry_run: Si True, simule sans supprimer.

    Returns:
        Nombre de fichiers supprimés (ou qui seraient supprimés).
    """
    strange_files = [
        ARKEA_HOME / "binaire" / "spark-3.5.1" / "=",
        ARKEA_HOME / "poc-design" / "domirama2" / "=",
        ARKEA_HOME / "poc-design" / "domirama2" / "${REPORT_FILE}",
    ]

    removed = 0
    for filepath in strange_files:
        if filepath.exists() and filepath.is_file():
            if not dry_run:
                try:
                    filepath.unlink()
                    print(f"✅ Supprimé: {filepath.relative_to(ARKEA_HOME)}")
                    removed += 1
                except Exception as e:
                    print(f"❌ Erreur suppression {filepath}: {e}")
            else:
                print(f"[DRY-RUN] Supprimerait: {filepath.relative_to(ARKEA_HOME)}")
                removed += 1

    return removed


def main() -> None:
    """Fonction principale — corrige les priorités critiques du projet."""
    parser = argparse.ArgumentParser(
        description="Corrige les 3 priorités critiques du projet ARKEA"
    )
    parser.add_argument(
        "--dry-run", action="store_true", help="Simule les corrections sans modifier"
    )
    parser.add_argument(
        "--priority",
        choices=["1", "2", "3", "all"],
        default="all",
        help="Priorité à corriger (1=chemins, 2=localhost, 3=fichiers étranges, all=tout)",
    )

    args = parser.parse_args()

    print("=" * 70)
    print("Correction des 3 Priorités Critiques - ARKEA")
    print("=" * 70)
    print(f"Répertoire ARKEA: {ARKEA_HOME}")
    print(f"Mode: {'DRY-RUN' if args.dry_run else 'EXECUTION'}")
    print(f"Priorité: {args.priority}")
    print("=" * 70)
    print()

    fixed_count = 0

    # Priorité 1 : Chemins hardcodés
    if args.priority in ["1", "all"]:
        print("\n🔴 PRIORITÉ 1 : Correction des chemins hardcodés")
        print("-" * 70)
        files = find_files(
            ARKEA_HOME,
            [".sh", ".md", ".py"],
            exclude_dirs={
                ".git",
                "binaire",
                "software",
                "logs",
                "archive",
                "__pycache__",
                ".backup",
            },
        )
        for filepath in files:
            if fix_hardcoded_paths(filepath, args.dry_run):
                fixed_count += 1

    # Priorité 2 : Références localhost
    if args.priority in ["2", "all"]:
        print("\n🔴 PRIORITÉ 2 : Correction des références localhost")
        print("-" * 70)
        files = find_files(
            ARKEA_HOME,
            [".sh", ".scala", ".py"],
            exclude_dirs={
                ".git",
                "binaire",
                "software",
                "logs",
                "archive",
                "__pycache__",
                ".backup",
            },
        )
        for filepath in files:
            if fix_localhost_references(filepath, args.dry_run):
                fixed_count += 1

    # Priorité 3 : Fichiers étranges
    if args.priority in ["3", "all"]:
        print("\n🔴 PRIORITÉ 3 : Suppression des fichiers étranges")
        print("-" * 70)
        removed = remove_strange_files(args.dry_run)
        fixed_count += removed

    print("\n" + "=" * 70)
    if args.dry_run:
        print(f"✅ [DRY-RUN] {fixed_count} correction(s) seraient effectuée(s)")
        print("Pour exécuter réellement, relancez sans --dry-run")
    else:
        print(f"✅ {fixed_count} correction(s) effectuée(s)")
    print("=" * 70)


if __name__ == "__main__":
    main()
