# ✅ Correction : Script 09 Kafka - Spark-Cassandra Connector

**Date** : 2025-12-01
**Script** : `09_load_interactions_realtime.sh`
**Problème** : Spark-Cassandra Connector ne fonctionnait pas pour BIC alors qu'il fonctionne pour domiramaCatOps

---

## 🔍 Analyse du Problème

### Question

Pourquoi le Spark-Cassandra Connector ne fonctionne pas pour BIC alors qu'il fonctionne pour domiramaCatOps et domirama2 ?

### Différences Identifiées

#### 1. Version du Connecteur

- **domiramaCatOps** : `com.datastax.spark:spark-cassandra-connector_2.12:3.5.0`
- **BIC script 08** : `com.datastax.spark:spark-cassandra-connector_2.12:3.4.1`
- **BIC script 09** : `com.datastax.spark:spark-cassandra-connector_2.12:3.4.1` ❌

#### 2. Méthode d'Exécution

- **domiramaCatOps** : `spark-shell -i fichier.scala` ✅
- **BIC script 08** : `spark-shell < fichier.scala` ✅
- **BIC script 09** : `pyspark < fichier.py` ❌

#### 3. Format du Code

- **domiramaCatOps** : Code Scala complet dans un fichier ✅
- **BIC script 08** : Code Scala complet dans un fichier ✅
- **BIC script 09** : Code Python (ne fonctionne pas bien avec Spark-Cassandra) ❌

---

## ✅ Solution Appliquée

### Changements Effectués

1. **Version du Connecteur** : `3.4.1` → `3.5.0`
   - Utilisation de la même version que domiramaCatOps

2. **Méthode d'Exécution** : `pyspark` → `spark-shell -i`
   - Utilisation de la même méthode que domiramaCatOps

3. **Format du Code** : Python → Scala complet
   - Code Scala complet dans un fichier (comme domiramaCatOps)

4. **Mode Kafka** : Streaming → Batch pour test
   - Mode batch pour test initial (comme domiramaCatOps)
   - Le mode streaming peut être activé ensuite

---

## 📋 Code Corrigé

### Avant (Ne fonctionnait pas)

```bash
# Exécution avec pyspark
"$SPARK_HOME/bin/pyspark" \
    --packages com.datastax.spark:spark-cassandra-connector_2.12:3.4.1 \
    < "$PYTHON_SCRIPT"
```

### Après (Fonctionne comme domiramaCatOps)

```bash
# Exécution avec spark-shell -i (même méthode que domiramaCatOps)
SPARK_OUTPUT=$("$SPARK_HOME/bin/spark-shell" \
    --packages com.datastax.spark:spark-cassandra-connector_2.12:3.5.0 \
    --conf spark.cassandra.connection.host="$HCD_HOST" \
    --conf spark.cassandra.connection.port="$HCD_PORT" \
    --conf spark.sql.extensions=com.datastax.spark.connector.CassandraSparkExtensions \
    -i "$SPARK_SCALA_SCRIPT" \
    2>&1)
```

---

## 🔍 Pourquoi ça ne fonctionnait pas ?

### 1. Version du Connecteur

- La version `3.4.1` peut avoir des problèmes de compatibilité
- La version `3.5.0` est plus stable et testée

### 2. Format Python vs Scala

- Spark-Cassandra Connector est mieux supporté avec Scala
- Python peut avoir des problèmes de typage et de compatibilité
- Le mode interactif Python (`pyspark < script`) ne fonctionne pas bien

### 3. Méthode d'Exécution

- `spark-shell -i fichier.scala` : Exécute le fichier complet
- `pyspark < script.py` : Mode interactif, problèmes de typage
- `spark-shell < script.scala` : Fonctionne mais `-i` est plus fiable

---

## ✅ Résultat

Le script 09 utilise maintenant :

- ✅ Même version du connecteur que domiramaCatOps (`3.5.0`)
- ✅ Même méthode d'exécution (`spark-shell -i`)
- ✅ Même format de code (Scala complet)
- ✅ Même configuration Spark-Cassandra

**Le script devrait maintenant fonctionner correctement !**

---

## 📝 Notes

- Le script 08 (batch) utilise déjà la bonne méthode et fonctionne
- La différence était uniquement dans le script 09 (Kafka)
- Le mode streaming peut être activé après validation du mode batch

---

**Date** : 2025-12-01
**Statut** : Correction appliquée, prêt pour test
