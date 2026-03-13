# 📁 Guide de Structure du Projet ARKEA

**Date** : 2026-03-13
**Objectif** : Documenter l'organisation complète du projet

---

## 🏗️ Structure Complète

```
Arkea/
├── README.md                 # Documentation principale
├── .poc-profile              # Configuration environnement (source manuel)
├── .poc-config.sh            # Configuration centralisée (auto-chargée)
├── .gitignore                # Exclusions Git
│
├── scripts/                  # Tous les scripts organisés
│   ├── setup/                # Scripts d'installation/setup
│   │   ├── 01_install_hcd.sh
│   │   ├── 02_install_spark_kafka.sh
│   │   ├── 03_start_hcd.sh
│   │   ├── 04_start_kafka.sh
│   │   ├── 05_setup_kafka_hcd_streaming.sh
│   │   └── 06_test_kafka_hcd_streaming.sh
│   │
│   ├── utils/                # Scripts utilitaires
│   │   ├── 70_kafka-helper.sh
│   │   ├── 80_verify_all.sh
│   │   └── 90_list_scripts.sh
│   │
│   ├── scala/                # Scripts/test Scala
│   │   ├── kafka_to_hcd_streaming.scala
│   │   ├── test_spark_hcd.scala
│   │   ├── test_spark_hcd_connection.scala
│   │   └── test_spark_simple.scala
│   │
│   └── migrate_hardcoded_paths.sh
│
├── schemas/                  # Schémas CQL
│   └── kafka/
│       └── create_kafka_schema.cql
│
├── binaire/                  # Logiciels installés
│   ├── hcd-1.2.3/
│   ├── spark-3.5.1/
│   ├── spark-jars/
│   └── kafka/ (lien symbolique)
│
├── software/                 # Archives des logiciels
│   ├── hcd-1.2.3-bin.tar.gz
│   ├── spark-3.5.1-bin-hadoop3.tgz
│   └── dsbulk-1.11.0.tar.gz
│
├── docs/                     # Documentation complète
│   ├── README.md
│   ├── INDEX.md
│   ├── GUIDE_STRUCTURE.md (ce fichier)
│   └── ... (autres documents)
│
├── inputs-clients/           # Documents fournis par le client
│   ├── Etat de l'art HBase chez Arkéa.pdf
│   └── groupe_*.zip
│
├── inputs-ibm/               # Documents fournis par IBM
│   └── PROPOSITION_MECE_MIGRATION_HBASE_HCD.md
│
├── poc-design/              # POCs de démonstration
│   ├── domirama/            # POC initial
│   ├── domirama2/           # POC table domirama (95% conformité)
│   └── domiramaCatOps/      # POC complet (domirama + meta-categories)
│
├── data/                    # Données de test (optionnel)
├── hcd-data/                # Données HCD (exclu du Git)
│
└── logs/                    # Logs organisés
    ├── archive/             # Logs archivés
    ├── current/             # Logs actuels
    └── UNLOAD_*/            # Logs existants (à archiver)
```

---

## 📦 Description des Répertoires

### `scripts/` - Scripts Organisés

**Organisation** :

- `setup/` : Scripts d'installation, démarrage, configuration
- `utils/` : Scripts utilitaires (vérification, listing, helpers)
- `scala/` : Scripts et tests Scala pour Spark

**Convention** :

- Scripts numérotés (01-06) dans `setup/`
- Scripts numérotés (70-90) dans `utils/`
- Fichiers Scala dans `scala/`

---

### `schemas/` - Schémas CQL

**Organisation** :

- `kafka/` : Schémas liés à Kafka
- Schémas spécifiques aux POCs dans `poc-design/*/schemas/`

---

### `binaire/` - Logiciels Installés

**Contenu** :

- Logiciels extraits et prêts à l'emploi
- Exclu du contrôle de version (via `.gitignore`)

**Composants** :

- HCD 1.2.3
- Spark 3.5.1
- spark-cassandra-connector
- Kafka (lien symbolique)

---

### `software/` - Archives

**Contenu** :

- Fichiers d'archive téléchargés (.tar.gz, .tgz)
- Conservation pour réinstallation

**Taille** : ~469 MB (exclu du Git)

---

### `docs/` - Documentation

**Organisation** :

- Documentation générale du projet
- Guides d'installation
- Analyses et audits
- Documentation spécifique aux POCs dans `poc-design/*/doc/`

---

### `poc-design/` - POCs de Démonstration

**Structure** :

- Chaque POC a sa propre structure :
  - `scripts/` : Scripts du POC
  - `doc/` : Documentation du POC
  - `schemas/` : Schémas CQL du POC
  - `utils/` : Utilitaires du POC

---

### `logs/` - Logs Organisés

**Organisation** :

- `archive/` : Logs archivés (organisés par date)
- `current/` : Logs actuels (organisés par date)
- `UNLOAD_*` : Logs existants (à archiver progressivement)

**Nettoyage** : Les logs sont exclus du Git et peuvent être nettoyés régulièrement

---

## 🔍 Où Trouver Quoi ?

| Type | Emplacement |
|------|-------------|
| **Scripts d'installation** | `scripts/setup/` |
| **Scripts utilitaires** | `scripts/utils/` |
| **Tests Scala** | `scripts/scala/` |
| **Schémas CQL** | `schemas/` ou `poc-design/*/schemas/` |
| **Documentation générale** | `docs/` |
| **Documentation POC** | `poc-design/*/doc/` |
| **Logiciels installés** | `binaire/` |
| **Archives** | `software/` |
| **Logs** | `logs/` |

---

## 📝 Conventions de Nommage

### Scripts Shell

- `setup_*.sh` : Scripts d'installation/setup
- `start_*.sh` : Scripts de démarrage
- `test_*.sh` : Scripts de test
- `*_helper.sh` : Scripts utilitaires

### Fichiers Scala

- `test_*.scala` : Tests
- `*_streaming.scala` : Scripts de streaming

### Schémas CQL

- `create_*.cql` : Schémas de création
- Organisés par domaine (kafka, domirama, etc.)

---

## 🚀 Utilisation

### Exécuter un Script

```bash
# Scripts setup
./scripts/setup/01_install_hcd.sh

# Scripts utils
./scripts/utils/80_verify_all.sh
```

### Charger la Configuration

```bash
# Charger la configuration
source .poc-profile

# Ou utiliser setup_paths() dans les scripts
source .poc-config.sh
```

---

**Date** : 2026-03-13
**Version** : 1.0
