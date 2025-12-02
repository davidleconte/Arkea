# 🔍 Diagnostic : Problème d'Écriture HCD - Script 09 Kafka

**Date** : 2025-12-01  
**Script** : `09_load_interactions_realtime.sh`  
**Problème** : Écriture dans HCD échoue lors de l'ingestion Kafka

---

## ❌ Problème Identifié

### Erreur
```
Couldn't find bic_poc or any similarly named keyspaces
```

### Vérifications Effectuées

#### ✅ Keyspace Existe
- Le keyspace `bic_poc` existe bien dans HCD
- Vérifié via `cqlsh` : `SELECT keyspace_name FROM system_schema.keyspaces WHERE keyspace_name = 'bic_poc';`
- Résultat : **Keyspace présent**

#### ✅ Table Existe
- La table `interactions_by_client` existe dans le keyspace `bic_poc`
- Schéma correct et conforme

#### ❌ Spark-Cassandra Connector
- **Problème** : Spark ne peut pas se connecter à HCD ou ne trouve pas le keyspace
- Test d'écriture simple échoue avec la même erreur
- Test de lecture échoue également

---

## 🔍 Causes Probables

### 1. Problème de Connexion Spark-HCD
- Spark Cassandra Connector ne peut pas établir la connexion
- Problème de réseau ou de configuration
- Version incompatible du connecteur

### 2. Configuration Spark-Cassandra
- Configuration `spark.cassandra.connection.host` incorrecte
- Configuration `spark.cassandra.connection.port` incorrecte
- Problème avec `spark.sql.extensions`

### 3. Visibilité du Keyspace
- Le keyspace n'est pas visible depuis Spark
- Problème de permissions ou de réplication

---

## ✅ Solutions Proposées

### Solution 1 : Driver Python Cassandra (Recommandée)

**Avantages** :
- ✅ Plus fiable pour l'ingestion Kafka
- ✅ Contourne les problèmes Spark-Cassandra
- ✅ Plus simple à déboguer
- ✅ Meilleure gestion des erreurs

**Implémentation** :
- Utiliser `kafka-python` pour consommer Kafka
- Utiliser `cassandra-driver` pour écrire dans HCD
- Script Python créé : `/tmp/bic_kafka_direct_*.py`

**Code** :
```python
from kafka import KafkaConsumer
from cassandra.cluster import Cluster
import json

# Connexion Kafka
consumer = KafkaConsumer('bic-event', bootstrap_servers='localhost:9092')

# Connexion HCD
cluster = Cluster(['localhost'], port=9042)
session = cluster.connect('bic_poc')

# Ingestion
for message in consumer:
    event = json.loads(message.value.decode('utf-8'))
    # Transformation et insertion dans HCD
    session.execute(insert_query, (event['code_efs'], ...))
```

---

### Solution 2 : Corriger Spark-Cassandra Connector

**Actions** :
1. Vérifier la version du connecteur
2. Vérifier la configuration réseau
3. Tester avec une connexion directe
4. Vérifier les logs Spark pour plus de détails

**Configuration à vérifier** :
```scala
.config("spark.cassandra.connection.host", "localhost")
.config("spark.cassandra.connection.port", "9042")
.config("spark.cassandra.auth.username", "...")  // Si nécessaire
.config("spark.cassandra.auth.password", "...")  // Si nécessaire
```

---

### Solution 3 : Approche Hybride (Spark + Python)

**Étapes** :
1. Lire Kafka avec Spark → Écrire en Parquet
2. Lire Parquet avec Python → Écrire dans HCD via driver Python

**Avantages** :
- ✅ Utilise Spark pour le traitement (puissant)
- ✅ Utilise Python pour l'écriture (fiable)

---

## 📋 Plan d'Action

### Phase 1 : Solution Immédiate (Python)
- [x] Créer script Python pour ingestion directe
- [ ] Installer dépendances (`kafka-python`, `cassandra-driver`)
- [ ] Tester l'ingestion avec données réelles
- [ ] Intégrer dans le script 09

### Phase 2 : Correction Spark-Cassandra (Optionnel)
- [ ] Vérifier la version du connecteur
- [ ] Tester différentes configurations
- [ ] Vérifier les logs Spark détaillés
- [ ] Documenter la solution

### Phase 3 : Amélioration (Long terme)
- [ ] Créer un script hybride (Spark + Python)
- [ ] Optimiser les performances
- [ ] Ajouter monitoring et alertes

---

## 🔧 Script Python de Contournement

Le script Python suivant a été créé pour contourner le problème :

**Fichier** : `/tmp/bic_kafka_direct_*.py`

**Fonctionnalités** :
- ✅ Consomme Kafka (topic `bic-event`)
- ✅ Parse JSON
- ✅ Transforme vers format HCD
- ✅ Écrit directement dans HCD via driver Python

**Dépendances** :
```bash
pip install kafka-python cassandra-driver
```

**Exécution** :
```bash
python3 /tmp/bic_kafka_direct_*.py
```

---

## 📊 Résultats Attendus

Avec la solution Python :
- ✅ Lecture depuis Kafka : **OK**
- ✅ Parsing JSON : **OK**
- ✅ Écriture dans HCD : **À tester**

---

## 📝 Notes

- Le problème Spark-Cassandra peut être lié à la version du connecteur
- La solution Python est plus simple et plus fiable pour l'ingestion Kafka
- Pour le batch (Parquet), Spark fonctionne correctement (script 08)

---

**Date** : 2025-12-01  
**Statut** : Diagnostic complet, solution proposée

