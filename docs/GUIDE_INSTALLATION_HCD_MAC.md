# Guide d'Installation HCD 1.2.3 sur MacBook Pro M3 Pro

**Référence** : [DataStax HCD Installation Documentation](https://docs.datastax.com/en/hyper-converged-database/1.2/install/install-tarball.html)

**Date** : 2025-11-25  
**Système** : macOS sur MacBook Pro M3 Pro (ARM64)

---

## 📋 Prérequis

### État Actuel de Votre Système

✅ **Python** : 3.10.11 (compatible, plage requise : 3.8-3.11)  
⚠️ **Java** : OpenJDK 23.0.2 (HCD requiert Java 11)  
✅ **Architecture** : ARM64 (M3 Pro)  
✅ **HCD Tarball** : `hcd-1.2.3-bin.tar.gz` disponible (87MB)

### Actions Requises

1. **Installer Java 11** (requis par HCD)
2. **Configurer JAVA_HOME** vers Java 11
3. **Extraire et installer HCD**

---

## 🔧 Étape 1 : Installation de Java 11

### Option A : Via Homebrew (Recommandé)

```bash
# Installer OpenJDK 11
brew install openjdk@11

# Lier Java 11
sudo ln -sfn /opt/homebrew/opt/openjdk@11/libexec/openjdk.jdk /Library/Java/JavaVirtualMachines/openjdk-11.jdk

# Vérifier l'installation
/opt/homebrew/opt/openjdk@11/bin/java -version
```

### Option B : Via jenv (Si vous utilisez jenv)

```bash
# Installer Java 11 via jenv
jenv add /opt/homebrew/opt/openjdk@11/libexec/openjdk.jdk/Contents/Home

# Activer Java 11 pour ce projet
jenv local 11
```

### Vérification

```bash
# Vérifier que Java 11 est disponible
java -version
# Doit afficher : openjdk version "11.x.x"
```

---

## 🔧 Étape 2 : Configuration JAVA_HOME

### Définir JAVA_HOME pour Java 11

```bash
# Pour Homebrew
export JAVA_HOME=/opt/homebrew/opt/openjdk@11/libexec/openjdk.jdk/Contents/Home

# Pour jenv
export JAVA_HOME=$(jenv prefix)

# Vérifier
echo $JAVA_HOME
java -version
```

### Persistance (Optionnel - pour la session)

Ajouter dans `~/.zshrc` ou `~/.bash_profile` :

```bash
# HCD Java 11 Configuration
export JAVA_HOME=/opt/homebrew/opt/openjdk@11/libexec/openjdk.jdk/Contents/Home
export PATH="$JAVA_HOME/bin:$PATH"
```

---

## 🔧 Étape 3 : Installation HCD

### 3.1 Extraction du Tarball

```bash
cd /Users/david.leconte/Documents/Arkea

# Extraire HCD
tar xvzf hcd-1.2.3-bin.tar.gz

# Vérifier l'extraction
ls -la hcd-1.2.3/
```

**Structure attendue** :
```
hcd-1.2.3/
├── bin/
│   └── hcd
├── resources/
│   └── cassandra/
│       └── conf/
│           └── cassandra.yaml
├── lib/
└── ...
```

### 3.2 Configuration des Répertoires de Données (Optionnel)

Par défaut, HCD stocke les données dans l'installation. Pour un environnement de développement, vous pouvez créer des répertoires personnalisés :

```bash
cd /Users/david.leconte/Documents/Arkea

# Créer les répertoires de données
mkdir -p hcd-data/{data,commitlog,saved_caches,hints,cdc_raw}

# Vérifier
ls -la hcd-data/
```

### 3.3 Configuration cassandra.yaml (Si répertoires personnalisés)

Si vous avez créé des répertoires personnalisés, éditez `hcd-1.2.3/resources/cassandra/conf/cassandra.yaml` :

```yaml
data_file_directories:
  - /Users/david.leconte/Documents/Arkea/hcd-data/data
commitlog_directory: /Users/david.leconte/Documents/Arkea/hcd-data/commitlog
saved_caches_directory: /Users/david.leconte/Documents/Arkea/hcd-data/saved_caches
hints_directory: /Users/david.leconte/Documents/Arkea/hcd-data/hints
cdc_raw_directory: /Users/david.leconte/Documents/Arkea/hcd-data/cdc_raw
```

---

## 🚀 Étape 4 : Démarrage HCD

### 4.1 Démarrage Basique

```bash
cd /Users/david.leconte/Documents/Arkea/hcd-1.2.3

# Vérifier Java 11
java -version

# Démarrer HCD
bin/hcd cassandra
```

### 4.2 Démarrage avec Logs Personnalisés (Optionnel)

```bash
cd /Users/david.leconte/Documents/Arkea/hcd-1.2.3

# Créer répertoire de logs
mkdir -p logs

# Démarrer avec logs personnalisés
CASSANDRA_LOG_DIR=$(pwd)/logs bin/hcd cassandra
```

### 4.3 Démarrage en Arrière-plan (Pour développement)

```bash
cd /Users/david.leconte/Documents/Arkea/hcd-1.2.3

# Démarrer en arrière-plan
nohup bin/hcd cassandra > hcd.log 2>&1 &

# Vérifier le processus
ps aux | grep hcd

# Voir les logs
tail -f hcd.log
```

---

## ✅ Étape 5 : Vérification de l'Installation

### 5.1 Vérifier que HCD est Démarré

```bash
# Vérifier les processus
ps aux | grep cassandra

# Vérifier les ports (9042 = CQL, 7000 = inter-node)
lsof -i :9042
lsof -i :7000
```

### 5.2 Connexion avec cqlsh

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

## 🔐 Étape 6 : Sécurisation (Important pour Production)

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

## 📊 Étape 7 : Configuration pour POC

### 7.1 Créer un Keyspace pour le POC

```bash
cqlsh localhost 9042
```

```cql
-- Créer keyspace pour POC
CREATE KEYSPACE IF NOT EXISTS poc_hbase_migration
WITH REPLICATION = {
  'class': 'SimpleStrategy',
  'replication_factor': 1
};

-- Utiliser le keyspace
USE poc_hbase_migration;

-- Vérifier
DESCRIBE KEYSPACE poc_hbase_migration;
```

### 7.2 Configuration Recommandée pour Développement Local

Dans `hcd-1.2.3/resources/cassandra/conf/cassandra.yaml` :

```yaml
# Pour développement local (single node)
endpoint_snitch: SimpleSnitch

# Réplication simple
# (déjà configuré dans les keyspaces avec SimpleStrategy)
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
tail -f hcd-1.2.3/logs/system.log

# 3. Vérifier les ports
lsof -i :9042
lsof -i :7000
```

### Problème : Port déjà utilisé

```bash
# Trouver le processus utilisant le port
lsof -i :9042

# Tuer le processus si nécessaire
kill -9 <PID>
```

### Problème : Erreur de permissions

```bash
# Donner les permissions nécessaires
chmod +x hcd-1.2.3/bin/hcd
```

### Problème : Architecture ARM64

HCD 1.2.3 devrait fonctionner sur ARM64 (Apple Silicon). Si problème :

1. Vérifier que Java 11 est compatible ARM64
2. Utiliser Rosetta 2 si nécessaire (non recommandé)
3. Contacter DataStax Support pour version ARM64 native

---

## 📝 Commandes Utiles

### Gestion HCD

```bash
# Démarrer HCD
cd hcd-1.2.3 && bin/hcd cassandra

# Arrêter HCD (Ctrl+C ou)
pkill -f cassandra

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

1. ✅ **Créer les schémas Domirama/BIC** (voir `PLAN_ACTION_IMMEDIAT.md`)
2. ✅ **Configurer Spark pour se connecter à HCD**
3. ✅ **Développer les jobs Spark** (ingestion, détection, exposition)
4. ✅ **Tester la migration HBase → HCD**

---

## 📚 Références

- [DataStax HCD Installation Guide](https://docs.datastax.com/en/hyper-converged-database/1.2/install/install-tarball.html)
- [HCD Documentation](https://docs.datastax.com/en/hyper-converged-database/1.2/)
- [CQL Reference](https://docs.datastax.com/en/cql-oss/3.3/cql/cql_reference/)

---

## ✅ Checklist d'Installation

- [ ] Java 11 installé et configuré
- [ ] JAVA_HOME pointant vers Java 11
- [ ] HCD extrait (`hcd-1.2.3/`)
- [ ] Répertoires de données créés (optionnel)
- [ ] HCD démarré avec succès
- [ ] Connexion cqlsh fonctionnelle
- [ ] Keyspace POC créé
- [ ] Utilisateur par défaut sécurisé (pour production)

---

**Prêt à installer ?** Suivez les étapes dans l'ordre ! 🚀

