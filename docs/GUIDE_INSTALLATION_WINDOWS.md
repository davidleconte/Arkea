# 🪟 Guide d'Installation Windows - ARKEA

**Date** : 2026-03-13
**Objectif** : Guide complet pour installer et configurer le projet ARKEA sur Windows via WSL2
**Version** : 1.0

---

## 📋 Table des Matières

- [Prérequis](#prérequis)
- [Installation WSL2](#installation-wsl2)
- [Installation dans WSL2](#installation-dans-wsl2)
- [Configuration](#configuration)
- [Utilisation](#utilisation)
- [Dépannage](#dépannage)
- [Alternatives](#alternatives)

---

## ⚠️ Important

**Le projet ARKEA nécessite un environnement Unix/Linux pour fonctionner.**

**Options sur Windows** :

1. ✅ **WSL2 (Recommandé)** - Windows Subsystem for Linux 2
2. ⚠️ **Git Bash** - Partiel (certaines fonctionnalités ne fonctionnent pas)
3. ⚠️ **Podman Desktop** - Pour conteneurisation (voir ADR-0001)
4. ❌ **PowerShell** - Nécessiterait réécriture complète des scripts

**Ce guide se concentre sur WSL2**, qui est la solution recommandée.

---

## 🔧 Prérequis

### Système d'Exploitation

- ✅ **Windows 10** version 2004+ (Build 19041+)
- ✅ **Windows 11** (recommandé)
- ✅ **Windows Server 2019+**

### Exigences Système

- ✅ **Virtualisation activée** (BIOS/UEFI)
- ✅ **Au moins 4 GB de RAM** (8 GB recommandé)
- ✅ **Espace disque** : Au moins 10 GB libres

---

## 📦 Installation WSL2

### 1. Vérifier les Prérequis

**Vérifier la version de Windows** :

```powershell
winver
# Doit afficher Windows 10 version 2004+ ou Windows 11
```

**Vérifier si WSL est déjà installé** :

```powershell
wsl --list --verbose
```

---

### 2. Installer WSL2

#### Option 1 : Installation Automatique (Recommandé)

```powershell
# Exécuter PowerShell en tant qu'administrateur
wsl --install
```

**Ceci installe** :

- WSL2
- Ubuntu (distribution Linux par défaut)
- Kernel Linux pour WSL2

**Redémarrer Windows** après l'installation.

---

#### Option 2 : Installation Manuelle

```powershell
# Exécuter PowerShell en tant qu'administrateur

# 1. Activer les fonctionnalités Windows
dism.exe /online /enable-feature /featurename:Microsoft-Windows-Subsystem-Linux /all /norestart
dism.exe /online /enable-feature /featurename:VirtualMachinePlatform /all /norestart

# 2. Redémarrer Windows

# 3. Télécharger et installer le kernel Linux
# Télécharger depuis : https://aka.ms/wsl2kernel
# Installer le package .msixbundle

# 4. Définir WSL2 comme version par défaut
wsl --set-default-version 2

# 5. Installer Ubuntu
wsl --install -d Ubuntu
```

---

### 3. Configurer Ubuntu

**Lancer Ubuntu** (depuis le menu Démarrer ou PowerShell) :

```bash
# Créer un utilisateur et un mot de passe
# (suivre les instructions à l'écran)
```

**Mettre à jour Ubuntu** :

```bash
sudo apt-get update
sudo apt-get upgrade -y
```

---

### 4. Vérifier l'Installation

```powershell
# Depuis PowerShell
wsl --list --verbose
# Doit afficher Ubuntu avec VERSION 2
```

```bash
# Depuis WSL2 (Ubuntu)
uname -a
# Doit afficher Linux avec kernel 5.x+
```

---

## 📦 Installation dans WSL2

### 1. Accéder à WSL2

**Depuis PowerShell** :

```powershell
wsl
# Ouvre Ubuntu dans WSL2
```

**Depuis le menu Démarrer** :

- Rechercher "Ubuntu"
- Cliquer sur l'application Ubuntu

---

### 2. Installer les Prérequis

**Suivre le guide Linux (legacy)** : `docs/archive/legacy_v1/GUIDE_INSTALLATION_LINUX.md`

**Résumé rapide** :

```bash
# Mettre à jour
sudo apt-get update

# Installer Java 11 et 17
sudo apt-get install -y openjdk-11-jdk openjdk-17-jdk

# Installer Python 3.11
sudo apt-get install -y python3.11 python3-pip

# Installer les outils
sudo apt-get install -y curl wget tar gzip git
```

**Configurer JAVA_HOME** :

```bash
export JAVA_HOME=/usr/lib/jvm/java-11-openjdk-amd64
export JAVA17_HOME=/usr/lib/jvm/java-17-openjdk-amd64
echo 'export JAVA_HOME=/usr/lib/jvm/java-11-openjdk-amd64' >> ~/.bashrc
echo 'export JAVA17_HOME=/usr/lib/jvm/java-17-openjdk-amd64' >> ~/.bashrc
echo 'export PATH=$JAVA_HOME/bin:$PATH' >> ~/.bashrc
source ~/.bashrc
```

---

### 3. Cloner le Projet

```bash
# Dans WSL2
cd ~
git clone https://github.com/votre-org/Arkea.git
cd Arkea
```

**Note** : Le système de fichiers Windows est accessible depuis WSL2 via `/mnt/c/`, `/mnt/d/`, etc.

**Exemple** :

```bash
# Accéder au disque C: depuis WSL2
cd /mnt/c/Users/VotreNom/Documents
```

---

### 4. Installer les Composants

**Suivre les étapes du guide Linux** :

```bash
# 1. Configurer l'environnement
source .poc-profile

# 2. Installer HCD
./scripts/setup/01_install_hcd.sh

# 3. Installer Spark et Kafka
./scripts/setup/02_install_spark_kafka.sh
./scripts/setup/02_install_kafka_linux.sh

# 4. Vérifier
./scripts/utils/80_verify_all.sh
```

---

## ⚙️ Configuration

### 1. Accès aux Fichiers Windows

**Depuis WSL2, accéder aux fichiers Windows** :

```bash
# Accéder au disque C:
cd /mnt/c/Users/VotreNom/Documents/Arkea

# Accéder au disque D:
cd /mnt/d/
```

**Depuis Windows, accéder aux fichiers WSL2** :

```text
\\wsl$\Ubuntu\home\votrenom\Arkea
```

---

### 2. Variables d'Environnement

**Dans WSL2** :

```bash
# Ajouter à ~/.bashrc
export ARKEA_HOME="$HOME/Arkea"
export JAVA_HOME=/usr/lib/jvm/java-11-openjdk-amd64
export JAVA17_HOME=/usr/lib/jvm/java-17-openjdk-amd64

source ~/.bashrc
```

---

### 3. Ports et Réseau

**Les ports sont partagés entre Windows et WSL2** :

- `localhost:9102` (HCD) accessible depuis Windows
- `localhost:9192` (Kafka) accessible depuis Windows

**Tester depuis Windows** :

```powershell
# Tester la connexion HCD
Test-NetConnection -ComputerName localhost -Port 9102
```

---

## 🚀 Utilisation

### 1. Démarrer les Services

**Depuis WSL2** :

```bash
# Démarrer HCD
./scripts/setup/03_start_hcd.sh background

# Démarrer Kafka
./scripts/setup/04_start_kafka.sh background
```

**Vérifier depuis Windows** :

```powershell
# Vérifier les ports
netstat -an | findstr "9102"
netstat -an | findstr "9192"
```

---

### 2. Accéder aux Services depuis Windows

**HCD (cqlsh)** :

```bash
# Depuis WSL2
cqlsh localhost 9042
```

**Kafka** :

```bash
# Depuis WSL2
kafka-topics.sh --list --bootstrap-server localhost:9192
```

---

### 3. Intégration avec Windows

**Éditeurs de Code** :

- ✅ **VS Code** avec extension "Remote - WSL"
- ✅ **IntelliJ IDEA** avec support WSL2
- ✅ **Visual Studio** avec support WSL2

**Terminal** :

- ✅ **Windows Terminal** (recommandé)
- ✅ **PowerShell** avec `wsl` command
- ✅ **Ubuntu** (application WSL2)

---

## 🔧 Dépannage

### Problèmes Courants

#### WSL2 ne démarre pas

**Symptômes** :

- Erreur "WSL 2 requires an update to its kernel component"
- Erreur "The requested operation could not be completed"

**Solutions** :

```powershell
# Vérifier la version de WSL
wsl --list --verbose

# Mettre à jour WSL2
wsl --update

# Redémarrer WSL2
wsl --shutdown
wsl
```

---

#### Virtualisation non activée

**Symptômes** :

- Erreur "Virtualization is not enabled"
- WSL2 ne démarre pas

**Solutions** :

1. **Activer la virtualisation dans le BIOS/UEFI** :
   - Redémarrer et entrer dans le BIOS
   - Activer "Virtualization Technology" ou "VT-x"
   - Sauvegarder et redémarrer

2. **Vérifier depuis Windows** :

```powershell
systeminfo | findstr /C:"Hyper-V Requirements"
```

---

#### Problèmes de Performance

**Symptômes** :

- WSL2 lent
- Services qui mettent du temps à démarrer

**Solutions** :

1. **Placer les fichiers dans le système de fichiers WSL2** (pas sur `/mnt/c/`) :

```bash
# Éviter
cd /mnt/c/Users/VotreNom/Documents/Arkea

# Préférer
cd ~/Arkea
```

1. **Augmenter la mémoire allouée à WSL2** :
Créer `%UserProfile%\.wslconfig` :

```ini
[wsl2]
memory=8GB
processors=4
swap=2GB
```

Redémarrer WSL2 :

```powershell
wsl --shutdown
wsl
```

---

#### Ports déjà utilisés

**Symptômes** :

- Erreur "Address already in use"
- Services ne démarrent pas

**Solutions** :

```bash
# Dans WSL2, vérifier les ports
ss -tuln | grep 9042
ss -tuln | grep 9092

# Tuer les processus
pkill -f cassandra
pkill -f kafka
```

---

## 🔄 Alternatives

### Git Bash (Partiel)

**Limitations** :

- ❌ `lsof` non disponible
- ❌ `pkill` non disponible
- ⚠️ Certaines commandes Unix ne fonctionnent pas
- ⚠️ Performance réduite

**Utilisation** :

```bash
# Installer Git Bash depuis : https://git-scm.com/downloads
# Ouvrir Git Bash
cd /c/Users/VotreNom/Documents/Arkea
./scripts/setup/01_install_hcd.sh
```

---

### Podman Desktop (Recommandé par ADR-0001)

> ⚠️ **Important** : Ce projet utilise **Podman** au lieu de Docker conformément à l'ADR-0001.

**Installation** :

```bash
# Installer Podman Desktop depuis : https://podman-desktop.io/downloads
# ou via winget
winget install RedHat.Podman-Desktop

# Initialiser une machine Podman
podman machine init
podman machine start
```

**Utilisation** :

```bash
# Créer un conteneur Linux
podman run -it ubuntu:20.04 bash

# Installer les dépendances dans le conteneur
# Suivre le guide Linux
```

**Avantages vs Docker Desktop** :

- ✅ Open source et gratuit
- ✅ Architecture daemonless (plus sécurisé)
- ✅ Compatible avec les images OCI/Docker
- ✅ Pas de licence commerciale requise

---

## 📚 Références

- `docs/archive/legacy_v1/GUIDE_INSTALLATION_LINUX.md` - Guide Linux (legacy, utilisé dans WSL2)
- `docs/DEPLOYMENT.md` - Guide de déploiement général
- `docs/TROUBLESHOOTING.md` - Guide de dépannage détaillé
- [Documentation WSL2 Microsoft](https://docs.microsoft.com/en-us/windows/wsl/)
- [VS Code Remote - WSL](https://code.visualstudio.com/docs/remote/wsl)

---

## ✅ Checklist d'Installation

- [ ] Windows 10 version 2004+ ou Windows 11
- [ ] WSL2 installé et configuré
- [ ] Ubuntu installé dans WSL2
- [ ] Java 17 (actif) et Java 11 (legacy binaire) installés
- [ ] Python 3.11 installé
- [ ] Projet ARKEA cloné
- [ ] HCD installé
- [ ] Spark installé
- [ ] Kafka installé
- [ ] Services démarrés et fonctionnels
- [ ] Tests passés

---

**Date** : 2026-03-13
**Version** : 1.0
**Statut** : ✅ **Documentation complète**
