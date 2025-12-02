# 🚀 POC Migration HBase → HCD (Hyper-Converged Database)

**Date** : 2025-12-01  
**Version** : 1.0.0  
**Objectif** : Démonstration de faisabilité de la migration HBase vers DataStax HCD  
**IBM | Opportunité ICS 006gR000001hiA5QAI - ARKEA | Ingénieur Avant-Vente** : David LECONTE | <david.leconte1@ibm.com> - Mobile : +33614126117  
**License** : [Apache 2.0](LICENSE)

---

## 📋 Vue d'Ensemble

Ce projet démontre la faisabilité de migrer l'architecture HBase existante chez Arkéa vers DataStax Hyper-Converged Database (HCD) en utilisant Spark, Kafka et Cassandra.

### Composants Principaux

- **HCD 1.2.3** - Base de données cible (basée sur Cassandra 4.0.11)
- **Spark 3.5.1** - Traitement distribué et streaming
- **Kafka 4.1.1** - Streaming de données
- **spark-cassandra-connector 3.5.0** - Intégration Spark ↔ HCD

---

## 🏗️ Structure du Projet

```
Arkea/
├── scripts/             # Scripts organisés
│   ├── setup/           # Scripts d'installation/setup (01-06)
│   ├── utils/           # Scripts utilitaires (70-90)
│   └── scala/           # Scripts/test Scala
├── schemas/             # Schémas CQL
│   └── kafka/           # Schémas Kafka
├── tests/               # Tests automatisés
│   ├── unit/            # Tests unitaires
│   ├── integration/     # Tests d'intégration
│   ├── e2e/             # Tests end-to-end
│   └── fixtures/        # Données de test
├── .github/             # GitHub Actions workflows
│   └── workflows/       # CI/CD
├── inputs-clients/       # Documents fournis par le client
├── inputs-ibm/           # Documents fournis par IBM
├── software/             # Archives des logiciels (.tar.gz, .tgz)
├── binaire/              # Logiciels extraits et installés
├── docs/                 # Documentation complète
├── poc-design/           # POCs de démonstration
├── logs/                 # Logs organisés
│   ├── archive/         # Logs archivés
│   └── current/         # Logs actuels
├── LICENSE               # Licence Apache 2.0
├── CONTRIBUTING.md       # Guide de contribution
├── CHANGELOG.md          # Suivi des versions
├── .editorconfig         # Configuration éditeur
├── .pre-commit-config.yaml # Hooks pre-commit
├── .poc-profile          # Configuration (source manuel)
└── .poc-config.sh        # Configuration centralisée (auto-chargée)
```

**Voir** `docs/GUIDE_STRUCTURE.md` pour la structure complète.

---

## 🚀 Démarrage Rapide

### 1. Configuration de l'Environnement

```bash
cd /path/to/Arkea
source .poc-profile
check_poc_env
```

**Note** : Le projet utilise maintenant `.poc-config.sh` pour une configuration portable. Voir `docs/PLAN_ACTION_FACTORISATION_CONFIG.md` pour les détails.

### 2. Installation

```bash
# Installer HCD
./scripts/setup/01_install_hcd.sh

# Installer Spark et Kafka
./scripts/setup/02_install_spark_kafka.sh
```

### 3. Démarrage des Services

```bash
# Démarrer HCD
./scripts/setup/03_start_hcd.sh background

# Démarrer Kafka
./scripts/setup/04_start_kafka.sh background
```

### 4. Configuration et Test

```bash
# Configurer le streaming Kafka → HCD
./scripts/setup/05_setup_kafka_hcd_streaming.sh

# Tester le pipeline complet
./scripts/setup/06_test_kafka_hcd_streaming.sh
```

---

## 📚 Documentation

Toute la documentation est dans le répertoire `docs/` :

### Guides Principaux

- **ARCHITECTURE.md** - Architecture complète (composants, flux, décisions)
- **DEPLOYMENT.md** - Guide de déploiement complet
- **TROUBLESHOOTING.md** - Guide de dépannage (problèmes courants, solutions, FAQ)
- **GUIDE_STRUCTURE.md** - Structure complète du projet
- **ORDRE_EXECUTION_SCRIPTS.md** - Guide d'exécution des scripts

### Guides Spécialisés

- **GUIDE_INSTALLATION_*** - Guides d'installation (HCD, Spark, Kafka)
- **GUIDE_CHANGELOG.md** - Guide pour maintenir le CHANGELOG
- **INSTALLATION_SHELLCHECK.md** - Installation de ShellCheck
- **ARCHITECTURE_POC_COMPLETE.md** - Architecture technique détaillée
- **ANALYSE_ETAT_ART_HBASE.md** - Analyse de l'existant

Voir `docs/README.md` pour l'index complet.

---

## 🛠️ Scripts Disponibles

### Installation (scripts/setup/)

- `01_install_hcd.sh` - Installe HCD
- `02_install_spark_kafka.sh` - Installe Spark et Kafka
- `03_start_hcd.sh` - Démarre HCD
- `04_start_kafka.sh` - Démarre Kafka
- `05_setup_kafka_hcd_streaming.sh` - Configure le streaming
- `06_test_kafka_hcd_streaming.sh` - Test du pipeline

### Utilitaires (scripts/utils/)

- `70_kafka-helper.sh` - Helper pour Kafka
- `80_verify_all.sh` - Vérifie tous les composants
- `90_list_scripts.sh` - Liste tous les scripts

### Tests Scala (scripts/scala/)

- `test_spark_hcd.scala` - Tests Spark ↔ HCD
- `test_spark_hcd_connection.scala` - Tests de connexion
- `kafka_to_hcd_streaming.scala` - Streaming Kafka → HCD

---

## ⚙️ Configuration

Le fichier `.poc-profile` contient toutes les variables d'environnement nécessaires :

```bash
source .poc-profile
```

Voir `docs/CONFIGURATION_ENVIRONNEMENT.md` pour les détails.

---

## 📊 Objectifs du POC

1. ✅ **Maîtrise de l'existant** - Analyse HBase/MR/Kafka/Elastic
2. ✅ **POC Spark + Cassandra/HCD** - Schémas réalistes, données simulées
3. 🔄 **Réutilisation de la logique métier** - Adaptation de `recurrentDetection` pour Spark
4. 🔄 **Design de migration** - Stratégies HBase → HCD, documentation MECE

---

## 🔍 Vérification

```bash
# Vérifier l'état de tous les composants
./scripts/utils/80_verify_all.sh

# Lister tous les scripts
./scripts/utils/90_list_scripts.sh
```

---

## 📝 Prérequis

- **macOS** (testé sur MacBook Pro M3 Pro)
- **Java 11** (pour HCD et Spark 3.5.1)
- **Java 17** (pour Kafka 4.1.1)
- **Python 3.8-3.11**
- **Homebrew** (pour Kafka)
- **jenv** (recommandé pour gérer les versions Java)

---

## 🧪 Tests

Le projet inclut une structure de tests complète :

```bash
# Exécuter tous les tests
./tests/run_all_tests.sh

# Tests unitaires
./tests/run_unit_tests.sh

# Tests d'intégration
./tests/run_integration_tests.sh

# Tests E2E
./tests/run_e2e_tests.sh
```

Voir `tests/README.md` pour plus de détails.

---

## 🔧 Qualité de Code

### Pre-commit Hooks

Le projet utilise [pre-commit](https://pre-commit.com/) pour valider le code automatiquement :

```bash
# Installation (déjà fait si vous avez suivi le guide)
pip3 install pre-commit
pre-commit install

# Test manuel
pre-commit run --all-files
```

**Hooks configurés** :

- ✅ ShellCheck (linting shell)
- ✅ Black, isort, flake8 (Python)
- ✅ Markdownlint (Markdown)
- ✅ YAMLLint (YAML)
- ✅ Validation de fichiers (JSON, TOML, etc.)

### GitHub Actions

CI/CD automatique configuré (`.github/workflows/`) :

- ✅ Tests de syntaxe
- ✅ Validation de configuration
- ✅ Linting automatique
- ✅ Vérification de structure

Voir `.github/workflows/README.md` pour plus de détails.

---

## 🤝 Contribution

Le projet suit les standards de contribution :

- **CONTRIBUTING.md** - Guide complet de contribution
- **CHANGELOG.md** - Suivi des versions (format Keep a Changelog)
- **LICENSE** - Apache 2.0

**Processus** :

1. Fork le projet
2. Créer une branche (`feature/nom` ou `fix/nom`)
3. Commiter avec messages clairs (voir CONTRIBUTING.md)
4. Pousser et créer une Pull Request

---

## 📖 Pour Plus d'Informations

- Documentation complète : `docs/`
- Architecture : `docs/ARCHITECTURE.md`
- Déploiement : `docs/DEPLOYMENT.md`
- Dépannage : `docs/TROUBLESHOOTING.md`
- Structure : `docs/GUIDE_STRUCTURE.md`
- Configuration : `docs/CONFIGURATION_ENVIRONNEMENT.md`
- Contribution : `CONTRIBUTING.md`
- Changelog : `CHANGELOG.md`

---

## ✅ Statut

### Infrastructure

- ✅ Infrastructure installée et opérationnelle
- ✅ Pipeline Kafka → HCD fonctionnel
- ✅ Configuration centralisée et portable

### Qualité et Tests

- ✅ Structure de tests créée
- ✅ Pre-commit hooks configurés
- ✅ GitHub Actions CI/CD configuré
- ✅ Documentation complète

### Conformité

- ✅ License Apache 2.0
- ✅ Guide de contribution
- ✅ CHANGELOG maintenu
- ✅ Standards de code (`.editorconfig`)

### Développement

- 🔄 Schémas Domirama/BIC à créer
- 🔄 Jobs Spark métier à développer
- 🔄 Tests unitaires et d'intégration à compléter

---

## 📊 Métriques

- **Score de conformité** : ~90% (bonnes pratiques)
- **Documentation** : Complète et à jour
- **Tests** : Structure prête, tests à développer
- **CI/CD** : Configuré et opérationnel

---

**POC opérationnel, conforme aux bonnes pratiques et prêt pour le développement !** 🚀
