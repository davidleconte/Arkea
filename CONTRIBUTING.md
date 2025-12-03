# 🤝 Guide de Contribution

**Date** : 2025-12-01  
**Objectif** : Standards et processus de contribution au projet ARKEA

---

## 📋 Table des Matières

- [Code de Conduite](#code-de-conduite)
- [Processus de Contribution](#processus-de-contribution)
- [Standards de Code](#standards-de-code)
- [Commit Messages](#commit-messages)
- [Tests](#tests)
- [Documentation](#documentation)

---

## 📝 Code de Conduite

### Nos Standards

- ✅ **Respect mutuel** : Traiter tous les contributeurs avec respect
- ✅ **Communication constructive** : Feedback positif et constructif
- ✅ **Collaboration** : Travailler ensemble pour améliorer le projet
- ✅ **Professionnalisme** : Maintenir un environnement professionnel

---

## 🔄 Processus de Contribution

### 1. Fork et Clone

```bash
# Forker le projet sur GitHub
# Cloner votre fork
git clone https://github.com/votre-username/Arkea.git
cd Arkea
```

### 2. Créer une Branche

```bash
# Créer une branche pour votre feature/fix
git checkout -b feature/nom-de-votre-feature
# ou
git checkout -b fix/nom-du-bug
```

**Conventions de nommage** :

- `feature/` : Nouvelles fonctionnalités
- `fix/` : Corrections de bugs
- `docs/` : Documentation uniquement
- `refactor/` : Refactoring
- `test/` : Ajout de tests

### 3. Développer

- ✅ Suivre les standards de code (voir ci-dessous)
- ✅ Ajouter des tests si applicable
- ✅ Mettre à jour la documentation
- ✅ Vérifier que tout fonctionne

### 4. Commit

```bash
# Commits atomiques et descriptifs
git add .
git commit -m "feat: ajouter fonctionnalité X"
```

### 5. Push et Pull Request

```bash
# Pousser votre branche
git push origin feature/nom-de-votre-feature

# Créer une Pull Request sur GitHub
```

---

## 📐 Standards de Code

### Shell Scripts

**Obligatoire** :

- ✅ `set -euo pipefail` au début de chaque script
- ✅ Utiliser `setup_paths()` pour les chemins
- ✅ Documentation complète en en-tête
- ✅ Gestion d'erreurs robuste

**Exemple** :

```bash
#!/bin/bash
set -euo pipefail

# =============================================================================
# Script : Nom du Script
# =============================================================================
# Date : 2025-12-01
# Description : Description détaillée
# Usage : ./script.sh [options]
# =============================================================================

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../utils/didactique_functions.sh"
setup_paths

# Votre code ici
```

### Python

**Obligatoire** :

- ✅ PEP 8 (style guide)
- ✅ Docstrings pour toutes les fonctions
- ✅ Type hints si Python 3.6+
- ✅ Gestion d'erreurs explicite

**Exemple** :

```python
#!/usr/bin/env python3
"""
Module : Nom du Module
Description : Description détaillée
"""

def fonction_exemple(param1: str, param2: int) -> bool:
    """
    Description de la fonction.

    Args:
        param1: Description du paramètre 1
        param2: Description du paramètre 2

    Returns:
        Description de la valeur de retour
    """
    try:
        # Code ici
        return True
    except Exception as e:
        print(f"Erreur: {e}")
        return False
```

### Markdown

**Obligatoire** :

- ✅ En-tête avec date et objectif
- ✅ Table des matières pour documents longs
- ✅ Formatage cohérent
- ✅ Liens relatifs

---

## 💬 Commit Messages

### Format

```
<type>: <description courte>

<description détaillée si nécessaire>

<footer optionnel>
```

### Types

- `feat` : Nouvelle fonctionnalité
- `fix` : Correction de bug
- `docs` : Documentation uniquement
- `style` : Formatage, pas de changement de code
- `refactor` : Refactoring
- `test` : Ajout/modification de tests
- `chore` : Tâches de maintenance

### Exemples

```bash
feat: ajouter script de vérification des composants

fix: corriger gestion d'erreur dans setup_paths()

docs: mettre à jour GUIDE_STRUCTURE.md

refactor: factoriser configuration dans .poc-config.sh
```

---

## 🧪 Tests

### Structure

```
tests/
├── unit/              # Tests unitaires
│   ├── test_portability.sh
│   ├── test_consistency.sh
│   ├── test_poc_config.sh
│   └── test_portable_functions_example.sh
├── integration/       # Tests d'intégration
│   ├── test_poc_structure.sh
│   └── test_hcd_spark.sh
├── e2e/              # Tests end-to-end
│   └── test_kafka_hcd_pipeline.sh
├── fixtures/          # Données de test
└── utils/             # Framework de tests
    └── test_framework.sh
```

### Framework de Tests

Le projet utilise un framework de tests réutilisable (`tests/utils/test_framework.sh`) :

**Fonctions disponibles** :

- `test_suite_start(name)` : Début d'une suite de tests
- `test_suite_end()` : Fin avec résumé automatique
- `assert_equal()`, `assert_not_equal()` : Assertions d'égalité
- `assert_file_exists()`, `assert_dir_exists()` : Vérifications fichiers/répertoires
- `assert_port_open()`, `assert_command_exists()` : Vérifications système
- `assert_var_defined()`, `assert_file_contains()` : Vérifications variables/contenu

### Exigences

- ✅ **Tests unitaires** : Pour chaque nouvelle fonctionnalité
- ✅ **Tests d'intégration** : Pour les interactions entre composants
- ✅ **Tests E2E** : Pour les scénarios complets
- ✅ **Couverture** : Viser 80%+ de couverture
- ✅ **Framework** : Utiliser `test_framework.sh` pour tous les nouveaux tests

### Exécution

```bash
# Exécuter tous les tests
./tests/run_all_tests.sh

# Tests unitaires uniquement
./tests/run_unit_tests.sh

# Tests d'intégration uniquement
./tests/run_integration_tests.sh

# Tests E2E uniquement
./tests/run_e2e_tests.sh
```

### Créer un Nouveau Test

```bash
#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ARKEA_HOME="$(cd "$SCRIPT_DIR/../.." && pwd)"

source "$ARKEA_HOME/tests/utils/test_framework.sh"

test_suite_start "Nom de la suite de tests"

assert_equal "expected" "actual" "Description du test"

test_suite_end
```

---

## 📚 Documentation

### Obligations

- ✅ **README.md** : Mettre à jour si changement majeur
- ✅ **CHANGELOG.md** : Ajouter entrée pour chaque changement
- ✅ **Documentation inline** : Commenter le code complexe
- ✅ **Guides** : Mettre à jour les guides affectés
- ✅ **tests/README.md** : Documenter les nouveaux tests

### Dépendances

- ✅ **requirements.txt** : Ajouter les nouvelles dépendances Python
- ✅ **requirements-dev.txt** : Ajouter les dépendances de développement
- ✅ **docs/GUIDE_DEPENDENCIES.md** : Documenter les nouvelles dépendances

### Format

- Markdown pour tous les documents
- En-tête avec date et objectif
- Table des matières pour documents longs
- Exemples de code avec sortie attendue

---

## 🔍 Review Process

### Checklist pour Reviewers

- [ ] Code suit les standards
- [ ] Tests passent
- [ ] Documentation mise à jour
- [ ] Pas de régression
- [ ] Performance acceptable
- [ ] Sécurité vérifiée

### Checklist pour Auteurs

- [ ] Code testé localement
- [ ] Tests ajoutés/modifiés
- [ ] Documentation mise à jour
- [ ] CHANGELOG.md mis à jour
- [ ] Pas de warnings/erreurs
- [ ] Commit messages clairs

---

## 🚀 Pull Request

### Template

```markdown
## Description
Description détaillée des changements

## Type de changement
- [ ] Bug fix
- [ ] Nouvelle fonctionnalité
- [ ] Breaking change
- [ ] Documentation

## Tests
- [ ] Tests unitaires ajoutés
- [ ] Tests d'intégration passent
- [ ] Tests manuels effectués

## Checklist
- [ ] Code suit les standards
- [ ] Documentation mise à jour
- [ ] CHANGELOG.md mis à jour
- [ ] Pas de warnings
```

---

## 📞 Questions ?

Pour toute question :

- 📧 Email : [votre-email]
- 💬 Issues GitHub : Créer une issue
- 📖 Documentation : Voir `docs/`

---

**Merci de contribuer au projet ARKEA !** 🎉
