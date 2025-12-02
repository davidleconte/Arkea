# 📖 Guide : Configuration et Setup du POC BIC

**Date** : 2025-12-01  
**Version** : 1.0.0  
**Objectif** : Guide complet pour configurer et initialiser le POC BIC

---

## 📋 Table des Matières

- [Prérequis](#prérequis)
- [Configuration de l'Environnement](#configuration-de-lenvironnement)
- [Setup Initial](#setup-initial)
- [Vérification](#vérification)
- [Dépannage](#dépannage)

---

## 🔧 Prérequis

### Logiciels Requis

- **HCD 1.2.3** : DataStax Hyper-Converged Database
- **Spark 3.5.1** : Pour l'ingestion batch et streaming
- **Kafka 4.1.1** : Pour l'ingestion temps réel (optionnel)
- **Python 3.8-3.11** : Pour la génération de données
- **Bash 4.0+** : Pour l'exécution des scripts

### Variables d'Environnement

Les variables suivantes doivent être configurées (via `.poc-config.sh` ou variables d'environnement) :

- `HCD_DIR` : Chemin vers HCD (ex: `/path/to/hcd-1.2.3`)
- `SPARK_HOME` : Chemin vers Spark (ex: `/path/to/spark-3.5.1`)
- `HCD_HOST` : Host HCD (défaut: `localhost`)
- `HCD_PORT` : Port HCD (défaut: `9042`)
- `KAFKA_BOOTSTRAP_SERVERS` : Serveurs Kafka (défaut: `localhost:9092`)

---

## ⚙️ Configuration de l'Environnement

### 1. Charger la Configuration

```bash
cd /path/to/Arkea
source .poc-profile
check_poc_env
```

### 2. Vérifier les Chemins

```bash
echo "HCD_DIR: $HCD_DIR"
echo "SPARK_HOME: $SPARK_HOME"
echo "HCD_HOST: $HCD_HOST"
echo "HCD_PORT: $HCD_PORT"
```

### 3. Vérifier les Prérequis

```bash
# Vérifier Python
python3 --version  # Doit être 3.8+

# Vérifier Spark
"$SPARK_HOME/bin/spark-shell" --version

# Vérifier HCD
"$HCD_DIR/bin/cqlsh" --version
```

---

## 🚀 Setup Initial

### Étape 1 : Créer le Keyspace

```bash
cd poc-design/bic
./scripts/01_setup_bic_keyspace.sh
```

**Résultat attendu** : Keyspace `bic_poc` créé

### Étape 2 : Créer les Tables

```bash
./scripts/02_setup_bic_tables.sh
```

**Résultat attendu** : Table `interactions_by_client` créée avec :

- Partition key : `(code_efs, numero_client)`
- Clustering key : `(date_interaction, canal, type_interaction, idt_tech)`
- TTL : 2 ans (63072000 secondes)

### Étape 3 : Créer les Index SAI

```bash
./scripts/03_setup_bic_indexes.sh
```

**Résultat attendu** : Index SAI créés :

- `idx_interactions_canal` : Index sur `canal`
- `idx_interactions_type` : Index sur `type_interaction`
- `idx_interactions_resultat` : Index sur `resultat`
- `idx_interactions_date` : Index sur `date_interaction`
- `idx_interactions_json_data_fulltext` : Index full-text sur `json_data`

### Étape 4 : Vérifier le Setup

```bash
./scripts/04_verify_setup.sh
```

**Résultat attendu** : Toutes les vérifications passent

---

## ✅ Vérification

### Vérifier le Schéma

```bash
"$HCD_DIR/bin/cqlsh" "$HCD_HOST" "$HCD_PORT" -e "DESCRIBE KEYSPACE bic_poc;"
```

### Vérifier les Index

```bash
"$HCD_DIR/bin/cqlsh" "$HCD_HOST" "$HCD_PORT" -e "SELECT * FROM system_schema.indexes WHERE keyspace_name = 'bic_poc';"
```

### Vérifier la Table

```bash
"$HCD_DIR/bin/cqlsh" "$HCD_HOST" "$HCD_PORT" -e "DESCRIBE TABLE bic_poc.interactions_by_client;"
```

---

## 🔍 Dépannage

### Problème : HCD n'est pas démarré

**Symptôme** : `Connection refused` ou `HCD n'est pas démarré`

**Solution** :

```bash
# Démarrer HCD
"$HCD_DIR/bin/cassandra" -f
```

### Problème : Spark non trouvé

**Symptôme** : `SPARK_HOME non trouvé`

**Solution** :

```bash
# Définir SPARK_HOME
export SPARK_HOME="/path/to/spark-3.5.1"

# Ou configurer dans .poc-config.sh
echo "export SPARK_HOME=\"/path/to/spark-3.5.1\"" >> .poc-config.sh
```

### Problème : Keyspace existe déjà

**Symptôme** : `Keyspace already exists`

**Solution** :

```bash
# Supprimer le keyspace existant (ATTENTION : supprime toutes les données)
"$HCD_DIR/bin/cqlsh" "$HCD_HOST" "$HCD_PORT" -e "DROP KEYSPACE IF EXISTS bic_poc;"

# Recréer
./scripts/01_setup_bic_keyspace.sh
```

### Problème : Index SAI non créé

**Symptôme** : `Index creation failed`

**Solution** :

```bash
# Vérifier que HCD supporte SAI
"$HCD_DIR/bin/cqlsh" "$HCD_HOST" "$HCD_PORT" -e "SELECT * FROM system_schema.indexes WHERE index_type = 'StorageAttachedIndex';"

# Recréer l'index
"$HCD_DIR/bin/cqlsh" "$HCD_HOST" "$HCD_PORT" -e "CREATE CUSTOM INDEX idx_interactions_canal ON bic_poc.interactions_by_client (canal) USING 'StorageAttachedIndex';"
```

---

## 📚 Prochaines Étapes

Après le setup initial, vous pouvez :

1. **Générer des données** : `./scripts/05_generate_interactions_parquet.sh`
2. **Ingérer des données** : `./scripts/08_load_interactions_batch.sh`
3. **Tester les requêtes** : `./scripts/11_test_timeline_conseiller.sh`

Voir le [Guide d'Ingestion](03_GUIDE_INGESTION.md) pour plus de détails.

---

**Date** : 2025-12-01  
**Version** : 1.0.0
