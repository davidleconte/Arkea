# 🔧 Guide de Dépannage - ARKEA

**Date** : 2026-03-13
**Objectif** : Solutions aux problèmes courants du projet ARKEA
**Version** : 1.0

---

## 📋 Table des Matières

- [Problèmes Généraux](#problèmes-généraux)
- [Problèmes HCD](#problèmes-hcd)
- [Problèmes Spark](#problèmes-spark)
- [Problèmes Kafka](#problèmes-kafka)
- [Problèmes de Configuration](#problèmes-de-configuration)
- [Problèmes de Performance](#problèmes-de-performance)
- [FAQ](#faq)

---

## 🔍 Problèmes Généraux

### Erreur : "Command not found"

**Symptômes** :

```bash
bash: cqlsh: command not found
bash: spark-shell: command not found
```

**Solutions** :

1. **Vérifier la configuration** :

```bash
source .poc-profile
check_poc_env
```

2. **Vérifier le PATH** :

```bash
echo $PATH
which cqlsh
which spark-shell
```

3. **Ajouter au PATH manuellement** :

```bash
export PATH="$HCD_DIR/bin:$PATH"
export PATH="$SPARK_HOME/bin:$PATH"
```

**Cross-Platform** :

- **macOS/Linux** : Utiliser `which` ou `command -v`
- **Windows (WSL2)** : Utiliser `which` dans WSL2
- **Git Bash (Windows)** : Certaines commandes peuvent ne pas être disponibles

---

### Erreur : "Permission denied"

**Symptômes** :

```bash
bash: ./script.sh: Permission denied
```

**Solutions** :

```bash
# Ajouter les permissions d'exécution
chmod +x ./script.sh

# Ou pour tous les scripts
find scripts/ -name "*.sh" -exec chmod +x {} \;
```

---

### Erreur : "No such file or directory"

**Symptômes** :

```bash
./scripts/setup/01_install_hcd.sh: No such file or directory
```

**Solutions** :

1. **Vérifier que vous êtes dans le bon répertoire** :

```bash
pwd
# Doit être : /path/to/Arkea
```

2. **Vérifier que les scripts existent** :

```bash
ls -la scripts/setup/
```

3. **Utiliser le chemin absolu** :

```bash
cd /path/to/Arkea
./scripts/setup/01_install_hcd.sh
```

---

## 🗄️ Problèmes HCD

### HCD ne démarre pas

**Symptômes** :

```bash
Error: Address already in use
Error: Cannot bind to address 0.0.0.0:9102
```

**Solutions** :

1. **Vérifier si HCD est déjà démarré (fonction portable)** :

```bash
# Utiliser la fonction portable
source scripts/utils/portable_functions.sh
check_port 9102 && echo "Port 9102 utilisé" || echo "Port 9102 libre"

# Ou manuellement selon l'OS
# macOS/Linux
lsof -i :9102 || ss -tuln | grep 9102

# Windows (WSL2)
netstat -an | grep 9102
```

2. **Tuer les processus existants (fonction portable)** :

```bash
# Utiliser la fonction portable
source scripts/utils/portable_functions.sh
kill_process cassandra

# Ou manuellement selon l'OS
# macOS/Linux
pkill -f cassandra
pkill -f hcd

# Windows (WSL2)
pgrep -f cassandra | xargs kill -9
# Attendre quelques secondes
```

3. **Vérifier les ports** :

```bash
lsof -i :9102
netstat -an | grep 9102
```

4. **Redémarrer** :

```bash
./scripts/setup/03_start_hcd.sh background
```

---

### Erreur de Connexion à HCD

**Symptômes** :

```bash
Connection refused
Timeout connecting to localhost/127.0.0.1:9102
```

**Solutions** :

1. **Vérifier que HCD est démarré** :

```bash
ps aux | grep hcd
```

2. **Vérifier les logs** :

```bash
tail -f binaire/hcd-1.2.3/logs/cassandra/system.log
```

3. **Vérifier la configuration** :

```bash
echo $HCD_HOST
echo $HCD_PORT
```

4. **Tester la connexion** :

```bash
cqlsh $HCD_HOST $HCD_PORT -e "DESCRIBE KEYSPACES;"
```

---

### OutOfMemoryError dans HCD

**Symptômes** :

```bash
java.lang.OutOfMemoryError: Java heap space
```

**Solutions** :

1. **Augmenter la mémoire Java** :

```bash
export JAVA_OPTS="-Xms2G -Xmx4G"
```

2. **Modifier la configuration HCD** :

```bash
# Éditer binaire/hcd-1.2.3/bin/hcd
# Modifier JAVA_OPTS
```

3. **Vérifier la mémoire disponible** :

```bash
free -h  # Linux
vm_stat  # macOS
```

---

### Erreur : "Keyspace does not exist"

**Symptômes** :

```bash
InvalidRequest: Error from server: code=2200 [Invalid query] message="Keyspace 'poc_hbase_migration' does not exist"
```

**Solutions** :

1. **Créer le keyspace** :

```bash
cqlsh $HCD_HOST $HCD_PORT -e "CREATE KEYSPACE IF NOT EXISTS poc_hbase_migration WITH replication = {'class': 'SimpleStrategy', 'replication_factor': 1};"
```

2. **Ou exécuter le script de setup** :

```bash
./scripts/setup/05_setup_kafka_hcd_streaming.sh
```

---

## ⚡ Problèmes Spark

### Spark ne démarre pas

**Symptômes** :

```bash
Error: Could not find or load main class org.apache.spark.deploy.SparkSubmit
```

**Solutions** :

1. **Vérifier l'installation** :

```bash
ls -la $SPARK_HOME/bin/spark-shell
```

2. **Vérifier Java (selon le leg)** :

```bash
java -version
# Podman (OSS 5.0): Java 17
# Binary legacy: Java 11
```

3. **Vérifier JAVA_HOME** :

```bash
echo $JAVA_HOME
# Charger la configuration pour récupérer le bon contexte
source .poc-config.sh
```

---

### Erreur : "ClassNotFoundException"

**Symptômes** :

```bash
java.lang.ClassNotFoundException: com.datastax.spark.connector.CassandraSparkExtensions
```

**Solutions** :

1. **Vérifier le connector** :

```bash
ls -la binaire/spark-jars/spark-cassandra-connector_2.12-3.5.0.jar
```

2. **Ajouter le connector au classpath** :

```bash
spark-shell --jars binaire/spark-jars/spark-cassandra-connector_2.12-3.5.0.jar
```

3. **Ou utiliser --packages** :

```bash
spark-shell --packages com.datastax.spark:spark-cassandra-connector_2.12:3.5.0
```

---

### Erreur de Connexion Spark → HCD

**Symptômes** :

```bash
Connection refused connecting to localhost/127.0.0.1:9102
```

**Solutions** :

1. **Vérifier que HCD est démarré** :

```bash
./scripts/utils/80_verify_all.sh
```

2. **Vérifier la configuration Spark** :

```bash
spark-shell --conf spark.cassandra.connection.host=localhost --conf spark.cassandra.connection.port=9102
```

3. **Tester la connexion** :

```scala
import org.apache.spark.sql.cassandra._
spark.read.cassandraFormat("kafka_events", "poc_hbase_migration").load().show()
```

---

## 📨 Problèmes Kafka

### Kafka ne démarre pas

**Symptômes** :

```bash
Error: Zookeeper is not running
Error: Address already in use
```

**Solutions** :

1. **Vérifier Zookeeper** :

```bash
ps aux | grep zookeeper
lsof -i :2181
```

2. **Démarrer Zookeeper** (si nécessaire) :

```bash
# Kafka inclut Zookeeper, mais peut nécessiter démarrage séparé
```

3. **Vérifier les ports** :

```bash
lsof -i :9192
lsof -i :2181
```

4. **Tuer les processus existants** :

```bash
pkill -f kafka
pkill -f zookeeper
```

5. **Redémarrer** :

```bash
./scripts/setup/04_start_kafka.sh background
```

---

### Erreur : "Topic does not exist"

**Symptômes** :

```bash
Topic 'test-topic' does not exist
```

**Solutions** :

1. **Créer le topic** :

```bash
kafka-topics.sh --create --bootstrap-server localhost:9192 --topic test-topic --partitions 1 --replication-factor 1
```

2. **Lister les topics** :

```bash
kafka-topics.sh --list --bootstrap-server localhost:9192
```

---

### Erreur de Connexion Kafka

**Symptômes** :

```bash
Connection refused
Bootstrap broker localhost:9192 disconnected
```

**Solutions** :

1. **Vérifier que Kafka est démarré** :

```bash
ps aux | grep kafka
```

2. **Vérifier les logs** :

```bash
tail -f $KAFKA_HOME/libexec/logs/kafka.log
```

3. **Vérifier la configuration** :

```bash
echo $KAFKA_BOOTSTRAP_SERVERS
```

---

## ⚙️ Problèmes de Configuration

### Variables d'Environnement Non Définies

**Symptômes** :

```bash
HCD_DIR: command not found
SPARK_HOME: unbound variable
```

**Solutions** :

1. **Charger la configuration** :

```bash
source .poc-profile
```

2. **Vérifier les variables** :

```bash
check_poc_env
```

3. **Vérifier manuellement** :

```bash
echo $HCD_DIR
echo $SPARK_HOME
echo $HCD_HOST
```

---

### Chemins Incorrects

**Symptômes** :

```bash
No such file or directory: ${ARKEA_HOME}/binaire/hcd-1.2.3
```

**Solutions** :

1. **Vérifier ARKEA_HOME** :

```bash
echo $ARKEA_HOME
pwd
```

2. **Définir ARKEA_HOME** :

```bash
export ARKEA_HOME="$(pwd)"
source .poc-profile
```

3. **Vérifier les chemins** :

```bash
ls -la $HCD_DIR
ls -la $SPARK_HOME
```

---

## 🚀 Problèmes de Performance

### HCD Lent

**Symptômes** :

- Requêtes très lentes
- Timeouts fréquents

**Solutions** :

1. **Vérifier la mémoire** :

```bash
nodetool info
```

2. **Vérifier la compaction** :

```bash
nodetool compactionstats
```

3. **Vérifier les index** :

```bash
nodetool tablestats
```

4. **Optimiser les requêtes** :

- Utiliser les index appropriés
- Éviter les scans complets
- Limiter les résultats

---

### Spark Lent

**Symptômes** :

- Jobs très longs
- OutOfMemoryError

**Solutions** :

1. **Augmenter la mémoire** :

```bash
export SPARK_DRIVER_MEMORY="4g"
export SPARK_EXECUTOR_MEMORY="4g"
```

2. **Optimiser les partitions** :

```scala
df.repartition(10)
```

3. **Utiliser le cache** :

```scala
df.cache()
```

---

## ❓ FAQ

### Q : Comment réinitialiser complètement l'environnement ?

**R** :

```bash
# Arrêter tous les services
pkill -f hcd
pkill -f kafka
pkill -f spark

# Supprimer les données
rm -rf hcd-data/*
rm -rf logs/current/*

# Redémarrer
./scripts/setup/03_start_hcd.sh background
./scripts/setup/04_start_kafka.sh background
```

---

### Q : Comment changer le port de HCD ?

**R** :

```bash
# Définir avant de sourcer .poc-profile
export HCD_PORT="9043"
source .poc-profile

# Modifier aussi dans binaire/hcd-1.2.3/resources/cassandra/conf/cassandra.yaml
# rpc_port: 9043
```

---

### Q : Comment voir les logs en temps réel ?

**R** :

```bash
# HCD
tail -f binaire/hcd-1.2.3/logs/cassandra/system.log

# Kafka
tail -f $KAFKA_HOME/libexec/logs/kafka.log

# Spark
tail -f $SPARK_HOME/logs/spark-*.out
```

---

### Q : Comment déboguer un script qui échoue ?

**R** :

```bash
# Activer le mode debug
bash -x ./scripts/setup/01_install_hcd.sh

# Ou ajouter dans le script
set -x  # Activer le debug
```

---

### Q : Comment vérifier que tout fonctionne ?

**R** :

```bash
# Script de vérification complet
./scripts/utils/80_verify_all.sh
```

---

## 📞 Support

Si le problème persiste :

1. **Vérifier les logs** : `logs/`
2. **Consulter la documentation** : `docs/`
3. **Créer une issue** : GitHub Issues
4. **Consulter** : `docs/DEPLOYMENT.md`

---

**Date** : 2026-03-13
**Version** : 1.0
**Statut** : ✅ **Documentation complète**
