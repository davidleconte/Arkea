# 📋 Plan d'Action : Factorisation de la Configuration

**Date** : 2025-12-01  
**Date de mise à jour** : 2025-12-02  
**Objectif** : Éliminer tous les chemins hardcodés et factoriser la configuration pour rendre le projet portable  
**Périmètre** : Tous les fichiers sous `ARKEA` et ses sous-dossiers  
**Statut** : ✅ **IMPLÉMENTÉ** (Phases 1, 2, 3 complétées)

---

## ✅ État d'Implémentation

**Score de Portabilité** : **~90%** (amélioration de ~75% à ~90%)

### Phases Complétées

- ✅ **Phase 1 : Préparation** - Complétée (2025-12-01)
- ✅ **Phase 2 : Migration** - Complétée (2025-12-01)
- ✅ **Phase 3 : Tests et Validation** - Complétée (2025-12-02)
- ✅ **Phase 4 : Portabilité Cross-Platform** - Complétée (2025-12-02)

### Résultats

**Avant** :

- 93 occurrences de chemins hardcodés dans scripts
- 203 occurrences de `${USER_HOME:-$HOME}` dans 137 fichiers
- Support limité à macOS uniquement
- Chemins Mac hardcodés partout

**Après** :

- ✅ 0 chemins hardcodés dans `scripts/setup/`
- ✅ Détection automatique de l'OS (macOS, Linux, Windows WSL2)
- ✅ Fonctions portables (`get_realpath`, `check_port`, `kill_process`)
- ✅ Configuration centralisée (`.poc-config.sh`)
- ✅ Guides d'installation cross-platform créés
- ✅ Tests CI multi-OS préparés

**Voir** :

- `docs/AUDIT_PORTABILITE_CROSS_PLATFORM_2025.md` - Audit complet de portabilité
- `scripts/utils/portable_functions.sh` - Fonctions portables
- `docs/GUIDE_INSTALLATION_LINUX.md` - Guide Linux
- `docs/GUIDE_INSTALLATION_WINDOWS.md` - Guide Windows

---

## 🎯 Résumé Exécutif (Historique)

### Problèmes Identifiés

1. **93 occurrences** de `INSTALL_DIR="${ARKEA_HOME}"` hardcodé
2. **203 occurrences** de `${USER_HOME:-$HOME}` dans 137 fichiers
3. **298 fichiers** utilisant `HCD_HOME`, `SPARK_HOME`, etc. sans standardisation
4. **Chemins Mac hardcodés** : `/opt/homebrew/opt/kafka`, `/opt/homebrew/opt/zookeeper`, etc.
5. **Inconsistance** : Certains scripts utilisent `setup_paths()`, d'autres ont des chemins hardcodés

### Solution Proposée

**Architecture de Configuration en 3 Niveaux** :

1. **Niveau 1 : Variables d'Environnement Système** (priorité maximale)
   - `ARKEA_HOME` : Racine du projet
   - `HCD_DIR`, `SPARK_HOME`, `KAFKA_HOME`, etc.

2. **Niveau 2 : Fichier de Configuration Centralisé** (`.poc-config.sh`)
   - Valeurs par défaut portables
   - Détection automatique des chemins
   - Surchargeable par variables d'environnement

3. **Niveau 3 : Détection Automatique** (fallback)
   - `setup_paths()` détecte automatiquement les chemins
   - Utilise des chemins relatifs au script

---

## 📊 Analyse Détaillée

### 1. Inventaire des Chemins Hardcodés

#### 1.1 Chemins Absolus Mac

| Chemin | Occurrences | Fichiers | Impact |
|--------|-------------|----------|--------|
| `${ARKEA_HOME}` | 93 | Scripts shell | 🔴 Critique |
| `/opt/homebrew/opt/kafka` | 3 | `.poc-profile` | 🟡 Moyen |
| `/opt/homebrew/opt/zookeeper` | 2 | `.poc-profile` | 🟡 Moyen |
| `/opt/homebrew/opt/openjdk@11` | 5 | `.poc-profile` | 🟡 Moyen |
| `/opt/homebrew/opt/openjdk@17` | 2 | `.poc-profile` | 🟡 Moyen |

#### 1.2 Variables de Configuration

| Variable | Utilisation Actuelle | Standardisation Proposée |
|----------|---------------------|-------------------------|
| `INSTALL_DIR` | Hardcodé dans 93 scripts | `ARKEA_HOME` (env) → `setup_paths()` |
| `HCD_DIR` / `HCD_HOME` | Mixte (hardcodé + env) | `HCD_DIR` (env) → `setup_paths()` |
| `SPARK_HOME` | Mixte (hardcodé + env) | `SPARK_HOME` (env) → `setup_paths()` |
| `HCD_HOST` | `localhost` hardcodé | `HCD_HOST` (env, défaut: `localhost`) |
| `HCD_PORT` | `9042` hardcodé | `HCD_PORT` (env, défaut: `9042`) |
| `KAFKA_HOME` | `/opt/homebrew/opt/kafka` | `KAFKA_HOME` (env, détection auto) |

---

## 🔧 Solution : Architecture de Configuration

### 2.1 Fichier de Configuration Centralisé

**Créer** : `.poc-config.sh` à la racine du projet

```bash
#!/bin/bash
# =============================================================================
# Configuration Centralisée POC HBase → HCD
# =============================================================================
# Date : 2025-12-01
# Usage : Source automatique par setup_paths() ou manuellement
# =============================================================================

# Détecter la racine du projet (ARKEA_HOME)
# Priorité 1: Variable d'environnement ARKEA_HOME
# Priorité 2: Détection automatique (répertoire parent de ce fichier)
if [ -z "${ARKEA_HOME:-}" ]; then
    # Ce fichier est à la racine, donc ARKEA_HOME = répertoire de ce fichier
    ARKEA_HOME="$(cd "$(dirname "${BASH_SOURCE[0]:-${0}}")" && pwd)"
    export ARKEA_HOME
fi

# =============================================================================
# Chemins de Base (Relatifs à ARKEA_HOME)
# =============================================================================

# Répertoires principaux
export POC_HOME="${ARKEA_HOME}"
export BINAIRE_DIR="${BINAIRE_DIR:-${ARKEA_HOME}/binaire}"
export SOFTWARE_DIR="${SOFTWARE_DIR:-${ARKEA_HOME}/software}"
export DATA_DIR="${DATA_DIR:-${ARKEA_HOME}/data}"
export HCD_DATA_DIR="${HCD_DATA_DIR:-${ARKEA_HOME}/hcd-data}"

# =============================================================================
# HCD Configuration
# =============================================================================

# HCD Home (priorité: env > détection auto)
if [ -z "${HCD_DIR:-}" ] && [ -z "${HCD_HOME:-}" ]; then
    # Détection automatique
    if [ -d "${BINAIRE_DIR}/hcd-1.2.3" ]; then
        export HCD_DIR="${BINAIRE_DIR}/hcd-1.2.3"
    elif [ -d "${ARKEA_HOME}/binaire/hcd-1.2.3" ]; then
        export HCD_DIR="${ARKEA_HOME}/binaire/hcd-1.2.3"
    fi
else
    export HCD_DIR="${HCD_DIR:-${HCD_HOME}}"
fi

export HCD_VERSION="${HCD_VERSION:-1.2.3}"
export CASSANDRA_HOME="${CASSANDRA_HOME:-${HCD_DIR}/resources/cassandra}"

# HCD Connection (priorité: env > défaut)
export HCD_HOST="${HCD_HOST:-localhost}"
export HCD_PORT="${HCD_PORT:-9042}"
export CASSANDRA_HOST="${CASSANDRA_HOST:-${HCD_HOST}}"
export CASSANDRA_PORT="${CASSANDRA_PORT:-${HCD_PORT}}"
export CQLSH_HOST="${CQLSH_HOST:-${HCD_HOST}}"
export CQLSH_PORT="${CQLSH_PORT:-${HCD_PORT}}"

# =============================================================================
# Spark Configuration
# =============================================================================

# Spark Home (priorité: env > détection auto)
if [ -z "${SPARK_HOME:-}" ]; then
    if [ -d "${BINAIRE_DIR}/spark-3.5.1" ]; then
        export SPARK_HOME="${BINAIRE_DIR}/spark-3.5.1"
    elif [ -d "${ARKEA_HOME}/binaire/spark-3.5.1" ]; then
        export SPARK_HOME="${ARKEA_HOME}/binaire/spark-3.5.1"
    fi
fi

export SPARK_VERSION="${SPARK_VERSION:-3.5.1}"
export SPARK_CONF_DIR="${SPARK_CONF_DIR:-${SPARK_HOME}/conf}"
export SPARK_CHECKPOINT_DIR="${SPARK_CHECKPOINT_DIR:-/tmp/spark-checkpoints}"

# Spark Cassandra Connector
export SPARK_CASSANDRA_CONNECTOR_VERSION="${SPARK_CASSANDRA_CONNECTOR_VERSION:-3.5.0}"
export SPARK_CASSANDRA_CONNECTOR_JAR="${SPARK_CASSANDRA_CONNECTOR_JAR:-${ARKEA_HOME}/binaire/spark-jars/spark-cassandra-connector_2.12-${SPARK_CASSANDRA_CONNECTOR_VERSION}.jar}"

# =============================================================================
# Kafka Configuration (Détection Auto Multi-OS)
# =============================================================================

# Kafka Home (priorité: env > détection auto)
if [ -z "${KAFKA_HOME:-}" ]; then
    # Détection automatique selon OS
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

export KAFKA_VERSION="${KAFKA_VERSION:-4.1.1}"
export KAFKA_BOOTSTRAP_SERVERS="${KAFKA_BOOTSTRAP_SERVERS:-localhost:9092}"
export KAFKA_ZOOKEEPER_CONNECT="${KAFKA_ZOOKEEPER_CONNECT:-localhost:2181}"

# Zookeeper (détection auto)
if [ -z "${ZOOKEEPER_HOME:-}" ]; then
    if [[ "$OSTYPE" == "darwin"* ]]; then
        if [ -d "/opt/homebrew/opt/zookeeper" ]; then
            export ZOOKEEPER_HOME="/opt/homebrew/opt/zookeeper"
        elif [ -d "/usr/local/opt/zookeeper" ]; then
            export ZOOKEEPER_HOME="/usr/local/opt/zookeeper"
        fi
    elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
        if [ -d "/opt/zookeeper" ]; then
            export ZOOKEEPER_HOME="/opt/zookeeper"
        fi
    fi
fi

# =============================================================================
# Java Configuration (Détection Auto Multi-OS)
# =============================================================================

# Java 11 (priorité: jenv > Homebrew > système)
if [ -z "${JAVA_HOME:-}" ]; then
    # Essayer jenv d'abord
    if command -v jenv &> /dev/null; then
        eval "$(jenv init -)" 2>/dev/null || true
        if jenv versions | grep -q "11"; then
            export JAVA_HOME=$(jenv prefix 11 2>/dev/null || echo "")
            export JAVA11_HOME="$JAVA_HOME"
        fi
    fi

    # Fallback Homebrew (macOS)
    if [ -z "$JAVA_HOME" ] && [[ "$OSTYPE" == "darwin"* ]]; then
        if [ -d "/opt/homebrew/opt/openjdk@11/libexec/openjdk.jdk/Contents/Home" ]; then
            export JAVA_HOME="/opt/homebrew/opt/openjdk@11/libexec/openjdk.jdk/Contents/Home"
        elif [ -d "/opt/homebrew/opt/openjdk@11" ]; then
            export JAVA_HOME="/opt/homebrew/opt/openjdk@11"
        elif [ -d "/usr/local/opt/openjdk@11/libexec/openjdk.jdk/Contents/Home" ]; then
            export JAVA_HOME="/usr/local/opt/openjdk@11/libexec/openjdk.jdk/Contents/Home"
        fi
        export JAVA11_HOME="$JAVA_HOME"
    fi

    # Fallback système
    if [ -z "$JAVA_HOME" ] && command -v java &> /dev/null; then
        export JAVA_HOME=$(dirname $(dirname $(readlink -f $(which java) 2>/dev/null || which java)))
    fi
fi

# Java 17 (pour Kafka, optionnel)
if [ -z "${JAVA17_HOME:-}" ]; then
    if [[ "$OSTYPE" == "darwin"* ]]; then
        if [ -d "/opt/homebrew/opt/openjdk@17/libexec/openjdk.jdk/Contents/Home" ]; then
            export JAVA17_HOME="/opt/homebrew/opt/openjdk@17/libexec/openjdk.jdk/Contents/Home"
        elif [ -d "/opt/homebrew/opt/openjdk@17" ]; then
            export JAVA17_HOME="/opt/homebrew/opt/openjdk@17"
        fi
    fi
fi

# =============================================================================
# Python Configuration
# =============================================================================

# Python pour cqlsh et PySpark
if command -v python3.11 &> /dev/null; then
    export CQLSH_PYTHON=$(which python3.11)
    export PYSPARK_PYTHON=$(which python3.11)
    export PYSPARK_DRIVER_PYTHON=$(which python3.11)
elif command -v python3 &> /dev/null; then
    export PYSPARK_PYTHON=$(which python3)
    export PYSPARK_DRIVER_PYTHON=$(which python3)
fi

# =============================================================================
# PATH Configuration
# =============================================================================

# Ajouter les binaires au PATH (si disponibles)
[ -n "${SPARK_HOME:-}" ] && [ -d "${SPARK_HOME}/bin" ] && export PATH="${SPARK_HOME}/bin:${PATH}"
[ -n "${HCD_DIR:-}" ] && [ -d "${HCD_DIR}/bin" ] && export PATH="${HCD_DIR}/bin:${PATH}"
[ -n "${KAFKA_HOME:-}" ] && [ -d "${KAFKA_HOME}/libexec/bin" ] && export PATH="${KAFKA_HOME}/libexec/bin:${PATH}"
[ -n "${JAVA_HOME:-}" ] && [ -d "${JAVA_HOME}/bin" ] && export PATH="${JAVA_HOME}/bin:${PATH}"

# =============================================================================
# Data API Configuration
# =============================================================================

export DATA_API_ENDPOINT="${DATA_API_ENDPOINT:-http://localhost:8080}"
export DATA_API_USERNAME="${DATA_API_USERNAME:-cassandra}"
export DATA_API_PASSWORD="${DATA_API_PASSWORD:-cassandra}"
export DATA_API_TOKEN="${DATA_API_TOKEN:-Cassandra:Y2Fzc2FuZHJh:Y2Fzc2FuZHJh}"

# =============================================================================
# Hugging Face Configuration
# =============================================================================

export HF_API_KEY="${HF_API_KEY:-}"

# =============================================================================
# Keyspace et Tables HCD
# =============================================================================

export POC_KEYSPACE="${POC_KEYSPACE:-poc_hbase_migration}"
export KAFKA_EVENTS_TABLE="${KAFKA_EVENTS_TABLE:-kafka_events}"

# =============================================================================
# Spark Configuration Options
# =============================================================================

export SPARK_OPTS="${SPARK_OPTS:---conf spark.cassandra.connection.host=${HCD_HOST} --conf spark.cassandra.connection.port=${HCD_PORT} --conf spark.sql.extensions=com.datastax.spark.connector.CassandraSparkExtensions}"
export SPARK_PACKAGES="${SPARK_PACKAGES:-org.apache.spark:spark-sql-kafka-0-10_2.12:${SPARK_SQL_KAFKA_VERSION},com.datastax.spark:spark-cassandra-connector_2.12:${SPARK_CASSANDRA_CONNECTOR_VERSION}}"
export SPARK_SQL_KAFKA_VERSION="${SPARK_SQL_KAFKA_VERSION:-3.5.1}"
```

---

### 2.2 Mise à Jour de `setup_paths()`

**Fichier** : `poc-design/domirama2/utils/didactique_functions.sh` et `poc-design/domiramaCatOps/utils/didactique_functions.sh`

**Modification** :

```bash
setup_paths() {
    # Détecter le répertoire du script appelant
    local caller_script="${BASH_SOURCE[1]:-${BASH_SOURCE[0]}}"
    SCRIPT_DIR="$(cd "$(dirname "$caller_script")" && pwd)"

    # Charger la configuration centralisée (priorité 1)
    local config_file="${ARKEA_HOME:-$(cd "$SCRIPT_DIR/../.." && pwd)}/.poc-config.sh"
    if [ -f "$config_file" ]; then
        source "$config_file"
    fi

    # Détecter INSTALL_DIR (racine du projet Arkea)
    # Priorité 1: Variable d'environnement ARKEA_HOME (définie par .poc-config.sh)
    # Priorité 2: Détection automatique (2 niveaux au-dessus de domirama2/domiramaCatOps)
    if [ -z "${ARKEA_HOME:-}" ]; then
        INSTALL_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
        export ARKEA_HOME="$INSTALL_DIR"
    else
        INSTALL_DIR="$ARKEA_HOME"
    fi

    # Configuration HCD (déjà chargée par .poc-config.sh, mais fallback si nécessaire)
    HCD_DIR="${HCD_DIR:-${HCD_HOME:-${INSTALL_DIR}/binaire/hcd-1.2.3}}"

    # Configuration Spark (déjà chargée par .poc-config.sh, mais fallback si nécessaire)
    SPARK_HOME="${SPARK_HOME:-${INSTALL_DIR}/binaire/spark-3.5.1}"

    # Configuration HCD Host/Port (déjà chargée par .poc-config.sh, mais fallback si nécessaire)
    HCD_HOST="${HCD_HOST:-localhost}"
    HCD_PORT="${HCD_PORT:-9042}"

    # Exporter les variables pour qu'elles soient disponibles dans le script appelant
    export SCRIPT_DIR INSTALL_DIR HCD_DIR SPARK_HOME HCD_HOST HCD_PORT
}
```

---

### 2.3 Script de Migration Automatique

**Créer** : `scripts/migrate_hardcoded_paths.sh`

```bash
#!/bin/bash
# =============================================================================
# Script de Migration : Remplacement des Chemins Hardcodés
# =============================================================================
# Remplace tous les INSTALL_DIR hardcodés par setup_paths()
# =============================================================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ARKEA_HOME="${ARKEA_HOME:-$(cd "$SCRIPT_DIR/.." && pwd)}"

# Pattern à rechercher
HARDCODED_PATTERN='INSTALL_DIR="${ARKEA_HOME}"'
HARDCODED_PATTERN_ALT='INSTALL_DIR=.*"${USER_HOME:-$HOME}'

# Répertoires à traiter
DIRS=(
    "$ARKEA_HOME/poc-design/domirama2/scripts"
    "$ARKEA_HOME/poc-design/domiramaCatOps/scripts"
    "$ARKEA_HOME/poc-design/domirama/scripts"
    "$ARKEA_HOME"
)

# Fonction de remplacement
replace_hardcoded_paths() {
    local file="$1"
    local temp_file="${file}.tmp"

    # Lire le fichier
    local content
    content=$(cat "$file")

    # Vérifier si le fichier contient le pattern
    if ! echo "$content" | grep -q "$HARDCODED_PATTERN\|$HARDCODED_PATTERN_ALT"; then
        return 0  # Pas de remplacement nécessaire
    fi

    # Remplacer INSTALL_DIR hardcodé par setup_paths()
    # Pattern: INSTALL_DIR="${ARKEA_HOME}"
    # Remplacer par: setup_paths() (via fonction)

    # Créer le nouveau contenu
    local new_content
    new_content=$(echo "$content" | sed -E "
        # Supprimer les lignes INSTALL_DIR hardcodées
        /INSTALL_DIR=.*\"\/Users\/david\.leconte/d

        # Si setup_paths n'existe pas, l'ajouter après set -euo pipefail
        /^set -euo pipefail/a\\
# Configuration - Utiliser setup_paths si disponible\\
SCRIPT_DIR=\"\$(cd \"\$(dirname \"\${BASH_SOURCE[0]}\")\" \&\& pwd)\"\\
if [ -f \"\$SCRIPT_DIR/../utils/didactique_functions.sh\" ]; then\\
    source \"\$SCRIPT_DIR/../utils/didactique_functions.sh\"\\
    setup_paths\\
else\\
    # Fallback si les fonctions ne sont pas disponibles\\
    INSTALL_DIR=\"\${ARKEA_HOME:-\$(cd \"\$SCRIPT_DIR/../..\" \&\& pwd)}\"\\
    HCD_DIR=\"\${HCD_DIR:-\${INSTALL_DIR}/binaire/hcd-1.2.3}\"\\
    SPARK_HOME=\"\${SPARK_HOME:-\${INSTALL_DIR}/binaire/spark-3.5.1}\"\\
    HCD_HOST=\"\${HCD_HOST:-localhost}\"\\
    HCD_PORT=\"\${HCD_PORT:-9042}\"\\
fi
    ")

    # Écrire le nouveau contenu
    echo "$new_content" > "$temp_file"
    mv "$temp_file" "$file"

    echo "✅ Migré: $file"
}

# Traiter tous les fichiers
for dir in "${DIRS[@]}"; do
    if [ ! -d "$dir" ]; then
        continue
    fi

    echo "📁 Traitement de: $dir"
    find "$dir" -type f -name "*.sh" | while read -r file; do
        replace_hardcoded_paths "$file"
    done
done

echo "✅ Migration terminée"
```

---

## 📝 Plan d'Action Détaillé

### Phase 1 : Préparation (1-2 heures)

1. ✅ **Créer `.poc-config.sh`** à la racine
   - Configuration centralisée avec détection automatique
   - Support multi-OS (macOS, Linux)
   - Variables d'environnement prioritaires

2. ✅ **Mettre à jour `setup_paths()`**
   - Charger `.poc-config.sh` en premier
   - Fallback automatique si config absente
   - Compatibilité ascendante

3. ✅ **Créer script de migration**
   - Détecter tous les chemins hardcodés
   - Remplacer par `setup_paths()`
   - Backup automatique

### Phase 2 : Migration (2-3 heures)

4. ✅ **Exécuter script de migration**
   - Tous les scripts shell
   - Tous les fichiers Python
   - Vérification manuelle des cas spéciaux

5. ✅ **Mettre à jour `.poc-profile`**
   - Utiliser `.poc-config.sh` au lieu de chemins hardcodés
   - Détection automatique des chemins Mac/Linux
   - Compatibilité ascendante

6. ✅ **Mettre à jour scripts racine**
   - `01_install_hcd.sh`
   - `02_install_spark_kafka.sh`
   - `03_start_hcd.sh`
   - `05_setup_kafka_hcd_streaming.sh`
   - `06_test_kafka_hcd_streaming.sh`
   - `80_verify_all.sh`

### Phase 3 : Tests et Validation (1-2 heures)

7. ✅ **Tests de validation** - **COMPLÉTÉ**
   - ✅ Vérifier que tous les scripts fonctionnent
   - ✅ Tester sur machine différente (si possible)
   - ✅ Vérifier détection automatique

8. ✅ **Documentation** - **COMPLÉTÉ**
   - ✅ Guide de configuration (`CONFIGURATION_ENVIRONNEMENT.md`)
   - ✅ Variables d'environnement disponibles
   - ✅ Guides d'installation cross-platform

### Phase 4 : Portabilité Cross-Platform (2-3 heures) - **NOUVELLE PHASE**

9. ✅ **Fonctions portables** - **COMPLÉTÉ**
   - ✅ `scripts/utils/portable_functions.sh` créé
   - ✅ `get_realpath()` pour macOS/Linux/Windows
   - ✅ `check_port()` pour vérification de port
   - ✅ `kill_process()` pour arrêt de processus
   - ✅ `detect_os()` pour détection OS

10. ✅ **Scripts d'installation Linux** - **COMPLÉTÉ**
    - ✅ `scripts/setup/02_install_kafka_linux.sh` créé
    - ✅ Support Ubuntu, CentOS, RHEL, Debian, Fedora

11. ✅ **Guides d'installation** - **COMPLÉTÉ**
    - ✅ `docs/GUIDE_INSTALLATION_LINUX.md` créé
    - ✅ `docs/GUIDE_INSTALLATION_WINDOWS.md` créé
    - ✅ `docs/GUIDE_INSTALLATION_HCD.md` généralisé (cross-platform)

12. ✅ **Tests CI Multi-OS** - **COMPLÉTÉ**
    - ✅ `.github/workflows/test-multi-os.yml` créé
    - ✅ Tests Linux, macOS, Windows (WSL2) préparés

- Exemples d'utilisation

### Phase 4 : Nettoyage (30 minutes)

9. ✅ **Supprimer fichiers obsolètes**
   - Anciens fichiers de config
   - Scripts de migration temporaires

10. ✅ **Mettre à jour README**
    - Instructions de configuration
    - Variables d'environnement
    - Exemples

---

## 🎯 Recommandations Finales

### Option 1 : Configuration Centralisée (Recommandée)

**Avantages** :

- ✅ Un seul fichier de configuration
- ✅ Détection automatique multi-OS
- ✅ Variables d'environnement prioritaires
- ✅ Portable entre machines

**Inconvénients** :

- ⚠️ Nécessite migration de tous les scripts
- ⚠️ Tests nécessaires sur différentes machines

### Option 2 : Variables d'Environnement Uniquement

**Avantages** :

- ✅ Très portable
- ✅ Pas de fichier de config à maintenir

**Inconvénients** :

- ❌ Nécessite configuration manuelle sur chaque machine
- ❌ Pas de valeurs par défaut

### Option 3 : Hybrid (Recommandée)

**Architecture** :

1. Variables d'environnement (priorité maximale)
2. `.poc-config.sh` (valeurs par défaut portables)
3. Détection automatique (fallback)

**Avantages** :

- ✅ Flexibilité maximale
- ✅ Portable par défaut
- ✅ Surchargeable par variables d'environnement

---

## ✅ Conclusion

**Recommandation** : **Option 3 (Hybrid)** avec `.poc-config.sh` + `setup_paths()` + variables d'environnement.

**Priorité** : **Haute** - Bloque la portabilité du projet.

**Estimation** : **4-6 heures** pour migration complète.

---

**Date** : 2025-12-01  
**Version** : 1.0  
**Statut** : ✅ **Plan d'action complet**
