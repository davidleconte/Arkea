# 📦 Logiciels Installés pour le POC

**Date** : 2025-11-25  
**Répertoire** : `binaire/` - Tous les logiciels du POC

---

## 📋 Contenu

### HCD (Hyper-Converged Database)

- **Répertoire** : `hcd-1.2.3/`
- **Version** : 1.2.3
- **Type** : Installation locale (tarball extrait)
- **Chemin complet** : `binaire/hcd-1.2.3/`
- **Binaire principal** : `binaire/hcd-1.2.3/bin/hcd`
- **Port** : 9042 (CQL)

### Spark

- **Répertoire** : `spark-3.5.1/`
- **Version** : 3.5.1
- **Type** : Installation locale (tarball extrait)
- **Chemin complet** : `binaire/spark-3.5.1/`
- **Binaire principal** : `binaire/spark-3.5.1/bin/spark-shell`
- **Compatible** : Java 11

### Kafka

- **Répertoire** : `kafka/` (lien symbolique)
- **Version** : 4.1.1
- **Type** : Installation Homebrew
- **Chemin réel** : `/opt/homebrew/opt/kafka`
- **Binaire principal** : `kafka/libexec/bin/kafka-server-start.sh`
- **Port** : 9092
- **Compatible** : Java 17

### spark-cassandra-connector

- **Répertoire** : `spark-jars/`
- **Version** : 3.5.0
- **Type** : JAR téléchargé
- **Fichier** : `spark-jars/spark-cassandra-connector_2.12-3.5.0.jar`
- **Usage** : Via `--packages` ou copié dans `$SPARK_HOME/jars/`

---

## 🔗 Chemins Absolus

| Logiciel | Chemin Absolu |
|----------|---------------|
| **HCD** | `/Users/david.leconte/Documents/Arkea/binaire/hcd-1.2.3` |
| **Spark** | `/Users/david.leconte/Documents/Arkea/binaire/spark-3.5.1` |
| **Kafka** | `/opt/homebrew/opt/kafka` (via lien symbolique) |
| **spark-jars** | `/Users/david.leconte/Documents/Arkea/binaire/spark-jars` |

---

## 🚀 Utilisation

### Variables d'Environnement

```bash
export HCD_HOME="/Users/david.leconte/Documents/Arkea/binaire/hcd-1.2.3"
export SPARK_HOME="/Users/david.leconte/Documents/Arkea/binaire/spark-3.5.1"
export KAFKA_HOME="/opt/homebrew/opt/kafka"
export PATH="$SPARK_HOME/bin:$KAFKA_HOME/libexec/bin:$PATH"
```

### Démarrer HCD

```bash
cd binaire/hcd-1.2.3
bin/hcd cassandra
```

### Démarrer Spark Shell

```bash
cd binaire/spark-3.5.1
bin/spark-shell
```

### Démarrer Kafka

```bash
cd /opt/homebrew/opt/kafka
libexec/bin/kafka-server-start.sh .bottle/etc/kafka/server.properties
```

---

## 📝 Notes

- **HCD** et **Spark** sont des installations locales (tarballs extraits)
- **Kafka** est installé via Homebrew, donc le lien symbolique pointe vers `/opt/homebrew/opt/kafka`
- **spark-cassandra-connector** est un JAR téléchargé, utilisé via `--packages` dans Spark
- Tous les logiciels sont maintenant centralisés dans `binaire/`

---

**Tous les logiciels du POC sont organisés dans ce répertoire !** ✅
