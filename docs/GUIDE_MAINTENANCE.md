# 🔧 Guide de Maintenance - ARKEA

**Date** : 2026-03-13
**Objectif** : Processus de maintenance et archivage du projet ARKEA
**Version** : 1.0.0

---

## 📋 Vue d'Ensemble

Ce guide décrit les processus de **maintenance** et d'**archivage** pour le projet ARKEA :

- Mise à jour de la documentation
- Archivage des fichiers obsolètes
- Nettoyage automatique
- Vérification de cohérence

---

## 🔄 Maintenance Régulière

### 1. Mise à Jour de la Documentation

#### Documentation Principale

- **README.md** : Mettre à jour lors de changements majeurs
- **CHANGELOG.md** : Ajouter une entrée pour chaque version
- **CONTRIBUTING.md** : Mettre à jour si les standards changent

#### Documentation des POCs

- **poc-design/*/README.md** : Mettre à jour lors de changements
- **doc/demonstrations/*.md** : Générés automatiquement (ne pas modifier manuellement)
- **doc/audits/*.md** : Archiver les audits obsolètes

#### Processus de Mise à Jour

```bash
# 1. Vérifier les fichiers modifiés
git status

# 2. Mettre à jour la documentation si nécessaire
# 3. Vérifier la cohérence
./scripts/utils/91_check_consistency.sh

# 4. Générer la documentation si nécessaire
./scripts/utils/92_generate_docs.sh
```

---

### 2. Archivage des Fichiers Obsolètes

#### Fichiers à Archiver

- **Documentation obsolète** : Fichiers `.md` remplacés par de nouvelles versions
- **Scripts obsolètes** : Scripts remplacés par de nouvelles versions
- **Audits anciens** : Audits de plus de 6 mois (sauf audits de référence)

#### Processus

```bash
# 1. Identifier les fichiers obsolètes
find poc-design -name "*.md" -mtime +180 | grep -E "(audit|AUDIT)" | head -10

# 2. Créer le répertoire d'archive si nécessaire
mkdir -p poc-design/<poc-name>/doc/audits/archive/$(date +%Y-%m)

# 3. Déplacer les fichiers
mv poc-design/<poc-name>/doc/audits/OLD_AUDIT.md \
   poc-design/<poc-name>/doc/audits/archive/$(date +%Y-%m)/

# 4. Mettre à jour les index
./scripts/utils/92_generate_docs.sh
```

#### Structure d'Archive

```text
poc-design/<poc-name>/doc/
├── audits/
│   ├── archive/
│   │   ├── 2025-11/
│   │   │   └── OLD_AUDIT.md
│   │   └── 2025-12/
│   │       └── OLD_AUDIT.md
│   └── CURRENT_AUDIT.md
```

---

### 3. Nettoyage Automatique

#### Script de Nettoyage

Utiliser le script `scripts/utils/95_cleanup.sh` :

```bash
# Nettoyage en mode dry-run (simulation)
./scripts/utils/95_cleanup.sh --dry-run

# Nettoyage réel
./scripts/utils/95_cleanup.sh

# Nettoyage avec âge personnalisé (7 jours)
./scripts/utils/95_cleanup.sh --age 7
```

#### Éléments Nettoyés

- **Répertoires UNLOAD_*** : Répertoires temporaires de plus de 30 jours
- **Fichiers temporaires** : `*.tmp`, `*.bak`, `*.swp`, `*.swo`, `*~`
- **Logs anciens** : Logs de plus de 90 jours

#### Planification

Ajouter au crontab pour exécution automatique :

```bash
# Nettoyage hebdomadaire (dimanche à 2h du matin)
0 2 * * 0 cd /path/to/Arkea && ./scripts/utils/95_cleanup.sh --age 30
```

---

### 4. Vérification de Cohérence

#### Script de Vérification

Utiliser le script `scripts/utils/91_check_consistency.sh` :

```bash
# Vérification complète
./scripts/utils/91_check_consistency.sh

# Vérification spécifique
./scripts/utils/91_check_consistency.sh --check-hardcoded-paths
./scripts/utils/91_check_consistency.sh --check-scripts
./scripts/utils/91_check_consistency.sh --check-docs
```

#### Vérifications Effectuées

- ✅ **Chemins hardcodés** : Détection des chemins non portables
- ✅ **Scripts standards** : Vérification de `set -euo pipefail`
- ✅ **Documentation** : Vérification des liens et références
- ✅ **Incohérences** : Détection d'incohérences entre POCs

---

## 📅 Calendrier de Maintenance

### Hebdomadaire

- [ ] Exécuter `95_cleanup.sh` (nettoyage automatique)
- [ ] Vérifier les logs d'erreur

### Mensuel

- [ ] Exécuter `91_check_consistency.sh` (vérification de cohérence)
- [ ] Archiver les audits obsolètes (> 6 mois)
- [ ] Mettre à jour la documentation si nécessaire

### Trimestriel

- [ ] Audit complet du projet
- [ ] Révision des standards et conventions
- [ ] Mise à jour des guides

---

## 🔍 Détection de Problèmes

### Chemins Hardcodés

**Symptôme** : Scripts avec chemins `/Users/...` ou `/opt/homebrew/...`

**Solution** :

```bash
# Détecter
./scripts/utils/91_check_consistency.sh --check-hardcoded-paths

# Corriger (utiliser setup_paths() ou variables d'environnement)
```

### Scripts sans Standards

**Symptôme** : Scripts sans `set -euo pipefail`

**Solution** :

```bash
# Détecter
./scripts/utils/91_check_consistency.sh --check-scripts

# Corriger (ajouter set -euo pipefail)
```

### Documentation Obsolète

**Symptôme** : Liens cassés, références obsolètes

**Solution** :

```bash
# Détecter
./scripts/utils/91_check_consistency.sh --check-docs

# Corriger (mettre à jour les liens)
```

---

## 📊 Métriques de Maintenance

### Indicateurs

- **Nombre de fichiers obsolètes** : < 10
- **Nombre de chemins hardcodés** : 0
- **Nombre de scripts sans standards** : 0
- **Taille des archives** : < 100 MB par POC

### Rapports

Générer un rapport de maintenance :

```bash
./scripts/utils/91_check_consistency.sh --report > maintenance_report_$(date +%Y-%m-%d).md
```

---

## 🚨 Procédures d'Urgence

### Fichiers Corrompus

1. **Identifier** : Vérifier les logs d'erreur
2. **Restaurer** : Utiliser Git pour restaurer
3. **Corriger** : Corriger le problème
4. **Documenter** : Documenter dans CHANGELOG.md

### Scripts Cassés

1. **Identifier** : Exécuter `91_check_consistency.sh`
2. **Isoler** : Déplacer dans `scripts/archive/`
3. **Corriger** : Créer une nouvelle version
4. **Tester** : Tester la nouvelle version

### Documentation Incohérente

1. **Identifier** : Exécuter `91_check_consistency.sh --check-docs`
2. **Corriger** : Mettre à jour les liens et références
3. **Vérifier** : Re-exécuter la vérification

---

---

## 🐳 Scripts Podman & Containerisation

### 96_check_podman_ports.sh - Détection de Conflits de Ports

Script de vérification **pré-flight** pour détecter les conflits de ports avant de démarrer les conteneurs ARKEA.

```bash
# Vérification complète
./scripts/utils/96_check_podman_ports.sh

# Sortie exemple:
# Service              Host Port    Status          Note
# -------              ---------    ------          ----
# HCD_CQL              9102         ✅ Available    CQL Native Transport
# KAFKA                9192         ✅ Available    Kafka Broker
```

**Fonctionnalités**:

- ✅ Vérifie la machine `podman-wxd` (NE JAMAIS supprimer)
- ✅ Détecte les projets existants (à ne PAS modifier)
- ✅ Vérifie le réseau ARKEA (`arkea-network`)
- ✅ Valide l'allocation des ports (Base: 9100)

**⚠️ IMPERATIF**: Voir `PODMAN_RULES.md` pour les règles d'isolation obligatoires.

---

### 96_fix_localhost_references.sh - Correction Automatique localhost

Remplace les références `localhost` hardcodées par des variables d'environnement configurables.

```bash
# Mode simulation (dry-run)
./scripts/utils/96_fix_localhost_references.sh --dry-run

# Appliquer les corrections
./scripts/utils/96_fix_localhost_references.sh

# Fichier spécifique
./scripts/utils/96_fix_localhost_references.sh --file scripts/setup/03_start_hcd.sh
```

**Patterns corrigés**:

| Original | Remplacement |
|----------|--------------|
| `localhost:9042` | `${HCD_HOST:-localhost}:${HCD_PORT:-9042}` |
| `localhost:9092` | `${KAFKA_BOOTSTRAP_SERVERS:-localhost:9092}` |
| `localhost:2181` | `${KAFKA_ZOOKEEPER_CONNECT:-localhost:2181}` |

**Sauvegarde**: Les fichiers originaux sont sauvegardés dans `.backup_localhost_YYYYMMDD_HHMMSS/`.

---

### 97_check_monitoring.sh - Vérification Monitoring

Vérifie que les services de monitoring sont démarrés et accessibles.

```bash
./scripts/utils/97_check_monitoring.sh
```

**Services vérifiés**:

| Service | Port | Statut |
|---------|------|--------|
| Prometheus | 9090 | Obligatoire |
| Grafana | 3000 | Obligatoire |
| Alertmanager | 9093 | Optionnel |
| JMX Exporter HCD | 7072 | Optionnel |
| JMX Exporter Kafka | 7073 | Optionnel |

---

## 📚 Ressources

### Scripts de Maintenance

| Script | Usage | Priorité |
|--------|-------|----------|
| `91_check_consistency.sh` | Vérification de cohérence projet | Haute |
| `92_generate_docs.sh` | Génération de documentation | Moyenne |
| `95_cleanup.sh` | Nettoyage automatique | Hebdomadaire |
| `96_check_podman_ports.sh` | Détection conflits ports Podman | Pré-déploiement |
| `96_fix_localhost_references.sh` | Correction localhost hardcodés | Migration |
| `97_check_monitoring.sh` | Vérification services monitoring | Opérationnel |

### Documentation de Référence

- **CHANGELOG.md** : Historique des changements
- **PODMAN_RULES.md** : Règles d'isolation conteneur (OBLIGATOIRE)
- **docs/AUDIT_COMPLET_PROJET_ARKEA_2025_V2.md** : Audit complet du projet
- **docs/GUIDE_MONITORING.md** : Guide de configuration monitoring

---

## ✅ Checklist de Maintenance

### Tâches Hebdomadaires

- [ ] Exécuter `95_cleanup.sh`
- [ ] Vérifier les logs d'erreur
- [ ] Vérifier l'espace disque

### Tâches Mensuelles

- [ ] Exécuter `91_check_consistency.sh`
- [ ] Archiver les audits obsolètes
- [ ] Mettre à jour la documentation
- [ ] Vérifier les métriques

### Tâches Trimestrielles

- [ ] Audit complet du projet
- [ ] Révision des standards
- [ ] Mise à jour des guides
- [ ] Rapport de maintenance

---

**Pour plus d'informations, voir** :

- `scripts/utils/95_cleanup.sh` - Script de nettoyage
- `scripts/utils/91_check_consistency.sh` - Script de vérification
- `docs/AUDIT_COMPLET_PROJET_ARKEA_2025_V2.md` - Audit complet
