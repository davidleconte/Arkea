# 🔍 Audit de Portabilité Cross-Platform - ARKEA

**Date** : 2026-03-13
**Objectif** : Vérifier si le projet ARKEA peut être déployé cross-platform (macOS, Linux, Windows)
**Version** : 1.0

---

## 📊 Résumé Exécutif

**Score de Portabilité Global** : **~75%** ⚠️

**Plateformes Supportées** :

- ✅ **macOS** 12+ (testé et fonctionnel)
- ✅ **Linux** (Ubuntu 20.04+, CentOS 7+) - Partiellement testé
- ❌ **Windows** (non supporté actuellement)

**Points Forts** :

- ✅ Configuration centralisée (`.poc-config.sh`) avec détection automatique
- ✅ Détection OS via `$OSTYPE` (darwin, linux-gnu)
- ✅ Chemins relatifs utilisés dans la majorité des scripts
- ✅ Variables d'environnement surchargeables
- ✅ Scripts shell compatibles bash 4.0+

**Points d'Amélioration** :

- ⚠️ Chemins hardcodés macOS restants (31 occurrences dans `scripts/`, 125 dans `poc-design/`)
- ⚠️ Dépendance à Homebrew pour Kafka (macOS uniquement)
- ⚠️ Dépendance à `podman` (non disponible sur Windows)
- ⚠️ Scripts shell uniquement (pas de support Windows natif)
- ⚠️ Outils Unix (`lsof`, `readlink`, `which`) non disponibles sur Windows
- ⚠️ Chemins Java spécifiques macOS (`/opt/homebrew/opt/openjdk@11`)

---

## 🔍 Analyse Détaillée

### 1. Systèmes d'Exploitation

#### 1.1 macOS (Darwin)

**Statut** : ✅ **Entièrement Supporté**

**Détection** :

```bash
if [[ "$OSTYPE" == "darwin"* ]]; then
    # Configuration macOS
fi
```

**Dépendances Spécifiques** :

- ✅ Homebrew (`/opt/homebrew/` ou `/usr/local/`)
- ✅ Kafka via Homebrew (`brew install kafka`)
- ✅ Java via Homebrew (`brew install openjdk@11`)
- ✅ jenv (optionnel, recommandé)

**Chemins Hardcodés Identifiés** :

- `/opt/homebrew/opt/kafka` (3 occurrences)
- `/opt/homebrew/opt/zookeeper` (2 occurrences)
- `/opt/homebrew/opt/openjdk@11` (5 occurrences)
- `/opt/homebrew/opt/openjdk@17` (2 occurrences)
- `${ARKEA_HOME}` (31 occurrences dans `scripts/`, 125 dans `poc-design/`)

**Impact** : 🟡 **Moyen** - La plupart sont dans `.poc-config.sh` avec fallback Linux

---

#### 1.2 Linux (GNU/Linux)

**Statut** : ✅ **Partiellement Supporté**

**Détection** :

```bash
elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
    # Configuration Linux
fi
```

**Dépendances** :

- ✅ Java 11 et 17 (via `apt-get`, `yum`, etc.)
- ✅ Python 3.8-3.11
- ⚠️ Kafka (installation manuelle requise, pas via Homebrew)
- ✅ Spark (téléchargement et extraction)
- ✅ HCD (téléchargement et extraction)

**Chemins Standard Linux** :

- `/opt/kafka` (détecté automatiquement)
- `/usr/local/kafka` (fallback)
- `/opt/zookeeper` (détecté automatiquement)

**Problèmes Identifiés** :

- ⚠️ Scripts d'installation Kafka supposent Homebrew (macOS uniquement)
- ⚠️ Pas de guide d'installation Linux détaillé
- ⚠️ `readlink -f` utilisé (GNU Linux uniquement, pas compatible BSD/macOS)

**Impact** : 🟡 **Moyen** - Fonctionne mais nécessite ajustements manuels

---

#### 1.3 Windows

**Statut** : ❌ **Non Supporté**

**Problèmes Majeurs** :

1. **Scripts Shell** : Tous les scripts sont `.sh` (bash), non exécutables nativement sur Windows
2. **Outils Unix** : Dépendances à `lsof`, `readlink`, `which`, `grep`, `sed`, `awk`
3. **Chemins** : Utilisation de `/` au lieu de `\`
4. **Variables d'Environnement** : Syntaxe bash (`${VAR:-default}`) non compatible PowerShell
5. **Podman** : Non disponible sur Windows (nécessite WSL2 ou Docker Desktop)
6. **Homebrew** : Non disponible sur Windows (nécessite WSL2)

**Solutions Possibles** :

- ✅ **WSL2** (Windows Subsystem for Linux) - Recommandé
- ✅ **Git Bash** - Partiel (certaines commandes ne fonctionnent pas)
- ✅ **Docker Desktop** - Pour conteneurisation
- ❌ **PowerShell** - Nécessiterait réécriture complète des scripts

**Impact** : 🔴 **Critique** - Nécessite WSL2 ou réécriture complète

---

### 2. Dépendances et Logiciels

#### 2.1 Java

**Versions Requises** :

- ✅ Java 11 (HCD, Spark 3.5.1)
- ✅ Java 17 (Kafka 4.1.1, optionnel)

**Détection Multi-OS** :

```bash
# .poc-config.sh
if [ -z "${JAVA_HOME:-}" ]; then
    # Essayer jenv d'abord
    if command -v jenv &> /dev/null; then
        # jenv (multi-OS)
    fi

    # Fallback Homebrew (macOS uniquement)
    if [[ "$OSTYPE" == "darwin"* ]]; then
        if [ -d "/opt/homebrew/opt/openjdk@11" ]; then
            export JAVA_HOME="/opt/homebrew/opt/openjdk@11/..."
        fi
    fi

    # Fallback système (Linux)
    if [ -z "$JAVA_HOME" ] && command -v java &> /dev/null; then
        export JAVA_HOME=$(dirname $(dirname $(readlink -f $(which java) 2>/dev/null || which java)))
    fi
fi
```

**Problèmes** :

- ⚠️ `readlink -f` non disponible sur macOS (BSD) - Utilise `readlink` avec fallback
- ⚠️ Chemins Java hardcodés macOS (`/opt/homebrew/opt/openjdk@11`)

**Portabilité** : ✅ **Bonne** (jenv + fallback système)

---

#### 2.2 Kafka

**Installation** :

- **macOS** : Via Homebrew (`brew install kafka`)
- **Linux** : Téléchargement manuel requis (pas de script automatique)

**Détection** :

```bash
# .poc-config.sh
if [ -z "${KAFKA_HOME:-}" ]; then
    if [[ "$OSTYPE" == "darwin"* ]]; then
        # macOS (Homebrew)
        if [ -d "/opt/homebrew/opt/kafka" ]; then
            export KAFKA_HOME="/opt/homebrew/opt/kafka"
        elif [ -d "/usr/local/opt/kafka" ]; then
            export KAFKA_HOME="/usr/local/opt/kafka"
        fi
    elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
        # Linux (détection standard)
        if [ -d "/opt/kafka" ]; then
            export KAFKA_HOME="/opt/kafka"
        elif [ -d "/usr/local/kafka" ]; then
            export KAFKA_HOME="/usr/local/kafka"
        fi
    fi
fi
```

**Problèmes** :

- ⚠️ Script `02_install_spark_kafka.sh` suppose Homebrew (macOS uniquement)
- ⚠️ Pas de script d'installation automatique pour Linux

**Portabilité** : 🟡 **Moyenne** (nécessite installation manuelle sur Linux)

---

#### 2.3 HCD (Hyper-Converged Database)

**Installation** : ✅ **Portable** (tarball extrait dans `binaire/`)

**Détection** :

```bash
# .poc-config.sh
if [ -z "${HCD_DIR:-}" ] && [ -z "${HCD_HOME:-}" ]; then
    if [ -d "${BINAIRE_DIR}/hcd-1.2.3" ]; then
        export HCD_DIR="${BINAIRE_DIR}/hcd-1.2.3"
    fi
fi
```

**Portabilité** : ✅ **Excellente** (chemins relatifs)

---

#### 2.4 Spark

**Installation** : ✅ **Portable** (tarball extrait dans `binaire/`)

**Détection** :

```bash
# .poc-config.sh
if [ -z "${SPARK_HOME:-}" ]; then
    if [ -d "${BINAIRE_DIR}/spark-3.5.1" ]; then
        export SPARK_HOME="${BINAIRE_DIR}/spark-3.5.1"
    fi
fi
```

**Portabilité** : ✅ **Excellente** (chemins relatifs)

---

#### 2.5 Podman / Docker

**Utilisation** : Déploiement Stargate (Data API)

**Statut** :

- ✅ **Podman** : Disponible sur macOS et Linux
- ❌ **Windows** : Non disponible (nécessite WSL2 ou Docker Desktop)

**Scripts Affectés** :

- `poc-design/domirama2/scripts/39_deploy_stargate.sh`
- `poc-design/domirama2/scripts/41_demo_complete_podman.sh`

**Portabilité** : 🟡 **Moyenne** (nécessite WSL2 sur Windows)

---

### 3. Scripts Shell

#### 3.1 Compatibilité Bash

**Shebang** : `#!/bin/bash`

**Versions Testées** :

- ✅ Bash 4.0+ (macOS, Linux)
- ⚠️ Bash 3.x (macOS par défaut) - Peut nécessiter `brew install bash`

**Fonctionnalités Utilisées** :

- ✅ `set -euo pipefail` (bash 4.0+)
- ✅ `[[ "$OSTYPE" == "darwin"* ]]` (bash 4.0+)
- ✅ `BASH_SOURCE[0]` (bash 3.0+)
- ✅ `command -v` (POSIX)

**Portabilité** : ✅ **Bonne** (bash 4.0+ requis)

---

#### 3.2 Commandes Unix

**Commandes Utilisées** :

- ✅ `grep`, `sed`, `awk` - Disponibles sur macOS/Linux
- ✅ `which`, `command -v` - Disponibles sur macOS/Linux
- ⚠️ `readlink -f` - GNU Linux uniquement (pas macOS BSD)
- ⚠️ `lsof` - Disponible sur macOS/Linux, pas Windows
- ⚠️ `pkill` - Disponible sur macOS/Linux, pas Windows

**Problèmes Identifiés** :

```bash
# scripts/setup/03_start_hcd.sh
if lsof -Pi :9042 -sTCP:LISTEN -t >/dev/null 2>&1 ; then
    # Vérification port - Non disponible sur Windows
fi
```

**Portabilité** : 🟡 **Moyenne** (nécessite WSL2 sur Windows)

---

### 4. Chemins et Configuration

#### 4.1 Chemins Hardcodés

**Inventaire** :

| Chemin | Occurrences | Fichiers | Plateforme | Impact |
|--------|-------------|----------|------------|--------|
| `${ARKEA_HOME}` | 31 | `scripts/` | macOS | 🔴 Critique |
| `${ARKEA_HOME}` | 125 | `poc-design/` | macOS | 🔴 Critique |
| `/opt/homebrew/opt/kafka` | 3 | `.poc-config.sh`, scripts | macOS | 🟡 Moyen |
| `/opt/homebrew/opt/zookeeper` | 2 | `.poc-config.sh` | macOS | 🟡 Moyen |
| `/opt/homebrew/opt/openjdk@11` | 5 | `.poc-config.sh`, scripts | macOS | 🟡 Moyen |
| `/opt/homebrew/opt/openjdk@17` | 2 | `.poc-config.sh` | macOS | 🟡 Moyen |

**Solutions** :

- ✅ `.poc-config.sh` détecte automatiquement selon `$OSTYPE`
- ⚠️ Scripts individuels ont encore des chemins hardcodés
- ⚠️ Documentation contient des exemples avec chemins macOS

**Portabilité** : 🟡 **Moyenne** (amélioration nécessaire)

---

#### 4.2 Variables d'Environnement

**Architecture** :

1. **Niveau 1** : Variables d'environnement système (priorité maximale)
2. **Niveau 2** : `.poc-config.sh` (valeurs par défaut)
3. **Niveau 3** : Détection automatique (fallback)

**Exemple** :

```bash
# .poc-config.sh
if [ -z "${ARKEA_HOME:-}" ]; then
    ARKEA_HOME="$(cd "$(dirname "${BASH_SOURCE[0]:-${0}}")" && pwd)"
    export ARKEA_HOME
fi
```

**Portabilité** : ✅ **Excellente** (détection automatique)

---

### 5. GitHub Actions / CI/CD

#### 5.1 Workflows

**Fichiers** :

- `.github/workflows/test.yml`
- `.github/workflows/lint.yml`

**Plateformes Testées** :

- ✅ `ubuntu-latest` (Linux)
- ❌ macOS (non testé dans CI)
- ❌ Windows (non testé dans CI)

**Portabilité** : 🟡 **Moyenne** (seulement Linux testé)

---

## 📋 Recommandations

### Priorité 1 : Corrections Critiques

#### R1.1 : Éliminer les Chemins Hardcodés Restants

**Action** : Remplacer tous les chemins hardcodés par `setup_paths()` ou variables d'environnement

**Fichiers Affectés** :

- `scripts/setup/01_install_hcd.sh` (10 occurrences)
- `scripts/setup/02_install_spark_kafka.sh` (3 occurrences)
- `scripts/setup/03_start_hcd.sh` (5 occurrences)
- `scripts/setup/04_start_kafka.sh` (4 occurrences)
- `poc-design/*/scripts/*.sh` (125 occurrences)

**Exemple de Correction** :

```bash
# AVANT
HCD_DIR="${ARKEA_HOME}/binaire/hcd-1.2.3"

# APRÈS
source "$(dirname "$0")/../../.poc-config.sh" || source "${ARKEA_HOME}/.poc-config.sh"
HCD_DIR="${HCD_DIR:-${ARKEA_HOME}/binaire/hcd-1.2.3}"
```

---

#### R1.2 : Corriger `readlink -f` pour macOS

**Problème** : `readlink -f` n'existe pas sur macOS (BSD)

**Solution** :

```bash
# Fonction portable
get_realpath() {
    local path="$1"
    if [[ "$OSTYPE" == "darwin"* ]]; then
        # macOS (BSD)
        python3 -c "import os; print(os.path.realpath('$path'))"
    else
        # Linux (GNU)
        readlink -f "$path"
    fi
}
```

**Fichiers Affectés** :

- `.poc-config.sh` (ligne 150)

---

#### R1.3 : Remplacer `lsof` par Alternative Portable

**Problème** : `lsof` non disponible sur Windows

**Solution** :

```bash
# Fonction portable pour vérifier un port
check_port() {
    local port="$1"
    if [[ "$OSTYPE" == "msys" ]] || [[ "$OSTYPE" == "win32" ]]; then
        # Windows (Git Bash)
        netstat -an | grep -q ":$port.*LISTEN"
    else
        # macOS/Linux
        lsof -Pi :"$port" -sTCP:LISTEN -t >/dev/null 2>&1
    fi
}
```

**Fichiers Affectés** :

- `scripts/setup/03_start_hcd.sh`
- `scripts/setup/04_start_kafka.sh`

---

### Priorité 2 : Améliorations Importantes

#### R2.1 : Script d'Installation Kafka pour Linux

**Action** : Créer `scripts/setup/02_install_kafka_linux.sh`

**Contenu** :

```bash
#!/bin/bash
# Installation Kafka pour Linux

set -e

KAFKA_VERSION="4.1.1"
KAFKA_TGZ="kafka_2.13-${KAFKA_VERSION}.tgz"
KAFKA_URL="https://archive.apache.org/dist/kafka/${KAFKA_VERSION}/${KAFKA_TGZ}"

# Télécharger et extraire Kafka
cd "$INSTALL_DIR/software"
curl -L "$KAFKA_URL" -o "$KAFKA_TGZ"
tar -xzf "$KAFKA_TGZ" -C "$INSTALL_DIR/binaire"
mv "$INSTALL_DIR/binaire/kafka_2.13-${KAFKA_VERSION}" "$INSTALL_DIR/binaire/kafka"
export KAFKA_HOME="$INSTALL_DIR/binaire/kafka"
```

---

#### R2.2 : Guide d'Installation Linux

**Action** : Créer `docs/archive/legacy_v1/GUIDE_INSTALLATION_LINUX.md`

**Contenu** :

- Installation Java 11/17 (apt-get, yum)
- Installation Kafka (téléchargement manuel)
- Configuration des variables d'environnement
- Dépannage spécifique Linux

---

#### R2.3 : Support Windows via WSL2

**Action** : Créer `docs/GUIDE_INSTALLATION_WINDOWS.md`

**Contenu** :

- Installation WSL2
- Installation des dépendances dans WSL2
- Configuration Git Bash (alternative)
- Limitations et workarounds

---

### Priorité 3 : Améliorations Optionnelles

#### R3.1 : Tests CI Multi-OS

**Action** : Ajouter tests macOS et Windows dans GitHub Actions

**Fichier** : `.github/workflows/test.yml`

```yaml
jobs:
  test-macos:
    runs-on: macos-latest
    steps:
      - uses: actions/checkout@v4
      - name: Test on macOS
        run: ./scripts/utils/80_verify_all.sh

  test-windows:
    runs-on: windows-latest
    steps:
      - uses: actions/checkout@v4
      - name: Setup WSL2
        run: wsl --install
      - name: Test on Windows (WSL2)
        run: wsl bash ./scripts/utils/80_verify_all.sh
```

---

#### R3.2 : Scripts PowerShell (Optionnel)

**Action** : Créer versions PowerShell des scripts principaux

**Fichiers** :

- `scripts/setup/01_install_hcd.ps1`
- `scripts/setup/02_install_spark_kafka.ps1`

**Note** : Nécessiterait réécriture complète, coût élevé

---

#### R3.3 : Documentation Cross-Platform

**Action** : Mettre à jour `README.md` avec section "Supported Platforms"

**Contenu** :

- Tableau comparatif macOS / Linux / Windows
- Instructions d'installation par plateforme
- Limitations connues

---

## 📊 Tableau Récapitulatif

| Composant | macOS | Linux | Windows | Notes |
|-----------|-------|-------|---------|-------|
| **HCD** | ✅ | ✅ | ⚠️ WSL2 | Portable (tarball) |
| **Spark** | ✅ | ✅ | ⚠️ WSL2 | Portable (tarball) |
| **Kafka** | ✅ Homebrew | ⚠️ Manuel | ⚠️ WSL2 | Installation différente |
| **Java** | ✅ | ✅ | ⚠️ WSL2 | jenv + fallback |
| **Python** | ✅ | ✅ | ⚠️ WSL2 | Standard |
| **Podman** | ✅ | ✅ | ❌ | WSL2 ou Docker Desktop |
| **Scripts Shell** | ✅ | ✅ | ⚠️ WSL2/Git Bash | Bash requis |
| **Chemins** | ⚠️ Hardcodés | ✅ Relatifs | ⚠️ WSL2 | Amélioration nécessaire |
| **CI/CD** | ❌ | ✅ | ❌ | Seulement Linux testé |

**Légende** :

- ✅ **Entièrement Supporté**
- ⚠️ **Partiellement Supporté** (nécessite ajustements)
- ❌ **Non Supporté**

---

## 🎯 Plan d'Action Recommandé

### Phase 1 : Corrections Critiques (1-2 semaines)

1. ✅ Éliminer chemins hardcodés restants (R1.1)
2. ✅ Corriger `readlink -f` pour macOS (R1.2)
3. ✅ Remplacer `lsof` par alternative portable (R1.3)

### Phase 2 : Améliorations Importantes (2-3 semaines)

1. ✅ Script d'installation Kafka pour Linux (R2.1)
2. ✅ Guide d'installation Linux (R2.2)
3. ✅ Guide d'installation Windows (R2.3)

### Phase 3 : Améliorations Optionnelles (1-2 semaines)

1. ⚠️ Tests CI Multi-OS (R3.1)
2. ⚠️ Documentation Cross-Platform (R3.3)
3. ❌ Scripts PowerShell (R3.2) - Optionnel, coût élevé

---

## 📝 Conclusion

**Statut Actuel** : Le projet ARKEA est **partiellement portable** avec un support complet pour macOS et un support partiel pour Linux. Windows nécessite WSL2.

**Score de Portabilité** : **~75%**

**Actions Prioritaires** :

1. Éliminer les chemins hardcodés restants
2. Corriger les commandes Unix non portables (`readlink -f`, `lsof`)
3. Créer des guides d'installation pour Linux et Windows (WSL2)

**Objectif** : Atteindre **~90%** de portabilité avec les corrections Phase 1 et Phase 2.

---

**Date** : 2026-03-13
**Version** : 1.0
**Statut** : ✅ **Audit Complet**
