# 📖 Guide : Ingestion de Données dans le POC BIC

**Date** : 2025-12-01  
**Version** : 1.0.0  
**Objectif** : Guide complet pour ingérer des données dans HCD

---

## 📋 Table des Matières

- [Vue d'Ensemble](#vue-densemble)
- [Ingestion Batch (Parquet)](#ingestion-batch-parquet)
- [Ingestion Temps Réel (Kafka)](#ingestion-temps-réel-kafka)
- [Ingestion JSON](#ingestion-json)
- [Vérification](#vérification)
- [Dépannage](#dépannage)

---

## 🎯 Vue d'Ensemble

Le POC BIC supporte trois modes d'ingestion :

1. **Batch (Parquet)** : Chargement massif depuis fichiers Parquet (équivalent HBase bulkLoad)
2. **Temps Réel (Kafka)** : Ingestion streaming depuis Kafka (topic `bic-event`)
3. **JSON** : Chargement depuis fichiers JSON individuels

---

## 📥 Ingestion Batch (Parquet)

### Prérequis

- Fichier Parquet généré (script 05)
- Spark configuré et accessible
- HCD démarré

### Génération des Données

```bash
# Générer 10 000 interactions (volume medium)
./scripts/05_generate_interactions_parquet.sh medium

# Ou volumes personnalisés
./scripts/05_generate_interactions_parquet.sh small   # 1 000
./scripts/05_generate_interactions_parquet.sh large   # 100 000
./scripts/05_generate_interactions_parquet.sh huge    # 1 000 000
```

### Chargement dans HCD

```bash
./scripts/08_load_interactions_batch.sh
```

**Options** :

- Premier argument : Chemin vers le fichier Parquet (optionnel)
- Par défaut : `data/parquet/interactions_10000.parquet`

**Résultat attendu** :

- Données chargées dans `bic_poc.interactions_by_client`
- Rapport généré : `doc/demonstrations/08_INGESTION_BATCH_DEMONSTRATION.md`

### Vérification

```bash
"$HCD_DIR/bin/cqlsh" "$HCD_HOST" "$HCD_PORT" -e "SELECT COUNT(*) FROM bic_poc.interactions_by_client;"
```

---

## 🔄 Ingestion Temps Réel (Kafka)

### Prérequis

- Kafka démarré et accessible
- Topic `bic-event` créé
- Spark configuré

### Créer le Topic Kafka

```bash
kafka-topics.sh --create \
  --bootstrap-server localhost:9092 \
  --topic bic-event \
  --partitions 3 \
  --replication-factor 1
```

### Générer des Événements JSON

```bash
# Générer 1 000 événements JSON
./scripts/06_generate_interactions_json.sh small
```

### Ingestion Streaming

```bash
./scripts/09_load_interactions_realtime.sh 10
```

**Options** :

- Premier argument : Nombre d'événements à traiter (défaut: 10)
- Deuxième argument : Mode démo (true/false, défaut: true)

**Résultat attendu** :

- Événements Kafka traités et chargés dans HCD
- Rapport généré : `doc/demonstrations/09_INGESTION_KAFKA_DEMONSTRATION.md`

### Vérification

```bash
# Vérifier les messages Kafka
kafka-console-consumer.sh \
  --bootstrap-server localhost:9092 \
  --topic bic-event \
  --from-beginning \
  --max-messages 10

# Vérifier les données dans HCD
"$HCD_DIR/bin/cqlsh" "$HCD_HOST" "$HCD_PORT" -e "SELECT COUNT(*) FROM bic_poc.interactions_by_client;"
```

---

## 📄 Ingestion JSON

### Prérequis

- Fichier JSON généré (script 06)
- Spark configuré
- HCD démarré

### Génération des Données

```bash
# Générer 1 000 interactions JSON
./scripts/06_generate_interactions_json.sh small
```

### Chargement dans HCD

```bash
./scripts/10_load_interactions_json.sh
```

**Options** :

- Premier argument : Chemin vers le fichier JSON (optionnel)
- Par défaut : `data/json/interactions_1000.json`

**Résultat attendu** :

- Données chargées dans HCD
- Rapport généré : `doc/demonstrations/10_INGESTION_JSON_DEMONSTRATION.md`

---

## ✅ Vérification

### Compter les Interactions

```bash
"$HCD_DIR/bin/cqlsh" "$HCD_HOST" "$HCD_PORT" -e "SELECT COUNT(*) FROM bic_poc.interactions_by_client;"
```

### Vérifier un Client Spécifique

```bash
"$HCD_DIR/bin/cqlsh" "$HCD_HOST" "$HCD_PORT" -e "SELECT * FROM bic_poc.interactions_by_client WHERE code_efs = 'EFS001' AND numero_client = 'CLIENT123' LIMIT 10;"
```

### Vérifier la Distribution

```bash
# Par canal
"$HCD_DIR/bin/cqlsh" "$HCD_HOST" "$HCD_PORT" -e "SELECT canal, COUNT(*) FROM bic_poc.interactions_by_client GROUP BY canal;"

# Par type
"$HCD_DIR/bin/cqlsh" "$HCD_HOST" "$HCD_PORT" -e "SELECT type_interaction, COUNT(*) FROM bic_poc.interactions_by_client GROUP BY type_interaction;"
```

---

## 🔍 Dépannage

### Problème : Spark ne peut pas se connecter à HCD

**Symptôme** : `Couldn't find bic_poc or any similarly named keyspaces`

**Solution** :

```bash
# Vérifier que HCD est démarré
nc -z "$HCD_HOST" "$HCD_PORT"

# Vérifier la configuration Spark
"$SPARK_HOME/bin/spark-shell" \
  --conf spark.cassandra.connection.host="$HCD_HOST" \
  --conf spark.cassandra.connection.port="$HCD_PORT" \
  -e "println(\"Test connection\")"
```

### Problème : Kafka non accessible

**Symptôme** : `Kafka n'est pas accessible`

**Solution** :

```bash
# Vérifier que Kafka est démarré
nc -z localhost 9092

# Vérifier les topics
kafka-topics.sh --list --bootstrap-server localhost:9092
```

### Problème : Aucune donnée après ingestion

**Symptôme** : `COUNT(*) = 0`

**Solution** :

```bash
# Vérifier les logs Spark
tail -f "$SPARK_HOME/logs/spark-*.log"

# Vérifier manuellement
"$HCD_DIR/bin/cqlsh" "$HCD_HOST" "$HCD_PORT" -e "SELECT * FROM bic_poc.interactions_by_client LIMIT 1;"
```

---

## 📚 Prochaines Étapes

Après l'ingestion, vous pouvez :

1. **Tester les requêtes** : `./scripts/11_test_timeline_conseiller.sh`
2. **Tester les filtres** : `./scripts/12_test_filtrage_canal.sh`
3. **Tester la recherche** : `./scripts/16_test_fulltext_search.sh`

Voir le [Guide de Recherche](04_GUIDE_RECHERCHE.md) pour plus de détails.

---

**Date** : 2025-12-01  
**Version** : 1.0.0
