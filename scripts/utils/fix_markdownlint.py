#!/usr/bin/env python3
"""
Script pour corriger automatiquement certaines erreurs markdownlint courantes.
"""

import re
import sys
from pathlib import Path


def fix_line_length(content: str, max_length: int = 100) -> str:
    """Coupe les lignes trop longues en préservant le contexte."""
    lines = content.split("\n")
    fixed_lines = []

    for line in lines:
        # Ignorer les lignes de code, tableaux, et liens
        if (
            line.strip().startswith("```")
            or line.strip().startswith("|")
            or line.strip().startswith("http")
            or line.strip().startswith("<")
            or len(line.strip()) == 0
        ):
            fixed_lines.append(line)
            continue

        # Si la ligne est trop longue
        if len(line) > max_length:
            # Essayer de couper sur un espace avant max_length
            if " " in line[:max_length]:
                last_space = line.rfind(" ", 0, max_length)
                if last_space > max_length * 0.7:  # Au moins 70% de la ligne
                    fixed_lines.append(line[:last_space])
                    # Indenter la suite si c'est une liste
                    indent = len(line) - len(line.lstrip())
                    continuation = " " * (indent + 2) + line[last_space + 1 :]
                    fixed_lines.append(continuation)
                else:
                    fixed_lines.append(line)
            else:
                fixed_lines.append(line)
        else:
            fixed_lines.append(line)

    return "\n".join(fixed_lines)


def fix_emphasis_as_heading(content: str) -> str:
    """Remplace l'emphase utilisée comme titre par un vrai titre."""
    # Pattern: #### **Titre** ou ### **Titre**
    pattern = r"^(#{1,6})\s+\*\*(.+?)\*\*\s*$"

    def replace_emphasis(match):
        level = match.group(1)
        text = match.group(2)
        return f"{level} {text}"

    lines = content.split("\n")
    fixed_lines = []
    for line in lines:
        fixed_line = re.sub(pattern, replace_emphasis, line)
        fixed_lines.append(fixed_line)

    return "\n".join(fixed_lines)


def fix_code_blocks(content: str) -> str:
    """Ajoute 'bash' comme langage par défaut pour les blocs de code vides."""
    # Pattern: ``` suivi d'une nouvelle ligne (pas de langage)
    pattern = r"```\n(.*?)```"

    def add_language(match):
        code = match.group(1)
        # Détecter le type de code basé sur le contenu
        if any(keyword in code for keyword in ["#!/bin/bash", "echo", "$", "export"]):
            return f"```bash\n{code}```"
        elif any(keyword in code for keyword in ["def ", "import ", "print("]):
            return f"```python\n{code}```"
        elif any(keyword in code for keyword in ["SELECT", "FROM", "WHERE"]):
            return f"```sql\n{code}```"
        else:
            return f"```\n{code}```"

    return re.sub(pattern, add_language, content, flags=re.DOTALL)


def fix_duplicate_headings(content: str) -> str:
    """Ajoute un suffixe aux titres dupliqués."""
    lines = content.split("\n")
    heading_counts: dict[str, int] = {}
    fixed_lines = []

    for line in lines:
        # Détecter les titres markdown
        match = re.match(r"^(#{1,6})\s+(.+)$", line)
        if match:
            level = match.group(1)
            text = match.group(2).strip()

            # Compter les occurrences
            key = f"{level} {text}"
            if key in heading_counts:
                heading_counts[key] += 1
                # Ajouter un suffixe au titre dupliqué
                text = f"{text} ({heading_counts[key]})"
            else:
                heading_counts[key] = 1

            fixed_lines.append(f"{level} {text}")
        else:
            fixed_lines.append(line)

    return "\n".join(fixed_lines)


def process_file(file_path: Path) -> bool:
    """Traite un fichier markdown et corrige les erreurs."""
    try:
        with open(file_path, "r", encoding="utf-8") as f:
            content = f.read()

        original_content = content

        # Appliquer les corrections
        content = fix_emphasis_as_heading(content)
        content = fix_code_blocks(content)
        content = fix_line_length(content)
        # Note: fix_duplicate_headings peut être trop agressif, désactivé par défaut
        # content = fix_duplicate_headings(content)

        # Écrire seulement si des changements ont été faits
        if content != original_content:
            with open(file_path, "w", encoding="utf-8") as f:
                f.write(content)
            return True

        return False
    except Exception as e:
        print(f"Erreur lors du traitement de {file_path}: {e}", file=sys.stderr)
        return False


def main():
    """Fonction principale."""
    import argparse

    parser = argparse.ArgumentParser(description="Corrige les erreurs markdownlint")
    parser.add_argument("files", nargs="*", help="Fichiers à traiter (par défaut: tous les .md)")
    parser.add_argument(
        "--dry-run", action="store_true", help="Affiche les changements sans les appliquer"
    )

    args = parser.parse_args()

    if args.files:
        files = [Path(f) for f in args.files]
    else:
        # Par défaut, traiter tous les fichiers .md du projet (sauf binaire/)
        project_root = Path(__file__).parent.parent.parent
        files = list(project_root.rglob("*.md"))
        files = [f for f in files if "binaire/" not in str(f)]

    modified_count = 0
    for file_path in files:
        if file_path.is_file():
            if args.dry_run:
                print(f"Vérification: {file_path}")
            else:
                if process_file(file_path):
                    print(f"✓ Corrigé: {file_path}")
                    modified_count += 1

    if not args.dry_run:
        print(f"\n{modified_count} fichier(s) modifié(s)")
    else:
        print("\nMode dry-run: aucun fichier modifié")


if __name__ == "__main__":
    main()
