# 📝 Guide : Mettre à Jour le CHANGELOG.md

**Date** : 2025-12-01  
**Objectif** : Guide pour maintenir le CHANGELOG.md à jour  
**Version** : 1.0

---

## 📋 Principes

Le CHANGELOG.md suit le format [Keep a Changelog](https://keepachangelog.com/fr/1.0.0/) et le projet adhère à [Semantic Versioning](https://semver.org/lang/fr/).

---

## 🔄 Quand Mettre à Jour

### À Chaque Release

- ✅ Nouvelle version (ex: 1.0.0 → 1.1.0)
- ✅ Correction de bug importante
- ✅ Nouvelle fonctionnalité
- ✅ Changement breaking

### À Chaque Commit Significatif

- ✅ Ajout de fonctionnalité
- ✅ Correction de bug
- ✅ Changement de documentation majeur
- ✅ Refactoring important

---

## 📝 Format des Entrées

### Structure

```markdown
## [Version] - YYYY-MM-DD

### Ajouté
- Description du changement

### Modifié
- Description du changement

### Corrigé
- Description du changement

### Supprimé
- Description du changement

### Sécurité
- Description du changement
```

### Types de Changements

| Type | Description | Exemple |
|------|-------------|---------|
| **Ajouté** | Nouvelles fonctionnalités | `- Ajout du script de vérification` |
| **Modifié** | Changements dans fonctionnalités existantes | `- Amélioration de setup_paths()` |
| **Déprécié** | Fonctionnalités qui seront supprimées | `- Dépréciation de l'ancien format` |
| **Supprimé** | Fonctionnalités supprimées | `- Suppression de hcd-1.2.3/ (doublon)` |
| **Corrigé** | Corrections de bugs | `- Correction de la gestion d'erreur` |
| **Sécurité** | Corrections de vulnérabilités | `- Correction de l'exposition de secrets` |

---

## 🎯 Exemples

### Exemple 1 : Nouvelle Fonctionnalité

```markdown
## [1.1.0] - 2025-12-15

### Ajouté
- Script `scripts/utils/clean_logs.sh` pour archiver les logs
- Support de la configuration via variables d'environnement
- Documentation `docs/NEW_FEATURE.md`

### Modifié
- Amélioration de `setup_paths()` pour détection automatique
- Mise à jour de `README.md` avec nouvelles fonctionnalités
```

### Exemple 2 : Correction de Bug

```markdown
## [1.0.1] - 2025-12-10

### Corrigé
- Correction de la gestion d'erreur dans `scripts/setup/03_start_hcd.sh`
- Correction du chemin dans `.poc-config.sh` pour Linux
- Correction de la documentation des workflows GitHub Actions
```

### Exemple 3 : Release Majeure

```markdown
## [2.0.0] - 2026-01-01

### Ajouté
- Support de HCD 2.0.0
- Nouvelle architecture de tests
- Documentation complète de l'API

### Modifié
- Refactoring complet de la configuration
- Migration vers Python 3.12

### Supprimé
- Support de HCD 1.2.3 (remplacé par 2.0.0)
- Ancien format de configuration

### Breaking Changes
- `setup_paths()` nécessite maintenant Python 3.12+
- Configuration migrée vers `.poc-config-v2.sh`
```

---

## 📋 Checklist Avant Release

- [ ] Tous les changements documentés dans `[Unreleased]`
- [ ] Version mise à jour selon Semantic Versioning
- [ ] Date de release ajoutée
- [ ] Section `[Unreleased]` réinitialisée
- [ ] Liens de comparaison mis à jour (si applicable)
- [ ] Documentation à jour

---

## 🔄 Processus de Mise à Jour

### 1. Pendant le Développement

Ajouter les changements dans `[Unreleased]` :

```markdown
## [Unreleased]

### Ajouté
- Nouvelle fonctionnalité X

### Corrigé
- Bug Y
```

### 2. Avant une Release

1. **Déterminer la version** :
   - **MAJOR** (2.0.0) : Breaking changes
   - **MINOR** (1.1.0) : Nouvelles fonctionnalités
   - **PATCH** (1.0.1) : Corrections de bugs

2. **Créer la section de version** :

```markdown
## [1.1.0] - 2025-12-15

### Ajouté
- (copier depuis [Unreleased])

### Modifié
- (copier depuis [Unreleased])

### Corrigé
- (copier depuis [Unreleased])
```

3. **Réinitialiser [Unreleased]** :

```markdown
## [Unreleased]

### À venir
- Fonctionnalités planifiées
```

---

## 📝 Bonnes Pratiques

### ✅ À Faire

- ✅ **Être descriptif** : Expliquer ce qui a changé et pourquoi
- ✅ **Grouper par type** : Ajouté, Modifié, Corrigé, etc.
- ✅ **Utiliser le présent** : "Ajoute" plutôt que "Ajouté"
- ✅ **Référencer les issues** : `- Fix #123: Description`
- ✅ **Mettre à jour régulièrement** : Ne pas attendre la release

### ❌ À Éviter

- ❌ **Changements trop génériques** : "Améliorations"
- ❌ **Changements internes non visibles** : Refactoring mineur
- ❌ **Duplication** : Ne pas répéter la même information
- ❌ **Oublier les breaking changes** : Toujours les documenter

---

## 🔗 Liens Utiles

- [Keep a Changelog](https://keepachangelog.com/fr/1.0.0/)
- [Semantic Versioning](https://semver.org/lang/fr/)
- [CONTRIBUTING.md](../CONTRIBUTING.md) - Guide de contribution

---

## 📊 Exemple Complet

```markdown
# Changelog

## [Unreleased]

### À venir
- Tests E2E complets
- Support multi-cluster

---

## [1.1.0] - 2025-12-15

### Ajouté
- Script `scripts/utils/clean_logs.sh` pour archiver les logs
- Support de la configuration via `.env` (optionnel)
- Documentation `docs/NEW_FEATURE.md`

### Modifié
- Amélioration de `setup_paths()` pour détection automatique sur Linux
- Mise à jour de `README.md` avec nouvelles fonctionnalités
- Optimisation de la performance des scripts de test

### Corrigé
- Correction de la gestion d'erreur dans `scripts/setup/03_start_hcd.sh`
- Correction du chemin dans `.poc-config.sh` pour Linux
- Correction de la documentation des workflows GitHub Actions

---

## [1.0.0] - 2025-12-01

### Ajouté
- Structure complète du projet
- Configuration centralisée (.poc-config.sh)
- Documentation complète
- Tests et CI/CD
```

---

**Date** : 2025-12-01  
**Version** : 1.0  
**Statut** : ✅ **Guide complet**
