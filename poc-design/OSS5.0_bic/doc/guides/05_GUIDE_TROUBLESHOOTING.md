# 📖 Guide : Dépannage du POC BIC

**Date** : 2025-12-01
**Version** : 1.0.0
**Objectif** : Guide de résolution de problèmes courants

---

## 📋 Table des Matières

- [Problèmes de Connexion](#problèmes-de-connexion)
- [Problèmes d'Ingestion](#problèmes-dingestion)
- [Problèmes de Requêtes](#problèmes-de-requêtes)
- [Problèmes de Performance](#problèmes-de-performance)
- [Problèmes de Configuration](#problèmes-de-configuration)

---

## 🔌 Problèmes de Connexion

### HCD n'est pas accessible

**Symptôme** :

```
❌ HCD n'est pas démarré ou n'est pas accessible sur localhost:9042
```

**Solutions** :

1. **Vérifier que HCD est démarré** :

```bash
ps aux | grep cassandra
```

2. **Démarrer HCD** :

```bash
"$HCD_DIR/bin/cassandra" -f
```

3. **Vérifier la connexion** :

```bash
nc -z localhost 9042
```

4. **Vérifier les logs HCD** :

```bash
tail -f "$HCD_DIR/logs/system.log"
```

---

### Spark ne peut pas se connecter à HCD

**Symptôme** :

```
Couldn't find bic_poc or any similarly named keyspaces
```

**Solutions** :

1. **Vérifier la configuration Spark** :

```bash
"$SPARK_HOME/bin/spark-shell" \
  --conf spark.cassandra.connection.host="localhost" \
  --conf spark.cassandra.connection.port="9042" \
  -e "println(\"Test\")"
```

2. **Vérifier que le keyspace existe** :

```bash
"$HCD_DIR/bin/cqlsh" localhost 9042 -e "DESCRIBE KEYSPACES;"
```

3. **Vérifier les permissions** :

```bash
"$HCD_DIR/bin/cqlsh" localhost 9042 -e "SELECT * FROM system_auth.roles;"
```

---

### Kafka non accessible

**Symptôme** :

```
❌ Kafka n'est pas accessible sur localhost:9092
```

**Solutions** :

1. **Vérifier que Kafka est démarré** :

```bash
ps aux | grep kafka
```

2. **Démarrer Kafka** :

```bash
# Démarrer Zookeeper
zookeeper-server-start.sh "$KAFKA_HOME/config/zookeeper.properties" &

# Démarrer Kafka
kafka-server-start.sh "$KAFKA_HOME/config/server.properties" &
```

3. **Vérifier la connexion** :

```bash
nc -z localhost 9092
```

---

## 📥 Problèmes d'Ingestion

### Aucune donnée après ingestion batch

**Symptôme** : `COUNT(*) = 0` après exécution du script 08

**Solutions** :

1. **Vérifier les logs Spark** :

```bash
tail -f "$SPARK_HOME/logs/spark-*.log" | grep -i error
```

2. **Vérifier que le fichier Parquet existe** :

```bash
ls -lh data/parquet/interactions_*.parquet
```

3. **Vérifier manuellement** :

```bash
"$HCD_DIR/bin/cqlsh" localhost 9042 -e "SELECT COUNT(*) FROM bic_poc.interactions_by_client;"
```

4. **Réexécuter avec vérifications** :

```bash
./scripts/08_load_interactions_batch.sh
```

---

### Erreur Spark-Cassandra Connector

**Symptôme** :

```
java.lang.ClassNotFoundException: com.datastax.spark.connector.CassandraSparkExtensions
```

**Solutions** :

1. **Vérifier que le package est inclus** :

```bash
"$SPARK_HOME/bin/spark-shell" \
  --packages com.datastax.spark:spark-cassandra-connector_2.12:3.4.1 \
  --conf spark.sql.extensions=com.datastax.spark.connector.CassandraSparkExtensions
```

2. **Vérifier la version** :

- Spark 3.5.1 → Connector 3.5.0
- Spark 3.4.x → Connector 3.4.1

---

### Kafka ingestion échoue

**Symptôme** : Aucune donnée ingérée depuis Kafka

**Solutions** :

1. **Vérifier que le topic existe** :

```bash
kafka-topics.sh --list --bootstrap-server localhost:9092
```

2. **Vérifier les messages Kafka** :

```bash
kafka-console-consumer.sh \
  --bootstrap-server localhost:9092 \
  --topic bic-event \
  --from-beginning \
  --max-messages 10
```

3. **Vérifier les checkpoints Spark** :

```bash
ls -la data/checkpoints/kafka_streaming/
```

---

## 🔍 Problèmes de Requêtes

### Requête très lente

**Symptôme** : Requête prend > 1 seconde

**Solutions** :

1. **Vérifier avec TRACING** :

```cql
TRACING ON;
SELECT * FROM bic_poc.interactions_by_client WHERE ...;
```

2. **Vérifier les index SAI** :

```cql
SELECT * FROM system_schema.indexes WHERE keyspace_name = 'bic_poc';
```

3. **Vérifier que la partition key est utilisée** :

```cql
-- ✅ Bon : partition key utilisée
SELECT * FROM ... WHERE code_efs = '...' AND numero_client = '...';

-- ❌ Mauvais : pas de partition key
SELECT * FROM ... WHERE canal = 'email';  -- Nécessite ALLOW FILTERING (lent)
```

4. **Utiliser LIMIT** :

```cql
SELECT * FROM ... LIMIT 100;  -- Limite les résultats
```

---

### Aucun résultat retourné

**Symptôme** : `0 rows` alors que des données existent

**Solutions** :

1. **Vérifier que les données existent** :

```cql
SELECT COUNT(*) FROM bic_poc.interactions_by_client;
```

2. **Vérifier les filtres** :

```cql
-- Vérifier les valeurs disponibles
SELECT DISTINCT canal FROM bic_poc.interactions_by_client;
SELECT DISTINCT type_interaction FROM bic_poc.interactions_by_client;
```

3. **Vérifier la période** :

```cql
SELECT MIN(date_interaction), MAX(date_interaction) FROM bic_poc.interactions_by_client;
```

---

### Erreur "ALLOW FILTERING required"

**Symptôme** :

```
InvalidRequest: Error from server: code=2200 [Invalid query] message="Cannot execute this query as it might involve data filtering and thus may have unpredictable performance. If you want to execute this query despite the performance unpredictability, use ALLOW FILTERING"
```

**Solutions** :

1. **Utiliser les index SAI** :

```cql
-- Créer un index SAI
CREATE CUSTOM INDEX idx_interactions_canal ON bic_poc.interactions_by_client (canal)
USING 'StorageAttachedIndex';

-- Utiliser l'index
SELECT * FROM bic_poc.interactions_by_client
WHERE code_efs = 'EFS001' AND numero_client = 'CLIENT123' AND canal = 'email';
```

2. **Éviter ALLOW FILTERING** (lent, non recommandé)

---

## ⚡ Problèmes de Performance

### Performance dégradée sous charge

**Symptôme** : Temps de réponse > 100ms sous charge

**Solutions** :

1. **Vérifier les ressources système** :

```bash
# CPU
top

# Mémoire
free -h

# Disque
df -h
```

2. **Vérifier les index SAI** :

```cql
SELECT * FROM system_schema.indexes WHERE keyspace_name = 'bic_poc';
```

3. **Optimiser les requêtes** :

- Utiliser LIMIT
- Utiliser la pagination
- Éviter les scans complets

---

### Recherche full-text lente

**Symptôme** : Recherche full-text prend > 200ms

**Solutions** :

1. **Vérifier l'index full-text** :

```cql
SELECT * FROM system_schema.indexes
WHERE keyspace_name = 'bic_poc'
  AND index_name = 'idx_interactions_json_data_fulltext';
```

2. **Recréer l'index si nécessaire** :

```cql
DROP INDEX IF EXISTS bic_poc.idx_interactions_json_data_fulltext;

CREATE CUSTOM INDEX idx_interactions_json_data_fulltext
ON bic_poc.interactions_by_client (json_data)
USING 'StorageAttachedIndex'
WITH OPTIONS = {
    'index_analyzer': '{
        "tokenizer": {"name": "standard"},
        "filters": [
            {"name": "lowercase"},
            {"name": "asciifolding"},
            {"name": "frenchLightStem"}
        ]
    }'
};
```

---

## ⚙️ Problèmes de Configuration

### Variables d'environnement non définies

**Symptôme** :

```
SPARK_HOME n'est pas défini ou le répertoire n'existe pas
```

**Solutions** :

1. **Configurer dans .poc-config.sh** :

```bash
cat >> .poc-config.sh << EOF
export HCD_DIR="/path/to/hcd-1.2.3"
export SPARK_HOME="/path/to/spark-3.5.1"
export HCD_HOST="localhost"
export HCD_PORT="9042"
EOF
```

2. **Charger la configuration** :

```bash
source .poc-profile
```

3. **Vérifier** :

```bash
echo "HCD_DIR: $HCD_DIR"
echo "SPARK_HOME: $SPARK_HOME"
```

---

### Chemins incorrects

**Symptôme** : Scripts ne trouvent pas les fichiers

**Solutions** :

1. **Vérifier les chemins relatifs** :

```bash
cd poc-design/bic
pwd  # Doit être dans le répertoire bic
```

2. **Utiliser les chemins absolus** :

```bash
./scripts/08_load_interactions_batch.sh /absolute/path/to/file.parquet
```

---

## 📚 Ressources

- **Logs HCD** : `$HCD_DIR/logs/system.log`
- **Logs Spark** : `$SPARK_HOME/logs/spark-*.log`
- **Logs Kafka** : `$KAFKA_HOME/logs/server.log`
- **Documentation HCD** : [DataStax Documentation](https://docs.datastax.com/)

---

**Date** : 2025-12-01
**Version** : 1.0.0
