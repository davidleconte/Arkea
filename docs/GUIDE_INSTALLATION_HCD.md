# Guide d'Installation HCD 1.2.3 (Cross-Platform)

**Référence** : [DataStax HCD Installation Documentation](https://docs.datastax.com/en/hyper-converged-database/1.2/install/install-tarball.html)

**Date** : 2025-12-02 (Mise à jour pour portabilité cross-platform)  
**Systèmes supportés** : macOS, Linux, Windows (WSL2)

---

## 📋 Table des Matières

- [Prérequis](#prérequis)
- [Installation Automatique](#installation-automatique)
- [Installation Manuelle](#installation-manuelle)
  - [macOS](#macos)
  - [Linux](#linux)
  - [Windows (WSL2)](#windows-wsl2)
- [Configuration](#configuration)
- [Démarrage](#démarrage)
- [Vérification](#vérification)
- [Dépannage](#dépannage)

---

## 📋 Prérequis

### Systèmes d'Exploitation

- ✅ **macOS** 12+ (testé sur MacBook Pro M3 Pro)
- ✅ **Linux** (Ubuntu 20.04+, CentOS 7+, RHEL 7+, Debian 10+, Fedora 30+)
- ✅ **Windows** (via WSL2)

### Logiciels Requis

- ✅ **Java 11** (requis par HCD)
- ✅ **Python 3.8-3.11** (pour cqlsh)
- ✅ **HCD Tarball** : `hcd-1.2.3-bin.tar.gz` (87MB)

---

## 🚀 Installation Automatique (Recommandé)

**Utiliser le script d'installation automatique** :

```bash
# Charger la configuration
source .poc-profile

# Installer HCD (détection automatique de l'OS)
./scripts/setup/01_install_hcd.sh
```

**Ce script** :
- ✅ Détecte automatiquement l'OS
- ✅ Configure Java 11 automatiquement
- ✅ Extrait HCD dans `binaire/hcd-1.2.3/`
- ✅ Configure les permissions
- ✅ Crée les répertoires de données

**Voir** :
- `docs/GUIDE_INSTALLATION_LINUX.md` pour les détails Linux
- `docs/GUIDE_INSTALLATION_WINDOWS.md` pour Windows (WSL2)

---

## 🔧 Installation Manuelle

### macOS

#### Étape 1 : Installation de Java 11

**Option A : Via Homebrew (Recommandé)**

```bash
# Installer OpenJDK 11
brew install openjdk@11

# Lier Java 11
sudo ln -sfn /opt/homebrew/opt/openjdk@11/libexec/openjdk.jdk /Library/Java/JavaVirtualMachines/openjdk-11.jdk

# Vérifier l'installation
/opt/homebrew/opt/openjdk@11/bin/java -version
```

**Option B : Via jenv (Si vous utilisez jenv)**

```bash
# Installer Java 11 via jenv
jenv add /opt/homebrew/opt/openjdk@11/libexec/openjdk.jdk/Contents/Home

# Activer Java 11 pour ce projet
jenv local 11
```

#### Étape 2 : Configuration JAVA_HOME

```bash
# Pour Homebrew
export JAVA_HOME=/opt/homebrew/opt/openjdk@11/libexec/openjdk.jdk/Contents/Home

# Pour jenv
export JAVA_HOME=$(jenv prefix 11)

# Vérifier
echo $JAVA_HOME
java -version
```

**Persistance** (ajouter dans `~/.zshrc` ou `~/.bash_profile`) :
```bash
# HCD Java 11 Configuration
export JAVA_HOME=/opt/homebrew/opt/openjdk@11/libexec/openjdk.jdk/Contents/Home
export PATH="$JAVA_HOME/bin:$PATH"
```

#### Étape 3 : Installation HCD

```bash
# Détecter automatiquement le répertoire du projet
cd "${ARKEA_HOME:-$(pwd)}"

# Extraire HCD
tar xvzf software/hcd-1.2.3-bin.tar.gz -C binaire

# Vérifier l'extraction
ls -la binaire/hcd-1.2.3/
```

---

### Linux

#### Étape 1 : Installation de Java 11

**Ubuntu/Debian** :
```bash
sudo apt-get update
sudo apt-get install -y openjdk-11-jdk
```

**CentOS/RHEL** :
```bash
sudo yum install -y java-11-openjdk-devel
```

**Fedora** :
```bash
sudo dnf install -y java-11-openjdk-devel
```

#### Étape 2 : Configuration JAVA_HOME

```bash
# Ubuntu/Debian
export JAVA_HOME=/usr/lib/jvm/java-11-openjdk-amd64

# CentOS/RHEL
export JAVA_HOME=/usr/lib/jvm/java-11-openjdk

# Vérifier
echo $JAVA_HOME
java -version
```

**Persistance** (ajouter dans `~/.bashrc`) :
```bash
# HCD Java 11 Configuration
export JAVA_HOME=/usr/lib/jvm/java-11-openjdk-amd64
export PATH="$JAVA_HOME/bin:$PATH"
```

#### Étape 3 : Installation HCD

```bash
# Détecter automatiquement le répertoire du projet
cd "${ARKEA_HOME:-$(pwd)}"

# Extraire HCD
tar xvzf software/hcd-1.2.3-bin.tar.gz -C binaire

# Vérifier l'extraction
ls -la binaire/hcd-1.2.3/
```

---

### Windows (WSL2)

**Suivre le guide Linux** dans WSL2 : Voir `docs/GUIDE_INSTALLATION_WINDOWS.md`

**Résumé** :
1. Installer WSL2 et Ubuntu
2. Suivre les étapes Linux ci-dessus
3. Utiliser les chemins WSL2 (`/home/username/Arkea`)

---

## ⚙️ Configuration

### Configuration des Répertoires de Données (Optionnel)

Par défaut, HCD stocke les données dans l'installation. Pour un environnement de développement, vous pouvez créer des répertoires personnalisés :

```bash
# Détecter automatiquement le répertoire du projet
cd "${ARKEA_HOME:-$(pwd)}"

# Créer les répertoires de données
mkdir -p hcd-data/{data,commitlog,saved_caches,hints,cdc_raw}

# Vérifier
ls -la hcd-data/
```

### Configuration cassandra.yaml (Si répertoires personnalisés)

Si vous avez créé des répertoires personnalisés, éditez `binaire/hcd-1.2.3/resources/cassandra/conf/cassandra.yaml` :

```yaml
data_file_directories:
  - ${ARKEA_HOME}/hcd-data/data
commitlog_directory: ${ARKEA_HOME}/hcd-data/commitlog
saved_caches_directory: ${ARKEA_HOME}/hcd-data/saved_caches
hints_directory: ${ARKEA_HOME}/hcd-data/hints
cdc_raw_directory: ${ARKEA_HOME}/hcd-data/cdc_raw
```

**Note** : Utiliser des variables d'environnement ou des chemins relatifs pour la portabilité.

---

## 🚀 Démarrage

### Démarrage Basique

```bash
# Charger la configuration
source .poc-profile

# Démarrer HCD
./scripts/setup/03_start_hcd.sh
```

### Démarrage en Arrière-plan

```bash
# Démarrer HCD en arrière-plan
./scripts/setup/03_start_hcd.sh background
```

### Démarrage Manuel

```bash
# Détecter automatiquement le répertoire
cd "${ARKEA_HOME:-$(pwd)}/binaire/hcd-1.2.3"

# Vérifier Java 11
java -version

# Démarrer HCD
bin/hcd cassandra
```

### Démarrage avec Logs Personnalisés

```bash
cd "${ARKEA_HOME:-$(pwd)}/binaire/hcd-1.2.3"

# Créer répertoire de logs
mkdir -p logs

# Démarrer avec logs personnalisés
CASSANDRA_LOG_DIR=$(pwd)/logs bin/hcd cassandra
```

---

## ✅ Vérification

### Vérifier que HCD est Démarré

**Utiliser le script de vérification** :
```bash
./scripts/utils/80_verify_all.sh
```

**Vérification manuelle** :
```bash
# Vérifier les processus (fonction portable)
source scripts/utils/portable_functions.sh
check_port 9042 && echo "✅ HCD est démarré (port 9042 utilisé)" || echo "❌ HCD n'est pas démarré"

# Ou utiliser les commandes natives
# macOS/Linux
lsof -i :9042 || ss -tuln | grep 9042

# Windows (WSL2)
netstat -an | grep 9042
```

### Connexion avec cqlsh

```bash
# Installer cqlsh si nécessaire
pip3 install cqlsh

# Se connecter à HCD
cqlsh localhost 9042
```

**Dans cqlsh** :
```cql
-- Vérifier la version
SELECT release_version FROM system.local;

-- Lister les keyspaces
DESCRIBE KEYSPACES;

-- Quitter
EXIT;
```

---

## 🔐 Sécurisation (Important pour Production)

### ⚠️ Attention : Utilisateur par Défaut

HCD crée un utilisateur `cassandra` par défaut avec privilèges administrateur. **Changez ou supprimez cet utilisateur avant la production.**

### Créer un Superuser Personnalisé

```bash
# Se connecter avec cqlsh
cqlsh localhost 9042

# Créer un nouveau superuser
CREATE ROLE admin WITH SUPERUSER = true AND LOGIN = true AND PASSWORD = 'VotreMotDePasseSecurise';

# Se connecter avec le nouveau superuser
cqlsh -u admin -p 'VotreMotDePasseSecurise' localhost 9042

# Désactiver l'utilisateur cassandra par défaut (optionnel)
ALTER ROLE cassandra WITH SUPERUSER = false;
```

---

## 🛠️ Dépannage

### Problème : HCD ne démarre pas

**Vérifications** :
```bash
# 1. Vérifier Java 11
java -version
echo $JAVA_HOME

# 2. Vérifier les logs
tail -f binaire/hcd-1.2.3/logs/system.log

# 3. Vérifier les ports (fonction portable)
source scripts/utils/portable_functions.sh
check_port 9042 && echo "Port 9042 utilisé" || echo "Port 9042 libre"
```

### Problème : Port déjà utilisé

```bash
# Utiliser la fonction portable
source scripts/utils/portable_functions.sh
kill_process cassandra

# Ou manuellement
# macOS/Linux
pkill -f cassandra

# Windows (WSL2)
pgrep -f cassandra | xargs kill -9
```

### Problème : Erreur de permissions

```bash
# Donner les permissions nécessaires
chmod +x binaire/hcd-1.2.3/bin/hcd
```

### Problème : Architecture ARM64 (macOS)

HCD 1.2.3 devrait fonctionner sur ARM64 (Apple Silicon). Si problème :

1. Vérifier que Java 11 est compatible ARM64
2. Utiliser Rosetta 2 si nécessaire (non recommandé)
3. Contacter DataStax Support pour version ARM64 native

---

## 📝 Commandes Utiles

### Gestion HCD

```bash
# Démarrer HCD (script portable)
./scripts/setup/03_start_hcd.sh background

# Arrêter HCD (fonction portable)
source scripts/utils/portable_functions.sh
kill_process cassandra

# Vérifier le statut
nodetool status

# Voir les informations du cluster
nodetool info
```

### Connexion CQL

```bash
# Connexion simple
cqlsh localhost 9042

# Connexion avec utilisateur
cqlsh -u admin -p password localhost 9042

# Exécuter un script CQL
cqlsh localhost 9042 -f script.cql
```

---

## 🎯 Prochaines Étapes

Une fois HCD installé et démarré :

1. ✅ **Créer les schémas Domirama/BIC** (voir guides POC)
2. ✅ **Configurer Spark pour se connecter à HCD**
3. ✅ **Développer les jobs Spark** (ingestion, détection, exposition)
4. ✅ **Tester la migration HBase → HCD**

---

## 📚 Références

- [DataStax HCD Installation Guide](https://docs.datastax.com/en/hyper-converged-database/1.2/install/install-tarball.html)
- [HCD Documentation](https://docs.datastax.com/en/hyper-converged-database/1.2/)
- [CQL Reference](https://docs.datastax.com/en/cql-oss/3.3/cql/cql_reference/)
- `docs/GUIDE_INSTALLATION_LINUX.md` - Guide Linux détaillé
- `docs/GUIDE_INSTALLATION_WINDOWS.md` - Guide Windows (WSL2)
- `docs/AUDIT_PORTABILITE_CROSS_PLATFORM_2025.md` - Détails portabilité

---

## ✅ Checklist d'Installation

- [ ] Java 11 installé et configuré
- [ ] JAVA_HOME pointant vers Java 11
- [ ] HCD extrait (`binaire/hcd-1.2.3/`)
- [ ] Répertoires de données créés (optionnel)
- [ ] HCD démarré avec succès
- [ ] Connexion cqlsh fonctionnelle
- [ ] Keyspace POC créé
- [ ] Utilisateur par défaut sécurisé (pour production)

---

**Prêt à installer ?** Utilisez le script automatique ou suivez les étapes manuelles selon votre OS ! 🚀
