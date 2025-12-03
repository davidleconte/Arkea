# Guide de Correction des Erreurs Markdownlint

Ce guide explique comment corriger les erreurs markdownlint les plus courantes dans le projet ARKEA.

## Configuration

Le fichier `.markdownlint.json` configure les règles markdownlint :

- **MD013** (line-length) : Limite à 100 caractères (au lieu de 80)
- **MD024** (duplicate-heading) : Permet les titres dupliqués dans différentes sections
- **MD036** (no-emphasis-as-heading) : Désactivé (tolère l'emphase comme titre)
- **MD033** (no-inline-html) : Désactivé (tolère le HTML inline)
- **MD040** (fenced-code-language) : Désactivé (tolère les blocs de code sans langage)
- **MD051** (link-fragments) : Désactivé (tolère les fragments de liens invalides)

## Erreurs Courantes et Solutions

### 1. MD013 - Lignes trop longues

**Erreur :** `Line length [Expected: 80; Actual: 103]`

**Solution :** Couper la ligne à 100 caractères maximum.

**Avant :**

```markdown
- **tests/utils/test_framework.sh** - Framework réutilisable avec fonctions d'assertion (10+ fonctions)
```

**Après :**

```markdown
- **tests/utils/test_framework.sh** - Framework réutilisable avec fonctions
  d'assertion (10+ fonctions)
```

**Ou utiliser des listes :**

```markdown
- **tests/utils/test_framework.sh**
  - Framework réutilisable avec fonctions d'assertion
  - 10+ fonctions disponibles
```

### 2. MD024 - Titres dupliqués

**Erreur :** `Multiple headings with the same content [Context: "Documentation"]`

**Solution :** Ajouter un contexte unique ou utiliser des sous-titres.

**Avant :**

```markdown
## Documentation

### Ajouté

## Documentation
```

**Après :**

```markdown
## Documentation

### Ajouté

## Documentation (Suite)
```

**Ou utiliser des numéros :**

```markdown
## Documentation - Partie 1

### Ajouté

## Documentation - Partie 2
```

### 3. MD036 - Emphase au lieu de titre

**Erreur :** `Emphasis used instead of a heading [Context: "Documentation BIC"]`

**Solution :** Remplacer l'emphase par un titre approprié.

**Avant :**

```markdown
#### **Documentation BIC**
```

**Après :**

```markdown
#### Documentation BIC
```

**Ou utiliser un titre de niveau approprié :**

```markdown
### Documentation BIC
```

### 4. MD040 - Bloc de code sans langage

**Erreur :** `Fenced code blocks should have a language specified`

**Solution :** Ajouter le langage au bloc de code.

**Avant :**

```
```bash
echo "test"
```

```

**Après :**
```markdown
```bash
echo "test"
```

```

### 5. MD051 - Fragments de liens invalides

**Erreur :** `Link fragments should be valid`

**Solution :** Vérifier que l'ancre existe dans le document.

**Avant :**
```markdown
[Commit Messages](#commit-messages)
```

**Après :**

```markdown
[Commit Messages](#commit-messages)

## Commit Messages
```

## Scripts d'Automatisation

### Correction automatique avec markdownlint-cli2

```bash
# Installer markdownlint-cli2-fix
npm install -g markdownlint-cli2-fix

# Corriger automatiquement les fichiers
npx markdownlint-cli2-fix "docs/**/*.md" "*.md"
```

### Script Python de correction

Un script `scripts/utils/fix_markdownlint.py` est disponible pour corriger
automatiquement certaines erreurs :

```bash
python3 scripts/utils/fix_markdownlint.py
```

## Vérification

### Vérifier les erreurs

```bash
# Tous les fichiers markdown du projet (sans binaire/)
npx markdownlint-cli2 "docs/**/*.md" "*.md" "poc-design/**/*.md" "tests/**/*.md"

# Un fichier spécifique
npx markdownlint-cli2 "CHANGELOG.md"

# Avec affichage détaillé
npx markdownlint-cli2 "docs/**/*.md" --fix
```

### Ignorer certains fichiers

Ajouter dans `.markdownlintignore` :

```
binaire/
*.min.js
node_modules/
```

## Bonnes Pratiques

1. **Longueur de ligne** : Garder les lignes à moins de 100 caractères
2. **Titres uniques** : Utiliser des titres uniques dans chaque section
3. **Blocs de code** : Toujours spécifier le langage
4. **Liens** : Vérifier que les ancres existent
5. **Emphase** : Utiliser des titres plutôt que de l'emphase pour les sections

## Exemples de Corrections

### Exemple 1 : Ligne trop longue

**Avant :**

```markdown
- **tests/utils/test_framework.sh** - Framework réutilisable avec fonctions d'assertion (10+ fonctions)
```

**Après :**

```markdown
- **tests/utils/test_framework.sh**
  - Framework réutilisable avec fonctions d'assertion
  - 10+ fonctions disponibles
```

### Exemple 2 : Titre dupliqué

**Avant :**

```markdown
## Documentation

### Ajouté

## Documentation
```

**Après :**

```markdown
## Documentation

### Ajouté

## Documentation Complémentaire
```

### Exemple 3 : Emphase au lieu de titre

**Avant :**

```markdown
#### **Documentation BIC**
```

**Après :**

```markdown
#### Documentation BIC
```

## Ressources

- [Documentation markdownlint](https://github.com/DavidAnson/markdownlint)
- [Règles markdownlint](https://github.com/DavidAnson/markdownlint/blob/main/doc/Rules.md)
- [Configuration markdownlint](https://github.com/DavidAnson/markdownlint#optionsconfig)
