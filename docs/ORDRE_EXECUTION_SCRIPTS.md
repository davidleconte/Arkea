# Ordre d'Exécution des Scripts

**Date** : 2025-11-25  
**Organisation** : Scripts numérotés selon l'ordre d'exécution logique

---

## 📋 Scripts d'Installation et Configuration (01-06)

### 01_install_hcd.sh
**Ordre** : 1  
**Description** : Installe HCD 1.2.3  
**Usage** : `./01_install_hcd.sh`  
**Prérequis** : Java 11, Python 3.8-3.11

### 02_install_spark_kafka.sh
**Ordre** : 2  
**Description** : Installe Spark 3.5.1, Kafka et spark-cassandra-connector  
**Usage** : `./02_install_spark_kafka.sh`  
**Prérequis** : Java 11, Homebrew

### 03_start_hcd.sh
**Ordre** : 3  
**Description** : Démarre HCD  
**Usage** : `./03_start_hcd.sh [background]`  
**Prérequis** : HCD installé (01_install_hcd.sh)

### 04_start_kafka.sh
**Ordre** : 4  
**Description** : Démarre Kafka  
**Usage** : `./04_start_kafka.sh [background]`  
**Prérequis** : Kafka installé (02_install_spark_kafka.sh)

### 05_setup_kafka_hcd_streaming.sh
**Ordre** : 5  
**Description** : Configure le streaming Kafka → HCD  
**Usage** : `./05_setup_kafka_hcd_streaming.sh`  
**Prérequis** : HCD et Kafka démarrés (03 et 04)

### 06_test_kafka_hcd_streaming.sh
**Ordre** : 6  
**Description** : Test complet du pipeline Kafka → HCD  
**Usage** : `./06_test_kafka_hcd_streaming.sh`  
**Prérequis** : Configuration terminée (05)

---

## 🛠️ Scripts Utilitaires (70-90)

### 70_kafka-helper.sh
**Ordre** : Utilitaire (pas d'ordre spécifique)  
**Description** : Helper pour utiliser les outils Kafka avec Java 17  
**Usage** : `./70_kafka-helper.sh <commande> [arguments...]`  
**Exemple** : `./70_kafka-helper.sh kafka-topics.sh --list --bootstrap-server localhost:9092`

### 80_verify_all.sh
**Ordre** : Utilitaire (peut être lancé à tout moment)  
**Description** : Vérifie l'état de tous les composants  
**Usage** : `./80_verify_all.sh`  
**Utile pour** : Vérifier l'installation et l'état des services

### 90_list_scripts.sh
**Ordre** : Utilitaire (peut être lancé à tout moment)  
**Description** : Liste tous les scripts disponibles avec leur description  
**Usage** : `./90_list_scripts.sh`

---

## 🚀 Workflow Complet

### Installation Initiale
```bash
# 1. Installer HCD
./01_install_hcd.sh

# 2. Installer Spark et Kafka
./02_install_spark_kafka.sh

# 3. Démarrer HCD
./03_start_hcd.sh background

# 4. Démarrer Kafka
./04_start_kafka.sh background

# 5. Configurer le streaming
./05_setup_kafka_hcd_streaming.sh

# 6. Tester le pipeline
./06_test_kafka_hcd_streaming.sh
```

### Vérification
```bash
# Vérifier l'état de tous les composants
./80_verify_all.sh

# Lister tous les scripts disponibles
./90_list_scripts.sh
```

### Utilisation Kafka
```bash
# Lister les topics
./70_kafka-helper.sh kafka-topics.sh --list --bootstrap-server localhost:9092

# Produire des messages
./70_kafka-helper.sh kafka-console-producer.sh \
  --bootstrap-server localhost:9092 \
  --topic test-topic
```

---

## 📝 Notes

- Les scripts 01-06 doivent être exécutés dans l'ordre pour une installation complète
- Les scripts 70-90 sont des utilitaires et peuvent être utilisés à tout moment
- Utilisez `./80_verify_all.sh` pour vérifier l'état avant de lancer les tests

---

**Tous les scripts sont numérotés pour faciliter l'utilisation !**
