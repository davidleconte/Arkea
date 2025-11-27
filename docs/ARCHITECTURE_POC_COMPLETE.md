# Architecture Complète du POC Migration HBase → HCD

**Date** : 2025-11-25  
**Objectif** : POC complet pour démontrer la migration HBase → HCD

---

## 🏗️ Architecture du POC

```
┌─────────────────────────────────────────────────────────────┐
│                    MacBook Pro M3 Pro                        │
│                                                               │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐      │
│  │   HCD 1.2.3  │  │  Spark 3.5.x │  │  Kafka 3.6.x │      │
│  │  (Cassandra) │  │              │  │              │      │
│  │   Port 9042  │  │              │  │  Port 9092    │      │
│  └──────┬───────┘  └──────┬───────┘  └──────┬───────┘      │
│         │                 │                 │               │
│         └─────────────────┼─────────────────┘               │
│                           │                                  │
│                  ┌────────▼─────────┐                        │
│                  │ spark-cassandra- │                        │
│                  │    connector     │                        │
│                  └──────────────────┘                        │
│                                                               │
│  ┌──────────────────────────────────────────────────────┐   │
│  │         Jobs Spark (POC)                             │   │
│  │  • Ingestion (HBase → HCD)                           │   │
│  │  • Détection (réutilisation logique métier)          │   │
│  │  • Exposition (HCD → API)                            │   │
│  └──────────────────────────────────────────────────────┘   │
│                                                               │
│  ┌──────────────────────────────────────────────────────┐   │
│  │         Schémas HCD                                   │   │
│  │  • poc_hbase_migration (keyspace)                    │   │
│  │  • domirama (table)                                    │   │
│  │  • bi_client (table)                                   │   │
│  └──────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────┘
```

---

## 📦 Composants Installés

### ✅ HCD 1.2.3 (Hyper-Converged Database)
- **Statut** : ✅ Installé et démarré
- **Port CQL** : 9042
- **Port Inter-node** : 7000
- **Version** : 4.0.11.0-0c7d6f7c9412
- **Java** : 11.0.28 (via jenv)

### ⏳ Spark 3.5.x
- **Statut** : À installer
- **Méthode** : Homebrew ou manuel
- **Usage** : Traitement distribué, jobs batch/streaming

### ⏳ spark-cassandra-connector
- **Statut** : À installer
- **Version** : 3.5.0 (compatible Spark 3.5.x)
- **Usage** : Connexion Spark ↔ HCD

### ⏳ Kafka 3.6.x
- **Statut** : À installer
- **Méthode** : Homebrew ou manuel
- **Port** : 9092
- **Usage** : Streaming (simulation BIC/EDM)

---

## 🔄 Flux de Données

### 1. Ingestion Batch (Simulation HBase → HCD)

```
Données Simulées (CSV/JSON)
    ↓
Spark Job (Ingestion)
    ↓
HCD (poc_hbase_migration.domirama)
```

### 2. Streaming (Simulation Kafka → HCD)

```
Kafka Topic (bic-events)
    ↓
Spark Streaming
    ↓
HCD (poc_hbase_migration.bi_client)
```

### 3. Détection (Réutilisation Logique Métier)

```
HCD (domirama)
    ↓
Spark Job (Détection)
    ↓ (réutilisation logique HBase)
HCD (domirama avec catégories)
```

### 4. Exposition

```
HCD (tables)
    ↓
Spark Job (Exposition)
    ↓
API / Export (ORC, JSON, etc.)
```

---

## 📊 Schémas de Données

### Keyspace POC

```cql
CREATE KEYSPACE poc_hbase_migration
WITH REPLICATION = {
  'class': 'SimpleStrategy',
  'replication_factor': 1
};
```

### Table Domirama

```cql
CREATE TABLE poc_hbase_migration.domirama (
    code_si text,
    numero_contrat text,
    operation_date blob,
    data text,
    meta text,
    PRIMARY KEY ((code_si, numero_contrat), operation_date)
) WITH CLUSTERING ORDER BY (operation_date DESC);
```

### Table BIC

```cql
CREATE TABLE poc_hbase_migration.bi_client (
    code_efs text,
    numero_client text,
    date_interaction text,
    cd_canal text,
    idt_tech text,
    json_data text,
    colonnes_dynamiques map<text, text>,
    PRIMARY KEY ((code_efs, numero_client), date_interaction, cd_canal, idt_tech)
) WITH CLUSTERING ORDER BY (date_interaction DESC, cd_canal ASC);
```

---

## 🛠️ Outils et Commandes

### HCD

```bash
# Démarrer
./start_hcd.sh

# Se connecter
cd hcd-1.2.3
./bin/cqlsh localhost 9042

# Arrêter
pkill -f cassandra
```

### Spark

```bash
# Spark Shell avec connector
spark-shell --packages com.datastax.spark:spark-cassandra-connector_2.12:3.5.0 \
  --conf spark.cassandra.connection.host=localhost \
  --conf spark.cassandra.connection.port=9042

# Soumettre un job
spark-submit --packages com.datastax.spark:spark-cassandra-connector_2.12:3.5.0 \
  --class com.example.IngestionJob \
  target/scala-2.12/poc-migration.jar
```

### Kafka

```bash
# Démarrer
brew services start zookeeper
brew services start kafka

# Créer un topic
kafka-topics.sh --create \
  --bootstrap-server localhost:9092 \
  --replication-factor 1 \
  --partitions 1 \
  --topic bic-events

# Producer
kafka-console-producer.sh \
  --bootstrap-server localhost:9092 \
  --topic bic-events

# Consumer
kafka-console-consumer.sh \
  --bootstrap-server localhost:9092 \
  --topic bic-events \
  --from-beginning
```

---

## 📝 Checklist d'Installation

### Infrastructure
- [x] HCD installé et démarré
- [ ] Spark installé
- [ ] spark-cassandra-connector installé
- [ ] Kafka installé
- [ ] Zookeeper installé et démarré

### Configuration
- [ ] SPARK_HOME configuré
- [ ] KAFKA_HOME configuré
- [ ] Variables d'environnement ajoutées
- [ ] Configuration Spark mise à jour

### Tests
- [ ] Spark démarre correctement
- [ ] Connexion Spark → HCD testée
- [ ] Kafka démarre correctement
- [ ] Topic Kafka créé et testé
- [ ] Pipeline Kafka → Spark → HCD testé

### Développement
- [ ] Keyspace POC créé
- [ ] Schémas Domirama/BIC créés
- [ ] Données simulées générées
- [ ] Job Spark Ingestion développé
- [ ] Job Spark Détection développé
- [ ] Job Spark Exposition développé

---

## 🚀 Prochaines Étapes

1. **Installer les composants** :
   ```bash
   ./install_spark_kafka.sh
   ```

2. **Configurer les variables d'environnement** :
   ```bash
   # Ajouter dans ~/.zshrc
   export SPARK_HOME=$(brew --prefix apache-spark)/libexec
   export KAFKA_HOME=$(brew --prefix kafka)
   export PATH=$SPARK_HOME/bin:$KAFKA_HOME/bin:$PATH
   ```

3. **Démarrer les services** :
   ```bash
   # HCD (déjà démarré)
   ./start_hcd.sh
   
   # Kafka
   brew services start zookeeper
   brew services start kafka
   ```

4. **Créer les schémas** :
   ```bash
   cd hcd-1.2.3
   ./bin/cqlsh localhost 9042
   # Exécuter les CREATE KEYSPACE et CREATE TABLE
   ```

5. **Développer les jobs Spark** :
   - Ingestion
   - Détection
   - Exposition

---

## 📚 Documentation

- **Installation HCD** : `GUIDE_INSTALLATION_HCD_MAC.md`
- **Installation Spark/Kafka** : `GUIDE_INSTALLATION_SPARK_KAFKA.md`
- **Plan d'action** : `PLAN_ACTION_IMMEDIAT.md`
- **Analyse HBase** : `ANALYSE_ETAT_ART_HBASE.md`

---

**Architecture prête pour le développement du POC !** 🚀

