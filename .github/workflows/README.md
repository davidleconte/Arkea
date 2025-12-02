# 🔄 GitHub Actions Workflows

**Date** : 2025-12-01  
**Objectif** : Documentation des workflows CI/CD

---

## 📋 Workflows Disponibles

### 1. `test.yml` - Tests

**Déclenchement** :

- Push sur `main` ou `develop`
- Pull Request vers `main` ou `develop`

**Jobs** :

- **syntax-check** : Vérification de la syntaxe des scripts shell et Python
- **config-check** : Vérification des fichiers de configuration
- **docs-check** : Vérification de la documentation
- **structure-check** : Vérification de la structure du projet

**Utilisation** :

```bash
# Les workflows s'exécutent automatiquement sur push/PR
# Voir les résultats dans l'onglet "Actions" de GitHub
```

---

### 2. `lint.yml` - Linting

**Déclenchement** :

- Push sur `main` ou `develop`
- Pull Request vers `main` ou `develop`

**Jobs** :

- **shellcheck** : Linting des scripts shell
- **python-lint** : Linting Python (black, isort, flake8)
- **markdown-lint** : Linting Markdown

**Utilisation** :

```bash
# Les workflows s'exécutent automatiquement sur push/PR
# Voir les résultats dans l'onglet "Actions" de GitHub
```

---

## 🚀 Activation

### Pour GitHub

1. **Créer un repository GitHub** (si pas déjà fait)
2. **Pousser le code** :

```bash
git remote add origin https://github.com/votre-org/Arkea.git
git push -u origin main
```

3. **Les workflows s'activent automatiquement** sur push/PR

### Pour GitLab (Alternative)

Les workflows peuvent être adaptés pour GitLab CI/CD (`.gitlab-ci.yml`)

---

## 🔧 Personnalisation

### Modifier les Triggers

Éditer `.github/workflows/*.yml` :

```yaml
on:
  push:
    branches: [ main, develop, feature/* ]  # Ajouter des branches
  pull_request:
    branches: [ main, develop ]
  schedule:
    - cron: '0 0 * * *'  # Exécution quotidienne
```

### Ajouter des Jobs

Exemple d'ajout d'un job de test :

```yaml
jobs:
  # ... jobs existants ...

  integration-tests:
    name: Integration Tests
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - name: Run Integration Tests
        run: ./tests/run_integration_tests.sh
```

---

## 📊 Monitoring

### Voir les Résultats

1. Aller sur GitHub → Onglet "Actions"
2. Sélectionner le workflow
3. Voir les résultats de chaque job

### Badges (Optionnel)

Ajouter dans `README.md` :

```markdown
![Tests](https://github.com/votre-org/Arkea/workflows/Tests/badge.svg)
![Lint](https://github.com/votre-org/Arkea/workflows/Lint/badge.svg)
```

---

## 🔍 Dépannage

### Workflow ne s'exécute pas

**Vérifier** :

- ✅ Repository est sur GitHub (pas seulement local)
- ✅ Fichiers `.github/workflows/*.yml` sont présents
- ✅ Syntaxe YAML est correcte
- ✅ Branche est `main` ou `develop` (selon configuration)

### Erreurs dans les Workflows

**Vérifier les logs** :

- Onglet "Actions" → Workflow → Job → Logs

**Problèmes courants** :

- Chemins incorrects → Vérifier les chemins dans les workflows
- Permissions → Vérifier les permissions des actions
- Versions → Vérifier les versions des actions utilisées

---

## 📚 Références

- [GitHub Actions Documentation](https://docs.github.com/en/actions)
- [Workflow Syntax](https://docs.github.com/en/actions/using-workflows/workflow-syntax-for-github-actions)
- [Actions Marketplace](https://github.com/marketplace?type=actions)

---

**Date** : 2025-12-01  
**Version** : 1.0  
**Statut** : ✅ **Documentation complète**
