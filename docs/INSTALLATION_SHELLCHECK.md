# 🔧 Installation de ShellCheck

**Date** : 2025-12-01  
**Objectif** : Guide d'installation de ShellCheck pour pre-commit  
**Version** : 1.0

---

## 📋 Qu'est-ce que ShellCheck ?

**ShellCheck** est un outil de linting pour les scripts shell (bash, sh, etc.). Il détecte les erreurs courantes, les mauvaises pratiques et les problèmes potentiels dans le code shell.

---

## 🍎 Installation sur macOS

### Méthode 1 : Homebrew (Recommandée)

```bash
brew install shellcheck
```

### Méthode 2 : MacPorts

```bash
sudo port install shellcheck
```

### Vérification

```bash
shellcheck --version
# Doit afficher : ShellCheck - shell script analysis tool
```

---

## 🐧 Installation sur Linux

### Ubuntu/Debian

```bash
sudo apt-get update
sudo apt-get install shellcheck
```

### Fedora/RHEL/CentOS

```bash
sudo dnf install shellcheck
# ou
sudo yum install shellcheck
```

### Arch Linux

```bash
sudo pacman -S shellcheck
```

### Vérification

```bash
shellcheck --version
```

---

## 🪟 Installation sur Windows

### Méthode 1 : Via WSL (Recommandée)

Installer dans WSL (Ubuntu) :
```bash
sudo apt-get update
sudo apt-get install shellcheck
```

### Méthode 2 : Via Chocolatey

```powershell
choco install shellcheck
```

### Méthode 3 : Via Scoop

```powershell
scoop install shellcheck
```

---

## ✅ Vérification de l'Installation

### Test Simple

```bash
# Vérifier que shellcheck est installé
shellcheck --version

# Tester sur un script
shellcheck scripts/setup/01_install_hcd.sh
```

### Test avec Pre-commit

```bash
# Exécuter pre-commit avec shellcheck
pre-commit run shellcheck --all-files
```

---

## 🔧 Configuration Pre-commit

ShellCheck est déjà configuré dans `.pre-commit-config.yaml` :

```yaml
- repo: https://github.com/shellcheck-py/shellcheck-py
  rev: v0.9.0.6
  hooks:
    - id: shellcheck
      args: [-e, SC1091]  # Ignore "Can't follow non-constant source"
```

**Note** : Si shellcheck n'est pas installé système, pre-commit tentera de l'installer automatiquement, mais cela peut échouer. Il est recommandé d'installer shellcheck manuellement.

---

## 🚀 Utilisation

### Linting Manuel

```bash
# Linter un fichier spécifique
shellcheck scripts/setup/01_install_hcd.sh

# Linter tous les scripts
find scripts/ -name "*.sh" -exec shellcheck {} \;

# Linter avec format de sortie
shellcheck -f gcc scripts/**/*.sh
```

### Avec Pre-commit

Les hooks pre-commit s'exécutent automatiquement à chaque commit. Pour tester manuellement :

```bash
# Tous les fichiers
pre-commit run shellcheck --all-files

# Fichiers modifiés uniquement
pre-commit run shellcheck
```

---

## 📊 Codes d'Erreur ShellCheck

ShellCheck utilise des codes d'erreur (SC####) :

| Code | Description | Exemple |
|------|-------------|---------|
| SC1091 | Cannot follow non-constant source | `source "$VAR"` |
| SC2086 | Double quote to prevent globbing | `rm $file` → `rm "$file"` |
| SC2155 | Declare and assign separately | `export VAR=$(cmd)` |
| SC2164 | Use 'cd ... || exit' | `cd dir` → `cd dir || exit` |

**Liste complète** : https://github.com/koalaman/shellcheck/wiki

---

## 🔍 Exemples de Corrections

### Exemple 1 : Double Quotes

**Avant** :
```bash
rm $file
```

**Après** :
```bash
rm "$file"
```

### Exemple 2 : cd avec Gestion d'Erreur

**Avant** :
```bash
cd "$DIR"
```

**Après** :
```bash
cd "$DIR" || exit 1
```

### Exemple 3 : set -euo pipefail

**Avant** :
```bash
#!/bin/bash
# Pas de gestion d'erreur
```

**Après** :
```bash
#!/bin/bash
set -euo pipefail
# Gestion d'erreur robuste
```

---

## 🐛 Dépannage

### Erreur : "shellcheck: command not found"

**Solution** :
```bash
# Vérifier l'installation
which shellcheck

# Réinstaller si nécessaire
brew install shellcheck  # macOS
sudo apt-get install shellcheck  # Linux
```

### Erreur Pre-commit : "Failed to install shellcheck"

**Solution** :
1. Installer shellcheck manuellement (voir ci-dessus)
2. Vérifier que shellcheck est dans le PATH
3. Réessayer : `pre-commit run shellcheck --all-files`

### Ignorer une Erreur Spécifique

Dans le script :
```bash
# shellcheck disable=SC2086
rm $file  # Intentionnel
```

Ou dans `.pre-commit-config.yaml` :
```yaml
args: [-e, SC1091, -e, SC2086]  # Ignorer plusieurs codes
```

---

## 📚 Ressources

- **Site officiel** : https://www.shellcheck.net/
- **GitHub** : https://github.com/koalaman/shellcheck
- **Wiki** : https://github.com/koalaman/shellcheck/wiki
- **Codes d'erreur** : https://github.com/koalaman/shellcheck/wiki/Checks

---

## ✅ Checklist

- [ ] ShellCheck installé (`shellcheck --version`)
- [ ] Test manuel réussi (`shellcheck scripts/setup/01_install_hcd.sh`)
- [ ] Pre-commit fonctionne (`pre-commit run shellcheck --all-files`)
- [ ] Hooks pre-commit installés (`.git/hooks/pre-commit`)

---

**Date** : 2025-12-01  
**Version** : 1.0  
**Statut** : ✅ **Documentation complète**

