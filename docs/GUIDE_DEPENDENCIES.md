# 📦 Guide des Dépendances - Projet ARKEA

**Date** : 2026-03-13
**Objectif** : Documentation complète des dépendances du projet ARKEA

---

## 📋 Table des Matières

- [Dépendances Python](#dépendances-python)
- [Dépendances Java](#dépendances-java)
- [Installation](#installation)
- [Mise à Jour](#mise-à-jour)

---

## 🐍 Dépendances Python

### Fichiers de Dépendances

- **`requirements.txt`** : Dépendances de production
- **`requirements-dev.txt`** : Dépendances de développement (inclut `requirements.txt`)

### Installation

```bash
# Installation des dépendances de production
pip install -r requirements.txt

# Installation des dépendances de développement
pip install -r requirements-dev.txt
```

### Dépendances Principales

#### Core Dependencies

- **astrapy** (>=2.0,<3.0) : Client Data API HCD
- **cassandra-driver** (>=3.28.0) : Driver Python pour Cassandra/HCD
- **cqlsh** (>=6.0.0) : Shell CQL pour tests et scripts

#### Machine Learning / Embeddings

- **torch** (>=2.0.0) : PyTorch pour embeddings
- **transformers** (>=4.30.0) : Hugging Face Transformers
- **sentence-transformers** (>=2.2.0) : Sentence Transformers

#### Data Processing

- **pandas** (>=2.0.0) : Manipulation de données
- **numpy** (>=1.24.0) : Calculs numériques

#### Testing & Quality

- **pytest** (>=7.4.0) : Framework de tests
- **pytest-cov** (>=4.1.0) : Couverture de code
- **pre-commit** (>=3.4.0) : Hooks pre-commit

#### Utilities

- **requests** (>=2.31.0) : Requêtes HTTP
- **pyyaml** (>=6.0) : Parsing YAML

---

## ☕ Dépendances Java

### Versions Requises

- **Java 17** : Recommandé pour Cassandra 5.0.6, Spark 3.5.1 et Kafka 3.7.1

### Composants Principaux

- **Apache Cassandra 5.0.6** : Base de données distribuée (OSS)
- **Spark 3.5.1** : Traitement distribué
- **Kafka 3.7.1 (KRaft)** : Streaming de données
- **spark-cassandra-connector 3.5.0** : Intégration Spark ↔ Cassandra

### Guides d'installation

Voir les guides d'installation :

- [Guide Installation HCD (Legacy)](archive/legacy_v1/GUIDE_INSTALLATION_HCD.md)
- [Guide Installation Spark/Kafka (Legacy)](archive/legacy_v1/GUIDE_INSTALLATION_SPARK_KAFKA.md)

---

## 📦 Installation

### Installation Complète

```bash
# 1. Installer les dépendances Python
pip install -r requirements.txt

# 2. Installer les dépendances de développement (optionnel)
pip install -r requirements-dev.txt

# 3. Installer HCD, Spark, Kafka
./scripts/setup/01_install_hcd.sh
./scripts/setup/02_install_spark_kafka.sh
```

### Installation dans un Environnement Virtuel

```bash
# Créer un environnement virtuel
python3 -m venv venv

# Activer l'environnement
source venv/bin/activate  # macOS/Linux
# ou
venv\Scripts\activate  # Windows

# Installer les dépendances
pip install -r requirements.txt
```

---

## 🔄 Mise à Jour

### Mettre à Jour les Dépendances Python

```bash
# Mettre à jour toutes les dépendances
pip install --upgrade -r requirements.txt

# Mettre à jour une dépendance spécifique
pip install --upgrade astrapy

# Vérifier les versions installées
pip list
```

### Mettre à Jour les Composants Java

Les composants Java (HCD, Spark, Kafka) sont installés manuellement via les scripts d'installation.

Pour mettre à jour :

1. Télécharger la nouvelle version
2. Suivre les guides d'installation
3. Mettre à jour les variables dans `.poc-config.sh`

---

## 🔍 Vérification

### Vérifier les Dépendances Python

```bash
# Lister les dépendances installées
pip list

# Vérifier les versions
pip check
```

### Vérifier les Composants Java

```bash
# Vérifier Java
java -version

# Vérifier HCD
$HCD_DIR/bin/cassandra -v

# Vérifier Spark
$SPARK_HOME/bin/spark-shell --version

# Vérifier Kafka
$KAFKA_HOME/bin/kafka-topics.sh --version
```

---

## 📝 Notes

- Les versions sont épinglées (pinned) pour assurer la reproductibilité
- Les dépendances de développement ne sont pas nécessaires en production
- Les composants Java sont installés séparément (non gérés par pip)

---

**Pour plus d'informations** :

- [Guide de Déploiement](DEPLOYMENT.md)
- [Configuration Environnement](CONFIGURATION_ENVIRONNEMENT.md)
